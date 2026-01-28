import 'package:flutter/material.dart';
import '../services/journey_service.dart';

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
  
  // Track visited destinations - Map<dayIndex, Set<destinationIndex>>
  Map<int, Set<int>> visitedDestinations = {};
  // Track which destination is currently expanded
  int? expandedDayIndex;
  int? expandedDestinationIndex;
  
  // Store destination IDs from database for updating
  Map<int, Map<int, String>> destinationDbIds = {}; // dayIndex -> destIndex -> dbId
  
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
                      secondChild: _buildExpandedSection(place),
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

  Widget _buildExpandedSection(Map<String, dynamic> place) {
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
            content: _buildPlaceholderContent('Weather information will be displayed here', Icons.wb_sunny),
          ),
          const Divider(height: 24),
          _buildInfoSection(
            icon: Icons.restaurant,
            iconColor: Colors.orange,
            title: 'Nearby Restaurants',
            content: _buildPlaceholderContent('Restaurant recommendations will appear here', Icons.restaurant_menu),
          ),
          const Divider(height: 24),
          _buildInfoSection(
            icon: Icons.hotel,
            iconColor: Colors.purple,
            title: 'Accommodation',
            content: _buildPlaceholderContent('Nearby hotels and rooms will be shown here', Icons.bed),
          ),
          const Divider(height: 24),
          _buildInfoSection(
            icon: Icons.attractions,
            iconColor: Colors.green,
            title: 'Nearby Attractions',
            content: _buildNearbyAttractions(place),
          ),
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
                color: iconColor.withValues(alpha: 0.1),
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

  Widget _buildPlaceholderContent(String text, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey.shade400, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Coming Soon',
              style: TextStyle(color: Colors.blue.shade700, fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyAttractions(Map<String, dynamic> place) {
    final attractions = place['nearby_attractions'];

    if (attractions == null || (attractions is List && attractions.isEmpty)) {
      return _buildPlaceholderContent('Nearby attractions will be displayed here', Icons.place);
    }

    List<String> attractionList = [];
    if (attractions is List) {
      attractionList = attractions.map((e) => e.toString()).toList();
    } else if (attractions is String) {
      attractionList = attractions.split(',').map((e) => e.trim()).toList();
    }

    if (attractionList.isEmpty) {
      return _buildPlaceholderContent('Nearby attractions will be displayed here', Icons.place);
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: attractionList.take(5).map((attraction) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.green.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.place, size: 14, color: Colors.green.shade700),
              const SizedBox(width: 4),
              Text(
                attraction,
                style: TextStyle(fontSize: 11, color: Colors.green.shade800),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
