"""
Integration Guide: Connecting Flutter Frontend to Trip Planning Backend
"""

# STEP 1: Backend Setup

## Prerequisites
- Python 3.8+
- Backend running on http://localhost:8000

## Steps
1. Navigate to backend directory
2. Create virtual environment
3. Install dependencies: pip install -r requirements.txt
4. Run: python -m uvicorn app.main:app --reload

# STEP 2: Flutter Integration

## Update Supabase Service (Optional)
# You can keep using Supabase for authentication and destination data
# The backend operates independently

## Create Trip Planning Service in Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class TripPlanningService {
  static const String baseUrl = 'http://localhost:8000';
  
  // For web debugging, use: http://localhost:8000
  // For Android emulator, use: http://10.0.2.2:8000
  // For actual device, use your machine's IP: http://192.168.x.x:8000
  
  Future<TripItinerary> planTrip({
    required DateTime startDate,
    required DateTime endDate,
    required double budget,
    required List<String> preferences,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/plan-trip'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start_date': startDate.toIso8601String().split('T')[0],
          'end_date': endDate.toIso8601String().split('T')[0],
          'budget': budget,
          'preferences': preferences,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );
      
      if (response.statusCode == 200) {
        return TripItinerary.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to plan trip');
      }
    } catch (e) {
      throw Exception('Error: $e');
    }
  }
}
```

## Create Models in Flutter

```dart
class TripItinerary {
  final String tripId;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDays;
  final double totalDistance;
  final double totalEstimatedCost;
  final List<DayItinerary> dailyItineraries;
  final String algorithmExplanation;
  
  TripItinerary.fromJson(Map<String, dynamic> json)
    : tripId = json['trip_id'],
      startDate = DateTime.parse(json['start_date']),
      endDate = DateTime.parse(json['end_date']),
      totalDays = json['total_days'],
      totalDistance = (json['total_distance'] as num).toDouble(),
      totalEstimatedCost = (json['total_estimated_cost'] as num).toDouble(),
      dailyItineraries = (json['daily_itineraries'] as List)
          .map((d) => DayItinerary.fromJson(d))
          .toList(),
      algorithmExplanation = json['algorithm_explanation'];
}

class DayItinerary {
  final int day;
  final DateTime date;
  final List<PlaceSuggestion> places;
  final double totalDistance;
  final double totalTime;
  final double estimatedBudget;
  
  DayItinerary.fromJson(Map<String, dynamic> json)
    : day = json['day'],
      date = DateTime.parse(json['date']),
      places = (json['places'] as List)
          .map((p) => PlaceSuggestion.fromJson(p))
          .toList(),
      totalDistance = (json['total_distance'] as num).toDouble(),
      totalTime = (json['total_time'] as num).toDouble(),
      estimatedBudget = (json['estimated_budget'] as num).toDouble();
}

class PlaceSuggestion {
  final String id;
  final String name;
  final String category;
  final double latitude;
  final double longitude;
  final double rating;
  final int reviews;
  final double estimatedCost;
  final String description;
  
  PlaceSuggestion.fromJson(Map<String, dynamic> json)
    : id = json['id'],
      name = json['name'],
      category = json['category'],
      latitude = (json['latitude'] as num).toDouble(),
      longitude = (json['longitude'] as num).toDouble(),
      rating = (json['rating'] as num).toDouble(),
      reviews = json['reviews'],
      estimatedCost = (json['estimated_cost'] as num).toDouble(),
      description = json['description'];
}
```

## Usage in Flutter

```dart
// In your trip planning screen
final tripService = TripPlanningService();

try {
  final itinerary = await tripService.planTrip(
    startDate: DateTime(2026, 2, 1),
    endDate: DateTime(2026, 2, 5),
    budget: 50000,
    preferences: ['beach', 'food', 'adventure'],
  );
  
  // Display itinerary
  setState(() {
    this.itinerary = itinerary;
  });
} catch (e) {
  print('Error: $e');
}
```

# STEP 3: Displaying Results

Create a Flutter widget to display the trip itinerary:

```dart
class TripItineraryView extends StatelessWidget {
  final TripItinerary itinerary;
  
  const TripItineraryView({required this.itinerary});
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trip Summary
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Trip Summary', style: Theme.of(context).textTheme.titleLarge),
                  SizedBox(height: 8),
                  Text('Duration: ${itinerary.totalDays} days'),
                  Text('Distance: ${itinerary.totalDistance.toStringAsFixed(1)} km'),
                  Text('Estimated Cost: ₹${itinerary.totalEstimatedCost.toStringAsFixed(0)}'),
                ],
              ),
            ),
          ),
          
          // Daily Itineraries
          ...itinerary.dailyItineraries.map((day) => DayItineraryCard(day: day)),
        ],
      ),
    );
  }
}

class DayItineraryCard extends StatelessWidget {
  final DayItinerary day;
  
  const DayItineraryCard({required this.day});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Day ${day.day} - ${day.date.toLocal()}'),
            SizedBox(height: 8),
            ...day.places.map((place) => PlaceListTile(place: place)),
            Divider(),
            Text('Distance: ${day.totalDistance.toStringAsFixed(1)} km'),
            Text('Estimated Cost: ₹${day.estimatedBudget.toStringAsFixed(0)}'),
          ],
        ),
      ),
    );
  }
}

class PlaceListTile extends StatelessWidget {
  final PlaceSuggestion place;
  
  const PlaceListTile({required this.place});
  
  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(place.name),
      subtitle: Text('${place.category} • ⭐ ${place.rating}'),
      trailing: Text('₹${place.estimatedCost.toStringAsFixed(0)}'),
    );
  }
}
```

# STEP 4: Network Configuration

## Android (if using Android emulator)
Change backend URL to: http://10.0.2.2:8000

## iOS
For simulator: Use your Mac's IP address

## Web (Chrome)
Use: http://localhost:8000

# STEP 5: Error Handling

```dart
Future<void> handleTripPlanningError(dynamic error) async {
  if (error is SocketException) {
    // Network error
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Connection Error'),
        content: Text('Could not reach the trip planning server'),
      ),
    );
  } else if (error.toString().contains('400')) {
    // Invalid request
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Invalid Input'),
        content: Text('Please check your inputs'),
      ),
    );
  } else {
    // Other errors
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Error'),
        content: Text('An error occurred: $error'),
      ),
    );
  }
}
```

# DEPLOYMENT

## Local Development
- Backend: http://localhost:8000
- Frontend: http://localhost (if using Flutter web)

## Production
- Deploy backend to cloud (AWS, GCP, Azure, Heroku)
- Update Flutter app with production backend URL
- Use HTTPS instead of HTTP
- Configure proper API keys for external services

## Recommended Platforms
- Backend: Heroku, AWS Lambda, Google Cloud Run, DigitalOcean
- Database: AWS RDS, Google Cloud SQL (if adding persistence)
- Frontend: Vercel, Netlify (for web version)
