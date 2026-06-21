import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';

/// Interactive map for placing a safe-zone center by tapping.
class SafeZonePickerMap extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final List<SafeZone> existingZones;
  final LatLng? selectedCenter;
  final double previewRadiusMeters;
  final ValueChanged<LatLng> onCenterSelected;
  final SafeZone? excludeZone;

  const SafeZonePickerMap({
    super.key,
    required this.initialLatitude,
    required this.initialLongitude,
    this.existingZones = const [],
    this.selectedCenter,
    this.previewRadiusMeters = 200,
    required this.onCenterSelected,
    this.excludeZone,
  });

  @override
  State<SafeZonePickerMap> createState() => _SafeZonePickerMapState();
}

class _SafeZonePickerMapState extends State<SafeZonePickerMap> {
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SafeZonePickerMap oldWidget) {
    super.didUpdateWidget(oldWidget);
    final center = widget.selectedCenter;
    if (center != null &&
        center != oldWidget.selectedCenter &&
        center.latitude != oldWidget.selectedCenter?.latitude) {
      _mapController.move(center, _mapController.camera.zoom);
    }
  }

  List<SafeZone> get _visibleZones {
    if (widget.excludeZone == null) return widget.existingZones;
    return widget.existingZones
        .where((z) => z.id != widget.excludeZone!.id)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final patientPoint = LatLng(widget.initialLatitude, widget.initialLongitude);
    final center = widget.selectedCenter ?? patientPoint;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            onTap: (_, point) => widget.onCenterSelected(point),
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mindmate.app',
            ),
            if (_visibleZones.isNotEmpty)
              CircleLayer(
                circles: _visibleZones
                    .map(
                      (zone) => CircleMarker(
                        point: LatLng(zone.latitude, zone.longitude),
                        radius: zone.radiusMeters,
                        useRadiusInMeter: true,
                        color: AppTheme.successColor.withValues(alpha: 0.12),
                        borderColor: AppTheme.successColor.withValues(alpha: 0.6),
                        borderStrokeWidth: 1.5,
                      ),
                    )
                    .toList(),
              ),
            if (widget.selectedCenter != null) ...[
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: widget.selectedCenter!,
                    radius: widget.previewRadiusMeters,
                    useRadiusInMeter: true,
                    color: AppTheme.primaryColor.withValues(alpha: 0.2),
                    borderColor: AppTheme.primaryColor,
                    borderStrokeWidth: 2.5,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: widget.selectedCenter!,
                    width: 40,
                    height: 40,
                    child: const Icon(
                      Icons.place,
                      color: AppTheme.primaryColor,
                      size: 40,
                    ),
                  ),
                ],
              ),
            ],
            MarkerLayer(
              markers: [
                Marker(
                  point: patientPoint,
                  width: 44,
                  height: 44,
                  child: const Icon(
                    Icons.location_on,
                    color: AppTheme.errorColor,
                    size: 40,
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          top: 12,
          left: 12,
          right: 12,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                'Tap the map to place the zone center. Red pin = patient location.',
                style: AppTheme.bodySmall.copyWith(color: AppTheme.secondaryColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
