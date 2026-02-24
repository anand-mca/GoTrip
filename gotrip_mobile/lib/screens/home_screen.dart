import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/app_constants.dart';
import '../widgets/trip_card.dart';
import '../models/destination_model.dart';
import '../providers/destination_provider.dart';
import '../providers/theme_provider.dart';
import '../services/journey_service.dart';
import 'journey_tracking_screen.dart';
import 'travel_history_screen.dart';
import 'profile_screen.dart';
import 'main_navigation_shell.dart';

// Original HomeScreen - redirects to MainNavigationShell
class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MainNavigationShell();
  }
}

// Content-only screen for use inside the navigation shell
class HomeContentScreen extends StatefulWidget {
  final Map<String, dynamic>? activeTrip;
  final VoidCallback? onActiveTripChanged;
  
  const HomeContentScreen({
    Key? key,
    this.activeTrip,
    this.onActiveTripChanged,
  }) : super(key: key);

  @override
  State<HomeContentScreen> createState() => _HomeContentScreenState();
}

class _HomeContentScreenState extends State<HomeContentScreen> {
  bool _dataLoaded = false;
  
  // Journey tracking
  final JourneyService _journeyService = JourneyService();

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
      
      // Load user favorites if logged in
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await destinationProvider.loadUserFavorites(user.id);
      }
      
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
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.lg),
              decoration: BoxDecoration(
                color: primaryColor,
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
                            Text(
                              'Hello, Traveler!',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: textOnPrimary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Ready for your next adventure?',
                              style: TextStyle(
                                fontSize: 14,
                                color: textOnPrimary.withOpacity(0.8),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            // History Button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const TravelHistoryScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                              child: Icon(
                                  Icons.history,
                                  color: textOnPrimary,
                                  size: 24,
                                ),
                              ),
                            ),
                            // Profile Button
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ProfileScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.sm),
                                decoration: BoxDecoration(
                                  color: textOnPrimary.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.person,
                                  color: textOnPrimary,
                                  size: 24,
                                ),
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
            
            // Active Journey Banner
            if (widget.activeTrip != null) ...[
              _buildActiveJourneyBanner(),
            ],
            
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
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/explore'),
                        child: Text('See All', style: TextStyle(color: primaryColor)),
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
                            final isFavorite = destinationProvider.isFavorite(destination.id);
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
                                  isSaved: isFavorite,
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/trip-detail',
                                      arguments: destination,
                                    );
                                  },
                                  onSavePressed: () async {
                                    final user = Supabase.instance.client.auth.currentUser;
                                    if (user == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Please login to save favorites'),
                                          backgroundColor: Colors.orange,
                                        ),
                                      );
                                      return;
                                    }
                                    await destinationProvider.toggleFavorite(user.id, destination.id);
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
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
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
                          final isFavorite = destinationProvider.isFavorite(destination.id);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: TripCard(
                              title: destination.title,
                              location: destination.location,
                              image: '',
                              price: destination.price,
                              rating: destination.rating,
                              reviews: destination.reviews,
                              isSaved: isFavorite,
                              onTap: () {
                                Navigator.pushNamed(
                                  context,
                                  '/trip-detail',
                                  arguments: destination,
                                );
                              },
                              onSavePressed: () async {
                                final user = Supabase.instance.client.auth.currentUser;
                                if (user == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please login to save favorites'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                await destinationProvider.toggleFavorite(user.id, destination.id);
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
            const SizedBox(height: AppSpacing.xl + 80), // Extra padding for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildActiveJourneyBanner() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDark = themeProvider.isDarkMode;
    final primaryColor = themeProvider.primaryColor;

    final tripName = widget.activeTrip!['trip_name'] ?? 'Your Trip';
    final startCity = widget.activeTrip!['start_city'] ?? 'Unknown';
    
    // Calculate progress
    final tripDays = widget.activeTrip!['trip_days'] as List? ?? [];
    int totalDestinations = 0;
    int visitedDestinations = 0;
    
    for (var day in tripDays) {
      final destinations = day['trip_destinations'] as List? ?? [];
      totalDestinations += destinations.length;
      visitedDestinations += destinations.where((d) => d['is_visited'] == true).length;
    }
    
    final progress = totalDestinations > 0 ? visitedDestinations / totalDestinations : 0.0;

    // Theme-aware colours
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = primaryColor;
    final textMain = primaryColor;
    final textSub = isDark ? Colors.white70 : const Color(0xFF2D3436).withOpacity(0.75);
    final iconBg = primaryColor.withOpacity(0.15);
    final progressBg = primaryColor.withOpacity(0.2);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.18),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _navigateToActiveJourney,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor.withOpacity(0.4), width: 1),
                      ),
                      child: Icon(
                        Icons.directions_walk,
                        color: textMain,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🚀 Active Journey',
                            style: TextStyle(
                              color: textMain,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            tripName,
                            style: TextStyle(
                              color: isDark ? Colors.white : const Color(0xFF2D3436),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: textMain,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Progress Bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: progressBg,
                          valueColor: AlwaysStoppedAnimation<Color>(textMain),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        color: textMain,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '$visitedDestinations of $totalDestinations destinations visited',
                  style: TextStyle(
                    color: textSub,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToActiveJourney() {
    if (widget.activeTrip == null) return;
    
    // Convert DB format to app format
    final tripPlan = _journeyService.convertDbTripToAppFormat(widget.activeTrip!);
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => JourneyTrackingScreen(
          tripPlan: tripPlan,
          fromDatabase: true,
        ),
      ),
    ).then((_) {
      // Refresh active trip when returning
      widget.onActiveTripChanged?.call();
    });
  }

  void _showActiveTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Active Trip Exists'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You already have an active journey in progress!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.map, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.activeTrip!['trip_name'] ?? 'Your Trip',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please end your current journey before planning a new trip.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _navigateToActiveJourney();
            },
            icon: const Icon(Icons.directions_walk, size: 18),
            label: const Text('Continue Journey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
