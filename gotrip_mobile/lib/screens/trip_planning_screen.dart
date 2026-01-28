import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/trip_planner_service.dart';
import '../services/journey_service.dart';
import '../providers/destination_provider.dart';
import '../models/destination_model.dart';
import 'journey_tracking_screen.dart';

class TripPlanningScreen extends StatefulWidget {
  const TripPlanningScreen({Key? key}) : super(key: key);

  @override
  State<TripPlanningScreen> createState() => _TripPlanningScreenState();
}

class _TripPlanningScreenState extends State<TripPlanningScreen> {
  final _formKey = GlobalKey<FormState>();
  final _startDateController = TextEditingController();
  final _endDateController = TextEditingController();
  final _budgetController = TextEditingController();
  final _startLocationController = TextEditingController(text: 'Mumbai');
  final JourneyService _journeyService = JourneyService();

  List<String> selectedPreferences = [];
  bool isLoading = false;
  bool _isStartingJourney = false;
  Map<String, dynamic>? tripPlan;
  String? errorMessage;

  // For adding destinations
  bool _isSearching = false;
  int? _searchingDayIndex;
  final _destinationSearchController = TextEditingController();

  // City coordinates lookup
  final Map<String, Map<String, dynamic>> _cityCoordinates = {
    'Mumbai': {'lat': 19.0760, 'lng': 72.8777},
    'Delhi': {'lat': 28.6139, 'lng': 77.2090},
    'Bangalore': {'lat': 12.9716, 'lng': 77.5946},
    'Bengaluru': {'lat': 12.9716, 'lng': 77.5946}, // Alternative spelling
    'Kolkata': {'lat': 22.5726, 'lng': 88.3639},
    'Chennai': {'lat': 13.0827, 'lng': 80.2707},
    'Hyderabad': {'lat': 17.3850, 'lng': 78.4867},
    'Pune': {'lat': 18.5204, 'lng': 73.8567},
    'Ahmedabad': {'lat': 23.0225, 'lng': 72.5714},
    'Jaipur': {'lat': 26.9124, 'lng': 75.7873},
    'Goa': {'lat': 15.2993, 'lng': 74.1240},
    'Munnar': {'lat': 10.0889, 'lng': 77.0595},
    'Manali': {'lat': 32.2432, 'lng': 77.1892},
    'Shimla': {'lat': 31.1048, 'lng': 77.1734},
    'Rishikesh': {'lat': 30.0869, 'lng': 78.2676},
    'Udaipur': {'lat': 24.5854, 'lng': 73.7125},
    'Kochi': {'lat': 9.9312, 'lng': 76.2673},
    'Cochin': {'lat': 9.9312, 'lng': 76.2673}, // Alternative spelling
    'Agra': {'lat': 27.1767, 'lng': 78.0081},
    'Varanasi': {'lat': 25.3176, 'lng': 82.9739},
    'Pondicherry': {'lat': 11.9416, 'lng': 79.8083},
    'Puducherry': {'lat': 11.9416, 'lng': 79.8083}, // Alternative spelling
    'Darjeeling': {'lat': 27.0360, 'lng': 88.2627},
  };

  final List<String> categories = [
    'beach',
    'history',
    'adventure',
    'food',
    'shopping',
    'nature',
    'religious',
    'cultural',
  ];

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _budgetController.dispose();
    _startLocationController.dispose();
    _destinationSearchController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (selected != null) {
      controller.text =
          '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    }
  }

  // Calculate total cost from all destinations in itinerary
  double _calculateTotalCost() {
    if (tripPlan == null) return 0;
    
    double totalCost = 0;
    final dailyItineraries = tripPlan!['daily_itineraries'] as List? ?? [];
    
    for (var day in dailyItineraries) {
      final destinations = day['destinations'] as List? ?? [];
      for (var destination in destinations) {
        if (destination is Map<String, dynamic>) {
          totalCost += (destination['estimated_cost'] ?? 0).toDouble();
        }
      }
    }
    
    return totalCost;
  }

  // Get the display cost - use calculated cost if total_cost is 0
  double _getDisplayCost() {
    if (tripPlan == null) return 0;
    
    final storedCost = (tripPlan!['total_cost'] ?? 0).toDouble();
    if (storedCost > 0) {
      return storedCost;
    }
    
    // If stored cost is 0, calculate from destinations
    return _calculateTotalCost();
  }

  Future<void> _planTrip() async {
    if (!_formKey.currentState!.validate()) return;
    if (selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one preference')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final startDate = _startDateController.text;
      final endDate = _endDateController.text;
      final budget = double.parse(_budgetController.text);

      // Validate dates
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final duration = end.difference(start).inDays + 1;

      if (duration < 1) {
        throw Exception('End date must be after start date');
      }

      // Get city name from input (no defaults to hardcoded coordinates)
      final cityName = _startLocationController.text.trim();

      if (cityName.isEmpty) {
        throw Exception(
            'Please enter a city name (e.g., "Goa", "Mumbai", "Delhi")');
      }

      // Call TripPlannerService with Supabase
      print('Planning trip for city: $cityName');
      print('Preferences: $selectedPreferences');
      print('Budget: $budget');
      print('Duration: $duration days');

      // Get city coordinates (case-insensitive)
      final normalizedCityName = cityName.trim();
      final coordinates = _cityCoordinates[normalizedCityName] ??
          _cityCoordinates[_cityCoordinates.keys.firstWhere(
            (key) => key.toLowerCase() == normalizedCityName.toLowerCase(),
            orElse: () => '',
          )];

      if (coordinates == null) {
        throw Exception(
            'City "$normalizedCityName" not found. Try: Mumbai, Delhi, Bangalore, Goa, etc.');
      }

      final tripPlannerService = TripPlannerService();
      final response = await tripPlannerService.planTrip(
        startLocation: {
          'name': normalizedCityName,
          'lat': coordinates['lat'],
          'lng': coordinates['lng'],
        },
        preferences: selectedPreferences,
        budget: budget,
        startDate: startDate,
        endDate: endDate,
        returnToStart: true,
      );

      print('Trip planning response: ${response['message']}');

      if (response['success'] == true && response['plan'] != null) {
        final plan = response['plan'];

        setState(() {
          tripPlan = {
            'trip_id': 'trip_${DateTime.now().millisecondsSinceEpoch}',
            'start_date': startDate,
            'end_date': endDate,
            'budget': budget,
            'preferences': selectedPreferences,
            'city_name': cityName,
            'duration_days': duration,
            'destinations': plan['destinations'] ?? [],
            'total_distance_km': plan['total_distance_km'] ?? 0,
            'total_cost': plan['total_cost'] ?? 0,
            'daily_itineraries': plan['daily_itinerary'] ?? [],
            'route': plan['route_segments'] ?? [],
            'status': 'optimized',
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Trip planned: ${(plan['destinations'] as List?)?.length ?? 0} destinations!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        throw Exception(response['message'] ?? 'Could not plan trip');
      }
    } catch (e) {
      final errorMsg = e.toString();
      setState(() {
        errorMessage = errorMsg;
      });

      print('Error during trip planning: $errorMsg');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error: $errorMsg'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _startJourney() async {
    if (tripPlan == null) return;

    setState(() => _isStartingJourney = true);

    try {
      // Check for existing active trip first
      final existingTrip = await _journeyService.getActiveTrip();
      if (existingTrip != null) {
        if (mounted) {
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
                            existingTrip['trip_name'] ?? 'Your Trip',
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
                    'Please end your current journey before starting a new trip.',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
        return;
      }

      // Save trip to database
      final savedTrip = await _journeyService.startJourney(tripPlan!);

      if (savedTrip != null && mounted) {
        // Convert to app format and navigate
        final formattedTrip = _journeyService.convertDbTripToAppFormat(savedTrip);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('🚀 Journey started! Enjoy your trip!'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => JourneyTrackingScreen(
              tripPlan: formattedTrip,
              fromDatabase: true,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting journey: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isStartingJourney = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plan Your Smart Trip'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dates Section
              Text('Travel Dates',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'Start Date',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                      onTap: () => _selectDate(_startDateController),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _endDateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        hintText: 'End Date',
                        suffixIcon: const Icon(Icons.calendar_today),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) =>
                          value?.isEmpty ?? true ? 'Required' : null,
                      onTap: () => _selectDate(_endDateController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Budget Section
              Text('Budget (₹)',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your total budget',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null)
                    return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Start Location
              Text('Based City',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startLocationController,
                decoration: InputDecoration(
                  hintText: 'Enter your starting city',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Preferences Section
              Text('What interests you?',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: categories.map((category) {
                  final isSelected = selectedPreferences.contains(category);
                  return FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          selectedPreferences.add(category);
                        } else {
                          selectedPreferences.remove(category);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Plan Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _planTrip,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Plan My Trip 🗺️',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 20),

              // Error Message
              if (errorMessage != null && tripPlan == null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: Colors.orange),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: const TextStyle(color: Colors.orange),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Results Section
              if (tripPlan != null) ...[
                // Trip Summary Card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade400, Colors.purple.shade400],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Optimized Trip Plan',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white70, height: 24),
                      _buildSummaryRow(
                          '📍 Starting City', '${tripPlan!['city_name']}'),
                      _buildSummaryRow(
                          '📅 Duration', '${tripPlan!['duration_days']} days'),
                      _buildSummaryRow('💰 Total Budget',
                          '₹${tripPlan!['budget'].toStringAsFixed(0)}'),
                      _buildSummaryRow('💸 Estimated Cost',
                          '₹${_getDisplayCost().toStringAsFixed(0)}'),
                      _buildSummaryRow('📏 Total Distance',
                          '${(tripPlan!['total_distance_km'] as num).toStringAsFixed(1)} km'),
                      _buildSummaryRow('🎯 Preferences',
                          (tripPlan!['preferences'] as List).join(', ')),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Daily Itineraries Section
                const Text('📋 Your Itinerary',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                ..._buildDailyItineraries(),

                const SizedBox(height: 24),

                // Start Journey Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isStartingJourney ? null : _startJourney,
                    icon: _isStartingJourney 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.play_arrow, color: Colors.white),
                    label: Text(
                      _isStartingJourney ? 'Starting...' : 'Start Journey 🚀',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Algorithm Explanation
                if (tripPlan!['algorithm_explanation'] != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('🤖 Trip Planning Algorithm',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 8),
                        Text(tripPlan!['algorithm_explanation'] ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                height: 1.5)),
                      ],
                    ),
                  ),
                ],
              ]
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDailyItineraries() {
    final dailyItineraries = tripPlan!['daily_itineraries'] as List? ?? [];
    if (dailyItineraries.isEmpty) {
      return [const Text('No itineraries available')];
    }

    return dailyItineraries.asMap().entries.map<Widget>((entry) {
      final dayIndex = entry.key;
      final dayData = entry.value;
      final day = dayData['day'] ?? (dayIndex + 1);
      final places = (dayData['destinations'] as List? ?? []);
      final distance = (dayData['total_distance'] ?? 0) as num;
      final budget = (dayData['estimated_budget'] ?? 0) as num;

      // Calculate total day budget from destinations
      double dayTotalBudget = 0;
      for (var place in places) {
        if (place is Map<String, dynamic>) {
          dayTotalBudget +=
              (place['estimated_cost'] ?? place['cost_per_day'] ?? 0)
                  .toDouble();
        }
      }
      // Use calculated budget if the provided one is 0
      final displayBudget = budget > 0 ? budget : dayTotalBudget;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: Colors.blue.withOpacity(0.05),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Day Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Day $day',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  'Distance: ${distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
            if (displayBudget > 0)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Budget: ₹${displayBudget.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange[700],
                      fontWeight: FontWeight.w500),
                ),
              ),
            const SizedBox(height: 10),

            // Destinations list
            ...places.asMap().entries.map((placeEntry) {
              final placeIndex = placeEntry.key;
              final placeData = placeEntry.value as Map<String, dynamic>?;
              if (placeData == null) return const SizedBox.shrink();

              // Calculate distance from previous place (for display)
              final distanceFromPrevious = placeIndex > 0
                  ? 'Travel distance: ~${((distance) / places.length).toStringAsFixed(1)} km'
                  : 'Starting point';
              final cost =
                  placeData['estimated_cost'] ?? placeData['cost_per_day'] ?? 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on,
                              size: 14, color: Colors.blue),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeData['name'] ?? 'Unknown',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                                if (placeData['city'] != null ||
                                    placeData['state'] != null)
                                  Text(
                                    '📍 ${[
                                      placeData['city'],
                                      placeData['state']
                                    ].where((e) => e != null).join(', ')}',
                                    style: TextStyle(
                                        fontSize: 10, color: Colors.grey[600]),
                                  ),
                                if (placeData['category'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '🏷️ ${placeData['category']}',
                                        style: const TextStyle(
                                            fontSize: 9, color: Colors.blue),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          // Delete button
                          IconButton(
                            icon: Icon(Icons.remove_circle,
                                color: Colors.red[400], size: 22),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () =>
                                _removeDestination(dayIndex, placeIndex),
                            tooltip: 'Remove destination',
                          ),
                        ],
                      ),
                      if (placeData['description'] != null &&
                          (placeData['description'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            placeData['description'] ?? '',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 10, color: Colors.grey[600]),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          distanceFromPrevious,
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic),
                        ),
                      ),
                      if (cost > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            '💰 ₹${cost.toString()}',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.green[700]),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),

            // Add destination button or search field
            if (_isSearching && _searchingDayIndex == dayIndex)
              _buildDestinationSearchField(dayIndex)
            else
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _isSearching = true;
                      _searchingDayIndex = dayIndex;
                      _destinationSearchController.clear();
                    });
                  },
                  icon:
                      Icon(Icons.add_circle, color: Colors.blue[600], size: 20),
                  label: Text(
                    'Add Destination',
                    style: TextStyle(color: Colors.blue[600], fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDestinationSearchField(int dayIndex) {
    return Consumer<DestinationProvider>(
      builder: (context, provider, _) {
        final searchText = _destinationSearchController.text.toLowerCase();
        final filteredDestinations = searchText.isEmpty
            ? <Destination>[]
            : provider.destinations
                .where((d) =>
                    d.title.toLowerCase().contains(searchText) ||
                    d.location.toLowerCase().contains(searchText))
                .take(5)
                .toList();

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _destinationSearchController,
                    decoration: InputDecoration(
                      hintText: 'Search destination...',
                      hintStyle: const TextStyle(fontSize: 12),
                      prefixIcon: const Icon(Icons.search, size: 18),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    style: const TextStyle(fontSize: 12),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _isSearching = false;
                      _searchingDayIndex = null;
                      _destinationSearchController.clear();
                    });
                  },
                ),
              ],
            ),
            if (filteredDestinations.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: filteredDestinations.map((destination) {
                    return ListTile(
                      dense: true,
                      leading: const Icon(Icons.location_on,
                          size: 18, color: Colors.blue),
                      title: Text(destination.title,
                          style: const TextStyle(fontSize: 12)),
                      subtitle: Text(destination.location,
                          style: const TextStyle(fontSize: 10)),
                      trailing: Text('₹${destination.price.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green[700])),
                      onTap: () => _addDestination(dayIndex, destination),
                    );
                  }).toList(),
                ),
              ),
          ],
        );
      },
    );
  }

  void _addDestination(int dayIndex, Destination destination) {
    setState(() {
      final dailyItineraries = tripPlan!['daily_itineraries'] as List;
      final places = List<Map<String, dynamic>>.from(
          dailyItineraries[dayIndex]['destinations'] as List? ?? []);

      // Get the current total cost before adding
      double currentTotalCost = _getDisplayCost();
      
      places.add({
        'id': destination.id,
        'name': destination.title,
        'city': destination.location.split(',').first.trim(),
        'state': destination.location.split(',').length > 1
            ? destination.location.split(',').last.trim()
            : '',
        'category': destination.category,
        'description': destination.description,
        'estimated_cost': destination.price, // This will be the entry fee
        'latitude': destination.latitude,
        'longitude': destination.longitude,
        'rating': destination.rating,
      });

      dailyItineraries[dayIndex]['destinations'] = places;

      // Add the destination's cost to current total
      tripPlan!['total_cost'] = currentTotalCost + destination.price;

      _isSearching = false;
      _searchingDayIndex = null;
      _destinationSearchController.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${destination.title} to Day ${dayIndex + 1} (+₹${destination.price.toStringAsFixed(0)})'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _removeDestination(int dayIndex, int placeIndex) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Destination'),
        content: const Text(
            'Are you sure you want to remove this destination from your itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              
              // Get the removed place's cost before removing it
              final dailyItineraries = tripPlan!['daily_itineraries'] as List;
              final places = List<Map<String, dynamic>>.from(
                  dailyItineraries[dayIndex]['destinations'] as List? ?? []);
              final removedPlace = places[placeIndex];
              double removedCost = (removedPlace['estimated_cost'] ?? 0).toDouble();
              
              setState(() {
                places.removeAt(placeIndex);
                dailyItineraries[dayIndex]['destinations'] = places;

                // Get current stored cost and subtract the removed cost
                double currentStoredCost = (tripPlan!['total_cost'] ?? 0).toDouble();
                tripPlan!['total_cost'] = (currentStoredCost - removedCost).clamp(0, double.infinity);
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Destination removed (-₹${removedCost.toStringAsFixed(0)})'),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
