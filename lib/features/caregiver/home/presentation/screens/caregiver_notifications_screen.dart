import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/assignments/data/models/assigned_patient_row.dart';
import 'package:mindmate/features/assignments/data/models/caregiver_relationship.dart';

/// Caregiver-focused activity: connected patients from the API and guidance on pending requests.
class CaregiverNotificationsScreen extends StatefulWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  State<CaregiverNotificationsScreen> createState() => _CaregiverNotificationsScreenState();
}

class _CaregiverNotificationsScreenState extends State<CaregiverNotificationsScreen> {
  final _service = AssignmentService();
  List<AssignedPatientRow> _patients = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await _service.fetchCaregiverPatients();
      setState(() {
        _patients = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Notifications'),
      body: RefreshIndicator(
        color: AppTheme.primaryColor,
        onRefresh: _load,
        child: _loading && _patients.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 120),
                  Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                ],
              )
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingXL, vertical: AppTheme.spacingM),
                children: [
              InfoCard(
                    tag: 'Info',
                    tagColor: AppTheme.infoColor,
                    children: [
                      Text(
                        'When you send an assignment request from Add patient, the patient must accept it '
                        'before they appear in your list below.',
                        style: AppTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingL),
                  Text('Connected patients', style: AppTheme.heading3.copyWith(fontSize: 18)),
                  const SizedBox(height: AppTheme.spacingS),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(_error!, style: AppTheme.bodyMedium.copyWith(color: AppTheme.errorColor)),
                    ),
                  if (_patients.isEmpty && !_loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Center(
                        child: Text(
                          'No connected patients yet',
                          style: AppTheme.bodyMedium.copyWith(color: AppTheme.textTertiary),
                        ),
                      ),
                    )
                  else
                    ..._patients.map((p) => _PatientNoticeCard(row: p)),
                ],
              ),
      ),
    );
  }
}

class _PatientNoticeCard extends StatelessWidget {
  final AssignedPatientRow row;

  const _PatientNoticeCard({required this.row});

  @override
  Widget build(BuildContext context) {
    final relEnum = CaregiverRelationship.tryParseApi(row.relationship);
    final rel = relEnum?.label ?? row.relationship ?? '—';
    final connected = row.connectedAt != null
        ? DateFormat.yMMMd().format(row.connectedAt!.toLocal())
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingM),
      elevation: 0,
      color: AppTheme.neutralLight,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingL, vertical: 8),
        title: Text(row.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(row.email, style: AppTheme.bodySmall),
            const SizedBox(height: 4),
            Text('Relationship: $rel', style: AppTheme.bodySmall),
            if (connected != null) Text('Connected $connected', style: AppTheme.bodySmall),
          ],
        ),
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          child: Text(
            row.name.isNotEmpty ? row.name[0].toUpperCase() : '?',
            style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}
