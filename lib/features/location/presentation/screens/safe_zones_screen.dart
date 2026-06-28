import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/core/widgets/info_card.dart';
import 'package:mindmate/core/widgets/profile_app_bar.dart';
import 'package:mindmate/features/location/data/models/patient_location.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';
import 'package:mindmate/features/location/presentation/cubit/location_cubit.dart';
import 'package:mindmate/features/location/presentation/cubit/location_state.dart';
import 'package:mindmate/features/location/presentation/widgets/safe_zone_picker_map.dart';

class SafeZonesScreen extends StatefulWidget {
  const SafeZonesScreen({super.key, this.initialTabIndex = 0});

  /// 0 = saved zones list, 1 = add / edit on map.
  final int initialTabIndex;

  @override
  State<SafeZonesScreen> createState() => _SafeZonesScreenState();
}

class _SafeZonesScreenState extends State<SafeZonesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  SafeZone? _editingZone;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openEditor({SafeZone? zone}) {
    setState(() => _editingZone = zone);
    _tabController.animateTo(1);
  }

  void _clearEditor() {
    setState(() => _editingZone = null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundWhite,
      appBar: ProfileAppBar(
        title: 'Safe zones',
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppTheme.neutralWhite, size: 28),
            tooltip: 'Add zone',
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.neutralLight,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppTheme.primaryColor,
                    borderRadius: BorderRadius.circular(50),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: AppTheme.neutralWhite,
                  unselectedLabelColor: AppTheme.neutralBlack,
                  labelStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'My zones'),
                    Tab(text: 'Add / Edit'),
                  ],
                ),
              ),
            ),
            Expanded(
              child: BlocBuilder<LocationCubit, LocationState>(
                builder: (context, state) {
                  if (state is! LocationLoaded) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppTheme.primaryColor,
                      ),
                    );
                  }

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _SafeZoneListTab(
                        zones: state.safeZones,
                        patientLocation: state.location,
                        onEdit: _openEditor,
                        onAdd: () => _openEditor(),
                      ),
                      _SafeZoneEditorTab(
                        key: ValueKey(_editingZone?.id ?? 'new'),
                        patientLocation: state.location,
                        existingZones: state.safeZones,
                        editingZone: _editingZone,
                        onSaved: () {
                          _clearEditor();
                          _tabController.animateTo(0);
                        },
                        onCancelEdit: _clearEditor,
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SafeZoneListTab extends StatelessWidget {
  final List<SafeZone> zones;
  final PatientLocation patientLocation;
  final void Function({SafeZone? zone}) onEdit;
  final VoidCallback onAdd;

  const _SafeZoneListTab({
    required this.zones,
    required this.patientLocation,
    required this.onEdit,
    required this.onAdd,
  });

  Future<void> _confirmDelete(BuildContext context, SafeZone zone) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove safe zone?'),
        content: Text('Remove "${zone.displayName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(color: AppTheme.errorColor),
            ),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<LocationCubit>().removeSafeZone(zone.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.map_outlined, size: 56, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No safe zones yet',
                style: AppTheme.heading3.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Add zones for places the patient should stay near. '
                'The backend stores one safe zone per patient; saving a new '
                'zone replaces the previous one.',
                textAlign: TextAlign.center,
                style: AppTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add),
                label: const Text('Add safe zone'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: zones.length,
      itemBuilder: (context, index) {
        final zone = zones[index];
        final inside = zone.contains(
          patientLocation.latitude,
          patientLocation.longitude,
        );

        return InfoCard(
          tag: inside ? 'Patient here' : '${zone.radiusMeters.round()} m',
          tagColor: inside ? AppTheme.successColor : AppTheme.infoColor,
          children: [
            Text(
              zone.displayName,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.secondaryColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${zone.latitude.toStringAsFixed(5)}, '
              '${zone.longitude.toStringAsFixed(5)}',
              style: AppTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => onEdit(zone: zone),
                  child: const Text('Edit'),
                ),
                TextButton(
                  onPressed: () => _confirmDelete(context, zone),
                  child: const Text(
                    'Remove',
                    style: TextStyle(color: AppTheme.errorColor),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SafeZoneEditorTab extends StatefulWidget {
  final PatientLocation patientLocation;
  final List<SafeZone> existingZones;
  final SafeZone? editingZone;
  final VoidCallback onSaved;
  final VoidCallback onCancelEdit;

  const _SafeZoneEditorTab({
    super.key,
    required this.patientLocation,
    required this.existingZones,
    required this.editingZone,
    required this.onSaved,
    required this.onCancelEdit,
  });

  @override
  State<_SafeZoneEditorTab> createState() => _SafeZoneEditorTabState();
}

class _SafeZoneEditorTabState extends State<_SafeZoneEditorTab> {
  static const _minRadiusMeters = 0.0;
  static const _defaultMaxRadiusMeters = 300.0;

  LatLng? _selectedCenter;
  late double _radiusMeters;
  late double _sliderMaxMeters;
  late final TextEditingController _nameController;
  bool _saving = false;

  bool get _isEditing => widget.editingZone != null;

  @override
  void initState() {
    super.initState();
    final zone = widget.editingZone;
    final rawRadius = zone?.radiusMeters ?? 200;
    _sliderMaxMeters = rawRadius > _defaultMaxRadiusMeters
        ? rawRadius
        : _defaultMaxRadiusMeters;
    _radiusMeters = rawRadius.clamp(_minRadiusMeters, _sliderMaxMeters);
    _nameController = TextEditingController(text: zone?.name ?? 'Home');
    if (zone != null) {
      _selectedCenter = LatLng(zone.latitude, zone.longitude);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _usePatientLocation() {
    setState(() {
      _selectedCenter = LatLng(
        widget.patientLocation.latitude,
        widget.patientLocation.longitude,
      );
    });
  }

  Future<void> _save() async {
    final center = _selectedCenter;
    if (center == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap the map to choose a location first')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final cubit = context.read<LocationCubit>();
      final name = _nameController.text.trim().isEmpty
          ? 'Home'
          : _nameController.text.trim();

      if (_isEditing) {
        await cubit.updateSafeZone(
          widget.editingZone!.copyWith(
            latitude: center.latitude,
            longitude: center.longitude,
            radiusMeters: _radiusMeters,
            name: name,
          ),
        );
      } else {
        await cubit.addSafeZone(
          latitude: center.latitude,
          longitude: center.longitude,
          radiusMeters: _radiusMeters,
          name: name,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_isEditing ? 'Zone updated' : 'Zone added')),
        );
        widget.onSaved();
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 5,
          child: SafeZonePickerMap(
            initialLatitude: widget.patientLocation.latitude,
            initialLongitude: widget.patientLocation.longitude,
            existingZones: widget.existingZones,
            excludeZone: widget.editingZone,
            selectedCenter: _selectedCenter,
            previewRadiusMeters: _radiusMeters,
            onCenterSelected: (point) =>
                setState(() => _selectedCenter = point),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_isEditing)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Editing "${widget.editingZone!.displayName}"',
                            style: AppTheme.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: widget.onCancelEdit,
                          child: const Text('Cancel edit'),
                        ),
                      ],
                    ),
                  ),
                OutlinedButton.icon(
                  onPressed: _usePatientLocation,
                  icon: const Icon(Icons.my_location),
                  label: const Text('Use patient location'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    side: const BorderSide(color: AppTheme.primaryColor),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Zone name',
                    filled: true,
                    fillColor: AppTheme.neutralLight,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Radius: ${_radiusMeters.round()} m',
                  style: AppTheme.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.secondaryColor,
                  ),
                ),
                Slider(
                  value: _radiusMeters,
                  min: _minRadiusMeters,
                  max: _sliderMaxMeters,
                  divisions: ((_sliderMaxMeters - _minRadiusMeters) / 1)
                      .round(),
                  activeColor: AppTheme.primaryColor,
                  label: '${_radiusMeters.round()} m',
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _radiusMeters = v),
                ),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(_isEditing ? 'Save changes' : 'Add safe zone'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
