import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  int _loadSeq = 0;
  Future<void>? _ongoingLoad;

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
      final location = await _locationService.resolveLocation(
        patientId: _patientId,
        patientName: _patientName,
        useDeviceLocation: _useDeviceLocation,
      );

      var safeZones = <SafeZone>[];
      GeofenceAlertEvent? newAlert;
      if (hasPatient) {
        safeZones = await _locationService.getSafeZones(_patientId!);
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
      final geofenceAlert = location.inSafeZone
          ? null
          : (newAlert ?? previous?.geofenceAlert);

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
      _ensureRefreshTimer();
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
      _ensureRefreshTimer();
    } catch (e) {
      if (!_isCurrentLoad(seq)) return;
      _emit(
        seq,
        LocationError(
          message: e.toString().replaceFirst('Exception: ', ''),
          useDeviceLocation: _useDeviceLocation,
        ),
      );
      _ensureRefreshTimer();
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
    _ensureRefreshTimer();
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
    _ensureRefreshTimer();
  }

  void _ensureRefreshTimer() {
    if (_refreshTimer != null) return;
    if (_patientId == null || _patientId!.isEmpty) return;

    final interval = _useDeviceLocation
        ? const Duration(seconds: 10)
        : const Duration(seconds: 30);
    debugPrint('[LocationCubit] starting poll every ${interval.inSeconds}s');
    _refreshTimer = Timer.periodic(
      interval,
      (_) => unawaited(_pollSilently()),
    );
  }

  Future<void> _pollSilently() async {
    if (isClosed) return;
    _loadMode = _LoadMode.silent;
    await load();
  }

  bool _isCurrentLoad(int seq) => !isClosed && seq == _loadSeq;

  void _emit(int seq, LocationState state) {
    if (!_isCurrentLoad(seq)) return;
    emit(state);
  }

  @override
  Future<void> close() {
    _loadSeq++;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    return super.close();
  }
}
