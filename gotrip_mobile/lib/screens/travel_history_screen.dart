import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/journey_service.dart';
import '../providers/theme_provider.dart';

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
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Travel History', style: TextStyle(color: textOnPrimary, fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: textColor.withOpacity(0.4)),
                      const SizedBox(height: 16),
                      Text('Error loading history', style: TextStyle(color: textColor.withOpacity(0.6))),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _loadTripHistory,
                        style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                        child: Text('Retry', style: TextStyle(color: textOnPrimary)),
                      ),
                    ],
                  ),
                )
              : _tripHistory.isEmpty
                  ? _buildEmptyState(primaryColor, textOnPrimary, textColor)
                  : _buildHistoryList(primaryColor, textOnPrimary, textColor),
    );
  }

  Widget _buildEmptyState(Color primaryColor, Color textOnPrimary, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.history,
              size: 80,
              color: primaryColor.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Travel Memories Yet',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: textColor,
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
                color: textColor.withOpacity(0.5),
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
              backgroundColor: primaryColor,
              foregroundColor: textOnPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(Color primaryColor, Color textOnPrimary, Color textColor) {
    return RefreshIndicator(
      onRefresh: _loadTripHistory,
      color: primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _tripHistory.length,
        itemBuilder: (context, index) {
          final trip = _tripHistory[index];
          return _buildTripCard(trip, primaryColor, textOnPrimary, textColor);
        },
      ),
    );
  }

  Widget _buildTripCard(Map<String, dynamic> trip, Color primaryColor, Color textOnPrimary, Color textColor) {
    final themeProvider = context.watch<ThemeProvider>();
    final surfaceColor = themeProvider.surfaceColor;
    
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
      color: surfaceColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => _showTripDetails(trip),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with solid color
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryColor,
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
                      color: textOnPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.flight_takeoff, color: textOnPrimary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tripName,
                          style: TextStyle(
                            color: textOnPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          startCity,
                          style: TextStyle(
                            color: textOnPrimary.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: textOnPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${tripDays.length} days',
                      style: TextStyle(
                        color: textOnPrimary,
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
                      _buildDetailChip(Icons.calendar_today, '$startDate to $endDate', textColor, surfaceColor),
                      const SizedBox(width: 12),
                      _buildDetailChip(Icons.place, '$visitedCount/$totalDestinations visited', textColor, surfaceColor),
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
                          color: textColor,
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
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                name,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textColor,
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
                        style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.5)),
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
                        foregroundColor: primaryColor,
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

  Widget _buildDetailChip(IconData icon, String text, Color textColor, Color surfaceColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor.withOpacity(0.6)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: textColor.withOpacity(0.6)),
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
    final themeProvider = context.read<ThemeProvider>();
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final primaryColor = themeProvider.primaryColor;
    
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
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: const BorderRadius.only(
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
                  color: textColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Icon(Icons.history, color: primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        trip['trip_name'] ?? 'Trip Details',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: textColor),
                    ),
                  ],
                ),
              ),
              
              Divider(height: 1, color: textColor.withOpacity(0.2)),
              
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
    final themeProvider = context.watch<ThemeProvider>();
    final surfaceColor = themeProvider.surfaceColor;
    final textColor = themeProvider.textColor;
    final primaryColor = themeProvider.primaryColor;
    
    final dayNumber = day['day_number'] ?? 0;
    final destinations = day['trip_destinations'] as List? ?? [];
    destinations.sort((a, b) => (a['visit_order'] ?? 0).compareTo(b['visit_order'] ?? 0));

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: surfaceColor,
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
                    color: primaryColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Day $dayNumber',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
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
                      color: isVisited ? Colors.green : textColor.withOpacity(0.4),
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
                              color: isVisited ? textColor.withOpacity(0.6) : textColor,
                            ),
                          ),
                          Text(
                            '${dest['city'] ?? ''}, ${dest['state'] ?? ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: textColor.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isVisited)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Visited',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.green,
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
