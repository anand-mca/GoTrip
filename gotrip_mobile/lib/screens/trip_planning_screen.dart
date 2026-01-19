import 'package:flutter/material.dart';
import '../services/trip_planner_service.dart';

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
  
  List<String> selectedPreferences = [];
  bool isLoading = false;
  Map<String, dynamic>? tripPlan;
  String? errorMessage;
  
  // City coordinates lookup
  final Map<String, Map<String, dynamic>> _cityCoordinates = {
    'Mumbai': {'lat': 19.0760, 'lng': 72.8777},
    'Delhi': {'lat': 28.6139, 'lng': 77.2090},
    'Bangalore': {'lat': 12.9716, 'lng': 77.5946},
    'Bengaluru': {'lat': 12.9716, 'lng': 77.5946},  // Alternative spelling
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
    'Cochin': {'lat': 9.9312, 'lng': 76.2673},  // Alternative spelling
    'Agra': {'lat': 27.1767, 'lng': 78.0081},
    'Varanasi': {'lat': 25.3176, 'lng': 82.9739},
    'Pondicherry': {'lat': 11.9416, 'lng': 79.8083},
    'Puducherry': {'lat': 11.9416, 'lng': 79.8083},  // Alternative spelling
    'Darjeeling': {'lat': 27.0360, 'lng': 88.2627},
  };

  final List<String> categories = [
    'beach', 'history', 'adventure', 'food', 'shopping', 'nature', 'religious', 'cultural',
  ];

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    _budgetController.dispose();
    _startLocationController.dispose();
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
      controller.text = '${selected.year}-${selected.month.toString().padLeft(2, '0')}-${selected.day.toString().padLeft(2, '0')}';
    }
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
      
      // Format dates to ISO format
      final startDateISO = '${startDate}T00:00:00Z';
      final endDateISO = '${endDate}T23:59:59Z';
      
      // Get coordinates for the start city
      final startCityName = _startLocationController.text.trim().isEmpty 
          ? 'Mumbai' 
          : _startLocationController.text.trim();
      
      final cityCoords = _cityCoordinates[startCityName] ?? _cityCoordinates['Mumbai']!;
      
      final startLocation = {
        'name': startCityName,
        'lat': cityCoords['lat'],
        'lng': cityCoords['lng'],
      };
      
      // Call Supabase-based trip planning service (no external API needed!)
      final tripPlannerService = TripPlannerService();
      final response = await tripPlannerService.planTrip(
        startLocation: startLocation,
        preferences: selectedPreferences,
        budget: budget,
        startDate: startDateISO,
        endDate: endDateISO,
        returnToStart: true,
      );
      
      if (response['success'] == true && response['plan'] != null) {
        final plan = response['plan'];
        
        setState(() {
          tripPlan = {
            'trip_id': 'api_${DateTime.now().millisecondsSinceEpoch}',
            'start_date': startDate,
            'end_date': endDate,
            'budget': budget,
            'preferences': selectedPreferences,
            'duration_days': duration,
            'destinations': plan['destinations'] ?? [],
            'total_cost': plan['total_cost'] ?? 0,
            'total_travel_cost': plan['total_travel_cost'] ?? 0,
            'total_accommodation_cost': plan['total_accommodation_cost'] ?? 0,
            'total_distance_km': plan['total_distance_km'] ?? 0,
            'total_travel_time_hours': plan['total_travel_time_hours'] ?? 0,
            'route_segments': plan['route_segments'] ?? [],
            'daily_itinerary': plan['daily_itinerary'] ?? [],
            'budget_remaining': plan['budget_remaining'] ?? 0,
            'status': 'optimized',
          };
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${response['message']}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        // No destinations found or failed
        setState(() {
          errorMessage = response['message'] ?? 'Could not plan trip with given constraints';
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
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
              Text('Travel Dates', style: Theme.of(context).textTheme.headlineSmall),
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
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
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                      onTap: () => _selectDate(_endDateController),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Budget Section
              Text('Budget (₹)', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your total budget',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Required';
                  if (double.tryParse(value!) == null) return 'Must be a number';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Start Location
              Text('Starting From', style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              TextFormField(
                controller: _startLocationController,
                decoration: InputDecoration(
                  hintText: 'Enter your starting city',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
              ),
              const SizedBox(height: 20),

              // Preferences Section
              Text('What interests you?', style: Theme.of(context).textTheme.headlineSmall),
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
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Plan My Trip 🗺️', style: TextStyle(fontSize: 16)),
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
                          Icon(Icons.check_circle, color: Colors.white, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'Optimized Trip Plan',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white70, height: 24),
                      _buildSummaryRow('📍 Destinations', '${(tripPlan!['destinations'] as List).length}'),
                      _buildSummaryRow('💰 Total Cost', '₹${tripPlan!['total_cost'].toStringAsFixed(0)}'),
                      _buildSummaryRow('🚗 Travel Cost', '₹${tripPlan!['total_travel_cost'].toStringAsFixed(0)}'),
                      _buildSummaryRow('🏨 Stay Cost', '₹${tripPlan!['total_accommodation_cost'].toStringAsFixed(0)}'),
                      _buildSummaryRow('📏 Total Distance', '${tripPlan!['total_distance_km'].toStringAsFixed(1)} km'),
                      _buildSummaryRow('⏱️ Travel Time', '${tripPlan!['total_travel_time_hours'].toStringAsFixed(1)} hrs'),
                      _buildSummaryRow('💵 Budget Left', '₹${tripPlan!['budget_remaining'].toStringAsFixed(0)}'),
                      _buildSummaryRow('📅 Duration', '${tripPlan!['duration_days']} days'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Route Visualization
                if ((tripPlan!['route_segments'] as List).isNotEmpty) ...[
                  const Text(
                    '🗺️ Your Optimized Route',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...((tripPlan!['route_segments'] as List).asMap().entries.map((entry) {
                    final index = entry.key;
                    final segment = entry.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.blue.withOpacity(0.05),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${segment['from']} → ${segment['to']}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '📏 ${segment['distance_km'].toStringAsFixed(1)} km  |  ⏱️ ${segment['travel_time_hours'].toStringAsFixed(1)} hrs  |  💰 ₹${segment['travel_cost'].toStringAsFixed(0)}',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList()),
                  const SizedBox(height: 24),
                ],

                // Daily Itinerary
                if ((tripPlan!['daily_itinerary'] as List).isNotEmpty) ...[
                  const Text(
                    '📅 Day-by-Day Itinerary',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ...((tripPlan!['daily_itinerary'] as List).map((day) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.purple.withOpacity(0.05),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Day ${day['day']}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.purple),
                              ),
                              Text(
                              day['date'].toString().split('T')[0],
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Display destinations for the day
                          if (day['destinations'] != null && (day['destinations'] as List).isNotEmpty) ...[
                            ...(day['destinations'] as List).map((dest) {
                              // Destination is now a Map with full details
                              final destMap = dest as Map<String, dynamic>;
                              final destName = destMap['name'] ?? 'Unknown';
                              final destCity = destMap['city'] ?? '';
                              final rating = destMap['rating']?.toString() ?? 'N/A';
                              final categories = destMap['categories'] as List?;
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(color: Colors.purple.withOpacity(0.2)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.place, size: 16, color: Colors.purple),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            destName,
                                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        if (rating != 'N/A')
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.amber.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.star, size: 12, color: Colors.amber),
                                                const SizedBox(width: 2),
                                                Text(rating, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    if (destCity.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Text('🏙️ $destCity', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                                    ],
                                    if (categories != null && categories.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: categories.take(3).map((cat) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              cat.toString(),
                                              style: const TextStyle(fontSize: 10, color: Colors.blue),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                          if (day['cities'] != null && (day['cities'] as List).isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              '🏙️ ${(day['cities'] as List).join(', ')}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            '🏨 Accommodation: ₹1500/night',
                            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                          ),
                          if (day['travel_from_previous'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              '🚗 Travel: ${day['travel_from_previous']['distance_km'].toStringAsFixed(1)} km (₹${day['travel_from_previous']['travel_cost'].toStringAsFixed(0)})',
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList()),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 14)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
