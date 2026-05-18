import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'package:zoopernova_zoo_system/features/map/widgets/animal_pin_card.dart';
import 'package:zoopernova_zoo_system/features/map/widgets/event_pin_card.dart';
import 'package:zoopernova_zoo_system/features/map/widgets/map_search_bar.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animationMatrix;
  bool _isFirstLoad = true;
  Size _screenSize = Size.zero;

  String? _mapUrl;
  List<QueryDocumentSnapshot> _animalDocs = [];
  List<QueryDocumentSnapshot> _eventDocs = [];
  Map<String, String> _zoneMap = {};
  Map<String, dynamic>? _selectedAnimal;
  Map<String, dynamic>? _selectedEvent;

  late final StreamSubscription<QuerySnapshot> _mapSub;
  late final StreamSubscription<QuerySnapshot> _animalSub;
  late final StreamSubscription<QuerySnapshot> _eventSub;

  @override
  void initState() {
    super.initState();

    _animationController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1500),
        )..addListener(() {
          if (_animationMatrix != null) {
            _transformationController.value = _animationMatrix!.value;
          }
        });

    _mapSub = FirebaseFirestore.instance.collection('map').snapshots().listen((
      snap,
    ) {
      if (!mounted) return;
      if (snap.docs.isEmpty) return;
      final data = snap.docs.first.data();
      final url = data['mapPicture'] as String?;
      if (url != null && url.isNotEmpty) {
        final isFirstUrl = _mapUrl == null;
        setState(() => _mapUrl = url);
        if (isFirstUrl && _isFirstLoad == false) {
          if (_selectedAnimal == null && _selectedEvent == null) {
            _startZoomOutAnimation();
          } else {
            final lx = (_selectedAnimal ?? _selectedEvent)?['locationX'];
            final ly = (_selectedAnimal ?? _selectedEvent)?['locationY'];
            if (lx != null && ly != null) {
              _zoomToLocation((lx as num).toDouble(), (ly as num).toDouble());
            }
          }
        }
      }
    }, onError: (e) => debugPrint('map stream: $e'));

    _animalSub = FirebaseFirestore.instance
        .collection('animal')
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() => _animalDocs = snap.docs);
        }, onError: (e) => debugPrint('animal stream: $e'));

    _eventSub = FirebaseFirestore.instance
        .collection('event')
        .snapshots()
        .listen((snap) {
          if (!mounted) return;
          setState(() => _eventDocs = snap.docs);
        }, onError: (e) => debugPrint('event stream: $e'));

    _loadZones();
  }

  Future<void> _loadZones() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('zone').get();
      if (!mounted) return;
      setState(() {
        _zoneMap = {
          for (final doc in snap.docs)
            doc.reference.path: (doc.data()['zoneName'] ?? '') as String,
        };
      });
    } catch (e) {
      debugPrint('zone load: $e');
    }
  }

  String _resolveZoneName(dynamic zoneRef) {
    if (zoneRef == null) return '';
    final path = zoneRef is DocumentReference
        ? zoneRef.path
        : zoneRef.toString();
    return _zoneMap[path] ?? '';
  }

  List<Map<String, dynamic>> get _searchItems {
    final animals = _animalDocs
        .where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['location_x'] != null && d['location_y'] != null;
        })
        .map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': (d['animalName'] ?? '') as String,
            'pictureUrl': d['animalPicture'] as String?,
            'locationX': (d['location_x'] as num).toDouble(),
            'locationY': (d['location_y'] as num).toDouble(),
            'type': 'animal',
            'data': {
              'id': doc.id,
              'animalName': d['animalName'] ?? '',
              'animalDetail': d['animalDetail'] ?? '',
              'animalPicture': d['animalPicture'] ?? '',
              'zoneId': d['zoneId'],
            },
          };
        })
        .toList();

    final events = _eventDocs
        .where((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return d['location_x'] != null && d['location_y'] != null;
        })
        .map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          return {
            'id': doc.id,
            'name': (d['eventName'] ?? '') as String,
            'pictureUrl': d['eventPicture'] as String?,
            'locationX': (d['location_x'] as num).toDouble(),
            'locationY': (d['location_y'] as num).toDouble(),
            'type': 'event',
            'data': {
              'id': doc.id,
              'eventName': d['eventName'] ?? '',
              'eventDetail': d['eventDetail'] ?? '',
              'eventPicture': d['eventPicture'] ?? '',
            },
          };
        })
        .toList();

    return [...animals, ...events];
  }

  Future<void> _startZoomOutAnimation() async {
    Size imageSize = Size.zero;
    try {
      final completer = Completer<Size>();
      NetworkImage(_mapUrl!)
          .resolve(ImageConfiguration.empty)
          .addListener(
            ImageStreamListener(
              (info, _) => completer.complete(
                Size(info.image.width.toDouble(), info.image.height.toDouble()),
              ),
              onError: (_, __) => completer.complete(Size.zero),
            ),
          );
      imageSize = await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () => Size.zero,
      );
    } catch (_) {}

    if (!mounted) return;

    Matrix4 targetMatrix;
    if (imageSize.width > 0 && imageSize.height > 0) {
      final s =
          min(
            _screenSize.width / imageSize.width,
            _screenSize.height / imageSize.height,
          ) *
          0.85;
      final tx = _screenSize.width / 2 - s * imageSize.width / 2;
      final ty = _screenSize.height / 2 - s * imageSize.height / 2;
      targetMatrix = Matrix4.identity()
        ..translate(tx, ty)
        ..scale(s);
    } else {
      targetMatrix = Matrix4.identity()
        ..translate(_screenSize.width * 0.05, _screenSize.height * 0.05)
        ..scale(
          min(_screenSize.width, _screenSize.height) /
              max(_screenSize.width, _screenSize.height) *
              0.9,
        );
    }

    final initialMatrix = Matrix4.identity()..scale(2.0);
    _animationController.duration = const Duration(milliseconds: 1500);
    _animationMatrix = Matrix4Tween(begin: initialMatrix, end: targetMatrix)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutQuart,
          ),
        );
    _animationController.forward(from: 0);
  }

  void _zoomToLocation(double locationX, double locationY) {
    const targetScale = 2.5;
    const cardOffset = 150.0;
    final tx = _screenSize.width / 2 - targetScale * locationX;
    final ty = (_screenSize.height / 2 - cardOffset) - targetScale * locationY;

    final targetMatrix = Matrix4.identity()
      ..translate(tx, ty)
      ..scale(targetScale);

    _animationController.duration = const Duration(milliseconds: 800);
    _animationMatrix =
        Matrix4Tween(
          begin: _transformationController.value,
          end: targetMatrix,
        ).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeInOutCubic,
          ),
        );
    _animationController.forward(from: 0);
  }

  void _onSearchSelected(Map<String, dynamic> item) {
    final locationX = item['locationX'] as double?;
    final locationY = item['locationY'] as double?;
    if (locationX == null || locationY == null) return;

    _zoomToLocation(locationX, locationY);

    final data = Map<String, dynamic>.from(
      item['data'] as Map<String, dynamic>,
    );
    if (item['type'] == 'animal') {
      data['zoneName'] = _resolveZoneName(data['zoneId']);
      setState(() {
        _selectedEvent = null;
        _selectedAnimal = data;
      });
    } else {
      setState(() {
        _selectedAnimal = null;
        _selectedEvent = data;
      });
    }
  }

  void _processScannedQRCode(String scannedId) {
    try {
      final doc = _animalDocs.firstWhere((d) => d.id == scannedId);
      final data = doc.data() as Map<String, dynamic>;

      final lx = data['location_x'];
      final ly = data['location_y'];
      if (lx != null && ly != null) {
        _zoomToLocation((lx as num).toDouble(), (ly as num).toDouble());
      }

      setState(() {
        _selectedEvent = null;
        _selectedAnimal = {
          'id': doc.id,
          'animalName': data['animalName'] ?? '',
          'animalDetail': data['animalDetail'] ?? '',
          'animalPicture': data['animalPicture'] ?? '',
          'zoneName': _resolveZoneName(data['zoneId']),
        };
      });
      return;
    } catch (_) {}

    try {
      final doc = _eventDocs.firstWhere((d) => d.id == scannedId);
      final data = doc.data() as Map<String, dynamic>;

      final lx = data['location_x'];
      final ly = data['location_y'];
      if (lx != null && ly != null) {
        _zoomToLocation((lx as num).toDouble(), (ly as num).toDouble());
      }

      setState(() {
        _selectedAnimal = null;
        _selectedEvent = {
          'id': doc.id,
          'eventName': data['eventName'] ?? '',
          'eventDetail': data['eventDetail'] ?? '',
          'eventPicture': data['eventPicture'] ?? '',
        };
      });
      return;
    } catch (_) {}

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invalid QR Code')));
  }

  @override
  void dispose() {
    _mapSub.cancel();
    _animalSub.cancel();
    _eventSub.cancel();
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildPin({
    required double x,
    required double y,
    String? imageUrl,
    Color borderColor = Colors.white,
    bool isHighlighted = false,
    VoidCallback? onTap,
  }) {
    return Positioned(
      left: x,
      top: y,
      child: FractionalTranslation(
        translation: const Offset(-0.5, -0.5),
        child: AnimatedBuilder(
          animation: _transformationController,
          builder: (context, _) {
            final scale = _transformationController.value.getMaxScaleOnAxis();
            final pinRadius = (25.0 / sqrt(scale)).clamp(6.0, 50.0);

            return GestureDetector(
              onTap: onTap,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isHighlighted ? 4 : 3),
                    decoration: BoxDecoration(
                      color: isHighlighted ? Colors.redAccent : borderColor,
                      shape: BoxShape.circle,
                      boxShadow: isHighlighted
                          ? [
                              BoxShadow(
                                color: Colors.redAccent.withValues(alpha: 0.6),
                                blurRadius: 15,
                                spreadRadius: 5,
                              ),
                            ]
                          : const [
                              BoxShadow(
                                color: Colors.black26,
                                blurRadius: 5,
                                spreadRadius: 1,
                              ),
                            ],
                    ),
                    child: CircleAvatar(
                      radius: pinRadius,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: NetworkImage(
                        imageUrl ??
                            'https://cdn-icons-png.flaticon.com/512/1998/1998614.png',
                      ),
                    ),
                  ),
                  if (isHighlighted)
                    Positioned(
                      top: -40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.redAccent,
                        size: 40,
                        shadows: [
                          Shadow(color: Colors.black45, blurRadius: 10),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _screenSize = MediaQuery.of(context).size;

    if (_isFirstLoad) {
      _isFirstLoad = false;
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      final focusAnimal = args?['focusAnimal'] as Map<String, dynamic>?;
      final focusEvent = args?['focusEvent'] as Map<String, dynamic>?;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (focusAnimal != null) {
          final lx = (focusAnimal['locationX'] as num).toDouble();
          final ly = (focusAnimal['locationY'] as num).toDouble();
          _zoomToLocation(lx, ly);
          if (mounted) setState(() => _selectedAnimal = focusAnimal);
        } else if (focusEvent != null) {
          final lx = (focusEvent['locationX'] as num).toDouble();
          final ly = (focusEvent['locationY'] as num).toDouble();
          _zoomToLocation(lx, ly);
          if (mounted) setState(() => _selectedEvent = focusEvent);
        } else if (_mapUrl != null) {
          _startZoomOutAnimation();
        }
      });
    }

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      bottomNavigationBar: const ZooBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          SafeArea(
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.1,
              maxScale: 5.0,
              constrained: false,
              boundaryMargin: const EdgeInsets.all(2000),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTapDown: (_) {
                      if (_selectedAnimal != null || _selectedEvent != null) {
                        setState(() {
                          _selectedAnimal = null;
                          _selectedEvent = null;
                        });
                      }
                    },
                    child: _mapUrl != null
                        ? Image.network(_mapUrl!, fit: BoxFit.cover)
                        : const Center(child: CircularProgressIndicator()),
                  ),

                  ..._animalDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['location_x'] == null ||
                        data['location_y'] == null) {
                      return const SizedBox.shrink();
                    }

                    bool isHighlighted =
                        _selectedAnimal != null &&
                        _selectedAnimal!['id'] == doc.id;

                    return _buildPin(
                      x: (data['location_x'] as num).toDouble(),
                      y: (data['location_y'] as num).toDouble(),
                      imageUrl: data['animalPicture'],
                      borderColor: Colors.white,
                      isHighlighted: isHighlighted,
                      onTap: () {
                        setState(() {
                          _selectedEvent = null;
                          _selectedAnimal = {
                            'id': doc.id,
                            'animalName': data['animalName'] ?? '',
                            'animalDetail': data['animalDetail'] ?? '',
                            'animalPicture': data['animalPicture'] ?? '',
                            'zoneName': _resolveZoneName(data['zoneId']),
                          };
                        });
                      },
                    );
                  }),

                  ..._eventDocs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    if (data['location_x'] == null ||
                        data['location_y'] == null) {
                      return const SizedBox.shrink();
                    }

                    bool isHighlighted =
                        _selectedEvent != null &&
                        _selectedEvent!['id'] == doc.id;

                    return _buildPin(
                      x: (data['location_x'] as num).toDouble(),
                      y: (data['location_y'] as num).toDouble(),
                      imageUrl: data['eventPicture'],
                      borderColor: Colors.orangeAccent,
                      isHighlighted: isHighlighted,
                      onTap: () {
                        setState(() {
                          _selectedAnimal = null;
                          _selectedEvent = {
                            'id': doc.id,
                            'eventName': data['eventName'] ?? '',
                            'eventDetail': data['eventDetail'] ?? '',
                            'eventPicture': data['eventPicture'] ?? '',
                          };
                        });
                      },
                    );
                  }),
                ],
              ),
            ),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: MapSearchBar(
                        items: _searchItems,
                        onSelected: _onSearchSelected,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final scannedId = await Navigator.pushNamed(
                          context,
                          AppRoute.qrScan,
                        );
                        if (scannedId != null && scannedId is String) {
                          _processScannedQRCode(scannedId);
                        }
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 12,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            'lib/assets/images/ZoopernovaQRcodeScanner.svg',
                            width: 26,
                            height: 26,
                            colorFilter: const ColorFilter.mode(
                              Colors.black87,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          if (_selectedAnimal != null)
            Positioned(
              bottom: MediaQuery.of(context).viewPadding.bottom + 104,
              left: 0,
              right: 0,
              child: AnimalPinCard(
                animal: _selectedAnimal!,
                onClose: () => setState(() => _selectedAnimal = null),
              ),
            ),

          if (_selectedEvent != null)
            Positioned(
              bottom: MediaQuery.of(context).viewPadding.bottom + 104,
              left: 0,
              right: 0,
              child: EventPinCard(
                event: _selectedEvent!,
                onClose: () => setState(() => _selectedEvent = null),
              ),
            ),
        ],
      ),
    );
  }
}
