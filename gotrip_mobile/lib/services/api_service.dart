import 'package:http/http.dart' as http;
import 'dart:convert';

class APIService {
  // Update this to your backend URL
  static const String _baseUrl = 'http://localhost:8000/api';
  
  // For web, you might need to use a different URL
  // static const String _baseUrl = 'http://127.0.0.1:8000/api';

  /// Fetch destinations by user preferences
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
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> destinations = data['destinations'] ?? [];
        return destinations.cast<Map<String, dynamic>>();
      } else if (response.statusCode == 404) {
        throw Exception('Backend API not found. Make sure your server is running.');
      } else {
        throw Exception('Failed to fetch destinations: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: Could not reach backend. Is it running on $_baseUrl?');
    } catch (e) {
      rethrow;
    }
  }

  /// Search destinations by keyword
  static Future<List<Map<String, dynamic>>> searchDestinations(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/destinations/search?q=$query'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> results = data['results'] ?? [];
        return results.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Search failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: Could not reach backend');
    } catch (e) {
      rethrow;
    }
  }

  /// Get detailed information about a specific destination
  static Future<Map<String, dynamic>> getDestinationDetails(
    String destinationId,
  ) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/destinations/$destinationId'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['destination'] ?? {};
      } else {
        throw Exception('Failed to fetch destination details: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: Could not reach backend');
    } catch (e) {
      rethrow;
    }
  }

  /// Get hotel options for a destination
  static Future<List<Map<String, dynamic>>> getHotels({
    required String destination,
    required String checkIn,
    required String checkOut,
    int? maxPrice,
  }) async {
    try {
      final queryParams = {
        'destination': destination,
        'check_in': checkIn,
        'check_out': checkOut,
        if (maxPrice != null) 'max_price': maxPrice.toString(),
      };

      final response = await http.get(
        Uri.parse('$_baseUrl/hotels').replace(queryParameters: queryParams),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> hotels = data['hotels'] ?? [];
        return hotels.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch hotels: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: Could not reach backend');
    } catch (e) {
      rethrow;
    }
  }

  /// Get activities/attractions for a destination
  static Future<List<Map<String, dynamic>>> getActivities({
    required String destination,
    required List<String> categories,
    int? maxPrice,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/activities/search'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'destination': destination,
          'categories': categories,
          if (maxPrice != null) 'max_price': maxPrice,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> activities = data['activities'] ?? [];
        return activities.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch activities: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: Could not reach backend');
    } catch (e) {
      rethrow;
    }
  }

  /// Get all available categories/preferences
  static Future<List<String>> getCategories() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/categories'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> categories = data['categories'] ?? [];
        return categories.cast<String>();
      } else {
        throw Exception('Failed to fetch categories: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Connection error: Could not reach backend');
    } catch (e) {
      rethrow;
    }
  }

  /// Health check endpoint
  static Future<bool> healthCheck() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Plan optimized trip with travel calculations
  /// This is the main endpoint for intelligent trip planning
  /// Returns: {success, message, plan: {destinations, total_cost, route_segments, daily_itinerary}}
  static Future<Map<String, dynamic>> planOptimizedTrip({
    required Map<String, dynamic> startLocation, // {name, lat, lng}
    required List<String> preferences,
    required double budget,
    required String startDate, // ISO format: "2026-02-01T00:00:00Z"
    required String endDate,   // ISO format: "2026-02-07T00:00:00Z"
    bool returnToStart = true,
  }) async {
    try {
      final requestBody = {
        'start_location': startLocation,
        'preferences': preferences,
        'budget': budget,
        'start_date': startDate,
        'end_date': endDate,
        'return_to_start': returnToStart,
      };

      final response = await http.post(
        Uri.parse('$_baseUrl/plan-trip'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 90), // Longer timeout for real API data fetching
        onTimeout: () => throw Exception('Trip planning timeout - APIs taking too long'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Trip planning failed: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw Exception('Network error during trip planning: $e');
    } catch (e) {
      rethrow;
    }
  }
}
