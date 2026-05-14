import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:animate_do/animate_do.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with SingleTickerProviderStateMixin {
  final MapController _mapController = MapController();
  Position? _currentPosition;
  bool _isLoading = true;
  String _statusMessage = 'Acquiring your location...';
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _getLocation();
  }

  Future<void> _getLocation() async {
    setState(() { _isLoading = true; _statusMessage = 'Checking permissions...'; });
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() { _isLoading = false; _statusMessage = 'Location permission denied.'; });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() { _isLoading = false; _statusMessage = 'Location permanently denied. Enable in settings.'; });
        return;
      }

      setState(() => _statusMessage = 'Locking onto your position...');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, timeLimit: Duration(seconds: 15)),
      );
      setState(() {
        _currentPosition = position;
        _isLoading = false;
        _statusMessage = 'Location locked';
      });
      _mapController.move(LatLng(position.latitude, position.longitude), 15);
    } catch (e) {
      setState(() { _isLoading = false; _statusMessage = 'Error: ${e.toString()}'; });
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pos = _currentPosition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('LIVE JOURNEY MAP', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 13)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.primary,
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            onPressed: _getLocation,
            tooltip: 'Re-acquire location',
          ),
        ],
      ),
      body: Stack(
        children: [
          // ── Map ────────────────────────────────────────────────────────────────
          if (pos != null)
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: LatLng(pos.latitude, pos.longitude),
                initialZoom: 15,
                minZoom: 4,
                maxZoom: 19,
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.hylator.app',
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(pos.latitude, pos.longitude),
                      width: 80, height: 80,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 60 + 20 * _pulseController.value,
                              height: 60 + 20 * _pulseController.value,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary.withAlpha((50 * (1 - _pulseController.value)).toInt()),
                              ),
                            ),
                            Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [BoxShadow(color: theme.colorScheme.primary.withAlpha(100), blurRadius: 15)],
                              ),
                              child: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            FlutterMap(
              options: const MapOptions(initialCenter: LatLng(20.5937, 78.9629), initialZoom: 5),
              children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hylator.app')],
            ),

          // ── Status Card ────────────────────────────────────────────────────────
          if (pos != null)
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: FadeInUp(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withAlpha(230),
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: theme.colorScheme.primary.withAlpha(40)),
                    boxShadow: [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 20)],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.location_on_rounded, color: theme.colorScheme.primary, size: 20),
                          const SizedBox(width: 8),
                          Text('YOUR POSITION', style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _CoordChip(label: 'LAT', value: pos.latitude.toStringAsFixed(4)),
                          _CoordChip(label: 'LNG', value: pos.longitude.toStringAsFixed(4)),
                          _CoordChip(label: 'ALT', value: '${pos.altitude.toStringAsFixed(0)}m'),
                          _CoordChip(label: 'ACC', value: '±${pos.accuracy.toStringAsFixed(0)}m'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // ── Loading Overlay ────────────────────────────────────────────────────
          if (_isLoading)
            Container(
              color: theme.colorScheme.surface.withAlpha(200),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: theme.colorScheme.primary),
                    const SizedBox(height: 20),
                    Text(_statusMessage, style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),

          // ── Error State ────────────────────────────────────────────────────────
          if (!_isLoading && pos == null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_off_rounded, size: 60, color: theme.colorScheme.primary.withAlpha(100)),
                  const SizedBox(height: 16),
                  Text(_statusMessage, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: _getLocation,
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('RETRY'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _CoordChip extends StatelessWidget {
  final String label, value;
  const _CoordChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: theme.colorScheme.primary, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
