import 'dart:io';
import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';

class MemoryService {
  final Dio _dio;
  final PatientContextStore _patientContextStore = PatientContextStore();

  MemoryService() : _dio = ApiHttpClient.dio;

  /// Retrieve the saved patient ID
  Future<String?> _getPatientId() => _patientContextStore.getActivePatientId();

  /// Build authorization headers
  Future<Options> _authOptions() => ApiHttpClient.authorizedOptions();

  /// Fetch all memories for the current patient
  /// Endpoint: GET /api/memories/patient/:patientId
  Future<List<MemoryItem>> getMemories() async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null || patientId.isEmpty) {
        throw Exception(
          'No connected patient. Please connect at least one patient first.',
        );
      }

      final response = await _dio.get(
        ApiConfig.memoriesForPatientEndpoint(patientId),
        options: await _authOptions(),
      );

      if (response.statusCode == 200) {
        final data = response.data;

        return _parseMemoryList(data);
      } else {
        throw Exception('Failed to fetch memories (${response.statusCode})');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        return [];
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? 'Failed to fetch memories');
    } catch (e) {
      throw Exception('Error loading memories: $e');
    }
  }

  /// Fetch memories filtered by type
  Future<List<MemoryItem>> getMemoriesByType(MemoryType type) async {
    final all = await getMemories();
    return all.where((item) => item.type == type).toList();
  }

  /// Create a new memory for the currently active patient.
  ///
  /// Endpoint: POST /api/memories  (multipart/form-data)
  /// Required fields: type, title, content. patientId is read from
  /// PatientContextStore. relation is required for photo/video memories
  /// (per Figma comment #22 from the design team). mediaFile is required
  /// for photo/video and ignored for text.
  ///
  /// Returns the created MemoryItem parsed from the API response. If the
  /// backend hasn't implemented this endpoint yet (404 / 501), throws a
  /// clear exception so the UI can show a "backend not ready" toast
  /// without pretending the save succeeded.
  Future<MemoryItem> createMemory({
    required MemoryType type,
    required String title,
    required String content,
    String? relation,
    List<String>? tags,
    File? mediaFile,
  }) async {
    final patientId = await _getPatientId();
    if (patientId == null || patientId.isEmpty) {
      throw Exception(
        'No connected patient. Select a patient first.',
      );
    }

    if (type != MemoryType.text && mediaFile == null) {
      throw Exception('Please pick a ${type.name} file before saving.');
    }
    if (type != MemoryType.text &&
        (relation == null || relation.trim().isEmpty)) {
      throw Exception('Relation is required for photo and video memories.');
    }

    // Backend contract (from MindMate-Project/Backend
    // src/controllers/memoryItem.controller.ts + uploadMemory.middleware.ts):
    //  - patient_id (snake_case, required)
    //  - type (required: 'photo' | 'video' | 'text')
    //  - title (required)
    //  - caption (required, NOT 'content')
    //  - relation (optional)
    //  - tags (optional, accepts comma-separated string or array)
    //  - file (multer upload.single('file'), required for photo/video)
    // Keep the Dart-side parameter names in camelCase; only translate to
    // backend snake_case here at the service boundary.
    final formMap = <String, dynamic>{
      'patient_id': patientId,
      'type': type.name,
      'title': title.trim(),
      'caption': content.trim(),
      if (relation != null && relation.trim().isNotEmpty)
        'relation': relation.trim(),
      if (tags != null && tags.isNotEmpty) 'tags': tags.join(','),
    };

    if (mediaFile != null) {
      final fileName = mediaFile.path.split(RegExp(r'[\\/]')).last;
      formMap['file'] = await MultipartFile.fromFile(
        mediaFile.path,
        filename: fileName,
      );
    }

    final formData = FormData.fromMap(formMap);

    try {
      final response = await _dio.post(
        ApiConfig.createMemoryEndpoint,
        data: formData,
        options: (await _authOptions()).copyWith(
          contentType: 'multipart/form-data',
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        Map<String, dynamic> created;
        if (data is Map<String, dynamic>) {
          final inner = data['data'] ?? data['memory'] ?? data['result'];
          created = inner is Map<String, dynamic>
              ? inner
              : data;
        } else {
          throw Exception('Unexpected create response shape');
        }
        return MemoryItem.fromJson(created);
      }
      throw Exception('Failed to create memory (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404 || e.response?.statusCode == 501) {
        throw Exception(
          'Backend does not yet support memory creation '
          '(${e.response?.statusCode}). Ask the API team to enable '
          'POST ${ApiConfig.createMemoryEndpoint}.',
        );
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to create memory');
    }
  }

  /// Update text fields of an existing memory.
  ///
  /// Endpoint: PUT /api/memories/:id  (application/json)
  /// The backend only accepts text fields — title, caption, relation, date,
  /// tags — and rejects requests with no fields. Media replacement is not
  /// supported (the route lacks the upload middleware). Pass `null` for any
  /// field you don't want to change.
  Future<MemoryItem> updateMemory({
    required String id,
    String? title,
    String? caption,
    String? relation,
    List<String>? tags,
  }) async {
    if (id.isEmpty) {
      throw Exception('Missing memory id.');
    }
    final body = <String, dynamic>{
      if (title != null) 'title': title.trim(),
      if (caption != null) 'caption': caption.trim(),
      if (relation != null) 'relation': relation.trim(),
      if (tags != null) 'tags': tags.join(','),
    };
    if (body.isEmpty) {
      throw Exception('At least one field is required to update.');
    }

    try {
      final response = await _dio.put(
        ApiConfig.updateMemoryEndpoint(id),
        data: body,
        options: (await _authOptions()).copyWith(
          contentType: 'application/json',
        ),
      );
      if (response.statusCode == 200) {
        final data = response.data;
        Map<String, dynamic> updated;
        if (data is Map<String, dynamic>) {
          final inner = data['data'] ?? data['memory'] ?? data['result'];
          updated = inner is Map<String, dynamic> ? inner : data;
        } else {
          throw Exception('Unexpected update response shape');
        }
        return MemoryItem.fromJson(updated);
      }
      throw Exception('Failed to update memory (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Memory not found.');
      }
      if (e.response?.statusCode == 501 || e.response?.statusCode == 405) {
        throw Exception(
          'Backend does not yet support memory editing '
          '(${e.response?.statusCode}).',
        );
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to update memory');
    }
  }

  /// Fetch a single memory by id.
  /// Endpoint: GET /api/memories/:id
  Future<MemoryItem> getMemoryById(String id) async {
    if (id.isEmpty) throw Exception('Missing memory id.');
    try {
      final response = await _dio.get(
        ApiConfig.memoryByIdEndpoint(id),
        options: await _authOptions(),
      );
      if (response.statusCode == 200) {
        return _parseMemoryItem(response.data);
      }
      throw Exception('Failed to fetch memory (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Memory not found.');
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? 'Failed to fetch memory');
    }
  }

  /// Search memories by tags.
  /// Endpoint: GET /api/memories/search?tags=...
  Future<List<MemoryItem>> searchMemoriesByTags(String tags) async {
    final query = tags.trim();
    if (query.isEmpty) return const [];
    try {
      final response = await _dio.get(
        ApiConfig.searchMemoriesEndpoint,
        queryParameters: {'tags': query},
        options: await _authOptions(),
      );
      if (response.statusCode == 200) {
        return _parseMemoryList(response.data);
      }
      throw Exception('Failed to search memories (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? 'Failed to search memories');
    }
  }

  MemoryItem _parseMemoryItem(dynamic data) {
    if (data is Map<String, dynamic>) {
      final inner = data['data'] ?? data['memory'] ?? data['result'];
      if (inner is Map<String, dynamic>) {
        return MemoryItem.fromJson(inner);
      }
      return MemoryItem.fromJson(data);
    }
    throw Exception('Unexpected memory response shape');
  }

  List<MemoryItem> _parseMemoryList(dynamic data) {
    List<dynamic> memoriesList;
    if (data is List) {
      memoriesList = data;
    } else if (data is Map) {
      memoriesList = data['memories'] ?? data['data'] ?? data['results'] ?? [];
    } else {
      memoriesList = [];
    }
    return memoriesList
        .map((json) => MemoryItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Delete a memory. Backend also destroys the Cloudinary asset.
  /// Endpoint: DELETE /api/memories/:id
  Future<void> deleteMemory(String id) async {
    if (id.isEmpty) {
      throw Exception('Missing memory id.');
    }
    try {
      final response = await _dio.delete(
        ApiConfig.deleteMemoryEndpoint(id),
        options: await _authOptions(),
      );
      if (response.statusCode == 200 || response.statusCode == 204) {
        return;
      }
      throw Exception('Failed to delete memory (${response.statusCode})');
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        throw Exception('Session expired. Please log in again.');
      }
      if (e.response?.statusCode == 404) {
        throw Exception('Memory not found.');
      }
      if (e.response?.statusCode == 501 || e.response?.statusCode == 405) {
        throw Exception(
          'Backend does not yet support memory deletion '
          '(${e.response?.statusCode}).',
        );
      }
      final msg = ApiHttpClient.messageFromResponseData(e.response?.data);
      throw Exception(msg ?? e.message ?? 'Failed to delete memory');
    }
  }
}
