import 'package:flutter/material.dart';
import '../services/journey_service.dart';
import '../services/location_services.dart';

class JourneyTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> tripPlan;
  final bool fromDatabase; // True if loaded from DB, false if new trip

  const JourneyTrackingScreen({
    Key? key,
    required this.tripPlan,
    this.fromDatabase = false,
  }) : super(key: key);

  @override
  State<JourneyTrackingScreen> createState() => _JourneyTrackingScreenState();
}

class _JourneyTrackingScreenState extends State<JourneyTrackingScreen> {
  final JourneyService _journeyService = JourneyService();
  final LocationServices _locationServices = LocationServices();
  
  // Track visited destinations - Map<dayIndex, Set<destinationIndex>>
  Map<int, Set<int>> visitedDestinations = {};
  // Track which destination is currently expanded
  int? expandedDayIndex;
  int? expandedDestinationIndex;
  
  // Store destination IDs from database for updating
  Map<int, Map<int, String>> destinationDbIds = {}; // dayIndex -> destIndex -> dbId
  
  // Cache for location data (weather, restaurants, hotels, attractions)
  Map<String, _ExpandedSectionData> _expandedDataCache = {};
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeVisitedDestinations();
  }

  void _initializeVisitedDestinations() {
    final dailyItineraries = widget.tripPlan['daily_itineraries'] as List? ?? [];
    
    for (int dayIndex = 0; dayIndex < dailyItineraries.length; dayIndex++) {
      visitedDestinations[dayIndex] = {};
      destinationDbIds[dayIndex] = {};
      
      final places = (dailyItineraries[dayIndex]['destinations'] as List? ?? []);
      for (int destIndex = 0; destIndex < places.length; destIndex++) {
        final place = places[destIndex] as Map<String, dynamic>?;
        if (place != null) {
          // Store the database ID if available
          if (place['id'] != null) {
            destinationDbIds[dayIndex]![destIndex] = place['id'].toString();
          }
          // Check if already visited (from database)
          if (place['is_visited'] == true) {
            visitedDestinations[dayIndex]!.add(destIndex);
          }
        }
      }
    }
  }

  Future<void> _toggleVisited(int dayIndex, int destIndex) async {
    final wasVisited = visitedDestinations[dayIndex]!.contains(destIndex);
    final newVisitedState = !wasVisited;
    
    // Get place data for fetching location info
    final dailyItineraries = widget.tripPlan['daily_itineraries'] as List? ?? [];
    Map<String, dynamic>? place;
    if (dayIndex < dailyItineraries.length) {
      final places = dailyItineraries[dayIndex]['destinations'] as List? ?? [];
      if (destIndex < places.length) {
        place = places[destIndex] as Map<String, dynamic>?;
      }
    }
    
    // Update UI immediately
    setState(() {
      if (wasVisited) {
        visitedDestinations[dayIndex]!.remove(destIndex);
        if (expandedDayIndex == dayIndex && expandedDestinationIndex == destIndex) {
          expandedDayIndex = null;
          expandedDestinationIndex = null;
        }
      } else {
        visitedDestinations[dayIndex]!.add(destIndex);
        expandedDayIndex = dayIndex;
        expandedDestinationIndex = destIndex;
      }
    });

    // Fetch location data if marking as visited
    if (newVisitedState && place != null) {
      _fetchLocationData(place, dayIndex, destIndex);
    }

    // Update in database
    final destDbId = destinationDbIds[dayIndex]?[destIndex];
    if (destDbId != null) {
      try {
        await _journeyService.markDestinationVisited(destDbId, newVisitedState);
      } catch (e) {
        print('Error updating destination in database: $e');
        // Revert UI on error
        setState(() {
          if (newVisitedState) {
            visitedDestinations[dayIndex]!.remove(destIndex);
          } else {
            visitedDestinations[dayIndex]!.add(destIndex);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  /// Fetch weather, restaurants, hotels, and attractions data for a place
  Future<void> _fetchLocationData(Map<String, dynamic> place, int dayIndex, int destIndex) async {
    final cacheKey = '${dayIndex}_$destIndex';
    
    // Check if already fetched
    if (_expandedDataCache.containsKey(cacheKey) && 
        _expandedDataCache[cacheKey]!.isLoaded) {
      return;
    }
    
    // Initialize with loading state
    setState(() {
      _expandedDataCache[cacheKey] = _ExpandedSectionData(isLoading: true);
    });

    try {
      // Get coordinates - first try from place data, then geocode
      double? latitude = place['latitude']?.toDouble();
      double? longitude = place['longitude']?.toDouble();
      
      if (latitude == null || longitude == null || latitude == 0 || longitude == 0) {
        // Geocode using place name
        final placeName = place['name'] ?? '';
        final city = place['city'] ?? '';
        final state = place['state'] ?? '';
        
        final coords = await _locationServices.getCoordinates(
          placeName, 
          city: city, 
          state: state,
        );
        
        if (coords != null) {
          latitude = coords['latitude'];
          longitude = coords['longitude'];
        }
      }
      
      if (latitude == null || longitude == null) {
        setState(() {
          _expandedDataCache[cacheKey] = _ExpandedSectionData(
            isLoading: false,
            isLoaded: true,
            error: 'Could not find location coordinates',
          );
        });
        return;
      }

      // Fetch all data in parallel
      final results = await Future.wait([
        _locationServices.getWeatherAlert(latitude, longitude),
        _locationServices.getNearbyRestaurants(latitude, longitude),
        _locationServices.getNearbyHotels(latitude, longitude),
        _locationServices.getNearbyAttractions(latitude, longitude),
      ]);

      if (mounted) {
        setState(() {
          _expandedDataCache[cacheKey] = _ExpandedSectionData(
            isLoading: false,
            isLoaded: true,
            weather: results[0] as WeatherAlert,
            restaurants: results[1] as List<Restaurant>,
            hotels: results[2] as List<Hotel>,
            attractions: results[3] as List<Attraction>,
          );
        });
      }
    } catch (e) {
      print('Error fetching location data: $e');
      if (mounted) {
        setState(() {
          _expandedDataCache[cacheKey] = _ExpandedSectionData(
            isLoading: false,
            isLoaded: true,
            error: 'Failed to fetch nearby places',
          );
        });
      }
    }
  }

  double _calculateDayProgress(int dayIndex, int totalDestinations) {
    if (totalDestinations == 0) return 0;
    return visitedDestinations[dayIndex]!.length / totalDestinations;
  }

  double _calculateOverallProgress() {
    final dailyItineraries = widget.tripPlan['daily_itineraries'] as List? ?? [];
    if (dailyItineraries.isEmpty) return 0;

    int totalVisited = 0;
    int totalDestinations = 0;

    for (int i = 0; i < dailyItineraries.length; i++) {
      final places = (dailyItineraries[i]['destinations'] as List? ?? []);
      totalDestinations += places.length;
      totalVisited += visitedDestinations[i]?.length ?? 0;
    }

    if (totalDestinations == 0) return 0;
    return totalVisited / totalDestinations;
  }

  Future<void> _endJourney() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Journey?'),
        content: const Text(
          'Are you sure you want to end this journey? This will mark your trip as completed and you can start planning a new trip.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('End Journey', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      
      try {
        final tripId = widget.tripPlan['trip_id'];
        if (tripId != null) {
          await _journeyService.endJourney(tripId);
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Journey completed! Check your travel history.'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate back to home
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ending journey: $e'), backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dailyItineraries = widget.tripPlan['daily_itineraries'] as List? ?? [];
    final overallProgress = _calculateOverallProgress();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journey Tracker'),
        elevation: 0,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Overall Progress Header
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade600, Colors.purple.shade500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.tripPlan['trip_name'] ?? 'Your Journey',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.tripPlan['city_name']} • ${widget.tripPlan['duration_days']} days',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: Stack(
                              children: [
                                CircularProgressIndicator(
                                  value: overallProgress,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.white.withValues(alpha: 0.3),
                                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                                Center(
                                  child: Text(
                                    '${(overallProgress * 100).toInt()}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: overallProgress,
                          minHeight: 10,
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),

                // Day-wise Timeline
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: dailyItineraries.length + 1, // +1 for end journey button
                    itemBuilder: (context, index) {
                      if (index == dailyItineraries.length) {
                        // End Journey Button
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          child: ElevatedButton.icon(
                            onPressed: _endJourney,
                            icon: const Icon(Icons.flag, color: Colors.white),
                            label: const Text(
                              'End Journey 🏁',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        );
                      }

                      final dayData = dailyItineraries[index];
                      final day = dayData['day'] ?? (index + 1);
                      final places = (dayData['destinations'] as List? ?? []);
                      final distance = (dayData['total_distance'] ?? 0) as num;
                      final budget = (dayData['estimated_budget'] ?? 0) as num;
                      final dayProgress = _calculateDayProgress(index, places.length);
                      final isCompleted = dayProgress == 1.0;

                      return _buildDaySection(
                        dayIndex: index,
                        day: day,
                        places: places,
                        distance: distance,
                        budget: budget,
                        dayProgress: dayProgress,
                        isCompleted: isCompleted,
                        isLastDay: index == dailyItineraries.length - 1,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildDaySection({
    required int dayIndex,
    required int day,
    required List places,
    required num distance,
    required num budget,
    required double dayProgress,
    required bool isCompleted,
    required bool isLastDay,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Day Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isCompleted ? Colors.green.shade50 : Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCompleted ? Colors.green.shade200 : Colors.blue.shade200,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.green : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isCompleted ? Icons.check : Icons.calendar_today,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Day $day',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isCompleted ? Colors.green.shade700 : Colors.blue.shade700,
                            ),
                          ),
                          Text(
                            '${places.length} destinations • ${distance.toStringAsFixed(1)} km',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (budget > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '₹${budget.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: dayProgress,
                  minHeight: 6,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${visitedDestinations[dayIndex]!.length}/${places.length} completed',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),

        // Destinations Timeline
        Padding(
          padding: const EdgeInsets.only(left: 28),
          child: Column(
            children: List.generate(places.length, (destIndex) {
              final place = places[destIndex] as Map<String, dynamic>?;
              if (place == null) return const SizedBox.shrink();

              final isVisited = visitedDestinations[dayIndex]!.contains(destIndex);
              final isExpanded = expandedDayIndex == dayIndex && expandedDestinationIndex == destIndex;
              final isLast = destIndex == places.length - 1;

              return _buildDestinationItem(
                dayIndex: dayIndex,
                destIndex: destIndex,
                place: place,
                isVisited: isVisited,
                isExpanded: isExpanded,
                isLast: isLast && isLastDay,
              );
            }),
          ),
        ),

        if (!isLastDay) const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildDestinationItem({
    required int dayIndex,
    required int destIndex,
    required Map<String, dynamic> place,
    required bool isVisited,
    required bool isExpanded,
    required bool isLast,
  }) {
    final cost = place['estimated_cost'] ?? place['cost_per_day'] ?? 0;

    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Timeline line and dot
            Column(
              children: [
                Container(
                  width: 2,
                  height: 20,
                  color: isVisited ? Colors.green : Colors.grey.shade300,
                ),
                GestureDetector(
                  onTap: () => _toggleVisited(dayIndex, destIndex),
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isVisited ? Colors.green : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isVisited ? Colors.green : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                    child: isVisited
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: isExpanded ? 10 : 30,
                    color: isVisited ? Colors.green : Colors.grey.shade300,
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Destination Card
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _toggleVisited(dayIndex, destIndex),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isVisited ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isVisited ? Colors.green.shade200 : Colors.grey.shade200,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 5,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    place['name'] ?? 'Unknown',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      decoration: isVisited ? TextDecoration.lineThrough : null,
                                      color: isVisited ? Colors.grey.shade600 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: 12, color: Colors.grey.shade500),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          '${place['city'] ?? ''}, ${place['state'] ?? ''}',
                                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (cost > 0) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '💰 ₹$cost',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Checkbox(
                              value: isVisited,
                              onChanged: (_) => _toggleVisited(dayIndex, destIndex),
                              activeColor: Colors.green,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expandable section
                    AnimatedCrossFade(
                      firstChild: const SizedBox.shrink(),
                      secondChild: _buildExpandedSection(place, dayIndex, destIndex),
                      crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildExpandedSection(Map<String, dynamic> place, int dayIndex, int destIndex) {
    final cacheKey = '${dayIndex}_$destIndex';
    final data = _expandedDataCache[cacheKey];
    
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection(
            icon: Icons.cloud,
            iconColor: Colors.blue,
            title: 'Weather Alert',
            content: _buildWeatherSection(data),
          ),
          const Divider(height: 24),
          _buildInfoSection(
            icon: Icons.restaurant,
            iconColor: Colors.orange,
            title: 'Nearby Restaurants',
            content: _buildRestaurantsSection(data),
          ),
          const Divider(height: 24),
          _buildInfoSection(
            icon: Icons.hotel,
            iconColor: Colors.purple,
            title: 'Accommodation',
            content: _buildHotelsSection(data),
          ),
          const Divider(height: 24),
          _buildInfoSection(
            icon: Icons.attractions,
            iconColor: Colors.green,
            title: 'Nearby Attractions',
            content: _buildAttractionsSection(data),
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherSection(_ExpandedSectionData? data) {
    if (data == null || data.isLoading) {
      return _buildLoadingContent('Fetching weather data...');
    }
    
    if (data.error != null || data.weather == null) {
      return _buildErrorContent('Weather data unavailable');
    }
    
    final weather = data.weather!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: weather.alertColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: weather.alertColor.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(weather.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  weather.alertType == AlertType.safe ? 'Great Weather!' : 'Weather Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: weather.alertColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            weather.message,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade700, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRestaurantsSection(_ExpandedSectionData? data) {
    if (data == null || data.isLoading) {
      return _buildLoadingContent('Finding nearby restaurants...');
    }
    
    if (data.error != null) {
      return _buildErrorContent('Could not find restaurants');
    }
    
    final restaurants = data.restaurants ?? [];
    if (restaurants.isEmpty) {
      return _buildEmptyContent('No restaurants found nearby', Icons.restaurant_menu);
    }
    
    return Column(
      children: restaurants.map((restaurant) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: restaurant.isVegetarian ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.restaurant,
                color: restaurant.isVegetarian ? Colors.green : Colors.orange,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          restaurant.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: restaurant.isVegetarian ? Colors.green : Colors.red.shade400,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          restaurant.isVegetarian ? 'VEG' : 'NON-VEG',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${restaurant.cuisine} • ${restaurant.distanceText}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  if (restaurant.rating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber, size: 12),
                        Text(' ${restaurant.rating!.toStringAsFixed(1)}', 
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildHotelsSection(_ExpandedSectionData? data) {
    if (data == null || data.isLoading) {
      return _buildLoadingContent('Finding nearby accommodations...');
    }
    
    if (data.error != null) {
      return _buildErrorContent('Could not find accommodations');
    }
    
    final hotels = data.hotels ?? [];
    if (hotels.isEmpty) {
      return _buildEmptyContent('No accommodations found nearby', Icons.hotel);
    }
    
    return Column(
      children: hotels.map((hotel) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                hotel.type == 'Hostel' ? Icons.business : 
                hotel.type == 'Homestay' ? Icons.home : Icons.hotel,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hotel.name,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          hotel.type,
                          style: TextStyle(fontSize: 9, color: Colors.purple.shade700, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        hotel.distanceText,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (hotel.starRating != null || hotel.estimatedPrice != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (hotel.starRating != null) ...[
                          ...List.generate(hotel.starRating!, (i) => 
                            Icon(Icons.star, color: Colors.amber, size: 12)),
                          const SizedBox(width: 8),
                        ],
                        if (hotel.estimatedPrice != null)
                          Text(
                            '~${hotel.priceText}',
                            style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildAttractionsSection(_ExpandedSectionData? data) {
    if (data == null || data.isLoading) {
      return _buildLoadingContent('Finding nearby attractions...');
    }
    
    if (data.error != null) {
      return _buildErrorContent('Could not find attractions');
    }
    
    final attractions = data.attractions ?? [];
    if (attractions.isEmpty) {
      return _buildEmptyContent('No nearby attractions found', Icons.place);
    }
    
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attractions.map((attraction) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(attraction.icon, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  attraction.name,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                ),
                Text(
                  '${attraction.type} • ${attraction.distanceText}',
                  style: TextStyle(fontSize: 10, color: Colors.green.shade600),
                ),
              ],
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildLoadingContent(String text) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blue.shade400),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorContent(String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.red.shade700, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildEmptyContent(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 20),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildInfoSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required Widget content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 10),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
        const SizedBox(height: 10),
        content,
      ],
    );
  }
}

/// Data class to hold expanded section data for each destination
class _ExpandedSectionData {
  final bool isLoading;
  final bool isLoaded;
  final String? error;
  final WeatherAlert? weather;
  final List<Restaurant>? restaurants;
  final List<Hotel>? hotels;
  final List<Attraction>? attractions;

  _ExpandedSectionData({
    this.isLoading = false,
    this.isLoaded = false,
    this.error,
    this.weather,
    this.restaurants,
    this.hotels,
    this.attractions,
  });
}
