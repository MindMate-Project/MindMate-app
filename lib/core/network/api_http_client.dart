import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/navigation/app_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';

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
      // The backend runs on a free Render dyno that sleeps after inactivity and
      // can take ~30-60s to wake, so the first request after idle needs headroom.
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  )..interceptors.add(
      InterceptorsWrapper(
        onError: (error, handler) async {
          if (error.response?.statusCode == 401) {
            final path = error.requestOptions.uri.path;
            if (!path.startsWith('/api/auth/')) {
              await _secureStorage.delete(key: 'auth_token');
              AppRouter.router.go(AppRoutes.login);
            }
          }
          handler.next(error);
        },
      ),
    );

  /// Wakes a sleeping Render dyno so the first real request doesn't time out.
  /// Fire-and-forget: any reply (even a 404) means the server is awake.
  static Future<void> warmUp() async {
    try {
      await dio.get(
        '/',
        options: Options(
          receiveTimeout: const Duration(seconds: 15),
          // Don't throw on non-2xx — reaching the server is all we need.
          validateStatus: (_) => true,
        ),
      );
    } catch (_) {
      // Ignored: warm-up is best-effort.
    }
  }

  /// Human-readable message for a failed request. Network/timeout errors get a
  /// friendly hint (the dyno may be waking); otherwise prefer the server message.
  static String friendlyError(
    DioException e, {
    String fallback = 'Something went wrong. Please try again.',
  }) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'The server is taking a while to respond (it may be waking up). '
            'Please try again in a moment.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the server. Please check your internet '
            'connection and try again.';
      default:
        return messageFromResponseData(e.response?.data) ?? e.message ?? fallback;
    }
  }

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
