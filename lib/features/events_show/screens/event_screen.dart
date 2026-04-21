import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/widgets/zoo_bottom_nav.dart';

class EventScreen extends StatelessWidget {
  const EventScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Sample events data
    final List<Map<String, dynamic>> events = [
      {
        'id': 1,
        'date': '12/04/2070',
        'title': 'Night Safari Party',
        'description': 'Experience the magic of wildlife under the stars',
        'image': 'https://via.placeholder.com/300x200?text=Night+Safari+Party',
      },
      {
        'id': 2,
        'date': '15/04/2070',
        'title': 'Daytime Adventure',
        'description': 'Explore exotic animals during the day',
        'image': 'https://via.placeholder.com/300x200?text=Daytime+Adventure',
      },
    ];

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: ZooBottomNav(currentIndex: 2),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section with Green Background
            Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF6FD480),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Back Button
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Icon(Icons.arrow_back_ios, size: 16),
                      ),
                      const SizedBox(height: 24),
                      
                      // Title
                      const Text(
                        'Join the Fun!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Color(0xFF10161F),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Description
                      const Text(
                        'Discover exciting events and activities you can enjoy with us.',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          height: 1.0,
                          letterSpacing: 0,
                          color: Color(0xFF10161F),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
            
            // Book Tickets Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20.0, 0, 20.0, 24.0),
              child: SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Booking page coming soon!')),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFD415),
                    foregroundColor: const Color(0xFF9C6300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    elevation: 4,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Icon(Icons.confirmation_num_outlined, size: 22),
                      SizedBox(width: 14),
                      Text(
                        'Book your tickets now!',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF9C6300),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
              
            // Events Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: const Text(
                'Events',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF10161F),
                ),
              ),
            ),
            const SizedBox(height: 16),
              
            // Event Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return EventCard(
                    date: event['date'],
                    title: event['title'],
                    description: event['description'],
                    imageUrl: event['image'],
                  );
                },
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }
}

class EventCard extends StatelessWidget {
  final String date;
  final String title;
  final String description;
  final String imageUrl;

  const EventCard({
    super.key,
    required this.date,
    required this.title,
    required this.description,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle event card tap
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title event details')),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Event Image
                Container(
                  width: double.infinity,
                  height: 200,
                  color: Colors.grey[300],
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[300],
                        child: const Icon(
                          Icons.image_not_supported,
                          size: 50,
                          color: Colors.grey,
                        ),
                      );
                    },
                  ),
                ),
                
                // Event Details
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date
                      Text(
                        date,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF999999),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF10161F),
                        ),
                      ),
                      const SizedBox(height: 8),
                      
                      // Description
                      Text(
                        description,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Color(0xFF999999),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}