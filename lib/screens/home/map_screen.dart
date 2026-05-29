import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;
import '../../services/location_service.dart';
import '../../services/firestore_service.dart';
import '../../models/issue_model.dart';
import '../../theme.dart';
import '../../services/auth_service.dart';
import '../../services/local_image_service.dart';
import '../../widgets/issue_image.dart';
import '../../widgets/emoji_rain.dart';

class IssueClusterData {
  final LatLng latLng;
  final String emoji;
  final int count;
  final int totalUpvotes;
  final List<Issue> issues;
  IssueClusterData({required this.latLng, required this.emoji, required this.count, required this.totalUpvotes, required this.issues});
}

class ClusterRenderData {
  final Offset point;
  final String emoji;
  final int count;
  final int totalUpvotes;
  final List<Issue> issues;
  ClusterRenderData({required this.point, required this.emoji, required this.count, required this.totalUpvotes, required this.issues});
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final Completer<GoogleMapController> _controller = Completer();
  final GlobalKey _mapKey = GlobalKey(); 
  final GlobalKey<EmojiRainState> _rainKey = GlobalKey<EmojiRainState>();
  bool _showMoodOptions = false;
  String _currentMoodEmoji = '😊';
  StreamSubscription<String>? _moodSubscription;
  bool _isFirstMoodEvent = true;
  
  static Position? _cachedPosition;
  
  CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(37.7749, -122.4194),
    zoom: 18.0,
    tilt: 75.0,
  );

  Position? _currentPosition;
  bool _isLocating = true;
  Set<Marker> _markers = {};
  
  List<Issue> _rawIssues = [];
  double _currentZoom = 18.0;
  
  List<IssueClusterData> _currentClusters = [];
  List<ClusterRenderData> _renderPoints = [];
  
  bool _isDisposed = false;
  bool _isUpdating = false;
  DateTime _lastUpdate = DateTime.now();

  StreamSubscription? _issueSubscription;
  bool _isLoading = true;
  double _devicePixelRatio = 1.0;

  @override
  void initState() {
    super.initState();
    if (_cachedPosition != null) {
      _currentPosition = _cachedPosition;
      _initialPosition = CameraPosition(
        target: LatLng(_cachedPosition!.latitude, _cachedPosition!.longitude), 
        zoom: 18.0, 
        tilt: 75.0
      );
      _isLocating = false;
    } else {
      _isLocating = true;
    }
    _determinePosition();
    _issueSubscription = context.read<FirestoreService>().getLiveIssues().listen((issues) {
      if (!_isDisposed && mounted) {
        _rawIssues = issues;
        _buildMarkers();
        setState(() => _isLoading = false);
      }
    });

    _moodSubscription = context.read<FirestoreService>().getMajorityMoodStream().listen((emoji) {
      if (!_isDisposed && mounted) {
        setState(() => _currentMoodEmoji = emoji);
        
        // "Welcome Rain": Trigger rain based on majority sentiment
        if (_isFirstMoodEvent) {
          _isFirstMoodEvent = false;
          Future.delayed(const Duration(milliseconds: 1200), () {
            if (mounted && !_isDisposed) {
              _rainKey.currentState?.startRain(emoji);
            }
          });
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cache devicePixelRatio so we don't call MediaQuery inside async methods
    _devicePixelRatio = kIsWeb ? 1.0 : MediaQuery.of(context).devicePixelRatio;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _issueSubscription?.cancel();
    _moodSubscription?.cancel();
    _markers.clear();
    _currentClusters.clear();
    _renderPoints.clear();
    _isUpdating = false;
    super.dispose();
  }

  Future<void> _updateParticlePositions({bool forced = false}) async {
    if (_isDisposed || !mounted || !_controller.isCompleted || _isUpdating) return;
    
    final now = DateTime.now();
    if (!forced && now.difference(_lastUpdate).inMilliseconds < 150) return;

    _isUpdating = true;
    _lastUpdate = now;

    try {
      final controller = await _controller.future;
      if (_isDisposed || !mounted) {
        _isUpdating = false;
        return;
      }
      
      List<ClusterRenderData> pts = [];
      
      final double ratio = _devicePixelRatio;
      
      for (var c in _currentClusters) {
        if (_isDisposed || !mounted) break;
        final screenCoord = await controller.getScreenCoordinate(c.latLng);
        
        // Double check after async call
        if (_isDisposed || !mounted) break;
        
        pts.add(ClusterRenderData(
          point: Offset(screenCoord.x.toDouble() / ratio, screenCoord.y.toDouble() / ratio), 
          emoji: c.emoji, 
          count: c.count,
          totalUpvotes: c.totalUpvotes,
          issues: c.issues,
        ));
      }
      
      if (mounted && !_isDisposed) {
        setState(() {
          _renderPoints = pts;
        });
      }
    } catch (e) {
      debugPrint("Particle update suppressed to protect Web Engine.");
    } finally {
      if (!_isDisposed) {
         _isUpdating = false;
      }
    }
  }

  // Removed _spreadOverlappingMarkers as we now aggregate into single points instead of fanning out.

  Future<void> _determinePosition() async {
    try {
      Position pos = await LocationService.getCurrentLocation();
      if (_isDisposed || !mounted) return;
      
      _cachedPosition = pos;
      
      setState(() {
        _currentPosition = pos;
        _initialPosition = CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 18.0, tilt: 75.0);
        _isLocating = false;
      });
      final GoogleMapController controller = await _controller.future;
      controller.animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
    } catch (e) {
      debugPrint("Error getting location: $e");
      if (mounted) setState(() => _isLocating = false);
    }
  }

  static const String _cleanMapStyle = '''[
    {"featureType": "poi","stylers": [{"visibility": "off"}]},
    {"featureType": "transit","stylers": [{"visibility": "off"}]},
    {"featureType": "road","elementType": "labels.icon","stylers": [{"visibility": "off"}]}
  ]''';

  void _onMapCreated(GoogleMapController controller) {
    if (_isDisposed) return;
    _controller.complete(controller);
    controller.setMapStyle(_cleanMapStyle);
  }

  void _buildMarkers() async {
    if (_isDisposed || !mounted) return;
    
    // Zoom Visibility: Hide markers if fully zoomed out
    if (_currentZoom < 10.0) {
      if (mounted && !_isDisposed) {
        setState(() {
          _markers = <Marker>{};
          _currentClusters = [];
          _renderPoints = [];
        });
      }
      return;
    }

    Set<Marker> newMarkers = <Marker>{};
    List<Issue> openIssues = _rawIssues.where((i) => i.status != 'resolved').toList();

    List<Issue> unclustered = List.from(openIssues);
    List<IssueClusterData> clusters = [];

    // Dynamic distance threshold: Closer zoom = smaller cluster radius
    // Base 150m at zoom 18. Doubles every zoom level out.
    double clusterRadiusMeters = 150.0 * math.pow(2, math.max(0.0, 18.0 - _currentZoom));

    // Location-based Clustering! (Groups different emojis if they are at the same spot)
    while (unclustered.isNotEmpty) {
      Issue current = unclustered.removeAt(0);
      List<Issue> group = [current];
      List<Issue> toRemove = [];
      for (var other in unclustered) {
        if (Geolocator.distanceBetween(current.latitude, current.longitude, other.latitude, other.longitude) <= clusterRadiusMeters) {
          group.add(other);
          toRemove.add(other);
        }
      }
      unclustered.removeWhere((i) => toRemove.contains(i));
      
      double avgLat = group.map((i) => i.latitude).reduce((a, b) => a + b) / group.length;
      double avgLng = group.map((i) => i.longitude).reduce((a, b) => a + b) / group.length;
      
      int groupUpvotes = group.fold(0, (sum, i) => sum + i.upvotes);
      
      // Smart emoji selection: use issue emoji if all match, else use cluster icon
      Set<String> uniqueEmojis = group.map((i) => i.emoji).toSet();
      String clusterEmoji = uniqueEmojis.length == 1 ? uniqueEmojis.first : '💠';

      clusters.add(IssueClusterData(
        latLng: LatLng(avgLat, avgLng),
        emoji: clusterEmoji,
        count: group.length,
        totalUpvotes: groupUpvotes,
        issues: group,
      ));
    }

    // Creating Invisible Markers for Tap Handling
    for (var c in clusters) {
      if (_isDisposed || !mounted) return;
      newMarkers.add(Marker(
        markerId: MarkerId(c.issues.first.id),
        position: c.latLng,
        alpha: 0.0, // Totally invisible, MapOverlayPainter handles visual
        onTap: () => _showIssueDetailsBottomSheet(c.issues),
      ));
    }

    if (mounted && !_isDisposed) {
      setState(() {
        _markers = newMarkers;
        _currentClusters = clusters;
      });
      _updateParticlePositions(forced: true);
    }
  }

  void _showIssueDetailsBottomSheet(List<Issue> issues) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        Issue? selectedIssue;
        // If there's only one issue, default to showing its details
        if (issues.length == 1) selectedIssue = issues.first;

        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: AppTheme.softShadow,
              ),
              child: selectedIssue != null 
                ? _buildSingleIssueDetail(selectedIssue!, issues.length > 1 ? () => setSheetState(() => selectedIssue = null) : null)
                : _buildMultiIssueList(issues, (issue) => setSheetState(() => selectedIssue = issue)),
            ).animate().slideY(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
          }
        );
      },
    );
  }

  Widget _buildMultiIssueList(List<Issue> issues, Function(Issue) onSelect) {
    // Group issues by emoji + title to collapse duplicates in the UI
    final Map<String, List<Issue>> grouped = {};
    for (var issue in issues) {
      final key = '${issue.emoji}_${issue.title}';
      grouped.putIfAbsent(key, () => []).add(issue);
    }
    final sortedKeys = grouped.keys.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 32, right: 32, top: 32, bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CLUSTER DETAILS', style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5)),
                  const SizedBox(height: 4),
                  Text('${issues.length} Issues at this Location', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                ],
              ),
              const Icon(Icons.layers_outlined, color: AppTheme.primaryBlue),
            ],
          ),
        ),
        const Divider(),
        Flexible(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: sortedKeys.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final group = grouped[sortedKeys[index]]!;
              final issue = group.first;
              final count = group.length;

              return ListTile(
                onTap: () => onSelect(issue),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                tileColor: AppTheme.backgroundLight.withOpacity(0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                leading: Text(issue.emoji, style: const TextStyle(fontSize: 28)),
                title: Row(
                  children: [
                    Expanded(child: Text(issue.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                    if (count > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: AppTheme.primaryBlue, borderRadius: BorderRadius.circular(12)),
                        child: Text('x$count', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
                subtitle: Text(issue.department, style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.w600, fontSize: 11)),
                trailing: const Icon(Icons.chevron_right, size: 20, color: AppTheme.textLight),
              );
            },
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildSingleIssueDetail(Issue issue, VoidCallback? onBack) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (onBack != null) 
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, size: 20),
                      onPressed: onBack,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  if (onBack != null) const SizedBox(width: 16),
                  Text(issue.emoji, style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(issue.title, style: Theme.of(context).textTheme.titleLarge),
                        Text(issue.department, style: TextStyle(color: AppTheme.primaryBlue, fontWeight: FontWeight.bold, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Description', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textDark.withOpacity(0.5), fontSize: 12)),
              const SizedBox(height: 4),
              Text(issue.description, style: Theme.of(context).textTheme.bodyLarge),
              if (issue.imageUrl.isNotEmpty) ...[
                const SizedBox(height: 24),
                ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: IssueImage(
                    imageUrl: issue.imageUrl,
                    height: 200,
                    width: double.infinity,
                  ),
                ),
              ],
              if (issue.aiSummary != null && issue.aiSummary!.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.primaryBlue.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_awesome, size: 14, color: AppTheme.primaryBlue),
                          const SizedBox(width: 8),
                          Text('AI SUMMARY', style: GoogleFonts.inter(color: AppTheme.primaryBlue, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        issue.aiSummary!,
                        style: const TextStyle(color: AppTheme.textDark, fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(60)),
                onPressed: () => Navigator.pop(context), 
                child: const Text('DISMISS')
              )
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            key: _mapKey, 
            initialCameraPosition: _initialPosition,
            onMapCreated: _onMapCreated,
            markers: _markers, // These are invisible tap zones
            // Removed redundant geofencing circles
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            buildingsEnabled: true,
            tiltGesturesEnabled: false,
            onCameraMove: (pos) {
              _currentZoom = pos.zoom;
              _updateParticlePositions();
            },
            onCameraIdle: () async {
              if (_isDisposed) return;
              final controller = await _controller.future;
              final zoom = await controller.getZoomLevel();
              
              if ((_currentZoom - zoom).abs() > 0.5) {
                _currentZoom = zoom;
                _buildMarkers(); 
              } else {
                _updateParticlePositions(forced: true);
              }
            },
          ),
          
          if (_isLoading && !_isLocating)
            const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),

          if (_isLocating)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, AppTheme.primaryBlue.withOpacity(0.1)],
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/logo.png', height: 180)
                        .animate().scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn(),
                    const SizedBox(height: 32),
                    Text('AuraCity', 
                      style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.textDark)
                    ).animate().shimmer(duration: 1500.ms, color: AppTheme.accentCyan),
                    const SizedBox(height: 8),
                    const Text('Initializing Urban Intelligence...', style: TextStyle(color: AppTheme.textLight, fontWeight: FontWeight.bold, letterSpacing: 1.2))
                        .animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),
            ),

          // High-performance overlay drawing the raw emojis directly onto the screen without backgrounds
          RepaintBoundary(
            child: IgnorePointer(
              child: CustomPaint(
                size: MediaQuery.of(context).size,
                painter: MapOverlayPainter(renderPoints: List.from(_renderPoints), zoomLevel: _currentZoom),
              ),
            ),
          ),

          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset('assets/images/logo.png', height: 28),
                    const SizedBox(width: 8),
                    Text('AuraCity', style: GoogleFonts.outfit(color: AppTheme.textDark, fontWeight: FontWeight.w900, fontSize: 18)),
                  ],
                ),
              ).animate().slideY(begin: -1, end: 0, duration: 600.ms, curve: Curves.easeOutCubic),
            ),
          ),

          // Action Column (AuraBot + Report)
          Positioned(
            right: 20,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AuraBot Floating Trigger
                GestureDetector(
                  onTap: () => context.push('/chat'),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.primaryBlue, AppTheme.accentCyan],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryBlue.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 28),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scale(begin: const Offset(1,1), end: const Offset(1.1, 1.1), duration: 1500.ms, curve: Curves.easeInOut)
                 .shimmer(delay: 2000.ms, duration: 1000.ms),
                
                if (!(context.watch<AuthService>().isAdmin || context.watch<AuthService>().isResolver)) ...[
                  const SizedBox(height: 16),
                  FloatingActionButton(
                    onPressed: () {
                      if (_currentPosition != null) {
                        context.push('/report', extra: {'lat': _currentPosition!.latitude, 'lng': _currentPosition!.longitude});
                      }
                    },
                    backgroundColor: AppTheme.primaryBlue,
                    child: const Icon(Icons.campaign_rounded),
                  ).animate().scale(begin: const Offset(0, 0), end: const Offset(1, 1), delay: 200.ms, curve: Curves.easeOutBack),
                ],
              ],
            ),
          ),

          // Emoji Rain Layer
          EmojiRain(key: _rainKey),

          // Mood Picker (Bottom Left)
          Positioned(
            left: 20,
            bottom: 110,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showMoodOptions) ...[
                  Text('CITY MAJORITY', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: AppTheme.primaryBlue, letterSpacing: 1)),
                  const SizedBox(height: 8),
                  _buildMoodButton('😊', Colors.green, 'happy'),
                  const SizedBox(height: 12),
                  _buildMoodButton('😐', Colors.amber, 'moderate'),
                  const SizedBox(height: 12),
                  _buildMoodButton('😠', Colors.red, 'angry'),
                  const SizedBox(height: 12),
                ],
                GestureDetector(
                  onTap: () => setState(() => _showMoodOptions = !_showMoodOptions),
                  child: Container(
                    width: 56, height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: Center(
                      child: _showMoodOptions 
                        ? const Icon(Icons.close_rounded, color: AppTheme.primaryBlue)
                        : Text(_currentMoodEmoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodButton(String emoji, Color color, String mood) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showMoodOptions = false;
          _currentMoodEmoji = emoji;
        });
        
        // Record individual vote for majority calculation (2hr window)
        final userId = context.read<AuthService>().currentUserId ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';
        context.read<FirestoreService>().updateUserMoodVote(userId, emoji);
        
        _rainKey.currentState?.startRain(emoji);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          behavior: SnackBarBehavior.floating,
          width: 200,
          backgroundColor: color,
          content: Text('City mood set to $mood! $emoji', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
        ));
      },
      child: Container(
        width: 48, height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
        ),
        alignment: Alignment.center,
        child: Text(emoji, style: const TextStyle(fontSize: 24)),
      ),
    ).animate().scale(curve: Curves.easeOutBack).fadeIn();
  }
}

class MapOverlayPainter extends CustomPainter {
  final List<ClusterRenderData> renderPoints;
  final double zoomLevel;
  MapOverlayPainter({required this.renderPoints, required this.zoomLevel});

  @override
  void paint(Canvas canvas, Size size) {
    final TextPainter tp = TextPainter(textDirection: TextDirection.ltr);

    final Paint badgeBgPaint = Paint()..color = AppTheme.priorityRed;
    final TextPainter badgeTp = TextPainter(textDirection: TextDirection.ltr);

    for (var p in renderPoints) {
      // Draw Urgency Heat Zones for high-density clusters
      if (p.count >= 3) {
        Color zoneColor = p.count >= 7 ? Colors.red.withOpacity(0.3) : Colors.amber.withOpacity(0.3);
        Color strokeColor = p.count >= 7 ? Colors.red : Colors.amber;
        
        double zoneRadius = 50.0 + (p.count * 3.0); // Radius grows with count
        
        final Paint zonePaint = Paint()
          ..color = zoneColor
          ..style = PaintingStyle.fill;
          
        final Paint zoneStroke = Paint()
          ..color = strokeColor.withOpacity(0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
          
        canvas.drawCircle(p.point, zoneRadius, zonePaint);
        canvas.drawCircle(p.point, zoneRadius, zoneStroke);
      }

      // Zoom-based scale: zoom 18 is 1.0x reference, each zoom level ≈ 15% change
      // Clamp the multiplier so emojis don't vanish or become absurdly large
      double zoomMultiplier = math.pow(1.15, zoomLevel - 18.0).toDouble().clamp(0.4, 1.8);
      
      // Dynamic emoji size: starts small, grows with complaints + upvotes + zoom
      double baseSize = 24.0 + ((p.count - 1) * 4.0) + (p.totalUpvotes / 2.0);
      baseSize = baseSize.clamp(24.0, 72.0);
      double emojiSize = baseSize * zoomMultiplier;
      
      tp.text = TextSpan(text: p.emoji, style: TextStyle(fontSize: emojiSize, shadows: [
        Shadow(color: Colors.black45, blurRadius: emojiSize * 0.2, offset: Offset(0, emojiSize * 0.08))
      ]));
      tp.layout();
      tp.paint(canvas, p.point - Offset(tp.width / 2, tp.height / 2));

      // Draw Cluster Badge (if multiple identical issues in area)
      if (p.count > 1) {
        String badgeText = '${p.count}x';
        badgeTp.text = TextSpan(text: badgeText, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold));
        badgeTp.layout();
        
        Offset badgeCenter = p.point + Offset(tp.width / 2 - 8, -tp.height / 2 + 8);
        double radius = badgeTp.width / 2 + 6;
        
        canvas.drawCircle(badgeCenter, radius, badgeBgPaint);
        badgeTp.paint(canvas, badgeCenter - Offset(badgeTp.width / 2, badgeTp.height / 2));
      }
    }
  }
  @override
  bool shouldRepaint(MapOverlayPainter oldDelegate) {
    if (zoomLevel != oldDelegate.zoomLevel) return true;
    if (renderPoints.length != oldDelegate.renderPoints.length) return true;
    for (int i = 0; i < renderPoints.length; i++) {
        if (renderPoints[i].point != oldDelegate.renderPoints[i].point || 
            renderPoints[i].count != oldDelegate.renderPoints[i].count ||
            renderPoints[i].totalUpvotes != oldDelegate.renderPoints[i].totalUpvotes) return true;
    }
    return false;
  }
}
