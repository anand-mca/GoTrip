import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../widgets/trip_card.dart';
import '../models/trip_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<String> savedTrips = [];

  final List<Trip> _featuredTrips = [
    Trip(
      id: '1',
      title: 'Swiss Alps Adventure',
      description: 'Experience the majestic Swiss Alps with guided mountain tours',
      image: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop',
      location: 'Switzerland',
      rating: 4.8,
      reviews: 234,
      price: 1299.99,
      duration: 7,
      difficulty: 'Moderate',
      highlights: ['Mountain Tours', 'Cable Cars', 'Alpine Lakes', 'Traditional Villages'],
      amenities: ['Hotel', 'Meals', 'Guide', 'Transportation'],
      groupSize: 12,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '2',
      title: 'Tropical Paradise',
      description: 'Relax on pristine beaches and explore tropical wildlife',
      image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&h=400&fit=crop',
      location: 'Maldives',
      rating: 4.9,
      reviews: 567,
      price: 1899.99,
      duration: 5,
      difficulty: 'Easy',
      highlights: ['Beach', 'Snorkeling', 'Water Sports', 'Sunset Cruise'],
      amenities: ['Resort', 'All Meals', 'Activities', 'Transfers'],
      groupSize: 20,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '3',
      title: 'Ancient Wonders',
      description: 'Explore historical sites and ancient civilizations',
      image: 'https://images.unsplash.com/photo-1499856871957-5b8620a56b38?w=500&h=400&fit=crop',
      location: 'Egypt',
      rating: 4.7,
      reviews: 345,
      price: 999.99,
      duration: 6,
      difficulty: 'Easy',
      highlights: ['Pyramids', 'Nile Cruise', 'Museums', 'Local Markets'],
      amenities: ['Hotel', 'Breakfast', 'Guide', 'Visa Support'],
      groupSize: 15,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
  ];

  final List<Trip> _allTrips = [
    Trip(
      id: '4',
      title: 'Amazon Rainforest',
      description: 'Wildlife expedition in the world\'s largest rainforest',
      image: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=500&h=400&fit=crop',
      location: 'Brazil',
      rating: 4.6,
      reviews: 289,
      price: 2499.99,
      duration: 10,
      difficulty: 'Hard',
      highlights: ['Jungle Hike', 'Wildlife', 'River Cruise', 'Indigenous Village'],
      amenities: ['Lodge', 'Meals', 'Expert Guide', 'Equipment'],
      groupSize: 8,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '5',
      title: 'Tokyo Modern',
      description: 'Experience the blend of tradition and cutting-edge technology',
      image: 'https://images.unsplash.com/photo-1540959375944-7049f642e9f1?w=500&h=400&fit=crop',
      location: 'Japan',
      rating: 4.8,
      reviews: 456,
      price: 1499.99,
      duration: 7,
      difficulty: 'Easy',
      highlights: ['Temples', 'Modern Tech', 'Food Tour', 'Cherry Blossoms'],
      amenities: ['Hotel', 'Breakfast', 'JR Pass', 'Local Guide'],
      groupSize: 18,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Hello, Traveler!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Ready for your next adventure?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search destinations...',
                          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.md,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Featured Trips Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Trips',
                        style: Theme.of(context).textTheme.displaySmall,
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/explore'),
                        child: const Text('See All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 280,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _featuredTrips.length,
                      itemBuilder: (context, index) {
                        final trip = _featuredTrips[index];
                        return SizedBox(
                          width: 250,
                          child: Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: TripCard(
                              title: trip.title,
                              location: trip.location,
                              image: trip.image,
                              price: trip.price,
                              rating: trip.rating,
                              reviews: trip.reviews,
                              isSaved: savedTrips.contains(trip.id),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/trip-detail',
                                  arguments: trip,
                                );
                              },
                              onSavePressed: () {
                                setState(() {
                                  if (savedTrips.contains(trip.id)) {
                                    savedTrips.remove(trip.id);
                                  } else {
                                    savedTrips.add(trip.id);
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Categories Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Categories',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('🏔️ Mountain', true),
                        const SizedBox(width: AppSpacing.md),
                        _buildCategoryChip('🏖️ Beach', false),
                        const SizedBox(width: AppSpacing.md),
                        _buildCategoryChip('🏙️ City', false),
                        const SizedBox(width: AppSpacing.md),
                        _buildCategoryChip('🌲 Adventure', false),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Popular Trips Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular This Month',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ..._allTrips.map((trip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TripCard(
                        title: trip.title,
                        location: trip.location,
                        image: trip.image,
                        price: trip.price,
                        rating: trip.rating,
                        reviews: trip.reviews,
                        isSaved: savedTrips.contains(trip.id),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/trip-detail',
                            arguments: trip,
                          );
                        },
                        onSavePressed: () {
                          setState(() {
                            if (savedTrips.contains(trip.id)) {
                              savedTrips.remove(trip.id);
                            } else {
                              savedTrips.add(trip.id);
                            }
                          });
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          // Handle navigation
          if (index == 1) Navigator.pushNamed(context, '/explore');
          if (index == 2) Navigator.pushNamed(context, '/bookings');
          if (index == 3) Navigator.pushNamed(context, '/profile');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.explore),
            label: 'Explore',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bookmark),
            label: 'Bookings',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, bool isSelected) {
    return Chip(
      label: Text(label),
      backgroundColor: isSelected ? AppColors.primary : AppColors.surfaceAlt,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppColors.textPrimary,
        fontWeight: FontWeight.w600,
      ),
      side: isSelected ? null : const BorderSide(color: AppColors.border),
    );
  }
}
