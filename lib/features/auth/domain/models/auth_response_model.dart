import 'user_model.dart';

class AuthResponse {
  final User? user;
  final String? token;
  final String? message;

  AuthResponse({this.user, this.token, this.message});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {

    User? user;
    String? token;

    // Extract token in login
    if (json['token'] != null) {
      token = json['token'] as String;
    }

    // Extract user data
    if (json['data'] != null && json['data'] is Map) {
      final data = json['data'] as Map<String, dynamic>;

      if (data['user'] != null && data['user'] is Map) {
        user = User.fromJson(data['user'] as Map<String, dynamic>);
      } else if (data.containsKey('_id') || data.containsKey('name')) {
        user = User.fromJson(data);
      }
    } else if (json['user'] != null && json['user'] is Map) {
      user = User.fromJson(json['user'] as Map<String, dynamic>);
    }

    return AuthResponse(
      user: user,
      token: token,
      message: json['message'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (user != null) 'user': user!.toJson(),
      if (token != null) 'token': token,
      if (message != null) 'message': message,
    };
  }
}
