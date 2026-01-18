import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;

class TripPlanningService {
  // Backend API URL - automatically adapts to platform
  static String get baseUrl {
    if (kIsWeb) {
      // For web, use localhost (same machine)
      return 'http://localhost:8000';
    } else {
      // For mobile, could use 10.0.2.2 (Android emulator) or actual IP
      return 'http://127.0.0.1:8000';
    }
  }
  
  /// Plan a smart trip based on user preferences
  static Future<Map<String, dynamic>> planTrip({
    required String startDate,
    required String endDate,
    required int budget,
    required List<String> preferences,
    double latitude = 28.6139,
    double longitude = 77.2090,
  }) async {
    try {
      print('🚀 Planning trip with:');
      print('   Dates: $startDate to $endDate');
      print('   Budget: ₹$budget');
      print('   Preferences: $preferences');
      print('   Location: ($latitude, $longitude)');

      final response = await http
          .post(
            Uri.parse('$baseUrl/api/plan-trip'),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'start_date': startDate,
              'end_date': endDate,
              'budget': budget,
              'preferences': preferences,
              'latitude': latitude,
              'longitude': longitude,
            }),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () => throw Exception('Request timeout after 30 seconds'),
          );

      print('✅ Backend response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('📋 Got trip plan: ${data['trip_id']}');
        print('📋 Daily itineraries: ${data['daily_itineraries']?.length ?? 0}');
        
        // Transform API response to match UI expectations
        return {
          'trip_id': data['trip_id'],
          'start_date': data['start_date'],
          'end_date': data['end_date'],
          'total_days': data['total_days'],
          'total_places': _countPlaces(data['daily_itineraries'] ?? []),
          'total_estimated_cost': data['total_estimated_cost'] ?? 0,
          'total_distance': data['total_distance'] ?? 0,
          'itinerary': _transformItinerary(data['daily_itineraries'] ?? []),
          'algorithm_explanation': data['algorithm_explanation'] ?? '',
        };
      } else {
        throw Exception('Failed to plan trip: ${response.body}');
      }
    } catch (e) {
      print('❌ Error planning trip: $e');
      rethrow;
    }
  }

  static int _countPlaces(List<dynamic> dailyItineraries) {
    int count = 0;
    for (var day in dailyItineraries) {
      count += (day['places'] as List?)?.length ?? 0;
    }
    return count;
  }

  static List<dynamic> _transformItinerary(List<dynamic> dailyItineraries) {
    return dailyItineraries.map((day) {
      return {
        'day': day['day'],
        'date': day['date'],
        'places': day['places'] ?? [],
        'daily_cost': day['estimated_budget'] ?? 0,
        'daily_distance': day['total_distance'] ?? 0,
      };
    }).toList();
  }

  /// Check if backend is healthy
  static Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      print('⚠️ Backend health check failed: $e');
      return false;
    }
  }

  /// Get API information
  static Future<Map<String, dynamic>> getApiInfo() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/info'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return {};
    } catch (e) {
      print('⚠️ Could not get API info: $e');
      return {};
    }
  }
}
