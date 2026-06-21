import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';

class LocationMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool isFallback;
  final List<SafeZone> safeZones;

  const LocationMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    this.safeZones = const [],
  });

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView> {
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
  void didUpdateWidget(covariant LocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      _mapController.move(
        LatLng(widget.latitude, widget.longitude),
        _mapController.camera.zoom,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.latitude, widget.longitude);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.mindmate.app',
        ),
        if (widget.safeZones.isNotEmpty)
          CircleLayer(
            circles: widget.safeZones
                .map(
                  (zone) => CircleMarker(
                    point: LatLng(zone.latitude, zone.longitude),
                    radius: zone.radiusMeters,
                    useRadiusInMeter: true,
                    color: AppTheme.successColor.withValues(alpha: 0.15),
                    borderColor: AppTheme.successColor,
                    borderStrokeWidth: 2,
                  ),
                )
                .toList(),
          ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 48,
              height: 48,
              child: Icon(
                widget.isFallback ? Icons.my_location : Icons.location_on,
                color: widget.isFallback ? Colors.orange : AppTheme.errorColor,
                size: 44,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
