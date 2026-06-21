import 'package:equatable/equatable.dart';
import 'package:mindmate/features/alerts/data/models/alert_list_item.dart';

abstract class AlertState extends Equatable {
  const AlertState();

  @override
  List<Object?> get props => [];
}

class AlertInitial extends AlertState {
  const AlertInitial();
}

class AlertLoading extends AlertState {
  const AlertLoading();
}

class AlertLoaded extends AlertState {
  final List<AlertListItem> alerts;

  const AlertLoaded(this.alerts);

  @override
  List<Object?> get props => [alerts];
}

class AlertError extends AlertState {
  final String message;

  const AlertError(this.message);

  @override
  List<Object?> get props => [message];
}
