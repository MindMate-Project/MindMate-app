import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';
import 'package:mindmate/features/memory/data/services/memory_training_service.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_state.dart';

class MemoryDrillScreen extends StatefulWidget {
  const MemoryDrillScreen({super.key});

  @override
  State<MemoryDrillScreen> createState() => _MemoryDrillScreenState();
}

class _MemoryDrillScreenState extends State<MemoryDrillScreen> {
  MemoryItem? _picked;
  bool _picking = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAndPick());
  }

  Future<void> _ensureAndPick() async {
    final args = ModalRoute.of(context)?.settings.arguments;
    final requestedId = args is Map ? args['memoryId'] as String? : null;

    final cubit = context.read<MemoryCubit>();
    final state = cubit.state;

    if (state is! MemoryLoaded) {
      await cubit.loadMemories();
    }

    final loaded = cubit.state;
    if (loaded is! MemoryLoaded) {
      if (!mounted) return;
      setState(() {
        _picking = false;
        _error = loaded is MemoryError
            ? loaded.message
            : 'Could not load memories.';
      });
      return;
    }

    final all = [...loaded.photos, ...loaded.videos, ...loaded.texts];

    MemoryItem? picked;
    if (requestedId != null && requestedId.isNotEmpty) {
      for (final m in all) {
        if (m.id == requestedId) {
          picked = m;
          break;
        }
      }
    }
    picked ??= await MemoryTrainingService.instance.pickRandomMemory(all);
    if (picked != null && picked.id != null && picked.id!.isNotEmpty) {
      await MemoryTrainingService.instance.rememberShown(picked.id!);
    }

    if (!mounted) return;
    setState(() {
      _picked = picked;
      _picking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.neutralWhite,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        title: const Text(
          'Memory Training',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_picking) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      );
    }

    if (_error != null) {
      return _CenteredMessage(
        icon: Icons.error_outline,
        title: 'Something went wrong',
        body: _error!,
        actionLabel: 'Try again',
        onAction: () {
          setState(() {
            _picking = true;
            _error = null;
          });
          _ensureAndPick();
        },
      );
    }

    final picked = _picked;
    if (picked == null) {
      return const _CenteredMessage(
        icon: Icons.photo_library_outlined,
        title: 'No memories yet',
        body:
            'Ask your caregiver to add some photos, videos, or notes — then come back to train your memory.',
      );
    }

    return _DrillContent(item: picked, onDone: () => Navigator.maybePop(context));
  }
}

class _DrillContent extends StatelessWidget {
  const _DrillContent({required this.item, required this.onDone});

  final MemoryItem item;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: _media(context)),
          const SizedBox(height: AppTheme.spacingL),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.secondaryColor,
            ),
            textAlign: TextAlign.center,
          ),
          if (item.subtitle != null && item.subtitle!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingS),
            Text(
              item.subtitle!,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (item.description != null && item.description!.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingL),
            Text(
              item.description!,
              style: const TextStyle(
                fontSize: 16,
                height: 1.5,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppTheme.spacingXXL),
          ElevatedButton(
            onPressed: onDone,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: AppTheme.neutralWhite,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Done',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _media(BuildContext context) {
    switch (item.type) {
      case MemoryType.photo:
        final url = item.imageUrl;
        if (url == null || url.isEmpty) {
          return _placeholder(Icons.image_not_supported_outlined);
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.cover,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: AppTheme.primaryColor),
            ),
            errorWidget: (context, url, error) =>
                _placeholder(Icons.broken_image_outlined),
          ),
        );

      case MemoryType.video:
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.videocam_outlined,
                  size: 72,
                  color: Colors.grey[500],
                ),
                const SizedBox(height: AppTheme.spacingM),
                Text(
                  'Video memory',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: AppTheme.spacingS),
                Text(
                  'Open the Memory tab to play.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );

      case MemoryType.text:
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.neutralLight,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Icon(
              Icons.format_quote,
              size: 88,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
            ),
          ),
        );
    }
  }

  Widget _placeholder(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 80, color: Colors.grey[400]),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: Colors.grey[400]),
            const SizedBox(height: AppTheme.spacingL),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingS),
            Text(
              body,
              style: TextStyle(fontSize: 15, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppTheme.spacingL),
              ElevatedButton(
                onPressed: onAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: AppTheme.neutralWhite,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
