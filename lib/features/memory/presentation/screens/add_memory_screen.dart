import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/custom_text_form_field.dart';
import 'package:mindmate/core/widgets/labeled_form_field.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_state.dart';

/// Caregiver-facing form to add a new memory for the active patient.
/// Matches the "Add New Memory" screen in the Figma: Type radio
/// (Photo/Video/Text), Title, Content, Tags, Relation (Photo/Video only),
/// Upload Media, Save/Cancel.
class AddMemoryScreen extends StatefulWidget {
  const AddMemoryScreen({super.key});

  @override
  State<AddMemoryScreen> createState() => _AddMemoryScreenState();
}

class _AddMemoryScreenState extends State<AddMemoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _contentCtrl = TextEditingController();
  final _tagsCtrl = TextEditingController();
  final _relationCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  MemoryType _type = MemoryType.photo;
  File? _mediaFile;
  String? _mediaFileName;
  bool _submitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _tagsCtrl.dispose();
    _relationCtrl.dispose();
    super.dispose();
  }

  bool get _needsMedia => _type != MemoryType.text;
  bool get _needsRelation => _type != MemoryType.text;

  String? _required(String? v) =>
      v == null || v.trim().isEmpty ? 'Required' : null;

  Future<void> _pickMedia() async {
    try {
      XFile? picked;
      if (_type == MemoryType.photo) {
        picked = await _picker.pickImage(source: ImageSource.gallery);
      } else if (_type == MemoryType.video) {
        picked = await _picker.pickVideo(source: ImageSource.gallery);
      }
      if (picked == null) return;
      setState(() {
        _mediaFile = File(picked!.path);
        _mediaFileName = picked.path.split(RegExp(r'[\\/]')).last;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not pick file: $e')),
      );
    }
  }

  void _onTypeChanged(MemoryType? v) {
    if (v == null || _submitting) return;
    setState(() {
      _type = v;
      // Reset media if switching away from media types or between them.
      if (v == MemoryType.text) {
        _mediaFile = null;
        _mediaFileName = null;
      }
    });
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    if (_needsMedia && _mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please pick a ${_type.name} file first')),
      );
      return;
    }

    final tags = _tagsCtrl.text
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    setState(() => _submitting = true);
    try {
      await context.read<MemoryCubit>().createMemory(
            type: _type,
            title: _titleCtrl.text,
            content: _contentCtrl.text,
            relation: _needsRelation ? _relationCtrl.text : null,
            tags: tags.isEmpty ? null : tags,
            mediaFile: _mediaFile,
          );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<MemoryCubit, MemoryState>(
      listener: (context, state) {
        if (state is MemoryCreated) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Memory saved'),
              backgroundColor: AppTheme.successColor,
            ),
          );
          Navigator.pop(context, true);
        } else if (state is MemoryCreateError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.neutralWhite,
        appBar: const ProfileAppBar(title: 'Add New Memory'),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(AppTheme.spacingL),
            children: [
              // Type selector — chunky pill row so Video doesn't get missed.
              LabeledFormField(
                label: 'Type *',
                child: Row(
                  children: [
                    _typePill(MemoryType.photo, 'Photo', Icons.photo_outlined),
                    const SizedBox(width: 8),
                    _typePill(MemoryType.video, 'Video', Icons.videocam_outlined),
                    const SizedBox(width: 8),
                    _typePill(MemoryType.text, 'Text', Icons.notes_outlined),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Title
              LabeledFormField(
                label: 'Title *',
                child: CustomTextFormField(
                  controller: _titleCtrl,
                  hintText: 'e.g. Wedding Day',
                  validator: _required,
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Content
              LabeledFormField(
                label: 'Content *',
                child: TextFormField(
                  controller: _contentCtrl,
                  maxLines: 5,
                  minLines: 3,
                  validator: _required,
                  decoration: InputDecoration(
                    hintText:
                        'A short description of this memory the patient should remember',
                    hintStyle: AppTheme.hintText,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.neutralMedium),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          const BorderSide(color: AppTheme.primaryColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Tags
              LabeledFormField(
                label: 'Tags',
                child: CustomTextFormField(
                  controller: _tagsCtrl,
                  hintText: 'family, holiday, 1999 (comma-separated)',
                ),
              ),
              const SizedBox(height: AppTheme.spacingL),

              // Relation (only for photo/video — per Figma comment #22)
              if (_needsRelation) ...[
                LabeledFormField(
                  label: 'Relation *',
                  child: CustomTextFormField(
                    controller: _relationCtrl,
                    hintText: 'e.g. Daughter, Grandchild, Sister',
                    validator:
                        _needsRelation ? _required : null,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingL),
              ],

              // Upload media (only for photo/video)
              if (_needsMedia) ...[
                _buildUploadButton(),
                const SizedBox(height: AppTheme.spacingXXL),
              ],

              // Save / Cancel
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: AppTheme.neutralWhite,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppTheme.neutralWhite,
                              ),
                            )
                          : const Text('Save'),
                    ),
                  ),
                  const SizedBox(width: AppTheme.spacingM),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _submitting
                          ? null
                          : () => Navigator.maybePop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryColor,
                        side:
                            const BorderSide(color: AppTheme.primaryColor),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typePill(MemoryType value, String label, IconData icon) {
    final selected = _type == value;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _submitting ? null : () => _onTypeChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primaryColor : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected
                  ? AppTheme.primaryColor
                  : AppTheme.neutralMedium,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: selected ? Colors.white : AppTheme.secondaryColor,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: AppTheme.label.copyWith(
                  color: selected ? Colors.white : AppTheme.secondaryColor,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadButton() {
    final isVideo = _type == MemoryType.video;
    final defaultLabel = isVideo ? 'Upload video' : 'Upload photo';
    final hint = isVideo
        ? 'Opens the gallery in video mode (MP4 recommended).'
        : 'Opens the gallery in photo mode.';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppTheme.neutralMedium),
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Icon(
              isVideo ? Icons.videocam_outlined : Icons.photo_outlined,
              color: AppTheme.primaryColor,
            ),
            title: Text(
              _mediaFileName ?? defaultLabel,
              style: AppTheme.label.copyWith(
                color: _mediaFileName == null
                    ? AppTheme.secondaryColor
                    : AppTheme.primaryColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: _mediaFile == null
                ? null
                : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: _submitting
                        ? null
                        : () => setState(() {
                              _mediaFile = null;
                              _mediaFileName = null;
                            }),
                  ),
            onTap: _submitting ? null : _pickMedia,
          ),
        ),
        if (_mediaFile == null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              hint,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
      ],
    );
  }
}
