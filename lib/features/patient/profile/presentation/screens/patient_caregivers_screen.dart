import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/error_retry_view.dart';
import 'package:mindmate/core/widgets/info_message_box.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/models/connected_caregiver.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/patient/profile/presentation/screens/patient_caregiver_detail_screen.dart';
import 'package:mindmate/features/patient/profile/presentation/widgets/connected_caregiver_card.dart';

/// Lists caregivers connected to the signed-in patient.
class PatientCaregiversScreen extends StatefulWidget {
  const PatientCaregiversScreen({super.key});

  @override
  State<PatientCaregiversScreen> createState() =>
      _PatientCaregiversScreenState();
}

class _PatientCaregiversScreenState extends State<PatientCaregiversScreen> {
  final AssignmentService _assignmentService = AssignmentService();

  bool _loading = true;
  String? _error;
  List<ConnectedCaregiver> _caregivers = const [];

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
      final authState = context.read<AuthCubit>().state;
      final patientId = authState is AuthSuccess ? authState.user.id : null;
      final caregivers = await _assignmentService.fetchMyCaregivers(
        patientId: patientId,
      );
      if (!mounted) return;
      setState(() {
        _caregivers = caregivers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(String caregiverId) async {
    final removed = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => PatientCaregiverDetailScreen(caregiverId: caregiverId),
      ),
    );
    if (removed == true) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: const ProfileAppBar(title: 'Caregivers'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.primaryColor,
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Connected Caregivers',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 15),
                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        )
                      else if (_error != null)
                        ErrorRetryView(
                          message: _error!,
                          onRetry: _load,
                          expand: false,
                        )
                      else if (_caregivers.isEmpty)
                        const InfoMessageBox(
                          message:
                              'No connected caregivers yet. When you accept a '
                              'caregiver request, they will appear here.',
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _caregivers.length,
                          separatorBuilder: (_, _) => const SizedBox.shrink(),
                          itemBuilder: (context, index) {
                            final caregiver = _caregivers[index];
                            return ConnectedCaregiverCard(
                              caregiver: caregiver,
                              onTap: () => _openDetail(caregiver.id),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
    );
  }
}
