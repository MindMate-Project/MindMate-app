import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/user_model.dart';
import '../../data/services/auth_service.dart';
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

        // Save patient ID for features like Memory
        final user = response.user!;
        if (user.role == 'patient' && user.id != null) {
          // Patient: use their own ID
          await _savePatientId(user.id!);
        } else if (user.role == 'caregiver' &&
            user.patients != null &&
            user.patients!.isNotEmpty) {
          // Caregiver: use the first linked patient's ID
          await _savePatientId(user.patients!.first);
        }

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

  /// Save patient ID for use by other features (Memory, etc.)
  Future<void> _savePatientId(String patientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('patient_id', patientId);
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

  /// Logout and clear stored data
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('patient_id');
    emit(AuthInitial());
  }

  /// Update current user in-memory (e.g. after profile update)
  void updateUser(User user) {
    final s = state;
    if (s is AuthSuccess) {
      emit(AuthSuccess(user, s.token));
    }
  }
}
