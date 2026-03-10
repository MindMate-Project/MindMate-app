import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';

class MemoryService {
  final Dio _dio;

  MemoryService()
      : _dio = Dio(
          BaseOptions(
            baseUrl: ApiConfig.baseUrl,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
          ),
        );

  /// Retrieve the saved auth token
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Retrieve the saved patient ID
  Future<String?> _getPatientId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('patient_id');
  }

  /// Build authorization headers
  Future<Options> _authOptions() async {
    final token = await _getToken();
    return Options(
      headers: {
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  /// Fetch all memories for the current patient
  /// Endpoint: GET /api/memories/patient/:patientId
  Future<List<MemoryItem>> getMemories() async {
    try {
      final patientId = await _getPatientId();
      if (patientId == null || patientId.isEmpty) {
        throw Exception('Patient ID not found. Please log in again.');
      }

      final response = await _dio.get(
        '/api/memories/patient/$patientId',
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
}
