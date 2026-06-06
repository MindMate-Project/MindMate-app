import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/patient/face_recognition/data/services/face_recognition_service.dart';

/// Caregiver form to register a person their patient should recognize.
/// Posts first/last name, relationship and at least 3 face photos to the
/// face-recognition backend so the patient's scan can identify them later.
class RegisterKnownPersonScreen extends StatefulWidget {
  const RegisterKnownPersonScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  final String patientId;
  final String patientName;

  @override
  State<RegisterKnownPersonScreen> createState() =>
      _RegisterKnownPersonScreenState();
}

class _RegisterKnownPersonScreenState extends State<RegisterKnownPersonScreen> {
  static const int _minPhotos = 3;
  static const List<String> _relationshipOptions = [
    'Son',
    'Daughter',
    'Brother',
    'Sister',
    'Husband',
    'Wife',
    'Grandchild',
    'Friend',
    'Doctor',
    'Nurse',
    'Neighbour',
    'Other',
  ];

  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _otherRelationshipCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  final List<File> _photos = [];
  String? _relationship;
  bool _submitting = false;

  bool get _isOther => _relationship == 'Other';

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

    final relationship =
        _isOther ? _otherRelationshipCtrl.text.trim() : (_relationship ?? '');
    if (relationship.isEmpty) {
      _toast('Please choose how this person is related to the patient.');
      return;
    }
    if (_photos.length < _minPhotos) {
      _toast('Please add at least $_minPhotos clear photos of their face.');
      return;
    }

    setState(() => _submitting = true);
    final result = await FaceRecognitionService.registerKnownPerson(
      patientId: widget.patientId,
      firstName: _firstNameCtrl.text,
      lastName: _lastNameCtrl.text,
      relationship: relationship,
      photos: _photos,
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (result.ok) {
      _toast('Saved. ${widget.patientName} can now recognize this person.');
      Navigator.pop(context, true);
    } else {
      _toast(result.error ?? 'Could not register the person.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: const ProfileAppBar(title: 'Add a known person'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.spacingL),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add someone ${widget.patientName} should recognize. '
                  'Enter their name and add at least $_minPhotos clear photos '
                  'of their face.',
                  style: AppTheme.bodyMedium,
                ),
                const SizedBox(height: AppTheme.spacingL),

                Text('First name', style: AppTheme.label),
                const SizedBox(height: AppTheme.spacingS),
                CustomTextFormField(
                  controller: _firstNameCtrl,
                  hintText: 'e.g. Samir',
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spacingL),

                Text('Last name', style: AppTheme.label),
                const SizedBox(height: AppTheme.spacingS),
                CustomTextFormField(
                  controller: _lastNameCtrl,
                  hintText: 'e.g. Atef',
                  validator: _required,
                ),
                const SizedBox(height: AppTheme.spacingL),

                Text('Relationship to the patient', style: AppTheme.label),
                const SizedBox(height: AppTheme.spacingS),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _relationshipOptions.map((option) {
                    final selected = _relationship == option;
                    return ChoiceChip(
                      label: Text(option),
                      selected: selected,
                      onSelected: _submitting
                          ? null
                          : (on) => setState(
                              () => _relationship = on ? option : null),
                      selectedColor:
                          AppTheme.primaryColor.withValues(alpha: 0.35),
                      labelStyle: TextStyle(
                        color: selected
                            ? AppTheme.secondaryColor
                            : AppTheme.textSecondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
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
                const SizedBox(height: AppTheme.spacingL),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Photos ($_minPhotos or more)', style: AppTheme.label),
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
                        _PhotoThumb(
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
                        : const Text('Save person'),
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

class _PhotoThumb extends StatelessWidget {
  const _PhotoThumb({required this.file, this.onRemove});

  final File file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.file(
            file,
            width: 84,
            height: 84,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => Container(
              width: 84,
              height: 84,
              color: AppTheme.neutralLight,
              child: const Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                decoration: const BoxDecoration(
                  color: AppTheme.errorColor,
                  shape: BoxShape.circle,
                ),
                padding: const EdgeInsets.all(2),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}
