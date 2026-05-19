import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';
import 'package:zoopernova_zoo_system/features/animals_info/domain/entities/animal_with_zone_entity.dart';
import 'package:zoopernova_zoo_system/features/events_show/domain/entities/event_entity.dart';
import '../providers/map_providers.dart';
import '../widgets/animal_pin_card.dart';
import '../widgets/event_pin_card.dart';
import '../widgets/map_search_bar.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with TickerProviderStateMixin {
  final TransformationController _transformationController =
      TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animationMatrix;
  bool _isFirstLoad = true;
  Size _screenSize = Size.zero;

  Map<String, dynamic>? _selectedAnimal;
  Map<String, dynamic>? _selectedEvent;

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
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _buildSearchItems(
    List<AnimalWithZoneEntity> animals,
    List<EventEntity> events,
  ) {
    final animalItems = animals
        .where((a) => a.locationX != null && a.locationY != null)
        .map(
          (a) => <String, dynamic>{
            'id': a.id,
            'name': a.animalName,
            'pictureUrl': a.animalPicture,
            'locationX': a.locationX!.toDouble(),
            'locationY': a.locationY!.toDouble(),
            'type': 'animal',
            'data': <String, dynamic>{
              'id': a.id,
              'animalName': a.animalName,
              'animalDetail': a.animalDetail,
              'animalPicture': a.animalPicture,
              'zoneName': a.zoneName,
            },
          },
        )
        .toList();

    final eventItems = events
        .where((e) => e.locationX != null && e.locationY != null)
        .map(
          (e) => <String, dynamic>{
            'id': e.id,
            'name': e.eventName,
            'pictureUrl': e.eventPicture,
            'locationX': e.locationX!,
            'locationY': e.locationY!,
            'type': 'event',
            'data': <String, dynamic>{
              'id': e.id,
              'eventName': e.eventName,
              'eventDetail': e.eventDetail,
              'eventPicture': e.eventPicture,
            },
          },
        )
        .toList();

    return [...animalItems, ...eventItems];
  }

  Future<void> _startZoomOutAnimation(String mapUrl) async {
    Size imageSize = Size.zero;
    try {
      final completer = Completer<Size>();
      NetworkImage(mapUrl)
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
    final animals =
        ref.read(mapAnimalsProvider).valueOrNull ?? <AnimalWithZoneEntity>[];
    final events = ref.read(mapEventsProvider).valueOrNull ?? <EventEntity>[];

    try {
      final animal = animals.firstWhere((a) => a.id == scannedId);
      if (animal.locationX != null && animal.locationY != null) {
        _zoomToLocation(
          animal.locationX!.toDouble(),
          animal.locationY!.toDouble(),
        );
      }
      setState(() {
        _selectedEvent = null;
        _selectedAnimal = {
          'id': animal.id,
          'animalName': animal.animalName,
          'animalDetail': animal.animalDetail,
          'animalPicture': animal.animalPicture,
          'zoneName': animal.zoneName,
        };
      });
      return;
    } catch (_) {}

    try {
      final event = events.firstWhere((e) => e.id == scannedId);
      if (event.locationX != null && event.locationY != null) {
        _zoomToLocation(event.locationX!, event.locationY!);
      }
      setState(() {
        _selectedAnimal = null;
        _selectedEvent = {
          'id': event.id,
          'eventName': event.eventName,
          'eventDetail': event.eventDetail,
          'eventPicture': event.eventPicture,
        };
      });
      return;
    } catch (_) {}

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Invalid QR Code')));
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
                    const Positioned(
                      top: -40,
                      child: Icon(
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

    // Trigger zoom-out animation when map URL first arrives
    ref.listen<AsyncValue<dynamic>>(mapPictureProvider, (prev, next) {
      final prevUrl = (prev?.valueOrNull as dynamic)?.mapPicture as String?;
      final nextEntity = next.valueOrNull;
      final nextUrl = nextEntity?.mapPicture as String?;
      if (prevUrl == null &&
          nextUrl != null &&
          nextUrl.isNotEmpty &&
          !_isFirstLoad) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_selectedAnimal == null && _selectedEvent == null) {
            _startZoomOutAnimation(nextUrl);
          } else {
            final lx =
                (_selectedAnimal ?? _selectedEvent)?['locationX'] as num?;
            final ly =
                (_selectedAnimal ?? _selectedEvent)?['locationY'] as num?;
            if (lx != null && ly != null) {
              _zoomToLocation(lx.toDouble(), ly.toDouble());
            }
          }
        });
      }
    });

    final mapEntity = ref.watch(mapPictureProvider).valueOrNull;
    final mapUrl = mapEntity?.mapPicture;
    final animals =
        ref.watch(mapAnimalsProvider).valueOrNull ?? <AnimalWithZoneEntity>[];
    final events = ref.watch(mapEventsProvider).valueOrNull ?? <EventEntity>[];

    // Handle initial focus from route arguments
    if (_isFirstLoad) {
      _isFirstLoad = false;
      final args = GoRouterState.of(context).extra as Map<String, dynamic>?;
      final focusAnimal = args?['focusAnimal'] as Map<String, dynamic>?;
      final focusEvent = args?['focusEvent'] as Map<String, dynamic>?;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        if (focusAnimal != null) {
          final lx = (focusAnimal['locationX'] as num).toDouble();
          final ly = (focusAnimal['locationY'] as num).toDouble();
          _zoomToLocation(lx, ly);
          setState(() => _selectedAnimal = focusAnimal);
        } else if (focusEvent != null) {
          final lx = (focusEvent['locationX'] as num).toDouble();
          final ly = (focusEvent['locationY'] as num).toDouble();
          _zoomToLocation(lx, ly);
          setState(() => _selectedEvent = focusEvent);
        } else if (mapUrl != null) {
          _startZoomOutAnimation(mapUrl);
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
                    child: mapUrl != null
                        ? Image.network(mapUrl, fit: BoxFit.cover)
                        : const Center(child: CircularProgressIndicator()),
                  ),

                  ...animals.map((animal) {
                    if (animal.locationX == null || animal.locationY == null) {
                      return const SizedBox.shrink();
                    }
                    final isHighlighted =
                        _selectedAnimal != null &&
                        _selectedAnimal!['id'] == animal.id;
                    return _buildPin(
                      x: animal.locationX!.toDouble(),
                      y: animal.locationY!.toDouble(),
                      imageUrl: animal.animalPicture,
                      borderColor: Colors.white,
                      isHighlighted: isHighlighted,
                      onTap: () {
                        setState(() {
                          _selectedEvent = null;
                          _selectedAnimal = {
                            'id': animal.id,
                            'animalName': animal.animalName,
                            'animalDetail': animal.animalDetail,
                            'animalPicture': animal.animalPicture,
                            'zoneName': animal.zoneName,
                          };
                        });
                      },
                    );
                  }),

                  ...events.map((event) {
                    if (event.locationX == null || event.locationY == null) {
                      return const SizedBox.shrink();
                    }
                    final isHighlighted =
                        _selectedEvent != null &&
                        _selectedEvent!['id'] == event.id;
                    return _buildPin(
                      x: event.locationX!,
                      y: event.locationY!,
                      imageUrl: event.eventPicture,
                      borderColor: Colors.orangeAccent,
                      isHighlighted: isHighlighted,
                      onTap: () {
                        setState(() {
                          _selectedAnimal = null;
                          _selectedEvent = {
                            'id': event.id,
                            'eventName': event.eventName,
                            'eventDetail': event.eventDetail,
                            'eventPicture': event.eventPicture,
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
                        items: _buildSearchItems(animals, events),
                        onSelected: _onSearchSelected,
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        final scannedId = await context.push<String>(
                          AppRoute.qrScan,
                        );
                        if (scannedId != null) {
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
