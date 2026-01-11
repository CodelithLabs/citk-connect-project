import 'dart:ui' as ui;
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:camera/camera.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ArNavigationScreen extends StatefulWidget {
  const ArNavigationScreen({super.key});

  @override
  State<ArNavigationScreen> createState() => _ArNavigationScreenState();
}

class _ArNavigationScreenState extends State<ArNavigationScreen>
    with TickerProviderStateMixin {
  // Core Services
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _flutterTts = FlutterTts();
  final GlobalKey _globalKey = GlobalKey();
  
  // State Variables
  bool _isMuted = false;
  bool _isFlashOn = false;
  bool _isNightMode = false;
  bool _isOnTarget = false;
  bool _hasSpokenGuidance = false;
  bool _showHelpOverlay = true;
  bool _isLoading = true;
  
  // Camera & Sensors
  CameraController? _cameraController;
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<CompassEvent>? _compassSubscription;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  
  // Location & Navigation
  Position? _currentPosition;
  double _heading = 0;
  double _devicePitch = 0;
  double _bearingToTarget = 0;
  String _distanceText = "Initializing GPS...";
  
  // Filters & Settings
  String _selectedFilter = 'all';
  double _maxDistance = 1000;
  Set<String> _favorites = {};
  
  // Animation Controllers
  late AnimationController _pulseController;
  late AnimationController _scanController;
  
  // Destinations List
  List<Map<String, dynamic>> _destinations = [
    {
      "name": "Main Building",
      "lat": 26.4705,
      "lng": 90.2705,
      "type": "academic",
      "floor": "Ground Floor",
      "icon": Icons.business_rounded,
      "description": "Administrative offices and classrooms"
    },
    {
      "name": "Central Library",
      "lat": 26.4710,
      "lng": 90.2710,
      "type": "academic",
      "floor": "1st Floor",
      "icon": Icons.library_books_rounded,
      "description": "Main library with digital resources"
    },
    {
      "name": "Boys Hostel",
      "lat": 26.4745,
      "lng": 90.2660,
      "type": "hostel",
      "floor": "Multiple",
      "icon": Icons.hotel_rounded,
      "description": "Student accommodation"
    },
    {
      "name": "Canteen",
      "lat": 26.4690,
      "lng": 90.2750,
      "type": "food",
      "floor": "Ground Floor",
      "icon": Icons.restaurant_rounded,
      "description": "Food and beverages"
    },
    {
      "name": "Computer Lab",
      "lat": 26.4715,
      "lng": 90.2695,
      "type": "academic",
      "floor": "2nd Floor",
      "icon": Icons.computer_rounded,
      "description": "Computer facilities and labs"
    },
    {
      "name": "Sports Complex",
      "lat": 26.4680,
      "lng": 90.2720,
      "type": "other",
      "floor": "Ground Floor",
      "icon": Icons.sports_basketball_rounded,
      "description": "Indoor and outdoor sports facilities"
    },
  ];
  
  late Map<String, dynamic> _selectedDestination;

  @override
  void initState() {
    super.initState();
    _selectedDestination = _destinations[0];
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await Future.wait([
      _initTts(),
      _initCamera(),
      _loadFavorites(),
      _playBackgroundMusic(),
      _fetchDestinations(),
    ]);
    
    await _startLocationUpdates();
    _startCompass();
    _startSensors();
    
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDestinations() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('campus_locations').get();
      if (snapshot.docs.isNotEmpty) {
        final List<Map<String, dynamic>> remoteDestinations = [];
        for (var doc in snapshot.docs) {
          final data = doc.data();
          remoteDestinations.add({
            "name": data['name'] ?? 'Unknown',
            "lat": (data['lat'] as num?)?.toDouble() ?? 0.0,
            "lng": (data['lng'] as num?)?.toDouble() ?? 0.0,
            "type": data['type'] ?? 'other',
            "floor": data['floor'] ?? 'Ground',
            "icon": _getIconForType(data['type']),
            "description": data['description'] ?? '',
          });
        }
        if (mounted) {
          setState(() => _destinations = remoteDestinations);
        }
      }
    } catch (e) {
      debugPrint("Error fetching destinations: $e");
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'academic': return Icons.school_rounded;
      case 'hostel': return Icons.hotel_rounded;
      case 'food': return Icons.restaurant_rounded;
      default: return Icons.location_on_rounded;
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _favorites = (prefs.getStringList('ar_favorites') ?? []).toSet();
        });
      }
    } catch (e) {
      debugPrint("Error loading favorites: $e");
    }
  }

  Future<void> _toggleFavorite(String destName) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        if (_favorites.contains(destName)) {
          _favorites.remove(destName);
        } else {
          _favorites.add(destName);
        }
      });
      await prefs.setStringList('ar_favorites', _favorites.toList());
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("Error toggling favorite: $e");
    }
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setLanguage("en-US");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      debugPrint("TTS init error: $e");
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _cameraController = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _cameraController?.initialize();
        if (mounted) setState(() {});
      }
    } catch (e) {
      debugPrint("Camera init error: $e");
    }
  }

  Future<void> _playBackgroundMusic() async {
    try {
      await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer.setVolume(_isMuted ? 0 : 0.3);
      await _audioPlayer.play(AssetSource('sounds/ar_ambient.mp3')).catchError((_) {});
    } catch (e) {
      debugPrint("Audio player error: $e");
    }
  }

  Future<void> _startLocationUpdates() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          setState(() => _distanceText = "GPS Disabled");
        }
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            setState(() => _distanceText = "Permission Denied");
          }
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() => _distanceText = "Permission Permanently Denied");
        }
        return;
      }

      const LocationSettings locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      );

      _positionStream = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (!mounted) return;

        final double distanceInMeters = Geolocator.distanceBetween(
          position.latitude,
          position.longitude,
          _selectedDestination['lat'],
          _selectedDestination['lng'],
        );

        final double bearing = Geolocator.bearingBetween(
          position.latitude,
          position.longitude,
          _selectedDestination['lat'],
          _selectedDestination['lng'],
        );

        setState(() {
          _currentPosition = position;
          if (distanceInMeters < 50) {
            _distanceText = "You have arrived! 🎉";
          } else if (distanceInMeters < 1000) {
            _distanceText = "${distanceInMeters.toStringAsFixed(0)}m away";
          } else {
            _distanceText = "${(distanceInMeters / 1000).toStringAsFixed(1)}km away";
          }
          _bearingToTarget = bearing;
        });
      });
    } catch (e) {
      debugPrint("Location error: $e");
      if (mounted) {
        setState(() => _distanceText = "Location Error");
      }
    }
  }

  void _startSensors() {
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      if (!mounted) return;
      final pitch = math.atan2(event.z, event.y);
      setState(() => _devicePitch = pitch);
    });
  }

  void _startCompass() {
    _compassSubscription = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      
      setState(() {
        _heading = event.heading ?? 0;

        double diff = (_bearingToTarget - _heading).abs();
        if (diff > 180) diff = 360 - diff;

        if (diff < 5 && !_isOnTarget) {
          HapticFeedback.heavyImpact();
          _isOnTarget = true;

          if (!_hasSpokenGuidance && !_isMuted) {
            _flutterTts.speak(
              "You are facing ${_selectedDestination['name']}. Walk straight ahead.",
            );
            _hasSpokenGuidance = true;
            Future.delayed(
              const Duration(seconds: 10),
              () {
                if (mounted) {
                  _hasSpokenGuidance = false;
                }
              },
            );
          }
        } else if (diff >= 5) {
          _isOnTarget = false;
        }
      });
    });
  }

  List<Map<String, dynamic>> get _filteredDestinations {
    if (_selectedFilter == 'all') return _destinations;
    if (_selectedFilter == 'favorites') {
      return _destinations
          .where((d) => _favorites.contains(d['name']))
          .toList();
    }
    return _destinations.where((d) => d['type'] == _selectedFilter).toList();
  }

  void _showDestinationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildDestinationSheet(),
    );
  }

  Widget _buildDestinationSheet() {
    final isDark = _isNightMode || Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF1A1F3A), const Color(0xFF0A0E27)]
              : [Colors.white, const Color(0xFFF5F7FA)],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Icon(
                  Icons.explore_rounded,
                  color: isDark ? const Color(0xFF6C63FF) : const Color(0xFF4285F4),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Text(
                  "Select Destination",
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredDestinations.length,
              itemBuilder: (context, index) {
                final dest = _filteredDestinations[index];
                final isSelected = dest == _selectedDestination;
                final isFavorite = _favorites.contains(dest['name']);
                
                return _buildDestinationTile(dest, isSelected, isFavorite, isDark);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinationTile(
    Map<String, dynamic> dest,
    bool isSelected,
    bool isFavorite,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: isDark
                    ? [const Color(0xFF6C63FF), const Color(0xFF3F3D56)]
                    : [const Color(0xFF4285F4), const Color(0xFF34A853)],
              )
            : null,
        color: isSelected
            ? null
            : (isDark
                ? const Color(0xFF1A1F3A).withValues(alpha: 0.6)
                : Colors.white),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected
              ? Colors.transparent
              : (isDark
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.05)),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.2)
                : (isDark
                    ? const Color(0xFF6C63FF).withValues(alpha: 0.1)
                    : const Color(0xFF4285F4).withValues(alpha: 0.1)),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            dest['icon'] ?? Icons.location_on_rounded,
            color: isSelected
                ? Colors.white
                : (isDark ? const Color(0xFF6C63FF) : const Color(0xFF4285F4)),
            size: 24,
          ),
        ),
        title: Text(
          dest['name'],
          style: GoogleFonts.poppins(
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white : Colors.black87),
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          "${dest['type'].toString().toUpperCase()} • ${dest['floor']}",
          style: GoogleFonts.inter(
            color: isSelected
                ? Colors.white.withValues(alpha: 0.8)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6)),
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentPosition != null)
              Text(
                "${Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, dest['lat'], dest['lng']).toStringAsFixed(0)}m",
                style: GoogleFonts.inter(
                  color: isSelected ? Colors.white : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: isFavorite
                    ? Colors.yellowAccent
                    : (isSelected ? Colors.white : Colors.grey),
              ),
              onPressed: () => _toggleFavorite(dest['name']),
            ),
          ],
        ),
        onTap: () {
          setState(() {
            _selectedDestination = dest;
            _distanceText = "Recalculating...";
            _hasSpokenGuidance = false;
          });
          Navigator.pop(context);
          HapticFeedback.mediumImpact();
        },
      ),
    );
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _audioPlayer.setVolume(_isMuted ? 0 : 0.3);
    HapticFeedback.lightImpact();
  }

  void _toggleNightMode() {
    setState(() => _isNightMode = !_isNightMode);
    HapticFeedback.lightImpact();
  }

  void _dismissHelp() {
    setState(() => _showHelpOverlay = false);
    HapticFeedback.mediumImpact();
  }

  void _setFilter(String filter) {
    setState(() => _selectedFilter = filter);
    HapticFeedback.selectionClick();
  }

  Future<void> _toggleFlashlight() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() => _isFlashOn = !_isFlashOn);
      await _cameraController?.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      HapticFeedback.mediumImpact();
    } catch (e) {
      debugPrint("Flashlight error: $e");
    }
  }

  Future<void> _shareLocation() async {
    try {
      if (_currentPosition != null) {
        final String googleMapsUrl =
            "https://www.google.com/maps/search/?api=1&query=${_currentPosition!.latitude},${_currentPosition!.longitude}";
        
        await SharePlus.instance.share(
          ShareParams(
            text: "I'm exploring CITK Campus in AR! Find me here: $googleMapsUrl",
          ),
        );
      }
    } catch (e) {
      debugPrint("Share location error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to share location", style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _reportIssue() {
    showDialog(
      context: context,
      builder: (context) {
        final isDark = _isNightMode || Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1A1F3A), const Color(0xFF2D3561)]
                    : [Colors.white, const Color(0xFFF5F7FA)],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.flag_rounded, color: Colors.redAccent, size: 48),
                const SizedBox(height: 16),
                Text(
                  "Report Issue",
                  style: GoogleFonts.poppins(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Is the location for '${_selectedDestination['name']}' incorrect?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.black.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text("Cancel", style: GoogleFonts.inter()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          FirebaseFirestore.instance.collection('reports').add({
                            'type': 'ar_issue',
                            'destination': _selectedDestination['name'],
                            'timestamp': FieldValue.serverTimestamp(),
                            'description': 'User reported incorrect location',
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Report submitted. Thank you!",
                                  style: GoogleFonts.inter()),
                              backgroundColor: const Color(0xFF4CAF50),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text("Report",
                            style: GoogleFonts.inter(
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _takeScreenshot() async {
    try {
      HapticFeedback.heavyImpact();
      
      final boundary = _globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData != null) {
        final pngBytes = byteData.buffer.asUint8List();
        
        await SharePlus.instance.share(
          ShareParams(
            files: [
              XFile.fromData(
                pngBytes,
                mimeType: 'image/png',
                name: 'citk_ar_view_${DateTime.now().millisecondsSinceEpoch}.png',
              )
            ],
            text: 'Found this via CITK AR!',
          ),
        );
      }
    } catch (e) {
      debugPrint("Screenshot error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to take screenshot", style: GoogleFonts.inter()),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scanController.dispose();
    _cameraController?.setFlashMode(FlashMode.off);
    _cameraController?.dispose();
    _audioPlayer.dispose();
    _flutterTts.stop();
    _positionStream?.cancel();
    _compassSubscription?.cancel();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.view_in_ar_rounded,
                  color: Color(0xFF4285F4), size: 80)
                  .animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 2000.ms),
              const SizedBox(height: 24),
              Text(
                "Initializing AR...",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RepaintBoundary(
        key: _globalKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraLayer(),
            if (_isNightMode) _buildNightModeOverlay(),
            _buildScanEffect(),
            _buildFilterChips(),
            _buildDistanceSlider(),
            _buildMainUI(),
            _buildControlButtons(),
            _buildNavigationArrow(),
            if (_currentPosition != null) _buildARMarkers(),
            if (_showHelpOverlay) _buildHelpOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildCameraLayer() {
    if (_cameraController != null && _cameraController!.value.isInitialized) {
      return SizedBox.expand(
        child: FittedBox(
          fit: BoxFit.cover,
          child: SizedBox(
            width: _cameraController!.value.previewSize!.height,
            height: _cameraController!.value.previewSize!.width,
            child: CameraPreview(_cameraController!),
          ),
        ),
      );
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black87, Colors.transparent, Colors.black87],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.view_in_ar_rounded,
          size: 100,
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
    );
  }

  Widget _buildNightModeOverlay() {
    return IgnorePointer(
      child: Container(
        color: const Color(0xFF00FF00).withValues(alpha: 0.08),
      ),
    );
  }

  Widget _buildScanEffect() {
    return AnimatedBuilder(
      animation: _scanController,
      builder: (context, child) {
        return CustomPaint(
          painter: _ScanLinePainter(
            progress: _scanController.value,
            isNightMode: _isNightMode,
          ),
        );
      },
    );
  }

  Widget _buildFilterChips() {
    return Positioned(
      top: 50,
      left: 20,
      right: 20,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', 'all', Icons.apps_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('Favorites', 'favorites', Icons.star_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('Academic', 'academic', Icons.school_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('Hostels', 'hostel', Icons.hotel_rounded),
            const SizedBox(width: 8),
            _buildFilterChip('Food', 'food', Icons.restaurant_rounded),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, IconData icon) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => _setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: _isNightMode
                      ? [const Color(0xFF00FF00), const Color(0xFF00CC00)]
                      : [const Color(0xFF4285F4), const Color(0xFF34A853)],
                )
              : null,
          color: isSelected ? null : Colors.black.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistanceSlider() {
    return Positioned(
      bottom: 140,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Viewing Range",
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  "${_maxDistance.toInt()}m",
                  style: GoogleFonts.poppins(
                    color: _isNightMode
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF4285F4),
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderThemeData(
                activeTrackColor: _isNightMode
                    ? const Color(0xFF00FF00)
                    : const Color(0xFF4285F4),
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
                overlayColor: (_isNightMode
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF4285F4))
                    .withValues(alpha: 0.3),
              ),
              child: Slider(
                value: _maxDistance,
                min: 100,
                max: 2000,
                onChanged: (val) => setState(() => _maxDistance = val),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainUI() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_awesome_rounded,
              color: _isNightMode
                  ? const Color(0xFF00FF00)
                  : const Color(0xFF4285F4),
              size: 48,
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
            const SizedBox(height: 24),
            ShaderMask(
              shaderCallback: (bounds) => LinearGradient(
                colors: _isNightMode
                    ? [const Color(0xFF00FF00), const Color(0xFF00CC00)]
                    : [const Color(0xFF4285F4), const Color(0xFF34A853)],
              ).createShader(bounds),
              child: Text(
                "AR NAVIGATOR",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: _isNightMode
                      ? const Color(0xFF00FF00).withValues(alpha: 0.5)
                      : Colors.white.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.navigation_rounded,
                    color: _isNightMode
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF4285F4),
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _distanceText,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.5, end: 0),
            const SizedBox(height: 16),
            Text(
              "Point your camera to navigate",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            GestureDetector(
              onTap: _showDestinationPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isNightMode
                        ? [const Color(0xFF00FF00), const Color(0xFF00CC00)]
                        : [const Color(0xFF4285F4), const Color(0xFF34A853)],
                  ),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: (_isNightMode
                              ? const Color(0xFF00FF00)
                              : const Color(0xFF4285F4))
                          .withValues(alpha: 0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _selectedDestination['icon'] ?? Icons.location_on_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _selectedDestination['name'],
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_drop_down_rounded, color: Colors.white),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return Stack(
      children: [
        Positioned(
          top: 50,
          left: 20,
          child: _buildControlButton(
            Icons.arrow_back_rounded,
            () => Navigator.pop(context),
          ),
        ),
        Positioned(
          top: 50,
          right: 20,
          child: _buildControlButton(
            _isMuted ? Icons.volume_off_rounded : Icons.volume_up_rounded,
            _toggleMute,
          ),
        ),
        Positioned(
          top: 110,
          right: 20,
          child: _buildControlButton(
            _isNightMode ? Icons.wb_sunny_rounded : Icons.nightlight_round_rounded,
            _toggleNightMode,
          ),
        ),
        Positioned(
          top: 170,
          right: 20,
          child: _buildControlButton(
            _isFlashOn ? Icons.flashlight_on_rounded : Icons.flashlight_off_rounded,
            _toggleFlashlight,
            color: _isFlashOn ? Colors.yellowAccent : null,
          ),
        ),
        Positioned(
          top: 230,
          right: 20,
          child: _buildControlButton(Icons.share_location_rounded, _shareLocation),
        ),
        Positioned(
          top: 290,
          right: 20,
          child: _buildControlButton(Icons.flag_rounded, _reportIssue),
        ),
        Positioned(
          top: 350,
          right: 20,
          child: _buildControlButton(
            _favorites.contains(_selectedDestination['name'])
                ? Icons.star_rounded
                : Icons.star_border_rounded,
            () => _toggleFavorite(_selectedDestination['name']),
            color: _favorites.contains(_selectedDestination['name'])
                ? Colors.yellowAccent
                : null,
          ),
        ),
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: GestureDetector(
              onTap: _takeScreenshot,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _isNightMode ? const Color(0xFF00FF00) : Colors.white,
                    width: 4,
                  ),
                  color: Colors.black.withValues(alpha: 0.3),
                ),
                child: Center(
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isNightMode
                            ? [const Color(0xFF00FF00), const Color(0xFF00CC00)]
                            : [const Color(0xFF4285F4), const Color(0xFF34A853)],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 140,
          left: 20,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              shape: BoxShape.circle,
              border: Border.all(
                color: _isNightMode
                    ? const Color(0xFF00FF00)
                    : Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Transform.rotate(
              angle: (-_heading * (math.pi / 180)),
              child: Icon(
                Icons.navigation_rounded,
                color: _isNightMode
                    ? const Color(0xFF00FF00)
                    : const Color(0xFFFF5252),
                size: 32,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Icon(
          icon,
          color: color ?? (_isNightMode ? const Color(0xFF00FF00) : Colors.white),
          size: 24,
        ),
      ),
    );
  }

  Widget _buildNavigationArrow() {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.4,
      left: 0,
      right: 0,
      child: Center(
        child: Transform.rotate(
          angle: ((_bearingToTarget - _heading) * (math.pi / 180)),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_pulseController.value * 0.1),
                child: Icon(
                  Icons.arrow_upward_rounded,
                  color: _isNightMode
                      ? const Color(0xFF00FF00)
                      : const Color(0xFF4285F4),
                  size: 120,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 30)],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildARMarkers() {
    return StreamBuilder<Position>(
      stream: Geolocator.getPositionStream(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final pos = snapshot.data!;

        return Stack(
          children: _filteredDestinations.map((dest) {
            final bearing = Geolocator.bearingBetween(
              pos.latitude,
              pos.longitude,
              dest['lat'],
              dest['lng'],
            );

            double diff = (bearing - _heading);
            if (diff > 180) diff -= 360;
            if (diff < -180) diff += 360;

            final double distance = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              dest['lat'],
              dest['lng'],
            );

            if (diff.abs() < 40 && distance <= _maxDistance) {
              final alignX = (diff / 40.0).clamp(-1.0, 1.0);
              final alignY = (_devicePitch * -1.5).clamp(-0.8, 0.8);

              return _buildARMarker(dest, alignX, alignY, distance);
            }
            return const SizedBox.shrink();
          }).toList(),
        );
      },
    );
  }

  Widget _buildARMarker(
    Map<String, dynamic> dest,
    double alignX,
    double alignY,
    double distance,
  ) {
    final double scale = (1.0 - (distance / 1500)).clamp(0.5, 1.0);
    final bool isSelected = dest == _selectedDestination;

    Widget markerWidget = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: isSelected
            ? LinearGradient(
                colors: _isNightMode
                    ? [const Color(0xFF00FF00), const Color(0xFF00CC00)]
                    : [const Color(0xFF4285F4), const Color(0xFF34A853)],
              )
            : null,
        color: isSelected ? null : Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? Colors.white.withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (isSelected
                    ? (_isNightMode
                        ? const Color(0xFF00FF00)
                        : const Color(0xFF4285F4))
                    : Colors.black)
                .withValues(alpha: 0.4),
            blurRadius: isSelected ? 20 : 10,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            dest['icon'] ?? Icons.location_on_rounded,
            color: Colors.white,
            size: 22,
          ),
          const SizedBox(height: 6),
          Text(
            dest['name'],
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            "${distance.toStringAsFixed(0)}m",
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (isSelected) {
      markerWidget = markerWidget
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(end: 1.1, duration: 800.ms);
    }

    return Align(
      alignment: Alignment(alignX, alignY),
      child: Transform.scale(
        scale: scale,
        child: GestureDetector(
          onTap: () {
            setState(() {
              _selectedDestination = dest;
              _distanceText = "Recalculating...";
              _hasSpokenGuidance = false;
            });
            HapticFeedback.mediumImpact();
          },
          child: markerWidget,
        ),
      ),
    );
  }

  Widget _buildHelpOverlay() {
    return GestureDetector(
      onTap: _dismissHelp,
      child: Container(
        color: Colors.black.withValues(alpha: 0.9),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.touch_app_rounded,
                color: _isNightMode ? const Color(0xFF00FF00) : const Color(0xFF4285F4),
                size: 80,
              )
                  .animate(onPlay: (c) => c.repeat())
                  .scale(begin: const Offset(0.9, 0.9), end: const Offset(1.1, 1.1)),
              const SizedBox(height: 24),
              Text(
                "Welcome to AR Navigator!",
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  "• Tap AR markers to set destinations\n• Follow the arrow to navigate\n• Use filters to find specific locations\n• Adjust viewing range with the slider",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _dismissHelp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isNightMode
                      ? const Color(0xFF00FF00)
                      : const Color(0xFF4285F4),
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                child: Text(
                  "Got it!",
                  style: GoogleFonts.poppins(
                    color: _isNightMode ? Colors.black : Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Custom Painter for Scan Effect
class _ScanLinePainter extends CustomPainter {
  final double progress;
  final bool isNightMode;

  _ScanLinePainter({required this.progress, required this.isNightMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (isNightMode ? const Color(0xFF00FF00) : const Color(0xFF4285F4))
          .withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final y = size.height * progress;
    canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

    final gradient = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          (isNightMode ? const Color(0xFF00FF00) : const Color(0xFF4285F4))
              .withValues(alpha: 0.0),
          (isNightMode ? const Color(0xFF00FF00) : const Color(0xFF4285F4))
              .withValues(alpha: 0.3),
          (isNightMode ? const Color(0xFF00FF00) : const Color(0xFF4285F4))
              .withValues(alpha: 0.0)
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(0, y - 50, size.width, 100));

    canvas.drawRect(Rect.fromLTWH(0, y - 50, size.width, 100), gradient);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}