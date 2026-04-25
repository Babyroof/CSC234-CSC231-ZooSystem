import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/routes/app_routes.dart';
import '../../../core/widgets/zoo_bottom_nav.dart';
import '../../../core/constants/app_colors.dart';
import '../services/animal_service.dart'; 

class AnimalScreen extends StatefulWidget { 
  const AnimalScreen({super.key});

  @override
  State<AnimalScreen> createState() => _AnimalScreenState();
}

class _AnimalScreenState extends State<AnimalScreen> {
  final _service = AnimalService();
  List<Map<String, dynamic>> animals = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAnimals();
  }

  Future<void> _loadAnimals() async {
    final data = await _service.getAnimalsWithZone();
    setState(() {
      animals = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final screenWidth = size.width;

    int responsiveCrossAxisCount = 2;
    if (screenWidth > 900) {
      responsiveCrossAxisCount = 4;
    } else if (screenWidth > 600) {
      responsiveCrossAxisCount = 3;
    }

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: const ZooBottomNav(currentIndex: -1),
      backgroundColor: AppColors.background,
      body: isLoading 
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  expandedHeight: 250,
                  toolbarHeight: 70,
                  backgroundColor: AppColors.background,
                  elevation: 0,
                  leadingWidth: 68,
                  leading: Padding(
                    padding: const EdgeInsets.only(left: 20.0, top: 16.0),
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(
                          Icons.arrow_back_ios, color: AppColors.black),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(bottom: 28),
                          width: double.infinity,
                          padding: const EdgeInsets.only(
                            top: 100,
                            left: 20,
                            right: 20,
                            bottom: 40,
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
                              const Text(
                                'Get to Know Our Animals',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.black,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Let\'s meet our wild residents and get to know them better',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.black,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 20,
                          right: 20,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () => Navigator.pushNamed(
                                  context, AppRoute.booking),
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
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20, 30, 20, 10),
                    child: Text(
                      'Animals',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.black,
                      ),
                    ),
                  ),
                ),

                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: responsiveCrossAxisCount,
                      childAspectRatio: 0.73,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final animal = animals[index]; 
                        return InkWell(
                          onTap: () => Navigator.pushNamed(
                            context,
                            AppRoute.animalInfo,
                            arguments: animal,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(12),
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
                                      animal['animalPicture'],
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      // ✅ เพิ่ม errorBuilder กัน crash
                                      errorBuilder: (_, __, ___) =>
                                          Container(
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.pets,
                                            color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 12, 0, 4),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        animal['animalName'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        animal['zoneName'],
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: animals.length, // ✅ ใช้ Firebase data
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 100)),
              ],
            ),
    );
  }
}