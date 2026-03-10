import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';
import 'package:mindmate/features/memory/data/services/memory_service.dart';
import 'memory_state.dart';

class MemoryCubit extends Cubit<MemoryState> {
  final MemoryService memoryService;

  MemoryCubit(this.memoryService) : super(MemoryInitial());

  /// Fetch all memories from the API and split by type
  Future<void> loadMemories() async {
    emit(MemoryLoading());
    try {
      final allMemories = await memoryService.getMemories();

      final photos =
          allMemories.where((m) => m.type == MemoryType.photo).toList();
      final videos =
          allMemories.where((m) => m.type == MemoryType.video).toList();
      final texts =
          allMemories.where((m) => m.type == MemoryType.text).toList();

      emit(MemoryLoaded(photos: photos, videos: videos, texts: texts));
    } catch (e) {
      emit(MemoryError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Refresh memories (pull-to-refresh)
  Future<void> refresh() => loadMemories();
}
