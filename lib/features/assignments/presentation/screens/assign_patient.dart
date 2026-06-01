import 'package:flutter/material.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/validation.utils.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/core/widgets/custom_elevated_button.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/assignments/data/models/caregiver_relationship.dart';

class AddPatient extends StatefulWidget {
  const AddPatient({super.key});

  @override
  State<AddPatient> createState() => _AddPatientState();
}

class _AddPatientState extends State<AddPatient> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _service = AssignmentService();

  CaregiverRelationship _relationship = CaregiverRelationship.son;
  bool _submitting = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      await _service.sendAssignmentRequest(
        patientEmail: _emailController.text.trim(),
        relationshipApiValue: _relationship.apiValue,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request sent. Waiting for the patient to respond.')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: const ProfileAppBar(title: 'Add New Patient'),
      body: SafeArea(
        minimum: const EdgeInsets.symmetric(vertical: 40, horizontal: 25),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                spacing: AppTheme.spacingS,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Patient email', style: AppTheme.label),
                  CustomTextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    hintText: 'example@gmail.com',
                    validator: (value) => ValidationUtils.validateEmail(value),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                spacing: 8.0,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your relationship', style: AppTheme.label),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: CaregiverRelationship.values.map((r) {
                      final selected = _relationship == r;
                      return ChoiceChip(
                        label: Text(r.label),
                        selected: selected,
                        onSelected: _submitting
                            ? null
                            : (on) {
                                if (on) setState(() => _relationship = r);
                              },
                        selectedColor: AppTheme.primaryColor.withValues(alpha: 0.35),
                        labelStyle: TextStyle(
                          color: selected ? AppTheme.secondaryColor : AppTheme.textSecondary,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'The patient will get a request they can accept or decline.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.textSecondary),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomElevatedButton(
                    text: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                    size: const Size(150, 45),
                    backgroundColor: const Color(0xffEB4335),
                  ),
                  const SizedBox(width: 16),
                  CustomElevatedButton(
                    text: _submitting ? 'Sending…' : 'Send request',
                    onPressed: _submitting ? () {} : _submit,
                    size: const Size(150, 45),
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
    );
  }
}
