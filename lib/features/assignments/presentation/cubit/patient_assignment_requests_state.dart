import 'package:equatable/equatable.dart';
import 'package:mindmate/features/assignments/data/models/pending_caregiver_request.dart';

enum PatientAssignmentLoadStatus { initial, loading, success, failure }

class PatientAssignmentRequestsState extends Equatable {
  final PatientAssignmentLoadStatus status;
  final List<PendingCaregiverRequest> requests;
  final String? errorMessage;
  final String? actingOnCaregiverId;

  const PatientAssignmentRequestsState({
    this.status = PatientAssignmentLoadStatus.initial,
    this.requests = const [],
    this.errorMessage,
    this.actingOnCaregiverId,
  });

  PatientAssignmentRequestsState copyWith({
    PatientAssignmentLoadStatus? status,
    List<PendingCaregiverRequest>? requests,
    String? errorMessage,
    String? actingOnCaregiverId,
    bool clearError = false,
    bool clearActing = false,
  }) {
    return PatientAssignmentRequestsState(
      status: status ?? this.status,
      requests: requests ?? this.requests,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      actingOnCaregiverId:
          clearActing ? null : (actingOnCaregiverId ?? this.actingOnCaregiverId),
    );
  }

  @override
  List<Object?> get props => [status, requests, errorMessage, actingOnCaregiverId];
}
