import 'package:dio/dio.dart';
import 'package:mindmate/core/config/api_config.dart';
import 'package:mindmate/core/network/api_http_client.dart';

/// Result of `POST /api/face/patient/identify`.
class FaceIdentifyResult {
  final bool success;
  final bool identified;
  final String? firstName;
  final String? lastName;
  final String? relationship;
  final double confidence;
  final String? error;

  const FaceIdentifyResult({
    required this.success,
    this.identified = false,
    this.firstName,
    this.lastName,
    this.relationship,
    this.confidence = 0,
    this.error,
  });

  String get fullName {
    final first = firstName?.trim() ?? '';
    final last = lastName?.trim() ?? '';
    if (first.isEmpty && last.isEmpty) return 'Unknown';
    if (last.isEmpty) return first;
    if (first.isEmpty) return last;
    return '$first $last';
  }

  factory FaceIdentifyResult.fromResponse(dynamic raw, {int? statusCode}) {
    if (raw is! Map) {
      return const FaceIdentifyResult(
        success: false,
        error: 'Unexpected response from server',
      );
    }

    final map = Map<String, dynamic>.from(raw);
    final identified = map['identified'] == true || map['recognized'] == true;

    if (identified) {
      final nested = map['person'] ?? map['data'] ?? map;
      final source = nested is Map ? Map<String, dynamic>.from(nested) : map;

      return FaceIdentifyResult(
        success: true,
        identified: true,
        firstName:
            source['firstName']?.toString() ?? source['name']?.toString(),
        lastName: source['lastName']?.toString(),
        relationship:
            source['relationship']?.toString() ??
            source['relation']?.toString(),
        confidence: _readConfidence(source['confidence'] ?? map['confidence']),
      );
    }

    if (statusCode == 404) {
      return const FaceIdentifyResult(success: true, identified: false);
    }

    return FaceIdentifyResult(
      success: map['success'] != false,
      identified: false,
      error: map['message']?.toString(),
    );
  }

  static double _readConfidence(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class FaceRecognitionService {
  Future<FaceIdentifyResult> identifyFace(String imagePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(imagePath, filename: 'face.jpg'),
      });

      final response = await ApiHttpClient.dio.post(
        ApiConfig.identifyFaceEndpoint,
        data: formData,
        options: await ApiHttpClient.authorizedOptions(),
      );

      final code = response.statusCode ?? 0;
      if (code == 200 || code == 201) {
        return FaceIdentifyResult.fromResponse(response.data, statusCode: code);
      }

      if (code == 404) {
        return const FaceIdentifyResult(success: true, identified: false);
      }

      return FaceIdentifyResult(
        success: false,
        error:
            ApiHttpClient.messageFromResponseData(response.data) ??
            'Server error: $code',
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return const FaceIdentifyResult(success: true, identified: false);
      }
      return FaceIdentifyResult(
        success: false,
        error: ApiHttpClient.friendlyError(
          e,
          fallback: 'Could not identify this person.',
        ),
      );
    } catch (e) {
      return FaceIdentifyResult(success: false, error: 'Error: $e');
    }
  }
}
