import 'package:equatable/equatable.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';

abstract class ReminderDetailState extends Equatable {
  const ReminderDetailState();

  @override
  List<Object?> get props => [];
}

class ReminderDetailInitial extends ReminderDetailState {}

class ReminderDetailLoading extends ReminderDetailState {}

class ReminderDetailLoaded extends ReminderDetailState {
  final ReminderItem item;

  const ReminderDetailLoaded(this.item);

  @override
  List<Object?> get props => [item];
}

class ReminderDetailDeleting extends ReminderDetailState {
  final ReminderItem item;

  const ReminderDetailDeleting(this.item);

  @override
  List<Object?> get props => [item];
}

class ReminderDetailError extends ReminderDetailState {
  final String message;

  const ReminderDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
