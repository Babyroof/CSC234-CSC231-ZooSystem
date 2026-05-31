import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../core/widgets/zoo_bottom_nav.dart';
import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../../../events_show/domain/entities/event_entity.dart';
import '../../../events_show/presentation/providers/event_providers.dart';
import '../../../profile/presentation/providers/profile_providers.dart';
import '../providers/home_providers.dart';
import '../widgets/menu_button.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);
    final profileAsync = ref.watch(profileNotifierProvider);
    final animalsAsync = ref.watch(homePopularAnimalsProvider);
    final showPopularAnimals = ref.watch(featurePopularAnimalsProvider);

    if (eventsAsync.isLoading ||
        profileAsync.isLoading ||
        animalsAsync.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final events = eventsAsync.valueOrNull ?? <EventEntity>[];
    final profile = profileAsync.valueOrNull;
    final animals = animalsAsync.valueOrNull ?? <AnimalWithZoneEntity>[];

    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      bottomNavigationBar: const ZooBottomNav(currentIndex: 0),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                Padding(
                  padding: EdgeInsetsGeometry.only(bottom: 30),
                  child: Container(
                    padding: const EdgeInsets.only(
                      top: 50,
                      left: 20,
                      right: 20,
                      bottom: 24,
                    ),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.white,
                              radius: 24,
                              backgroundImage: AssetImage(
                                'lib/assets/images/logo.png',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(
                          profile != null
                              ? 'Hi, ${profile.firstname} ${profile.lastname}'
                              : 'Hi, Anonymous...',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Plan your visit, get tickets, and explore animal facts—all in one place.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.black,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 20,
                  right: 20,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => context.push(AppRoute.booking),
                      icon: const Icon(
                        Icons.confirmation_num_outlined,
                        color: AppColors.navIcon,
                      ),
                      label: const Text(
                        'Book your tickets now!',
                        style: TextStyle(
                          color: AppColors.navIcon,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        alignment: Alignment.centerLeft,
                        backgroundColor: AppColors.primaryYellow,
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 20,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  Expanded(
                    child: MenuButton(
                      icon: Icons.celebration_outlined,
                      title: 'Event',
                      onTap: () => context.push(AppRoute.events),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MenuButton(
                      icon: Icons.pets_outlined,
                      title: 'Animals',
                      onTap: () => context.push(AppRoute.animals),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
              child: Text(
                'Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.black,
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: SizedBox(
              height: 250,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Semantics(
                    label: event.eventName,
                    button: true,
                    excludeSemantics: true,
                    child: InkWell(
                      onTap: () =>
                          context.push(AppRoute.eventsInfo, extra: event),
                      child: Container(
                        width: 160,
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  event.eventPicture,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  loadingBuilder: (_, child, progress) {
                                    if (progress == null) return child;
                                    return Container(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.08,
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.primary,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, err, stack) =>
                                      Container(
                                        decoration: BoxDecoration(
                                          color: AppColors.primary.withValues(
                                            alpha: 0.12,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.celebration_outlined,
                                            color: AppColors.primary,
                                            size: 36,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.eventName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ); // end Semantics
                },
              ),
            ),
          ),

          if (showPopularAnimals) ...[
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Recommend Animals',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final animal = animals[index];
                  return InkWell(
                    onTap: () => context.push(
                      AppRoute.animalInfo,
                      extra: animal.toMap(),
                    ),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              animal.animalPicture,
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, progress) {
                                if (progress == null) return child;
                                return Container(
                                  width: 80,
                                  height: 80,
                                  color: AppColors.primary.withValues(
                                    alpha: 0.08,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: AppColors.primary,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (context, err, stack) => Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.12,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.pets,
                                    color: AppColors.primary,
                                    size: 36,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animal.animalName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  animal.animalDetail,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    final lx = animal.locationX;
                                    final ly = animal.locationY;
                                    if (lx == null || ly == null) return;
                                    context.push(
                                      AppRoute.map,
                                      extra: {
                                        'focusAnimal': {
                                          'animalName': animal.animalName,
                                          'animalDetail': animal.animalDetail,
                                          'animalPicture': animal.animalPicture,
                                          'zoneName': animal.zoneName,
                                          'locationX': lx.toDouble(),
                                          'locationY': ly.toDouble(),
                                        },
                                      },
                                    );
                                  },
                                  icon: const Icon(
                                    Icons.map_outlined,
                                    size: 16,
                                    color: AppColors.black,
                                  ),
                                  label: const Text(
                                    'Location',
                                    style: TextStyle(
                                      color: AppColors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 0,
                                    ),
                                    side: BorderSide(
                                      color: Colors.grey.shade300,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    minimumSize: const Size(0, 32),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }, childCount: animals.length),
              ),
            ),
          ], // end feature_popular_animals

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
