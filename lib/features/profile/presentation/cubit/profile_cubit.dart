import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/features/auth/domain/models/user_model.dart';
import 'package:mindmate/features/profile/data/services/profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService profileService;

  ProfileCubit(this.profileService) : super(ProfileInitial());

  Future<User> loadMyProfile({required String role}) async {
    emit(ProfileLoading());
    try {
      final user = await profileService.getMyProfile(role: role);
      emit(ProfileLoaded(user));
      return user;
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
      rethrow;
    }
  }

  Future<User> updateMyProfile({
    required String role,
    required String name,
    String? phone,
    String? gender,
    DateTime? dateOfBirth,
    String? address,
  }) async {
    final current = state is ProfileLoaded
        ? (state as ProfileLoaded).user
        : state is ProfileUpdateSuccess
            ? (state as ProfileUpdateSuccess).user
            : null;
    emit(ProfileUpdating(current));
    try {
      final user = await profileService.updateMyProfile(
        role: role,
        name: name,
        phone: phone,
        gender: gender,
        dateOfBirth: dateOfBirth,
        address: address,
      );
      emit(ProfileUpdateSuccess(user));
      return user;
    } catch (e) {
      emit(ProfileError(e.toString().replaceFirst('Exception: ', '')));
      rethrow;
    }
  }
}
