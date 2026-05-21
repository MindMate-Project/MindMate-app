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

        // Handle various response shapes
        List<dynamic> memoriesList;
        if (data is List) {
          memoriesList = data;
        } else if (data is Map) {
          memoriesList = data['memories'] ??
              data['data'] ??
              data['results'] ??
              [];
        } else {
          memoriesList = [];
        }

        return memoriesList
            .map((json) => MemoryItem.fromJson(json as Map<String, dynamic>))
            .toList();
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
      throw Exception(
          e.response?.data?['message'] ?? 'Failed to fetch memories');
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
}
