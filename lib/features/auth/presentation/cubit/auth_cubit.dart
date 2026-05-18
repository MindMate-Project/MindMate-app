import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import '../../domain/models/user_model.dart';
import '../../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;
  final PatientContextStore _patientContextStore = PatientContextStore();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

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
          await _patientContextStore.setActivePatientId(user.id!);
        } else if (user.role == 'caregiver' &&
            user.patients != null &&
            user.patients!.isNotEmpty) {
          // Caregiver: auto-select first linked patient as initial context.
          await _patientContextStore.setActivePatientId(user.patients!.first);
        } else {
          await _patientContextStore.clearActivePatientId();
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
  Future<void> forgotPassword(String email) async {
    emit(ForgotPasswordLoading());
    try {
      final result = await authService.forgotPassword(email);
      if (result['success'] == true) {
        emit(ForgotPasswordSuccess(result['message'] ?? 'Code sent successfully'));
      } else {
        emit(AuthFailure(result['message'] ?? 'Failed to send reset code'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Reset password using email, code, and new password
  Future<void> resetPassword(String email, String code, String newPassword) async {
    final _ = code;
    emit(ResetPasswordLoading());
    try {
      final response = await authService.resetPassword(
        email,
        newPassword,
        newPassword,
      );
      if (response.user != null && response.token != null) {
        await _saveToken(response.token!);
        emit(ResetPasswordSuccess(response.user!, response.token!));
      } else {
        emit(AuthFailure('Password reset failed: Invalid response from server'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Save authentication token to local storage
  Future<void> _saveToken(String token) async {
    await _secureStorage.write(key: 'auth_token', value: token);
  }

  /// Get saved authentication token from local storage
  Future<String?> getToken() async {
    return _secureStorage.read(key: 'auth_token');
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    await _secureStorage.delete(key: 'auth_token');
    await _patientContextStore.clearActivePatientId();
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
