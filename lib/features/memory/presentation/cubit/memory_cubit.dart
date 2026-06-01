import 'dart:io';
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

  /// Caregiver-initiated memory creation. Emits MemoryCreating during the
  /// request, MemoryCreated on success (briefly, so the form can show a
  /// confirmation), then immediately re-loads the list so the user sees
  /// the new item. On failure, emits MemoryCreateError without disturbing
  /// the loaded list.
  Future<void> createMemory({
    required MemoryType type,
    required String title,
    required String content,
    String? relation,
    List<String>? tags,
    File? mediaFile,
  }) async {
    emit(MemoryCreating());
    try {
      final created = await memoryService.createMemory(
        type: type,
        title: title,
        content: content,
        relation: relation,
        tags: tags,
        mediaFile: mediaFile,
      );
      emit(MemoryCreated(created));
      // Refresh the list from the server so the new item appears in the
      // correct tab and any server-side enrichment (id, urls, etc.) is
      // reflected.
      await loadMemories();
    } catch (e) {
      emit(MemoryCreateError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Caregiver-initiated edit. The backend only accepts text fields — media
  /// cannot be replaced.
  Future<void> updateMemory({
    required String id,
    String? title,
    String? caption,
    String? relation,
    List<String>? tags,
  }) async {
    emit(MemoryUpdating());
    try {
      final updated = await memoryService.updateMemory(
        id: id,
        title: title,
        caption: caption,
        relation: relation,
        tags: tags,
      );
      emit(MemoryUpdated(updated));
      await loadMemories();
    } catch (e) {
      emit(MemoryUpdateError(e.toString().replaceFirst('Exception: ', '')));
    }
  }

  /// Caregiver-initiated delete. Backend also clears the Cloudinary asset.
  Future<void> deleteMemory(String id) async {
    emit(MemoryDeleting());
    try {
      await memoryService.deleteMemory(id);
      emit(MemoryDeleted(id));
      await loadMemories();
    } catch (e) {
      emit(MemoryDeleteError(e.toString().replaceFirst('Exception: ', '')));
    }
  }
}
