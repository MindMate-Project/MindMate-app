import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/utils/validation.utils.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/date_picker_field.dart';
import 'package:mindmate/core/widgets/labeled_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/assignments/data/services/assignment_service.dart';
import 'package:mindmate/features/caregiver/patients/data/models/caregiver_patient_detail.dart';
import 'package:mindmate/features/caregiver/patients/presentation/cubit/edit_patient_cubit.dart';
import 'package:mindmate/features/caregiver/patients/presentation/cubit/edit_patient_state.dart';

class EditPatientScreen extends StatefulWidget {
  final CaregiverPatientDetail patient;

  const EditPatientScreen({super.key, required this.patient});

  @override
  State<EditPatientScreen> createState() => _EditPatientScreenState();
}

class _EditPatientScreenState extends State<EditPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _diagnosisController;
  late final TextEditingController _stageController;
  late final TextEditingController _chronicController;
  late final TextEditingController _allergiesController;
  late final TextEditingController _medicationsController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    final patient = widget.patient;
    final notes = patient.medicalNotes;
    _nameController = TextEditingController(text: patient.name);
    _diagnosisController = TextEditingController(text: notes.diagnosis ?? '');
    _stageController = TextEditingController(text: notes.stage ?? '');
    _chronicController = TextEditingController(
      text: notes.chronicDiseases.join(', '),
    );
    _allergiesController = TextEditingController(
      text: notes.allergies.join(', '),
    );
    _medicationsController = TextEditingController(
      text: notes.currentMedication.join(', '),
    );
    _selectedDate = patient.dateOfBirth;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _diagnosisController.dispose();
    _stageController.dispose();
    _chronicController.dispose();
    _allergiesController.dispose();
    _medicationsController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final medicalNotes = PatientMedicalNotes(
      diagnosis: _diagnosisController.text.trim(),
      stage: _stageController.text.trim(),
      chronicDiseases:
          PatientMedicalNotes.parseCommaSeparated(_chronicController.text),
      allergies:
          PatientMedicalNotes.parseCommaSeparated(_allergiesController.text),
      currentMedication:
          PatientMedicalNotes.parseCommaSeparated(_medicationsController.text),
    );

    context.read<EditPatientCubit>().save(
          name: _nameController.text.trim(),
          dateOfBirth: _selectedDate,
          medicalNotes: medicalNotes,
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EditPatientCubit(AssignmentService(), widget.patient.id),
      child: BlocConsumer<EditPatientCubit, EditPatientState>(
        listener: (context, state) {
          if (state is EditPatientSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Patient updated successfully')),
            );
            Navigator.pop(context, true);
          }
          if (state is EditPatientError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        builder: (context, state) {
          final isSaving = state is EditPatientSaving;

          return Scaffold(
            backgroundColor: AppTheme.backgroundWhite,
            appBar: const ProfileAppBar(title: 'Edit Patient'),
            body: AbsorbPointer(
              absorbing: isSaving,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppTheme.spacingXL,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: AppTheme.spacingXXL),
                          LabeledFormField(
                            label: 'Full Name',
                            child: CustomTextFormField(
                              controller: _nameController,
                              hintText: 'Patient name',
                              validator: ValidationUtils.validateName,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          LabeledFormField(
                            label: 'Birth Date',
                            child: DatePickerField(
                              selectedDate: _selectedDate,
                              onDateSelected: (d) =>
                                  setState(() => _selectedDate = d),
                              hintText: 'Birth Date',
                              dateFormat: DateFormat('d/M/yyyy'),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXXL),
                          Text(
                            'Health Information',
                            style: AppTheme.heading3.copyWith(
                              color: AppTheme.secondaryColor,
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          LabeledFormField(
                            label: 'Diagnosis',
                            child: CustomTextFormField(
                              controller: _diagnosisController,
                              hintText: 'e.g. Alzheimer\'s disease',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          LabeledFormField(
                            label: 'Stage',
                            child: CustomTextFormField(
                              controller: _stageController,
                              hintText: 'e.g. Early stage',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          LabeledFormField(
                            label: 'Chronic Diseases',
                            child: CustomTextFormField(
                              controller: _chronicController,
                              hintText: 'Separate multiple with commas',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          LabeledFormField(
                            label: 'Allergies',
                            child: CustomTextFormField(
                              controller: _allergiesController,
                              hintText: 'Separate multiple with commas',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingL),
                          LabeledFormField(
                            label: 'Current Medications',
                            child: CustomTextFormField(
                              controller: _medicationsController,
                              hintText: 'Separate multiple with commas',
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXXXL),
                          SizedBox(
                            height: 52,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () => _submit(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: AppTheme.textWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppTheme.radiusMedium,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'Save Changes',
                                style: AppTheme.elevatedButtonText,
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.spacingXXL),
                        ],
                      ),
                    ),
                  ),
                  if (isSaving)
                    const Positioned.fill(
                      child: ColoredBox(
                        color: Color(0x33FFFFFF),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
