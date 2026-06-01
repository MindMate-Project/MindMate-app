import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mindmate/core/network/patient_context_store.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/models/register_request.dart';
import '../../domain/models/user_model.dart';
import '../../data/services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService authService;
  final PatientContextStore _patientContextStore = PatientContextStore();
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';
  static const _userJsonKey = 'auth_user';
  static const _rememberMeKey = 'remember_me';
  static const _onboardingCompletedKey = 'onboarding_completed';

  AuthCubit(this.authService) : super(AuthInitial());

  /// Register a new user
  Future<void> register(RegisterRequest request) async {
    emit(AuthLoading());
    try {
      final response = await authService.register(request);
      if (response.user != null) {
        emit(AuthSuccess(response.user!, null));
      } else {
        emit(AuthFailure('Registration failed: User data not received'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  /// Login with email and password.
  /// When [rememberMe] is false, the session ends on the next app launch.
  Future<void> login(
    String email,
    String password, {
    required bool rememberMe,
  }) async {
    emit(AuthLoading());
    try {
      final response = await authService.login(email, password);
      if (response.user != null && response.token != null) {
        final user = response.user!;
        await _persistSession(user, response.token!, rememberMe: rememberMe);
        emit(AuthSuccess(user, response.token));
      } else {
        emit(AuthFailure('Login failed: Invalid response from server'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<bool> getRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_rememberMeKey) ?? false;
  }

  Future<void> markOnboardingComplete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingCompletedKey, true);
  }

  /// Resolves the first route after splash (session restore or guest flow).
  Future<String> resolveStartRoute() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (!rememberMe) {
      await _clearCredentials(keepRememberMeFlag: true);
    } else {
      final token = await getToken();
      final userJson = await _secureStorage.read(key: _userJsonKey);
      if (token != null &&
          token.isNotEmpty &&
          userJson != null &&
          userJson.isNotEmpty) {
        try {
          final user = User.fromJson(
            jsonDecode(userJson) as Map<String, dynamic>,
          );
          await _applyPatientContext(user);
          emit(AuthSuccess(user, token));
          return _homeRouteFor(user.role);
        } catch (_) {
          await _clearCredentials();
        }
      } else {
        await _clearCredentials();
      }
    }

    final onboardingDone = prefs.getBool(_onboardingCompletedKey) ?? false;
    return onboardingDone ? '/login' : '/roleSelection';
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

  /// Reset password 
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
        await _persistSession(
          response.user!,
          response.token!,
          rememberMe: true,
        );
        emit(ResetPasswordSuccess(response.user!, response.token!));
      } else {
        emit(AuthFailure('Password reset failed: Invalid response from server'));
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  Future<void> _persistSession(
    User user,
    String token, {
    required bool rememberMe,
  }) async {
    await _secureStorage.write(key: _tokenKey, value: token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (rememberMe) {
      await _secureStorage.write(
        key: _userJsonKey,
        value: jsonEncode(user.toJson()),
      );
    } else {
      await _secureStorage.delete(key: _userJsonKey);
    }

    await _applyPatientContext(user);
  }

  Future<void> _applyPatientContext(User user) async {
    if (user.role == 'patient' && user.id != null) {
      await _patientContextStore.setActivePatientId(user.id!);
    } else if (user.role == 'caregiver' &&
        user.patients != null &&
        user.patients!.isNotEmpty) {
      await _patientContextStore.setActivePatientId(user.patients!.first);
    } else {
      await _patientContextStore.clearActivePatientId();
    }
  }

  String _homeRouteFor(String role) =>
      role == 'caregiver' ? '/caregiver_home' : '/patient_home';

  Future<String?> getToken() async => _secureStorage.read(key: _tokenKey);

  Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_rememberMeKey) ?? false)) return false;
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> _clearCredentials({bool keepRememberMeFlag = false}) async {
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _userJsonKey);
    if (!keepRememberMeFlag) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_rememberMeKey, false);
    }
  }

  /// Logout and clear stored data
  Future<void> logout() async {
    await _clearCredentials();
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
