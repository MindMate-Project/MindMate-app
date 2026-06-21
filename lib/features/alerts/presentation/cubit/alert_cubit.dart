import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/alerts/data/models/alert_list_item.dart';
import 'package:mindmate/features/alerts/data/services/alert_service.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'alert_state.dart';

class AlertCubit extends Cubit<AlertState> {
  final AlertService _alertService;
  final AssignmentService _assignmentService;

  AlertCubit({AlertService? alertService, AssignmentService? assignmentService})
    : _alertService = alertService ?? AlertService(),
      _assignmentService = assignmentService ?? AssignmentService(),
      super(const AlertInitial());

  Future<void> loadAlerts() async {
    emit(const AlertLoading());

    try {
      final patients = await _assignmentService.fetchCaregiverPatients();
      final alerts = <AlertListItem>[];

      for (final patient in patients) {
        try {
          final list = await _alertService.fetchPatientAlerts(
            patient.patientId,
          );
          alerts.addAll(
            list.map(
              (alert) => AlertListItem(alert: alert, patientName: patient.name),
            ),
          );
        } catch (_) {
          // Skip patients whose alerts fail to load.
        }
      }

      alerts.sort((a, b) => b.alert.timestamp.compareTo(a.alert.timestamp));
      emit(AlertLoaded(alerts));
    } catch (e) {
      emit(AlertError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> acknowledgeAlert(String alertId, String caregiverId) async {
    if (state is! AlertLoaded) return;
    try {
      await _alertService.acknowledgeAlert(alertId, caregiverId: caregiverId);
      await loadAlerts();
    } catch (e) {
      emit(AlertError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
