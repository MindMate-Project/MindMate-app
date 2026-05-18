import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'reminder_detail_state.dart';

class ReminderDetailCubit extends Cubit<ReminderDetailState> {
  ReminderDetailCubit(this._service) : super(ReminderDetailInitial());

  final RemindersService _service;

  Future<void> load(String id) async {
    emit(ReminderDetailLoading());
    try {
      final item = await _service.getReminderById(id);
      emit(ReminderDetailLoaded(item));
    } catch (e) {
      emit(ReminderDetailError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<bool> delete(String id) async {
    final current = state;
    if (current is! ReminderDetailLoaded) return false;

    emit(ReminderDetailDeleting(current.item));
    try {
      await _service.deleteReminder(id);
      return true;
    } catch (e) {
      emit(ReminderDetailLoaded(current.item));
      return false;
    }
  }
}
