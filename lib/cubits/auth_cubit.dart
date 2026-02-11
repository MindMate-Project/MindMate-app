import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;

  AuthCubit(this.authService) : super(AuthInitial());

  /// Register a new user
  Future<void> register(User user, String password) async {
    emit(AuthLoading());
    try {
      final response = await authService.register(user, password);
      if (response.user != null) {
        emit(AuthSuccess(response.user!, null));
      } else {
        emit(AuthFailure('Registration failed: User data not received'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    emit(AuthLoading());
    try {
      final response = await authService.login(email, password);
      if (response.user != null && response.token != null) {
        await _saveToken(response.token!);
        emit(AuthSuccess(response.user!, response.token));
      } else {
        emit(AuthFailure('Login failed: Invalid response from server'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Send password reset code to email
  // Future<void> forgotPassword(String email) async {
  //   emit(ForgotPasswordLoading());
  //   try {
  //     final result = await authService.forgotPassword(email);
  //     if (result['success'] == true) {
  //       emit(ForgotPasswordSuccess(result['message'] ?? 'Code sent successfully'));
  //     } else {
  //       emit(AuthFailure(result['message'] ?? 'Failed to send reset code'));
  //     }
  //   } catch (e) {
  //     emit(AuthFailure(e.toString()));
  //   }
  // }

  /// Reset password using email, code, and new password
  // Future<void> resetPassword(String email, String code, String newPassword) async {
  //   emit(ResetPasswordLoading());
  //   try {
  //     final response = await authService.resetPassword(email, code, newPassword);
  //     if (response.user != null && response.token != null) {
  //       await _saveToken(response.token!);
  //       emit(ResetPasswordSuccess(response.user!, response.token!));
  //     } else {
  //       emit(AuthFailure('Password reset failed: Invalid response from server'));
  //     }
  //   } catch (e) {
  //     emit(AuthFailure(e.toString()));
  //   }
  // }

  /// Save authentication token to local storage
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  /// Get saved authentication token from local storage
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout and clear stored token
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    emit(AuthInitial());
  }
}
