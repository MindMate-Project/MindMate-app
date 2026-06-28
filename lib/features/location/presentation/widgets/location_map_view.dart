import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mindmate/core/themes/app_theme.dart';
import 'package:mindmate/features/location/data/models/safe_zone.dart';

class LocationMapView extends StatefulWidget {
  final double latitude;
  final double longitude;
  final bool isFallback;
  final bool isDeviceOnline;
  final List<SafeZone> safeZones;
  final bool patientInSafeZone;

  const LocationMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.isFallback,
    this.isDeviceOnline = true,
    this.safeZones = const [],
    this.patientInSafeZone = true,
  });

  @override
  State<LocationMapView> createState() => _LocationMapViewState();
}

class _LocationMapViewState extends State<LocationMapView>
    with TickerProviderStateMixin {
  static const _distance = Distance();
  static const _minMoveMeters = 1.0;

  late final MapController _mapController;
  late AnimationController _moveController;
  late AnimationController _pulseController;
  late LatLng _displayPoint;
  LatLng? _moveFrom;
  LatLng? _moveTo;

  static bool _isFiniteLatLng(LatLng point) =>
      point.latitude.isFinite && point.longitude.isFinite;

  static bool _isFiniteCoord(double lat, double lng) =>
      lat.isFinite && lng.isFinite;

  List<SafeZone> get _renderableZones =>
      widget.safeZones.where((zone) => zone.isRenderable).toList();

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _displayPoint = _isFiniteCoord(widget.latitude, widget.longitude)
        ? LatLng(widget.latitude, widget.longitude)
        : const LatLng(0, 0);
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..addListener(_onMoveTick);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _moveController.dispose();
    _pulseController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMoveTick() {
    final from = _moveFrom;
    final to = _moveTo;
    if (from == null || to == null) return;
    if (!_isFiniteLatLng(from) || !_isFiniteLatLng(to)) {
      _moveController.stop();
      return;
    }

    final t = Curves.easeInOut.transform(_moveController.value);
    final point = LatLng(
      from.latitude + (to.latitude - from.latitude) * t,
      from.longitude + (to.longitude - from.longitude) * t,
    );
    if (!_isFiniteLatLng(point)) {
      _moveController.stop();
      return;
    }
    setState(() => _displayPoint = point);
    _mapController.move(point, _mapController.camera.zoom);
  }

  void _animateTo(LatLng target) {
    if (!_isFiniteLatLng(target) || !_isFiniteLatLng(_displayPoint)) return;
    _moveFrom = _displayPoint;
    _moveTo = target;
    _moveController.forward(from: 0);
    _pulseController.forward(from: 0);
  }

  @override
  void didUpdateWidget(covariant LocationMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isFiniteCoord(widget.latitude, widget.longitude)) return;

    final previous = LatLng(oldWidget.latitude, oldWidget.longitude);
    final target = LatLng(widget.latitude, widget.longitude);
    if (!_isFiniteLatLng(previous)) {
      setState(() => _displayPoint = target);
      _mapController.move(target, _mapController.camera.zoom);
      return;
    }

    final movedMeters = _distance(previous, target);
    if (movedMeters.isFinite && movedMeters >= _minMoveMeters) {
      _animateTo(target);
      return;
    }

    if (oldWidget.latitude != widget.latitude ||
        oldWidget.longitude != widget.longitude) {
      setState(() => _displayPoint = target);
      _mapController.move(target, _mapController.camera.zoom);
    }
  }

  Color get _pinColor {
    if (widget.isFallback) return Colors.orange;
    if (!widget.isDeviceOnline) return AppTheme.neutralMedium;
    return AppTheme.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    final offline = !widget.isFallback && !widget.isDeviceOnline;
    final zones = _renderableZones;
    final markerPoint = _isFiniteLatLng(_displayPoint)
        ? _displayPoint
        : (_isFiniteCoord(widget.latitude, widget.longitude)
              ? LatLng(widget.latitude, widget.longitude)
              : null);

    if (markerPoint == null) {
      return const Center(
        child: Text(
          'Waiting for a valid location…',
          style: TextStyle(color: AppTheme.neutralDark),
        ),
      );
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: markerPoint,
            initialZoom: 16,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.mindmate.app',
            ),
            if (zones.isNotEmpty)
              CircleLayer(
                circles: zones
                    .map(
                      (zone) => CircleMarker(
                        point: LatLng(zone.latitude, zone.longitude),
                        radius: zone.radiusMeters,
                        useRadiusInMeter: true,
                        color:
                            (widget.patientInSafeZone
                                    ? AppTheme.successColor
                                    : AppTheme.warningColor)
                                .withValues(alpha: offline ? 0.08 : 0.15),
                        borderColor: widget.patientInSafeZone
                            ? AppTheme.successColor
                            : AppTheme.warningColor,
                        borderStrokeWidth: 2,
                      ),
                    )
                    .toList(),
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: markerPoint,
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          if (_pulseController.isDismissed) {
                            return const SizedBox.shrink();
                          }
                          final scale = 1 + _pulseController.value * 1.4;
                          final opacity = (1 - _pulseController.value) * 0.5;
                          return Transform.scale(
                            scale: scale,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _pinColor.withValues(alpha: opacity),
                              ),
                            ),
                          );
                        },
                      ),
                      Icon(
                        widget.isFallback
                            ? Icons.my_location
                            : Icons.location_on,
                        color: _pinColor,
                        size: 44,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        if (offline)
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Text(
                  'Device offline — last known location',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        if (_moveController.isAnimating)
          Positioned(
            bottom: 12,
            left: 0,
            right: 0,
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.directions_walk,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Updating location…',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
