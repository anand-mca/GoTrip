# API Integration Guide for Trip Planning Feature

## Overview

The Trip Planning system needs to integrate with real tourism data APIs to:
1. Fetch actual destinations based on user preferences
2. Get real pricing and availability data
3. Generate AI-powered trip recommendations
4. Manage destination inventory

---

## Recommended Tourism APIs

### Option 1: **Google Places API** (Best for location data)
- Get destination details, reviews, ratings
- Search by category (beaches, restaurants, hotels, etc.)
- Get coordinates and opening hours
- **Cost**: Free tier available, then pay-as-you-go
- **Documentation**: https://developers.google.com/maps/documentation/places/web-service/overview

### Option 2: **Amadeus Travel API** (Best for flights & hotels)
- Flight search and pricing
- Hotel search and pricing
- Destination insights
- **Cost**: Free tier + paid
- **Documentation**: https://developers.amadeus.com/

### Option 3: **ToursByLocals / Viator API** (Best for tours & activities)
- Tour packages and activities
- Pricing by category
- **Cost**: Depends on provider

### Option 4: **Your Own Backend API** (Recommended for full control)
- Create your own API that aggregates data
- Store destination data in Supabase
- More control over data and pricing

---

## Recommended Architecture

```
Flutter App (Trip Planning Screen)
        ↓
Service Layer (api_service.dart)
        ↓
Backend API (Node.js / Python / Dart)
        ↓
Database (Supabase)
        ↓
External APIs (Google Places, Amadeus, etc.)
```

---

## Step-by-Step Integration

### Step 1: Create API Service Layer

Create `lib/services/api_service.dart`:

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class APIService {
  static const String _baseUrl = 'http://localhost:8000/api'; // Your backend URL
  
  // Fetch destinations by preferences
  static Future<List<Map<String, dynamic>>> fetchDestinationsByPreferences({
    required List<String> preferences,
    required int maxBudget,
    required int days,
    required String location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/destinations/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'preferences': preferences,
          'max_budget': maxBudget,
          'days': days,
          'location': location,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['destinations'];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch destinations');
      }
    } catch (e) {
      print('Error fetching destinations: $e');
      throw Exception('Error: $e');
    }
  }

  // Search destinations by keyword
  static Future<List<Map<String, dynamic>>> searchDestinations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/destinations/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['results'];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Search failed');
      }
    } catch (e) {
      print('Error searching destinations: $e');
      throw Exception('Error: $e');
    }
  }

  // Get destination details
  static Future<Map<String, dynamic>> getDestinationDetails(String destinationId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/destinations/$destinationId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['destination'];
      } else {
        throw Exception('Failed to fetch destination details');
      }
    } catch (e) {
      print('Error fetching details: $e');
      throw Exception('Error: $e');
    }
  }

  // Get hotel prices
  static Future<List<Map<String, dynamic>>> getHotels({
    required String destination,
    required String checkIn,
    required String checkOut,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/hotels?destination=$destination&check_in=$checkIn&check_out=$checkOut'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body)['hotels'];
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch hotels');
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      throw Exception('Error: $e');
    }
  }
}
```

### Step 2: Create Provider for API Integration

Create `lib/providers/destination_api_provider.dart`:

```dart
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DestinationAPIProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _destinations = [];
  bool _isLoading = false;
  String? _error;

  List<Map<String, dynamic>> get destinations => _destinations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchRecommendedDestinations({
    required List<String> preferences,
    required int budget,
    required int days,
    required String userLocation,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations = await APIService.fetchDestinationsByPreferences(
        preferences: preferences,
        maxBudget: budget,
        days: days,
        location: userLocation,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchDestinations(String query) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _destinations = await APIService.searchDestinations(query);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
```

### Step 3: Update Trip Planning Screen to Use API

Modify `trip_planning_screen.dart`:

```dart
// Add at the top
import 'package:provider/provider.dart';
import '../providers/destination_api_provider.dart';

// In _planTrip method, replace mock data with API call:
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
    tripPlan = null;
  });

  try {
    final startDate = _startDateController.text;
    final endDate = _endDateController.text;
    final budget = int.parse(_budgetController.text);
    
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final duration = end.difference(start).inDays + 1;
    
    // Call API instead of using mock data
    final apiProvider = context.read<DestinationAPIProvider>();
    await apiProvider.fetchRecommendedDestinations(
      preferences: selectedPreferences,
      budget: budget,
      days: duration,
      userLocation: 'Delhi', // Get from user location
    );

    final recommendations = apiProvider.destinations;
    final totalDistance = recommendations.fold<num>(0, (sum, r) => sum + (r['distance'] ?? 0)) as int;

    setState(() {
      tripPlan = {
        'trip_id': 'local_${DateTime.now().millisecondsSinceEpoch}',
        'start_date': startDate,
        'end_date': endDate,
        'budget': budget,
        'preferences': selectedPreferences,
        'duration_days': duration,
        'budget_per_day': (budget / duration).toStringAsFixed(2),
        'total_places': recommendations.length,
        'total_distance': totalDistance,
        'recommendations': recommendations,
        'status': 'from_api',
      };
    });

    if (recommendations.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No destinations found. Try adjusting filters.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Found ${recommendations.length} destinations!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
    );
  } finally {
    setState(() {
      isLoading = false;
    });
  }
}
```

### Step 4: Backend API Structure (Node.js example)

Create backend endpoint at `POST /api/destinations/recommendations`:

```javascript
// server.js or routes/destinations.js
const express = require('express');
const axios = require('axios');
const router = express.Router();

router.post('/recommendations', async (req, res) => {
  try {
    const { preferences, max_budget, days, location } = req.body;

    // Step 1: Use Google Places API to get destinations by category
    const destinations = [];
    
    for (const pref of preferences) {
      const googlePlacesResponse = await axios.get(
        'https://maps.googleapis.com/maps/api/place/nearbysearch/json',
        {
          params: {
            location: location, // e.g., "28.6139,77.2090" for Delhi
            radius: 50000,
            type: mapCategoryToPlaceType(pref),
            key: process.env.GOOGLE_PLACES_API_KEY,
          },
        }
      );

      // Step 2: Get prices from your database or Amadeus API
      for (const place of googlePlacesResponse.data.results) {
        const priceInfo = await getPriceInfo(place.name, pref);
        
        destinations.push({
          id: place.place_id,
          name: place.name,
          category: pref,
          latitude: place.geometry.location.lat,
          longitude: place.geometry.location.lng,
          cost: priceInfo.cost,
          days: priceInfo.days,
          distance: calculateDistance(location, place.geometry.location),
          rating: place.rating,
          reviews: place.user_ratings_total,
          image: place.photos?.[0]?.photo_reference,
          description: place.vicinity,
        });
      }
    }

    // Step 3: Filter by budget
    const filteredDestinations = destinations
      .filter(d => d.cost <= max_budget)
      .sort((a, b) => b.rating - a.rating)
      .slice(0, 10);

    res.json({ destinations: filteredDestinations });
  } catch (error) {
    console.error('Error:', error);
    res.status(500).json({ error: error.message });
  }
});

function mapCategoryToPlaceType(category) {
  const mapping = {
    'beach': 'tourist_attraction',
    'adventure': 'amusement_park',
    'food': 'restaurant',
    'history': 'museum',
    'shopping': 'shopping_mall',
    'nature': 'natural_feature',
    'religious': 'place_of_worship',
    'cultural': 'museum',
  };
  return mapping[category] || 'tourist_attraction';
}

async function getPriceInfo(placeName, category) {
  // Query your database or call Amadeus API
  // Return { cost: number, days: number }
  return { cost: 1500, days: 2 };
}

function calculateDistance(location, destination) {
  // Implement Haversine formula or use Google Distance Matrix API
  return 50;
}

module.exports = router;
```

---

## Setup Instructions

### 1. Install HTTP Package

```bash
flutter pub add http
```

### 2. Add Providers to main.dart

```dart
MultiProvider(
  providers: [
    // ... existing providers ...
    ChangeNotifierProvider(create: (_) => DestinationAPIProvider()),
  ],
  child: // ... your app
)
```

### 3. Set Backend URL

In `lib/services/api_service.dart`, update `_baseUrl`:

```dart
static const String _baseUrl = 'http://your-backend-domain.com/api';
// For local testing:
// static const String _baseUrl = 'http://localhost:8000/api';
```

### 4. Add Permissions (Android)

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
```

---

## Environment Variables Setup

Create `.env` file in Flutter project root:

```
BACKEND_URL=http://localhost:8000/api
GOOGLE_PLACES_API_KEY=your_key_here
AMADEUS_API_KEY=your_key_here
```

Load in pubspec.yaml:

```yaml
dependencies:
  flutter_dotenv: ^5.0.0
```

---

## Error Handling & Retry Logic

```dart
Future<T> _retryRequest<T>(
  Future<T> Function() request, {
  int maxRetries = 3,
  Duration delay = const Duration(seconds: 2),
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } catch (e) {
      if (i == maxRetries - 1) rethrow;
      await Future.delayed(delay * (i + 1));
    }
  }
  throw Exception('Max retries exceeded');
}
```

---

## Testing the API Integration

1. Start your backend server
2. Update `_baseUrl` in `api_service.dart`
3. Run the app: `flutter run -d chrome`
4. Fill in trip planning form
5. Click "Plan My Trip"
6. Should fetch real data from API

---

## Next Steps

1. **Set up backend server** (Node.js, Python, or Firebase Functions)
2. **Get API keys** for Google Places, Amadeus, etc.
3. **Create destination database** in Supabase
4. **Implement caching** to reduce API calls
5. **Add error handling** and offline support
6. **Test with real data**

---

## Recommended Tech Stack

- **Backend**: Node.js + Express / Python + FastAPI / Firebase Functions
- **Database**: Supabase (PostgreSQL)
- **External APIs**: Google Places, Amadeus, Viator
- **Caching**: Redis (optional, for performance)
- **Deployment**: Heroku, AWS, Firebase, DigitalOcean

Would you like me to help set up a specific backend?
