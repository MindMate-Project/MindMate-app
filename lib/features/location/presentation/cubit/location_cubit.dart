import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';
import 'package:mindmate/core/services/caregiver_notification_preferences.dart';
import 'package:mindmate/features/location/data/models/geofence_alert_event.dart';
import 'package:mindmate/features/location/data/models/location_exception.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';
import 'package:mindmate/features/location/data/services/geofence_alert_service.dart';
import 'package:mindmate/features/location/data/services/location_service.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
import 'location_state.dart';

enum _LoadMode { initial, explicit, silent }

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(
    this._locationService, {
    GeofenceAlertService? geofenceAlertService,
  })  : _geofenceAlertService = geofenceAlertService ?? GeofenceAlertService(),
        super(const LocationInitial());

  final LocationService _locationService;
  final GeofenceAlertService _geofenceAlertService;
  String? _patientId;
  String _patientName = 'Patient';
  bool _useDeviceLocation = false;
  _LoadMode _loadMode = _LoadMode.initial;
  Timer? _refreshTimer;
  StreamSubscription<Position>? _devicePositionSub;
  bool? _pollWhileOnline;
  int _loadSeq = 0;
  Future<void>? _ongoingLoad;

  static const _onlinePollInterval = Duration(seconds: 5);
  static const _offlinePollInterval = Duration(seconds: 30);

  String? get patientId => _patientId;
  String get patientName => _patientName;

  Future<void> load({
    String? patientId,
    String? patientName,
  }) async {
    if (_ongoingLoad != null) {
      await _ongoingLoad;
      return;
    }

    final future = _loadInternal(
      patientId: patientId,
      patientName: patientName,
    );
    _ongoingLoad = future;
    try {
      await future;
    } finally {
      if (identical(_ongoingLoad, future)) {
        _ongoingLoad = null;
      }
    }
  }

  Future<void> _loadInternal({
    String? patientId,
    String? patientName,
  }) async {
    if (isClosed) return;

    _useDeviceLocation = await _locationService.getUseDeviceLocation();

    final seq = ++_loadSeq;

    final patientChanged =
        patientId != null && patientId.isNotEmpty && patientId != _patientId;
    if (patientId != null) _patientId = patientId;
    if (patientName != null) _patientName = patientName;
    if (patientChanged) {
      _loadMode = _LoadMode.initial;
      _geofenceAlertService.resetPatient(_patientId ?? '');
    }

    final hasPatient = _patientId != null && _patientId!.isNotEmpty;

    if (!hasPatient && !_useDeviceLocation) {
      _emit(
        seq,
        LocationNoPatient(useDeviceLocation: _useDeviceLocation),
      );
      return;
    }

    if (_loadMode != _LoadMode.silent) {
      _emit(
        seq,
        LocationLoading(useDeviceLocation: _useDeviceLocation),
      );
    }

    try {
      final bundle = await _locationService.resolveLocationWithZones(
        patientId: _patientId,
        patientName: _patientName,
        useDeviceLocation: _useDeviceLocation,
      );
      final location = bundle.location;
      final safeZones = bundle.safeZones;

      GeofenceAlertEvent? newAlert;
      if (hasPatient && location.isDeviceOnline) {
        newAlert = await _geofenceAlertService.onLocationUpdate(
          patientId: _patientId!,
          patientName: _patientName,
          location: location,
          safeZones: safeZones,
        );
      }

      if (!_isCurrentLoad(seq)) return;

      final previous =
          state is LocationLoaded ? state as LocationLoaded : null;
      final geofenceAlert = _resolveGeofenceAlert(
        location: location,
        newAlert: newAlert,
        previousAlert: previous?.geofenceAlert,
      );

      _emit(
        seq,
        LocationLoaded(
          location: location,
          useDeviceLocation: _useDeviceLocation,
          safeZones: safeZones,
          geofenceAlert: geofenceAlert,
        ),
      );
      _loadMode = _LoadMode.explicit;
      _syncLocationTracking(deviceOnline: location.isDeviceOnline);
    } on LocationException catch (e) {
      if (!_isCurrentLoad(seq)) return;
      _emit(
        seq,
        LocationError(
          message: e.message,
          useDeviceLocation: _useDeviceLocation,
          isRecoverable: e.isRecoverable,
        ),
      );
      _syncLocationTracking();
    } catch (e) {
      if (!_isCurrentLoad(seq)) return;
      _emit(
        seq,
        LocationError(
          message: e.toString().replaceFirst('Exception: ', ''),
          useDeviceLocation: _useDeviceLocation,
        ),
      );
      _syncLocationTracking();
    }
  }

  Future<void> addSafeZone({
    required double latitude,
    required double longitude,
    required double radiusMeters,
    String name = 'Home',
  }) async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    final zone = SafeZone(
      id: SafeZone.newId(),
      patientId: patientId,
      latitude: latitude,
      longitude: longitude,
      radiusMeters: radiusMeters,
      name: name,
    );
    await _locationService.addSafeZone(zone);
    _geofenceAlertService.resetPatient(patientId);
    await load();
  }

  Future<void> updateSafeZone(SafeZone zone) async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    await _locationService.updateSafeZone(zone);
    _geofenceAlertService.resetPatient(patientId);
    await load();
  }

  Future<void> removeSafeZone(String zoneId) async {
    final patientId = _patientId;
    if (patientId == null || patientId.isEmpty) return;

    await _locationService.removeSafeZone(patientId, zoneId);
    _geofenceAlertService.resetPatient(patientId);
    await load();
  }

  void dismissGeofenceAlert() {
    if (state is! LocationLoaded) return;
    emit((state as LocationLoaded).copyWith(clearGeofenceAlert: true));
  }

  Future<void> refresh() async {
    _loadMode = _LoadMode.initial;
    await load();
  }

  Future<void> ensureMonitoring() async {
    if (state is! LocationLoaded) return;
    _loadMode = _LoadMode.silent;
    await load();
  }

  /// Starts polling + requests notification permission for caregivers.
  Future<void> startMonitoring({
    String? patientId,
    String? patientName,
  }) async {
    await MemoryTrainingService.instance.ensureNotificationPermissions();
    await load(
      patientId: patientId,
      patientName: patientName,
    );
    _syncLocationTracking();
  }

  Future<void> setUseDeviceLocation(bool value) async {
    if (_useDeviceLocation == value) return;
    await _locationService.setUseDeviceLocation(value);
    _useDeviceLocation = value;
    _loadMode = _LoadMode.initial;
    if (_patientId != null) {
      _geofenceAlertService.resetPatient(_patientId!);
    }
    await load();
    _syncLocationTracking();
  }

  void _syncLocationTracking({bool? deviceOnline}) {
    if (_useDeviceLocation) {
      _stopApiPolling();
      _ensureDevicePositionStream();
      return;
    }

    _stopDevicePositionStream();
    if (_patientId == null || _patientId!.isEmpty) return;

    final online = deviceOnline ??
        (state is LocationLoaded
            ? (state as LocationLoaded).location.isDeviceOnline
            : false);
    if (_pollWhileOnline != online) {
      _stopApiPolling();
      _pollWhileOnline = online;
    }
    _ensureApiPolling(online: online);
  }

  void _ensureApiPolling({required bool online}) {
    if (_refreshTimer != null) return;

    final interval = online ? _onlinePollInterval : _offlinePollInterval;
    debugPrint(
      '[LocationCubit] polling every ${interval.inSeconds}s '
      '(device ${online ? 'online' : 'offline'})',
    );
    _refreshTimer = Timer.periodic(
      interval,
      (_) => unawaited(_pollSilently()),
    );
  }

  void _ensureDevicePositionStream() {
    if (_devicePositionSub != null) return;

    debugPrint('[LocationCubit] starting live device GPS stream');
    _devicePositionSub = _locationService.watchDevicePosition().listen(
      (position) => unawaited(_onDevicePositionUpdate(position)),
      onError: (Object e) =>
          debugPrint('[LocationCubit] device GPS stream error: $e'),
    );
  }

  Future<void> _onDevicePositionUpdate(Position position) async {
    if (isClosed || !_useDeviceLocation) return;

    try {
      var location = await _locationService.buildDeviceLocationFromPosition(
        position,
        patientName: _patientName,
      );

      final previous = state is LocationLoaded ? state as LocationLoaded : null;
      final safeZones = previous?.safeZones ?? const [];
      if (safeZones.isNotEmpty) {
        location = SafeZone.applyZoneStatus(
          location: location,
          zones: safeZones,
        );
      }

      GeofenceAlertEvent? geofenceAlert = previous?.geofenceAlert;
      final patientId = _patientId;
      if (patientId != null &&
          patientId.isNotEmpty &&
          safeZones.isNotEmpty &&
          !location.inSafeZone) {
        final newAlert = await _geofenceAlertService.onLocationUpdate(
          patientId: patientId,
          patientName: _patientName,
          location: location,
          safeZones: safeZones,
        );
        geofenceAlert = _resolveGeofenceAlert(
          location: location,
          newAlert: newAlert,
          previousAlert: geofenceAlert,
        );
      } else if (location.inSafeZone) {
        geofenceAlert = null;
      } else {
        geofenceAlert = _resolveGeofenceAlert(
          location: location,
          newAlert: null,
          previousAlert: geofenceAlert,
        );
      }

      if (isClosed || !_useDeviceLocation) return;

      emit(
        LocationLoaded(
          location: location,
          useDeviceLocation: true,
          safeZones: safeZones,
          geofenceAlert: geofenceAlert,
        ),
      );
    } catch (e) {
      debugPrint('[LocationCubit] device position update failed: $e');
    }
  }

  void _stopApiPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void _stopDevicePositionStream() {
    _devicePositionSub?.cancel();
    _devicePositionSub = null;
  }

  Future<void> _pollSilently() async {
    if (isClosed) return;
    _loadMode = _LoadMode.silent;
    await load();
  }

  bool _isCurrentLoad(int seq) => !isClosed && seq == _loadSeq;

  GeofenceAlertEvent? _resolveGeofenceAlert({
    required PatientLocation location,
    GeofenceAlertEvent? newAlert,
    GeofenceAlertEvent? previousAlert,
  }) {
    if (!CaregiverNotificationPreferences.instance.flutterSideAlertsEnabled) {
      return null;
    }
    if (!location.isDeviceOnline || location.inSafeZone) return null;
    return newAlert ?? previousAlert;
  }

  void _emit(int seq, LocationState state) {
    if (!_isCurrentLoad(seq)) return;
    emit(state);
  }

  @override
  Future<void> close() {
    _loadSeq++;
    _stopApiPolling();
    _stopDevicePositionStream();
    _pollWhileOnline = null;
    return super.close();
  }
}
