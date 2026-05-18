import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Shared Dio instance and bearer auth helpers used by API services.
class ApiHttpClient {
  ApiHttpClient._();
  static const _secureStorage = FlutterSecureStorage();

  static final Dio dio = Dio(
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

  static Future<Options> authorizedOptions() async {
    final token = await _secureStorage.read(key: 'auth_token');
    return Options(
      headers: {
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );
  }

  static String? messageFromResponseData(dynamic data) {
    if (data is Map) {
      return data['message']?.toString() ?? data['error']?.toString();
    }
    if (data is String && data.trim().isNotEmpty) return data;
    return null;
  }
}
