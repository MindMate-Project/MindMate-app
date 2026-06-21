import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';

/// Info card shown on the map screen and caregiver home (patient location summary).
class LocationInfoCard extends StatelessWidget {
  final PatientLocation location;
  final bool hasSafeZones;

  const LocationInfoCard({
    super.key,
    required this.location,
    this.hasSafeZones = false,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _tagColor;
    final tag = _tag;

    return InfoCard(
      tag: tag,
      tagColor: statusColor,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppTheme.secondaryColor,
              child: Text(
                location.displayInitial,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              child: Text(
                location.patientName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.secondaryColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.location_on,
          iconColor: AppTheme.errorColor,
          text: location.address.isNotEmpty
              ? location.address
              : 'Address unavailable',
        ),
        const SizedBox(height: 8),
        _InfoRow(
          icon: Icons.access_time,
          iconColor: AppTheme.neutralMedium,
          text: _formatTime(location.updatedAt),
        ),
        if (location.isFallback) ...[
          const SizedBox(height: 8),
          Text(
            'Showing your current location (device data unavailable)',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ],
    );
  }

  String get _tag {
    if (!hasSafeZones) return 'Live Location';
    if (location.inSafeZone) {
      return location.zoneLabel ?? 'In Safe Zone';
    }
    return 'Outside Zone';
  }

  Color get _tagColor {
    if (!hasSafeZones) return AppTheme.infoColor;
    return location.inSafeZone ? AppTheme.successColor : AppTheme.warningColor;
  }

  static String _formatTime(DateTime? time) {
    if (time == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(time);
    final absolute = DateFormat.jm().format(time);
    if (diff.inSeconds < 60) return '$absolute (just now)';
    if (diff.inMinutes < 60) return '$absolute (${diff.inMinutes}m ago)';
    if (diff.inHours < 24) return '$absolute (${diff.inHours}h ago)';
    return absolute;
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.neutralDark,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
