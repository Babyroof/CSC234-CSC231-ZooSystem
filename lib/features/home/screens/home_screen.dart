import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/mock_data.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/widgets/zoo_bottom_nav.dart';
import '../widgets/menu_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final popularAnimals = MockData.animalsMap.take(4).toList();

    final mockEvents = [
      {
        'eventName': 'Elephant Feeding',
        'eventDetail':
            'Get up close and personal with our gentle giants. Feed them fresh fruits and learn about their daily routines from our expert caretakers.',
        'eventPicture':
            'https://images.unsplash.com/photo-1557050543-4d5f4e07ef46?auto=format&fit=crop&w=400&q=80',
      },
      {
        'eventName': 'Penguin Parade Walk',
        'eventDetail':
            'Watch our adorable penguins take their daily stroll outside their enclosure. A perfect photo opportunity for the whole family!',
        'eventPicture':
            'https://images.unsplash.com/photo-1598439210625-5067c578f3f6?auto=format&fit=crop&w=400&q=80',
      },
      {
        'eventName': 'Tiger Meet & Greet',
        'eventDetail':
            'Experience the thrill of watching our majestic Bengal tigers enjoy their afternoon meal while keepers share fascinating facts about these apex predators.',
        'eventPicture':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcQ_TZn9EfBu-ygqogCLp2-gr9sVnYWeD41v6A&s',
      },
      {
        'eventName': 'Macaw Flight Show',
        'eventDetail':
            'Look up to the sky as our colorful macaws perform breathtaking free-flight demonstrations right above your head.',
        'eventPicture':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcSf3bUoLwlDteIdAU6cib-ewvOdMefICmSk1Q&s',
      },
      {
        'eventName': 'Dolphin Splash Time',
        'eventDetail':
            'Join us at the grand aquarium for an interactive session where you can see the incredible intelligence and agility of our playful dolphins.',
        'eventPicture':
            'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTv4Us3jhYDPphHAvfQPZPsMUOunh76agOnyQ&s',
      },
    ];

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
                              child: Icon(
                                Icons.pets,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Hi, Jeffy',
                          style: TextStyle(
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
                      onPressed: () =>
                          Navigator.pushNamed(context, AppRoute.booking),
                      icon: const Icon(
                        Icons.confirmation_num_outlined,
                        color: AppColors.navIcon,
                      ),
                      label: const Text(
                        'Book your tickets now!',
                        style: TextStyle(
                          color: AppColors.white,
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
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoute.events),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: MenuButton(
                      icon: Icons.pets_outlined,
                      title: 'Animals',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoute.animals),
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
                itemCount: mockEvents.length,
                itemBuilder: (context, index) {
                  final event = mockEvents[index];
                  return InkWell(
                    onTap: () {}, // Route Event info
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
                            color: Colors.black.withOpacity(0.05),
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
                                event['eventPicture']!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                              ),
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(0, 12, 0, 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  event['eventName']!,
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
                  );
                },
              ),
            ),
          ),

          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Text(
                'Popular Animals',
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
                final animal = popularAnimals[index];

                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoute.animalInfo,
                      arguments: animal,
                    );
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            animal['animalPicture'],
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                animal['animalName'],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),

                              Text(
                                animal['animalDetail'],
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
                                  // go to map
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
                                  side: BorderSide(color: Colors.grey.shade300),
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
              }, childCount: popularAnimals.length),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }
}
