import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/patient/reminders/data/models/reminder_item.dart';
import 'package:mindmate/features/patient/reminders/data/services/reminders_service.dart';
import 'reminders_state.dart';

class RemindersCubit extends Cubit<RemindersState> {
  final RemindersService remindersService;

  RemindersCubit(this.remindersService) : super(RemindersInitial());

  Future<void> loadPatientReminders() async {
    emit(RemindersLoading());
    try {
      final List<ReminderItem> reminders =
          await remindersService.getPatientReminders();
      emit(RemindersLoaded(reminders));
    } catch (e) {
      emit(
        RemindersError(e.toString().replaceFirst('Exception: ', '')),
      );
    }
  }
}

