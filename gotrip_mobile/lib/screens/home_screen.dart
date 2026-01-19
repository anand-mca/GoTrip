import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../widgets/trip_card.dart';
import '../models/destination_model.dart';
import '../providers/destination_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final List<String> savedTrips = [];
  bool _dataLoaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadDestinations();
    });
  }

  Future<void> _loadDestinations() async {
    if (!_dataLoaded) {
      print('🏠 HomeScreen: Loading destinations...');
      final destinationProvider = context.read<DestinationProvider>();
      await destinationProvider.fetchAllDestinations();
      print('🏠 HomeScreen: Got ${destinationProvider.destinations.length} destinations');
      setState(() {
        _dataLoaded = true;
      });
    }
  }

  final List<Destination> _fallbackDestinations = [
    Destination(
      id: 'mock-1',
      title: 'Taj Mahal',
      location: 'Agra, Uttar Pradesh',
      description: 'The Taj Mahal is an ivory-white marble mausoleum. A UNESCO World Heritage Site and one of the most beautiful buildings in the world, built by Mughal emperor Shah Jahan in memory of his wife Mumtaz Mahal.',
      image: 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=500&h=400&fit=crop',
      rating: 4.9,
      reviews: 2847,
      price: 250,
      duration: 4,
      difficulty: 'Easy',
      highlights: ['UNESCO World Heritage Site', 'Marble Architecture', 'Sunrise View', 'Night Illumination'],
      amenities: ['Restaurant', 'Parking', 'Rest Areas', 'Photography Allowed'],
      groupSize: 50,
      category: 'Heritage',
      latitude: 27.1751,
      longitude: 78.0421,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
                        Row(
                          children: [
                            // Profile Button
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
                      ],
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
                  Consumer<DestinationProvider>(
                    builder: (context, destinationProvider, child) {
                      if (destinationProvider.isLoading) {
                        return SizedBox(
                          height: 280,
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      // Just show first 10 destinations without filtering
                      List<dynamic> destinationsToDisplay = destinationProvider.destinations.isEmpty 
                          ? _fallbackDestinations 
                          : destinationProvider.destinations.take(10).toList();

                      if (destinationsToDisplay.isEmpty) {
                        return SizedBox(
                          height: 280,
                          child: Center(
                            child: Text('No destinations available'),
                          ),
                        );
                      }

                      return SizedBox(
                        height: 280,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: destinationsToDisplay.length,
                          itemBuilder: (context, index) {
                            final destination = destinationsToDisplay[index];
                            return SizedBox(
                              width: 250,
                              child: Padding(
                                padding: const EdgeInsets.only(right: AppSpacing.md),
                                child: TripCard(
                                  title: destination.title,
                                  location: destination.location,
                                  image: '',
                                  price: destination.price,
                                  rating: destination.rating,
                                  reviews: destination.reviews,
                                  isSaved: savedTrips.contains(destination.id),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/trip-detail',
                                      arguments: destination,
                                    );
                                  },
                                  onSavePressed: () {
                                    setState(() {
                                      if (savedTrips.contains(destination.id)) {
                                        savedTrips.remove(destination.id);
                                      } else {
                                        savedTrips.add(destination.id);
                                      }
                                    });
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // Popular Destinations Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Popular Destinations',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Consumer<DestinationProvider>(
                    builder: (context, destinationProvider, child) {
                      if (destinationProvider.isLoading) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (destinationProvider.destinations.isEmpty) {
                        return const Center(child: Text('No destinations available'));
                      }

                      return Column(
                        children: destinationProvider.destinations.skip(10).take(5).map((destination) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: TripCard(
                              title: destination.title,
                              location: destination.location,
                              image: '',
                              price: destination.price,
                              rating: destination.rating,
                              reviews: destination.reviews,
                              isSaved: savedTrips.contains(destination.id),
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/trip-detail',
                                  arguments: destination,
                                );
                              },
                              onSavePressed: () {
                                setState(() {
                                  if (savedTrips.contains(destination.id)) {
                                    savedTrips.remove(destination.id);
                                  } else {
                                    savedTrips.add(destination.id);
                                  }
                                });
                              },
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
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
          if (index == 2) Navigator.pushNamed(context, '/plan-trip');
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
            icon: Icon(Icons.map),
            label: 'Plan Trip',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

}
