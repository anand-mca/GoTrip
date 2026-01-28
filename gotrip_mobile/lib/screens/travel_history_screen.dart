import 'package:flutter/material.dart';
import '../services/journey_service.dart';

class TravelHistoryScreen extends StatefulWidget {
  const TravelHistoryScreen({Key? key}) : super(key: key);

  @override
  State<TravelHistoryScreen> createState() => _TravelHistoryScreenState();
}

class _TravelHistoryScreenState extends State<TravelHistoryScreen> {
  final JourneyService _journeyService = JourneyService();
  
  List<Map<String, dynamic>> _tripHistory = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTripHistory();
  }

  Future<void> _loadTripHistory() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final history = await _journeyService.getTripHistory();
      setState(() {
        _tripHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Travel History'),
        elevation: 0,
        backgroundColor: Colors.purple.shade600,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      Text('Error loading history', style: TextStyle(color: Colors.grey.shade600)),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadTripHistory,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _tripHistory.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.purple.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 80,
              color: Colors.purple.shade300,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Travel Memories Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Complete your first journey and your memories will appear here! ✨',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushNamed(context, '/plan-trip');
            },
            icon: const Icon(Icons.explore),
            label: const Text('Plan Your First Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList() {
    return RefreshIndicator(
      onRefresh: _loadTripHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tripHistory.length,
        itemBuilder: (context, index) {
          final trip = _tripHistory[index];
          return _buildTripCard(trip);
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip) {
    final tripDays = trip['trip_days'] as List? ?? [];
    final tripName = trip['trip_name'] ?? 'Trip';
    final startDate = trip['start_date'] ?? '';
    final endDate = trip['end_date'] ?? '';
    final startCity = trip['start_city'] ?? '';
    
    // Calculate visited count
    int totalDestinations = 0;
    int visitedCount = 0;
    
    for (var day in tripDays) {
      final destinations = day['trip_destinations'] as List? ?? [];
      totalDestinations += destinations.length;
      for (var dest in destinations) {
        if (dest['is_visited'] == true) {
          visitedCount++;
        }
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.blue.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.flight_takeoff, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          startCity,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tripDays.length} days',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Trip details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildDetailChip(Icons.calendar_today, '$startDate to $endDate'),
                      const SizedBox(width: 12),
                      _buildDetailChip(Icons.place, '$visitedCount/$totalDestinations visited'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Visited destinations preview
                  if (visitedCount > 0) ...[
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Places Visited:',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _getVisitedDestinations(tripDays).take(5).map((name) {
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
                              Icon(Icons.check_circle, size: 14, color: Colors.green.shade600),
                              const SizedBox(width: 4),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    if (_getVisitedDestinations(tripDays).length > 5) ...[
                      const SizedBox(height: 8),
                      Text(
                        '+${_getVisitedDestinations(tripDays).length - 5} more places',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ],
                  
                  const SizedBox(height: 12),
                  
                  // View details button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _showTripDetails(trip),
                      icon: const Icon(Icons.visibility),
                      label: const Text('View Full Journey'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.purple.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  List<String> _getVisitedDestinations(List tripDays) {
    final visited = <String>[];
    for (var day in tripDays) {
      final destinations = day['trip_destinations'] as List? ?? [];
      for (var dest in destinations) {
        if (dest['is_visited'] == true) {
          visited.add(dest['destination_name'] ?? 'Unknown');
        }
      }
    }
    return visited;
  }

  void _showTripDetails(Map<String, dynamic> trip) {
    final tripDays = trip['trip_days'] as List? ?? [];
    tripDays.sort((a, b) => (a['day_number'] ?? 0).compareTo(b['day_number'] ?? 0));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.history, color: Colors.purple.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trip['trip_name'] ?? 'Trip Details',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              // Trip days
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: tripDays.length,
                  itemBuilder: (context, index) {
                    final day = tripDays[index];
                    return _buildDayCard(day);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(Map<String, dynamic> day) {
    final dayNumber = day['day_number'] ?? 0;
    final destinations = day['trip_destinations'] as List? ?? [];
    destinations.sort((a, b) => (a['visit_order'] ?? 0).compareTo(b['visit_order'] ?? 0));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day $dayNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            ...destinations.map((dest) {
              final isVisited = dest['is_visited'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(
                      isVisited ? Icons.check_circle : Icons.radio_button_unchecked,
                      color: isVisited ? Colors.green : Colors.grey.shade400,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dest['destination_name'] ?? 'Unknown',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              decoration: isVisited ? TextDecoration.lineThrough : null,
                              color: isVisited ? Colors.grey.shade600 : Colors.black87,
                            ),
                          ),
                          Text(
                            '${dest['city'] ?? ''}, ${dest['state'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isVisited)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Visited',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
