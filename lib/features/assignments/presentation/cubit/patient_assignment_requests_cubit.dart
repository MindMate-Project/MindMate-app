import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/assignments/presentation/cubit/patient_assignment_requests_state.dart';

class PatientAssignmentRequestsCubit extends Cubit<PatientAssignmentRequestsState> {
  PatientAssignmentRequestsCubit(this._service) : super(const PatientAssignmentRequestsState());

  final AssignmentService _service;

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: PatientAssignmentLoadStatus.loading,
        clearError: true,
        clearActing: true,
      ),
    );
    try {
      final list = await _service.fetchPendingAssignmentRequests();
      emit(
        state.copyWith(
          status: PatientAssignmentLoadStatus.success,
          requests: list,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PatientAssignmentLoadStatus.failure,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
          requests: const [],
        ),
      );
    }
  }

  Future<void> respond({required String caregiverId, required bool accept}) async {
    emit(state.copyWith(actingOnCaregiverId: caregiverId, clearError: true));
    try {
      await _service.respondToAssignmentRequest(caregiverId: caregiverId, accept: accept);
      await refresh();
    } catch (e) {
      emit(
        state.copyWith(
          clearActing: true,
          errorMessage: e.toString().replaceFirst('Exception: ', ''),
        ),
      );
    }
  }
}
