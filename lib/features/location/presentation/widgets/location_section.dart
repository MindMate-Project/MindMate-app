import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mindmate/core/navigation/app_routes.dart';
import 'package:mindmate/core/services/caregiver_notification_preferences.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_message_box.dart';
import 'package:mindmate/features/caregiver/home/presentation/models/active_patient.dart';
import 'package:mindmate/features/location/presentation/cubit/location_cubit.dart';
import 'package:mindmate/features/location/presentation/cubit/location_state.dart';
import 'package:mindmate/features/location/presentation/widgets/geofence_alert_banner.dart';
import 'package:mindmate/features/location/presentation/widgets/location_info_card.dart';

/// Caregiver home location preview; shares [LocationCubit] with the map screen.
class LocationSection extends StatefulWidget {
  final ActivePatient patient;

  const LocationSection({super.key, required this.patient});

  @override
  State<LocationSection> createState() => _LocationSectionState();
}

class _LocationSectionState extends State<LocationSection> {
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant LocationSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.patient.id != widget.patient.id) _load();
  }

  void _load() {
    context.read<LocationCubit>().startMonitoring(
      patientId: widget.patient.id,
      patientName: widget.patient.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Location',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(height: 8),
        BlocBuilder<LocationCubit, LocationState>(
          builder: (context, state) {
            return ValueListenableBuilder<int>(
              valueListenable:
                  CaregiverNotificationPreferences.instance.revision,
              builder: (context, _, child) {
                if (state is LocationLoading || state is LocationInitial) {
                  return child!;
                }
                return _buildLocationContent(context, state);
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLocationContent(BuildContext context, LocationState state) {
    if (state is LocationNoPatient) {
      return const InfoMessageBox(
        message: 'Select a patient above to see their location.',
      );
    }

    if (state is LocationError) {
      return InfoMessageBox(message: state.message);
    }

    if (state is LocationLoaded) {
      final loc = state.location;
      final offline = loc.isStaleDeviceData;
      final outside = !offline && state.hasSafeZones && !loc.inSafeZone;
      final flutterAlerts =
          CaregiverNotificationPreferences.instance.flutterSideAlertsEnabled;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (flutterAlerts && outside && state.geofenceAlert != null)
            GeofenceAlertBanner(
              alert: state.geofenceAlert!,
              onDismiss: () =>
                  context.read<LocationCubit>().dismissGeofenceAlert(),
            )
          else if (flutterAlerts && outside)
            const InfoMessageBox(
              message: 'Patient is outside all safe zones. Monitoring active.',
            ),
          InkWell(
            onTap: () => context.push(AppRoutes.location),
            borderRadius: BorderRadius.circular(16),
            child: LocationInfoCard(
              location: state.location,
              hasSafeZones: state.hasSafeZones,
            ),
          ),
        ],
      );
    }

    return const InfoMessageBox(message: 'Location unavailable.');
  }
}
