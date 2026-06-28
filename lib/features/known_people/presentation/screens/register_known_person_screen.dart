import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/labeled_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/known_people/data/models/known_person.dart';
import 'package:mindmate/features/known_people/data/services/known_people_service.dart';
import 'package:mindmate/features/known_people/presentation/widgets/known_person_photo_thumb.dart';

/// Register a new known person or add photos to someone already registered.
///
/// Patients omit [patientId]. Caregivers pass the assigned patient's id.
class RegisterKnownPersonScreen extends StatefulWidget {
  const RegisterKnownPersonScreen({
    super.key,
    this.patientId,
    this.patientName,
    this.initialMode = KnownPersonFormMode.register,
    this.prefillFirstName,
    this.prefillLastName,
  });

  /// Required when a caregiver registers for an assigned patient.
  final String? patientId;
  final String? patientName;
  final KnownPersonFormMode initialMode;
  final String? prefillFirstName;
  final String? prefillLastName;

  bool get isCaregiverFlow =>
      patientId != null && patientId!.trim().isNotEmpty;

  @override
  State<RegisterKnownPersonScreen> createState() =>
      _RegisterKnownPersonScreenState();
}

class _RegisterKnownPersonScreenState extends State<RegisterKnownPersonScreen> {
  static const int _minRegisterPhotos = 3;
  static const int _minAddPhotos = 1;

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _otherRelationshipCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final KnownPeopleService _service = KnownPeopleService();

  final List<File> _photos = [];
  late KnownPersonFormMode _mode;
  String? _relationship;
  bool _submitting = false;

  bool get _isRegisterMode => _mode == KnownPersonFormMode.register;
  bool get _isOther => _relationship == 'Other';
  bool get _lockNameFields =>
      !_isRegisterMode &&
      widget.prefillFirstName != null &&
      widget.prefillLastName != null;

  int get _minPhotos => _isRegisterMode ? _minRegisterPhotos : _minAddPhotos;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.prefillFirstName != null) {
      _firstNameCtrl.text = widget.prefillFirstName!.trim();
    }
    if (widget.prefillLastName != null) {
      _lastNameCtrl.text = widget.prefillLastName!.trim();
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _otherRelationshipCtrl.dispose();
    super.dispose();
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Required' : null;

  Future<void> _addFromGallery() async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _photos.addAll(picked.map((x) => File(x.path))));
    } catch (e) {
      _toast('Could not pick photos: $e');
    }
  }

  Future<void> _addFromCamera() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.camera);
      if (picked == null) return;
      setState(() => _photos.add(File(picked.path)));
    } catch (e) {
      _toast('Could not open the camera: $e');
    }
  }

  void _toast(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;

    if (_isRegisterMode) {
      final relationship = _isOther
          ? _otherRelationshipCtrl.text.trim()
          : (_relationship ?? '');
      if (relationship.isEmpty) {
        _toast(
          widget.isCaregiverFlow
              ? 'Please choose how this person is related to the patient.'
              : 'Please choose how this person is related to you.',
        );
        return;
      }
    }

    if (_photos.length < _minPhotos) {
      _toast(
        _isRegisterMode
            ? 'Please add at least $_minRegisterPhotos clear photos of their face.'
            : 'Please add at least one clear photo of their face.',
      );
      return;
    }

    setState(() => _submitting = true);

    final result = _isRegisterMode
        ? await _service.registerKnownPerson(
            firstName: _firstNameCtrl.text,
            lastName: _lastNameCtrl.text,
            relationship: _isOther
                ? _otherRelationshipCtrl.text.trim()
                : (_relationship ?? ''),
            photos: _photos,
            patientId: widget.patientId,
          )
        : await _service.addPhotosToKnownPerson(
            firstName: _firstNameCtrl.text,
            lastName: _lastNameCtrl.text,
            photos: _photos,
            patientId: widget.patientId,
          );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.ok) {
      final who = widget.isCaregiverFlow
          ? (widget.patientName ?? 'the patient')
          : 'you';
      _toast(
        _isRegisterMode
            ? 'Saved. $who can now recognize this person when scanning.'
            : 'Photos added. $who can recognize this person more reliably.',
      );
      Navigator.pop(context, true);
    } else {
      _toast(
        result.error ??
            (_isRegisterMode
                ? 'Could not register the person.'
                : 'Could not add photos.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final subject = widget.isCaregiverFlow
        ? (widget.patientName ?? 'the patient')
        : 'you';

    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: ProfileAppBar(
        title: _isRegisterMode ? 'Add a known person' : 'Add more photos',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRegisterMode
                      ? (widget.isCaregiverFlow
                          ? 'Add someone $subject should recognize. Enter their '
                              'name and add at least $_minRegisterPhotos clear '
                              'photos of their face.'
                          : 'Add someone you should recognize. Enter their name '
                              'and add at least $_minRegisterPhotos clear photos '
                              'of their face.')
                      : 'Add more face photos for someone already registered. '
                          'Use the same first and last name as on their record.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingL),
                LabeledFormField(
                  label: 'What are you doing?',
                  child: RadioGroup<KnownPersonFormMode>(
                    groupValue: _mode,
                    onChanged: _submitting
                        ? (_) {}
                        : (value) {
                            if (value == null) return;
                            setState(() => _mode = value);
                          },
                    child: Column(
                      children: [
                        RadioListTile<KnownPersonFormMode>(
                          title: const Text('Register a new person'),
                          subtitle: Text(
                            'First time adding this person',
                            style: AppTheme.bodySmall,
                          ),
                          value: KnownPersonFormMode.register,
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                        RadioListTile<KnownPersonFormMode>(
                          title: const Text('Add photos to someone known'),
                          subtitle: Text(
                            'They are already registered',
                            style: AppTheme.bodySmall,
                          ),
                          value: KnownPersonFormMode.addPhotos,
                          activeColor: AppTheme.primaryColor,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text('First name', style: AppTheme.label),
                const SizedBox(height: AppTheme.spacingS),
                CustomTextFormField(
                  controller: _firstNameCtrl,
                  hintText: 'e.g. Samir',
                  readOnly: _lockNameFields,
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Text('Last name', style: AppTheme.label),
                const SizedBox(height: AppTheme.spacingS),
                CustomTextFormField(
                  controller: _lastNameCtrl,
                  hintText: 'e.g. Atef',
                  readOnly: _lockNameFields,
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spacingL),
                Opacity(
                  opacity: _isRegisterMode ? 1 : 0.45,
                  child: IgnorePointer(
                    ignoring: !_isRegisterMode,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Relationship', style: AppTheme.label),
                        const SizedBox(height: AppTheme.spacingS),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children:
                              KnownPersonRelationships.options.map((option) {
                            final selected = _relationship == option;
                            return ChoiceChip(
                              label: Text(option),
                              selected: selected,
                              onSelected: _submitting
                                  ? null
                                  : (on) => setState(
                                        () => _relationship = on ? option : null,
                                      ),
                              selectedColor:
                                  AppTheme.primaryColor.withValues(alpha: 0.35),
                              labelStyle: TextStyle(
                                color: selected
                                    ? AppTheme.secondaryColor
                                    : AppTheme.textSecondary,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w400,
                              ),
                            );
                          }).toList(),
                        ),
                        if (_isOther) ...[
                          const SizedBox(height: AppTheme.spacingM),
                          CustomTextFormField(
                            controller: _otherRelationshipCtrl,
                            hintText: 'Describe the relationship',
                            validator: (v) => _isOther ? _required(v) : null,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Photos ($_minPhotos or more)',
                      style: AppTheme.label,
                    ),
                    Text(
                      '${_photos.length} added',
                      style: AppTheme.bodySmall.copyWith(
                        color: _photos.length >= _minPhotos
                            ? AppTheme.successColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingS),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _addFromGallery,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: const Text('Gallery'),
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingM),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _submitting ? null : _addFromCamera,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Camera'),
                      ),
                    ),
                  ],
                ),
                if (_photos.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingM),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < _photos.length; i++)
                        KnownPersonPhotoThumb(
                          file: _photos[i],
                          onRemove: _submitting
                              ? null
                              : () => setState(() => _photos.removeAt(i)),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.spacingXXL),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: AppTheme.neutralWhite,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isRegisterMode ? 'Save person' : 'Add photos'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
