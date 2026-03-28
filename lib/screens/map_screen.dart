import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/place.dart';
import '../services/api_service.dart';

// Design system
const _bg = Color(0xFF131313);
const _surface = Color(0xFF1E1E1E);
const _surfaceHigh = Color(0xFF2A2A2A);
const _primary = Color(0xFFC4C0FF);
const _primaryDark = Color(0xFF8781FF);
const _secondary = Color(0xFF5CDBC0);

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  LatLng? _userPosition;
  List<Place> _places = [];
  bool _loading = true;
  final _searchController = TextEditingController();
  String _activeFilter = 'tutti';
  Timer? _debounce;
  static const _defaultPosition = LatLng(41.9028, 12.4964);

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        final pos = await Geolocator.getCurrentPosition();
        setState(() {
          _userPosition = LatLng(pos.latitude, pos.longitude);
        });
        await ApiService.updateLocation(pos.latitude, pos.longitude);
        _mapController.move(_userPosition!, 14);
        await _loadPlacesNearby(pos.latitude, pos.longitude);
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Posizione non disponibile. Cerca una città.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadPlacesNearby(double lat, double lon) async {
    setState(() => _loading = true);
    try {
      final rawPlaces = await ApiService.getNearbyPlaces(lat, lon);
      setState(() {
        _places = rawPlaces.map((p) => Place.fromJson(p)).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _searchCity(String city) async {
    if (city.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      final places = await ApiService.getPlacesByCity(city.trim());
      if (places.isNotEmpty) {
        final first = places.first;
        _mapController.move(LatLng(first.lat, first.lon), 13);
        setState(() {
          _places = places;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Nessun posto trovato a $city')),
          );
        }
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _onMapMoved(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () async {
      final bounds = camera.visibleBounds;
      final newPlaces = await ApiService.getPlacesByBbox(
        minLat: bounds.south,
        maxLat: bounds.north,
        minLon: bounds.west,
        maxLon: bounds.east,
      );
      setState(() {
        final existing = {for (var p in _places) '${p.lat},${p.lon}': p};
        for (var p in newPlaces) {
          existing['${p.lat},${p.lon}'] = p;
        }
        _places = existing.values.toList();
      });
    });
  }

  List<Place> get _filteredPlaces {
    if (_activeFilter == 'tutti') return _places;
    return _places.where((p) => p.category == _activeFilter).toList();
  }

  void _centerOnUser() {
    final pos = _userPosition ?? _defaultPosition;
    _mapController.move(pos, 15);
  }

  Future<void> _openGoogleMaps(Place place) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${place.lat},${place.lon}'
      '&travelmode=walking',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openAppleMaps(Place place) async {
    final encoded = Uri.encodeComponent(place.name);
    final uri = Uri.parse(
      'maps://maps.apple.com/?daddr=${place.lat},${place.lon}&q=$encoded',
    );
    final fallback = Uri.parse(
      'https://maps.apple.com/?daddr=${place.lat},${place.lon}&q=$encoded',
    );
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(fallback, mode: LaunchMode.externalApplication);
    }
  }

  String _distanceLabel(Place place) {
    if (place.distanceM == null) return '';
    final d = place.distanceM!;
    if (d >= 1000) return '${(d / 1000).toStringAsFixed(1)} km';
    return '${d.toStringAsFixed(0)} m';
  }

  void _showPlaceDetail(Place place) {
    final isCafe = place.category == 'cafe';
    final categoryColor = isCafe ? const Color(0xFFFFB347) : _secondary;
    final categoryLabel = isCafe ? '☕ Bar & Caffè' : '📚 Biblioteca';
    final dist = _distanceLabel(place);

    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Name + distance
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                ),
                if (dist.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9999),
                    ),
                    child: Text(
                      dist,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 12,
                        color: _primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
            // Category chip
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: categoryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                categoryLabel,
                style: GoogleFonts.beVietnamPro(
                  fontSize: 13,
                  color: categoryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (place.address != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: Colors.white38),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      place.address!,
                      style: GoogleFonts.beVietnamPro(
                        fontSize: 13,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openGoogleMaps(place),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _primaryDark,
                        borderRadius: BorderRadius.circular(9999),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryDark.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.map_rounded,
                              color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Google Maps',
                            style: GoogleFonts.beVietnamPro(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _openAppleMaps(place),
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: _primaryDark.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.navigation_rounded,
                              color: _primaryDark, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Apple Maps',
                            style: GoogleFonts.beVietnamPro(
                              color: _primaryDark,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final active = _activeFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = value),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              active ? _primaryDark : _surface.withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          label,
          style: GoogleFonts.beVietnamPro(
            color: active ? Colors.white : Colors.white54,
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // LAYER 1 — Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userPosition ?? _defaultPosition,
              initialZoom: 13,
              onMapEvent: (event) {
                if (event is MapEventMoveEnd) {
                  _onMapMoved(event.camera, true);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.incontro.studymatch',
              ),
              MarkerLayer(
                markers: [
                  if (_userPosition != null)
                    Marker(
                      point: _userPosition!,
                      width: 28,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _primaryDark,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: _primaryDark.withValues(alpha: 0.55),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.person,
                            color: Colors.white, size: 14),
                      ),
                    ),
                  ..._filteredPlaces.map((place) {
                    final isCafe = place.category == 'cafe';
                    return Marker(
                      point: LatLng(place.lat, place.lon),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => _showPlaceDetail(place),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _secondary,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _secondary.withValues(alpha: 0.45),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isCafe ? Icons.coffee : Icons.local_library,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),

          // LAYER 2 — Search bar + filter chips
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter:
                            ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                        child: Container(
                          color: _surface.withValues(alpha: 0.88),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _searchController,
                                  style: GoogleFonts.beVietnamPro(
                                      color: Colors.white),
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: _searchCity,
                                  decoration: InputDecoration(
                                    hintText:
                                        'Cerca città... es. Napoli, Roma',
                                    hintStyle: GoogleFonts.beVietnamPro(
                                        color: Colors.white38,
                                        fontSize: 14),
                                    prefixIcon: const Icon(Icons.search,
                                        color: Colors.white38),
                                    border: InputBorder.none,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                            vertical: 14),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: _centerOnUser,
                                icon: const Icon(
                                    Icons.my_location_rounded,
                                    color: _primaryDark),
                                tooltip: 'La mia posizione',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        _buildFilterChip('Tutti', 'tutti'),
                        const SizedBox(width: 8),
                        _buildFilterChip('☕ Bar & Caffè', 'cafe'),
                        const SizedBox(width: 8),
                        _buildFilterChip(
                            '📚 Biblioteche', 'study_room'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // LAYER 3 — Result count badge
          if (_filteredPlaces.isNotEmpty)
            Positioned(
              bottom: 100,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: _surface.withValues(alpha: 0.90),
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  '${_filteredPlaces.length} posti trovati',
                  style: GoogleFonts.beVietnamPro(
                      color: Colors.white70, fontSize: 12),
                ),
              ),
            ),

          // LAYER 4 — Loading
          if (_loading)
            Positioned(
              top: 130,
              left: 0,
              right: 0,
              child: Center(
                child: CircularProgressIndicator(
                    color: _primary.withValues(alpha: 0.8)),
              ),
            ),
        ],
      ),
      floatingActionButton: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: _primaryDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _primaryDark.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          onPressed: _centerOnUser,
          icon: const Icon(Icons.my_location_rounded,
              color: Colors.white, size: 22),
        ),
      ),
    );
  }
}
