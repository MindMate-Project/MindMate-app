import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/caregiver/location/data/services/device_location_service.dart';

/// Caregiver tab showing the active patient's last reported device location.
class PatientLocationScreen extends StatefulWidget {
  const PatientLocationScreen({super.key});

  @override
  State<PatientLocationScreen> createState() => _PatientLocationScreenState();
}

class _PatientLocationScreenState extends State<PatientLocationScreen> {
  final DeviceLocationService _service = DeviceLocationService();
  late Future<PatientDeviceLocation?> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.getActivePatientLocation();
  }

  void _reload() {
    setState(() => _future = _service.getActivePatientLocation());
  }

  Future<void> _openInMaps(double lat, double lng) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      body: SafeArea(
        child: Column(
          children: [
            const ProfileAppBar(
              title: 'Location',
              centerTitle: true,
              showBackButton: false,
            ),
            Expanded(
              child: FutureBuilder<PatientDeviceLocation?>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return ErrorRetryView(
                      message: snapshot.error
                          .toString()
                          .replaceFirst('Exception: ', ''),
                      onRetry: _reload,
                    );
                  }
                  final location = snapshot.data;
                  if (location == null) {
                    return _EmptyState(
                      title: 'No tracking device',
                      message:
                          'No tracking device is assigned to this patient yet.',
                      onRefresh: _reload,
                    );
                  }
                  if (!location.hasCoordinates) {
                    return _EmptyState(
                      title: 'Waiting for location',
                      message:
                          "The device hasn't reported a location yet. Pull to "
                          'refresh once it comes online.',
                      onRefresh: _reload,
                    );
                  }
                  return _LocationDetails(
                    location: location,
                    onOpenMaps: () => _openInMaps(
                      location.latitude!,
                      location.longitude!,
                    ),
                    onRefresh: _reload,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }
}

class _LocationDetails extends StatelessWidget {
  const _LocationDetails({
    required this.location,
    required this.onOpenMaps,
    required this.onRefresh,
  });

  final PatientDeviceLocation location;
  final VoidCallback onOpenMaps;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final name = location.patientName?.trim();
    final updated = location.timestamp;
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async => onRefresh(),
      child: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingL),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacingL),
            decoration: BoxDecoration(
              color: AppTheme.neutralLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: AppTheme.primaryColor),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        name == null || name.isEmpty
                            ? 'Last known location'
                            : "$name's last location",
                        style: AppTheme.heading3
                            .copyWith(color: AppTheme.secondaryColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingM),
                _InfoLine(
                  label: 'Coordinates',
                  value:
                      '${location.latitude!.toStringAsFixed(5)}, ${location.longitude!.toStringAsFixed(5)}',
                ),
                if (updated != null)
                  _InfoLine(
                    label: 'Last updated',
                    value: DateFormat('d MMM yyyy, h:mm a').format(updated),
                  ),
                if (location.battery != null)
                  _InfoLine(
                    label: 'Battery',
                    value: '${location.battery}%',
                  ),
                if (location.deviceId != null)
                  _InfoLine(label: 'Device', value: location.deviceId!),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Open in Google Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: AppTheme.neutralWhite,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppTheme.spacingM),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: AppTheme.label.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTheme.bodyMedium
                  .copyWith(color: AppTheme.secondaryColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.onRefresh,
  });

  final String title;
  final String message;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppTheme.primaryColor,
      onRefresh: () async => onRefresh(),
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.18),
          Icon(Icons.location_off_outlined,
              size: 64, color: Colors.grey[400]),
          const SizedBox(height: AppTheme.spacingL),
          Center(
            child: Text(
              title,
              style: AppTheme.heading3.copyWith(color: AppTheme.secondaryColor),
            ),
          ),
          const SizedBox(height: AppTheme.spacingS),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppTheme.spacingXXL),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.bodyMedium.copyWith(color: AppTheme.neutralMedium),
            ),
          ),
          const SizedBox(height: AppTheme.spacingL),
          Center(
            child: TextButton.icon(
              onPressed: onRefresh,
              icon: const Icon(Icons.refresh, color: AppTheme.primaryColor),
              label: const Text('Refresh',
                  style: TextStyle(color: AppTheme.primaryColor)),
            ),
          ),
        ],
      ),
    );
  }
}
