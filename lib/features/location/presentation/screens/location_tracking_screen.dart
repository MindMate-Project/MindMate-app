import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/caregiver/home/data/active_patient_resolver.dart';
import 'package:mindmate/features/location/presentation/cubit/location_cubit.dart';
import 'package:mindmate/features/location/presentation/cubit/location_state.dart';
import 'package:mindmate/features/location/presentation/widgets/location_info_card.dart';
import 'package:mindmate/features/location/presentation/widgets/location_map_view.dart';

class LocationTrackingScreen extends StatefulWidget {
  const LocationTrackingScreen({super.key});

  @override
  State<LocationTrackingScreen> createState() => _LocationTrackingScreenState();
}

class _LocationTrackingScreenState extends State<LocationTrackingScreen> {
  final _resolver = ActivePatientResolver();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final cubit = context.read<LocationCubit>();
    final state = cubit.state;

    if (state is LocationLoaded) return;

    if (state is LocationInitial || state is LocationNoPatient) {
      final patient = await _resolver.resolve();
      if (!mounted) return;
      await cubit.load(
        patientId: patient?.id,
        patientName: patient?.name ?? 'Patient',
      );
      return;
    }

    await cubit.load();
  }

  bool _isCaregiver(AuthState state) =>
      state is AuthSuccess && state.user.isCaregiver;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (!_isCaregiver(authState)) {
                  return const SizedBox.shrink();
                }
                return BlocBuilder<LocationCubit, LocationState>(
                  builder: (context, state) => SwitchListTile(
                    secondary: Icon(Icons.my_location, color: Colors.grey[600]),
                    title: const Text(
                      'Use device location (testing)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.secondaryColor,
                      ),
                    ),
                    subtitle: Text(
                      'Falls back to this phone\'s GPS when patient data is unavailable',
                      style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                    ),
                    value: state.useDeviceLocation,
                    activeThumbColor: AppTheme.primaryColor,
                    onChanged: (value) => context
                        .read<LocationCubit>()
                        .setUseDeviceLocation(value),
                  ),
                );
              },
            ),
            Expanded(
              child: BlocBuilder<LocationCubit, LocationState>(
                builder: (context, state) => RefreshIndicator(
                  color: AppTheme.primaryColor,
                  onRefresh: () =>
                      context.read<LocationCubit>().refresh(),
                  child: LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: constraints.maxHeight,
                        child: _buildBody(state),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildBody(LocationState state) {
    if (state is LocationLoading || state is LocationInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (state is LocationNoPatient) {
      return BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) => _message(
          _isCaregiver(authState)
              ? 'No patient selected. Go to the home screen and select a patient first.'
              : 'Location tracking is managed by your caregiver.',
        ),
      );
    }

    if (state is LocationError) {
      if (!state.isRecoverable) {
        return _message(state.message);
      }
      return ErrorRetryView(message: state.message, onRetry: _load);
    }

    if (state is LocationLoaded) {
      final loc = state.location;
      return Column(
        children: [
          Expanded(
            child: LocationMapView(
              latitude: loc.latitude,
              longitude: loc.longitude,
              isFallback: loc.isFallback,
            ),
          ),
          LocationInfoCard(location: loc),
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _message(String text) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16, color: AppTheme.neutralDark),
        ),
      ),
    );
  }
}
