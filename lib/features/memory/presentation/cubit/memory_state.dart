import 'package:mindmate/features/memory/data/models/memory_item.dart';

abstract class MemoryState {}

class MemoryInitial extends MemoryState {}

class MemoryLoading extends MemoryState {}

class MemoryLoaded extends MemoryState {
  final List<MemoryItem> photos;
  final List<MemoryItem> videos;
  final List<MemoryItem> texts;

  MemoryLoaded({
    required this.photos,
    required this.videos,
    required this.texts,
  });
}

class MemoryError extends MemoryState {
  final String message;
  MemoryError(this.message);
}

/// Emitted while a caregiver-initiated POST is in flight.
class MemoryCreating extends MemoryState {}

/// Emitted when a memory is successfully created. Carries the new item so
/// the UI can show a confirmation; the cubit immediately follows up with
/// MemoryLoading -> MemoryLoaded by reloading the list from the server.
class MemoryCreated extends MemoryState {
  final MemoryItem item;
  MemoryCreated(this.item);
}

/// Emitted when a create attempt fails. Distinct from MemoryError so the
/// add-memory screen can show the error without unmounting the list.
class MemoryCreateError extends MemoryState {
  final String message;
  MemoryCreateError(this.message);
}
