import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/trip_planner_service.dart';
import '../services/journey_service.dart';
import '../services/groq_service.dart';
import '../providers/destination_provider.dart';
import '../providers/theme_provider.dart';
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
  bool _isGeocodingCity = false;

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

      // Get city name from input
      final cityName = _startLocationController.text.trim();

      if (cityName.isEmpty) {
        throw Exception(
            'Please enter a city name (e.g., "Goa", "Mumbai", "Delhi", "Coorg")');
      }

      print('Planning trip for city: $cityName');
      print('Preferences: $selectedPreferences');
      print('Budget: $budget');
      print('Duration: $duration days');

      // Geocode city using Groq AI — works for ANY Indian city
      setState(() { _isGeocodingCity = true; });
      final coordsRaw = await GroqService.getCityCoordinates(cityName);
      setState(() { _isGeocodingCity = false; });

      if (coordsRaw == null) {
        throw Exception(
            'Could not find coordinates for "$cityName". Please check the city name and try again.');
      }

      final coordinates = <String, dynamic>{
        'lat': coordsRaw['lat'],
        'lng': coordsRaw['lng'],
      };
      final normalizedCityName = cityName;

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
        _isGeocodingCity = false;
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
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final surfaceColor = themeProvider.surfaceColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Plan Your Smart Trip', style: TextStyle(color: textOnPrimary, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dates Section
              Text('Travel Dates',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _startDateController,
                      readOnly: true,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Start Date',
                        suffixIcon: Icon(Icons.calendar_today, color: primaryColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor)),
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
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'End Date',
                        suffixIcon: Icon(Icons.calendar_today, color: primaryColor),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: primaryColor)),
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter your total budget',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor)),
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
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: textColor)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startLocationController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter your starting city',
                  prefixIcon: Icon(Icons.location_on, color: primaryColor),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: primaryColor)),
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
                  onPressed: (isLoading || _isGeocodingCity) ? null : _planTrip,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: (isLoading || _isGeocodingCity)
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                            const SizedBox(width: 12),
                            Text(
                              _isGeocodingCity
                                  ? 'Finding city coordinates...'
                                  : 'Planning your trip...',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ],
                        )
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
                    color: primaryColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle,
                              color: textOnPrimary, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            'Optimized Trip Plan',
                            style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textOnPrimary),
                          ),
                        ],
                      ),
                      Divider(color: textOnPrimary.withOpacity(0.5), height: 24),
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
                Text('📋 Your Itinerary',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor)),
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
                      color: surfaceColor,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: textColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('🤖 Trip Planning Algorithm',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                        const SizedBox(height: 8),
                        Text(tripPlan!['algorithm_explanation'] ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: textColor.withOpacity(0.7),
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
    final themeProvider = context.watch<ThemeProvider>();
    final surfaceColor = themeProvider.surfaceColor;
    final textColor = themeProvider.textColor;
    final primaryColor = themeProvider.primaryColor;
    
    final dailyItineraries = tripPlan!['daily_itineraries'] as List? ?? [];
    if (dailyItineraries.isEmpty) {
      return [Text('No itineraries available', style: TextStyle(color: textColor))];
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
          border: Border.all(color: primaryColor.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
          color: surfaceColor,
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
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                ),
                Text(
                  'Distance: ${distance.toStringAsFixed(1)} km',
                  style: TextStyle(
                      fontSize: 12,
                      color: textColor.withOpacity(0.7),
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
                      color: primaryColor,
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
                    color: textColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: primaryColor.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on,
                              size: 14, color: primaryColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  placeData['name'] ?? 'Unknown',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: textColor),
                                ),
                                if (placeData['city'] != null ||
                                    placeData['state'] != null)
                                  Text(
                                    '📍 ${[
                                      placeData['city'],
                                      placeData['state']
                                    ].where((e) => e != null).join(', ')}',
                                    style: TextStyle(
                                        fontSize: 10, color: textColor.withOpacity(0.6)),
                                  ),
                                if (placeData['category'] != null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: primaryColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        '🏷️ ${placeData['category']}',
                                        style: TextStyle(
                                            fontSize: 9, color: primaryColor),
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
                                fontSize: 10, color: textColor.withOpacity(0.6)),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          distanceFromPrevious,
                          style: TextStyle(
                              fontSize: 9,
                              color: primaryColor,
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
                                color: Colors.green),
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
                      Icon(Icons.add_circle, color: primaryColor, size: 20),
                  label: Text(
                    'Add Destination',
                    style: TextStyle(color: primaryColor, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildDestinationSearchField(int dayIndex) {
    final themeProvider = context.watch<ThemeProvider>();
    final surfaceColor = themeProvider.surfaceColor;
    final textColor = themeProvider.textColor;
    final primaryColor = themeProvider.primaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    
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
                      hintStyle: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
                      prefixIcon: Icon(Icons.search, size: 18, color: textColor.withOpacity(0.5)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: textColor.withOpacity(0.2)),
                      ),
                      filled: true,
                      fillColor: surfaceColor,
                    ),
                    style: TextStyle(fontSize: 12, color: textColor),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close, color: textColor.withOpacity(0.6)),
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
                  color: surfaceColor,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: textColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: filteredDestinations.map((destination) {
                    final isFavorite = provider.isFavorite(destination.id);
                    return ListTile(
                      dense: true,
                      leading: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on,
                              size: 18, color: primaryColor),
                          if (isFavorite)
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Icon(Icons.favorite,
                                  size: 14, color: Colors.red),
                            ),
                        ],
                      ),
                      title: Text(destination.title,
                          style: TextStyle(fontSize: 12, color: textColor)),
                      subtitle: Text(destination.location,
                          style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6))),
                      trailing: Text('₹${destination.price.toStringAsFixed(0)}',
                          style: TextStyle(
                              fontSize: 10, color: Colors.green)),
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
