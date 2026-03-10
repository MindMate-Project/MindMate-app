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
