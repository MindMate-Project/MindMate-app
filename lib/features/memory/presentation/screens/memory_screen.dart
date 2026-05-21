import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/navigation/app_bottom_nav.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:mindmate/features/auth/presentation/cubit/auth_state.dart';
import 'package:mindmate/features/memory/data/models/memory_item.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_cubit.dart';
import 'package:mindmate/features/memory/presentation/cubit/memory_state.dart';
import 'package:mindmate/features/memory/presentation/widgets/photo_tab.dart';
import 'package:mindmate/features/memory/presentation/widgets/video_tab.dart';
import 'package:mindmate/features/memory/presentation/widgets/text_tab.dart';

class MemoryScreen extends StatefulWidget {
  const MemoryScreen({super.key});

  @override
  State<MemoryScreen> createState() => _MemoryScreenState();
}

class _MemoryScreenState extends State<MemoryScreen> {
  int _selectedTab = 0; // 0 = Photo, 1 = Video, 2 = Text
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    context.read<MemoryCubit>().loadMemories();
  }

  List<MemoryItem> _filtered(List<MemoryItem> source) {
    if (_searchQuery.isEmpty) return source;
    final q = _searchQuery.toLowerCase();
    return source.where((item) {
      return item.title.toLowerCase().contains(q) ||
          (item.subtitle?.toLowerCase().contains(q) ?? false) ||
          (item.description?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  String get _headerTitle {
    switch (_selectedTab) {
      case 0:
        return 'Photo';
      case 1:
        return 'Video';
      case 2:
        return 'Text';
      default:
        return 'Memory';
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _headerTitle,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildTabSelector(),
          Expanded(child: _buildBody()),
        ],
      ),
      floatingActionButton: _buildAddMemoryFab(),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 1),
    );
  }

  /// FAB visible only when the current user is a caregiver. Tapping it
  /// pushes the Add Memory screen and reloads the list when it returns
  /// with a `true` result (i.e. a memory was created).
  Widget _buildAddMemoryFab() {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        if (!AppBottomNav.isCaregiver(state)) {
          return const SizedBox.shrink();
        }
        return FloatingActionButton(
          backgroundColor: AppTheme.primaryColor,
          tooltip: 'Add memory',
          onPressed: () async {
            final created = await Navigator.pushNamed(context, '/memory/add');
            if (created == true && context.mounted) {
              context.read<MemoryCubit>().loadMemories();
            }
          },
          child: const Icon(Icons.add, color: Colors.white),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (value) => setState(() => _searchQuery = value),
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            suffixIcon: Icon(Icons.search, color: Colors.grey[500]),
          ),
        ),
      ),
    );
  }

  Widget _buildTabSelector() {
    const labels = ['Photo', 'Video', 'Text'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: Row(
        children: List.generate(labels.length, (i) {
          final isSelected = _selectedTab == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedTab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.primaryColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryColor
                        : Colors.grey.shade300,
                  ),
                ),
                child: Center(
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey[700],
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<MemoryCubit, MemoryState>(
      builder: (context, state) {
        if (state is MemoryLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryColor),
          );
        }

        if (state is MemoryError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        context.read<MemoryCubit>().loadMemories(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                    ),
                    child: const Text('Retry',
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is MemoryLoaded) {
          return _buildTabContent(state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildTabContent(MemoryLoaded state) {
    switch (_selectedTab) {
      case 0:
        return PhotoTab(items: _filtered(state.photos));
      case 1:
        return VideoTab(items: _filtered(state.videos));
      case 2:
        return TextTab(items: _filtered(state.texts));
      default:
        return const SizedBox.shrink();
    }
  }
}
