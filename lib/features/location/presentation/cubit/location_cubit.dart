import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/location/data/models/location_exception.dart';
import 'package:mindmate/features/location/data/services/location_service.dart';
import 'location_state.dart';

enum _LoadMode { initial, explicit, silent }

class LocationCubit extends Cubit<LocationState> {
  LocationCubit(this._locationService) : super(const LocationInitial()) {
    _init();
  }

  final LocationService _locationService;
  String? _patientId;
  String _patientName = 'Patient';
  bool _useDeviceLocation = false;
  _LoadMode _loadMode = _LoadMode.initial;
  Timer? _refreshTimer;

  Future<void> _init() async {
    _useDeviceLocation = await _locationService.getUseDeviceLocation();
  }

  Future<void> load({
    String? patientId,
    String? patientName,
  }) async {
    _refreshTimer?.cancel();
    _refreshTimer = null;

    final patientChanged =
        patientId != null && patientId.isNotEmpty && patientId != _patientId;
    if (patientId != null) _patientId = patientId;
    if (patientName != null) _patientName = patientName;
    if (patientChanged) _loadMode = _LoadMode.initial;

    final hasPatient = _patientId != null && _patientId!.isNotEmpty;

    if (!hasPatient && !_useDeviceLocation) {
      emit(LocationNoPatient(useDeviceLocation: _useDeviceLocation));
      return;
    }

    if (_loadMode != _LoadMode.silent) {
      emit(LocationLoading(useDeviceLocation: _useDeviceLocation));
    }

    try {
      final location = await _locationService.resolveLocation(
        patientId: _patientId,
        patientName: _patientName,
        useDeviceLocation: _useDeviceLocation,
      );
      emit(LocationLoaded(
        location: location,
        useDeviceLocation: _useDeviceLocation,
      ));
      _loadMode = _LoadMode.explicit;
      _startRefreshTimer();
    } on LocationException catch (e) {
      emit(LocationError(
        message: e.message,
        useDeviceLocation: _useDeviceLocation,
        isRecoverable: e.isRecoverable,
      ));
    } catch (e) {
      emit(LocationError(
        message: e.toString().replaceFirst('Exception: ', ''),
        useDeviceLocation: _useDeviceLocation,
      ));
    }
  }

  Future<void> refresh() async {
    _loadMode = _LoadMode.initial;
    await load();
  }

  Future<void> setUseDeviceLocation(bool value) async {
    if (_useDeviceLocation == value) return;
    await _locationService.setUseDeviceLocation(value);
    _useDeviceLocation = value;
    _loadMode = _LoadMode.initial;
    await load();
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 45),
      (_) {
        _loadMode = _LoadMode.silent;
        load();
      },
    );
  }

  @override
  Future<void> close() {
    _refreshTimer?.cancel();
    return super.close();
  }
}
