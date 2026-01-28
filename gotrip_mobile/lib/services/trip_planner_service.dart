import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Trip Planning Service - Uses Supabase destinations database
/// No external API calls needed
class TripPlannerService {
  final _supabase = Supabase.instance.client;

  /// Calculate distance between two coordinates (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371; // Earth radius in kilometers
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180;

  /// Plan a trip based on user preferences using Supabase destinations
  Future<Map<String, dynamic>> planTrip({
    required Map<String, dynamic> startLocation, // {name, lat, lng}
    required List<String> preferences,
    required double budget,
    required String startDate, // ISO format: "2026-02-01T00:00:00Z"
    required String endDate,   // ISO format: "2026-02-07T00:00:00Z"
    bool returnToStart = true,
  }) async {
    try {
      // Calculate trip duration
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final duration = end.difference(start).inDays + 1;

      if (duration < 1) {
        return {
          'success': false,
          'message': 'Invalid trip duration',
          'plan': null,
        };
      }

      // Get user starting location
      final startLat = startLocation['lat'] as double;
      final startLng = startLocation['lng'] as double;
      final startCity = startLocation['name'] as String;

      print('🔍 Searching destinations for preferences: $preferences');

      // Build Supabase query to fetch matching destinations
      var query = _supabase
          .from('destinations')
          .select('*')
          .eq('is_active', true);

      // Filter by categories (user preferences)
      // Use OR logic - any destination matching ANY preference
      if (preferences.isNotEmpty) {
        // Build filter: categories overlap with preferences array
        query = query.or(
          preferences.map((pref) => 'categories.cs.{$pref}').join(',')
        );
      }

      final response = await query.limit(100);
      
      if (response == null || (response as List).isEmpty) {
        return {
          'success': false,
          'message': 'No destinations found matching your preferences',
          'plan': null,
        };
      }

      List<Map<String, dynamic>> allDestinations = response
          .map((e) => e as Map<String, dynamic>)
          .toList();

      print('✅ Found ${allDestinations.length} destinations');

      // Calculate distance from start location for each destination
      for (var dest in allDestinations) {
        final lat = dest['latitude'] as num;
        final lng = dest['longitude'] as num;
        dest['distance_from_start'] = _calculateDistance(
          startLat,
          startLng,
          lat.toDouble(),
          lng.toDouble(),
        );
      }

      // Sort by distance (prefer closer destinations)
      allDestinations.sort((a, b) {
        final distA = a['distance_from_start'] as double;
        final distB = b['distance_from_start'] as double;
        return distA.compareTo(distB);
      });

      // Budget allocation
      const travelCostPerKm = 8.0; // ₹8 per km for travel
      const accommodationPerNight = 1500.0; // Average ₹1500 per night
      final nightsNeeded = duration - 1;
      final accommodationBudget = nightsNeeded * accommodationPerNight;

      // Calculate max destinations we can afford
      double spentBudget = 0;
      double travelBudget = 0;
      List<Map<String, dynamic>> selectedDestinations = [];
      List<Map<String, dynamic>> routeSegments = [];
      double totalDistance = 0;

      double currentLat = startLat;
      double currentLng = startLng;
      String currentCity = startCity;

      // Greedy selection: Pick closest destinations within budget
      for (var dest in allDestinations) {
        if (selectedDestinations.length >= duration * 2) break; // Max 2 destinations per day

        final destLat = (dest['latitude'] as num).toDouble();
        final destLng = (dest['longitude'] as num).toDouble();
        final costPerDay = (dest['cost_per_day'] as num?)?.toDouble() ?? 0;
        final entryFee = (dest['entry_fee'] as num?)?.toDouble() ?? 0;

        // Calculate travel cost from current location
        final distance = _calculateDistance(currentLat, currentLng, destLat, destLng);
        final travelCost = distance * travelCostPerKm;

        // Total cost to add this destination
        final totalCost = costPerDay + entryFee + travelCost;

        // Check if we can afford it
        if (spentBudget + totalCost + accommodationBudget > budget) {
          continue; // Skip if too expensive
        }

        // Add destination
        selectedDestinations.add(dest);
        
        // Add route segment
        routeSegments.add({
          'from': currentCity,
          'to': dest['city'],
          'distance_km': distance,
          'travel_cost': travelCost,
          'travel_time_hours': distance / 60, // Assume 60 km/h average
        });

        spentBudget += totalCost;
        travelBudget += travelCost;
        totalDistance += distance;
        
        currentLat = destLat;
        currentLng = destLng;
        currentCity = dest['city'] as String;
      }

      // Return to start if needed
      if (returnToStart && selectedDestinations.isNotEmpty) {
        final returnDistance = _calculateDistance(currentLat, currentLng, startLat, startLng);
        final returnCost = returnDistance * travelCostPerKm;

        routeSegments.add({
          'from': currentCity,
          'to': startCity,
          'distance_km': returnDistance,
          'travel_cost': returnCost,
          'travel_time_hours': returnDistance / 60,
        });

        travelBudget += returnCost;
        totalDistance += returnDistance;
        spentBudget += returnCost;
      }

      if (selectedDestinations.isEmpty) {
        return {
          'success': false,
          'message': 'No destinations found within your budget',
          'plan': null,
        };
      }

      // Create daily itinerary with distance calculation
      List<Map<String, dynamic>> dailyItinerary = [];
      int destsPerDay = (selectedDestinations.length / duration).ceil();
      
      for (int day = 0; day < duration; day++) {
        final startIdx = day * destsPerDay;
        final endIdx = min((day + 1) * destsPerDay, selectedDestinations.length);
        
        if (startIdx < selectedDestinations.length) {
          final dayDestinations = selectedDestinations.sublist(startIdx, endIdx);
          
          // Calculate distance traveled on this day
          double dayDistance = 0;
          for (int i = 0; i < dayDestinations.length - 1; i++) {
            final dest1 = dayDestinations[i];
            final dest2 = dayDestinations[i + 1];
            final lat1 = (dest1['latitude'] as num).toDouble();
            final lng1 = (dest1['longitude'] as num).toDouble();
            final lat2 = (dest2['latitude'] as num).toDouble();
            final lng2 = (dest2['longitude'] as num).toDouble();
            dayDistance += _calculateDistance(lat1, lng1, lat2, lng2);
          }
          
          dailyItinerary.add({
            'day': day + 1,
            'date': start.add(Duration(days: day)).toIso8601String(),
            'destinations': dayDestinations,
            'total_distance': dayDistance,
          });
        }
      }

      final totalCost = spentBudget + accommodationBudget;
      final totalTravelTime = routeSegments.fold<double>(
        0,
        (sum, segment) => sum + (segment['travel_time_hours'] as double),
      );

      return {
        'success': true,
        'message': 'Trip planned successfully with ${selectedDestinations.length} destinations',
        'plan': {
          'destinations': selectedDestinations,
          'total_cost': totalCost,
          'total_travel_cost': travelBudget,
          'total_accommodation_cost': accommodationBudget,
          'total_distance_km': totalDistance,
          'total_travel_time_hours': totalTravelTime,
          'route_segments': routeSegments,
          'daily_itinerary': dailyItinerary,
          'budget_remaining': budget - totalCost,
          'duration_days': duration,
        },
      };
    } catch (e) {
      print('❌ Error planning trip: $e');
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
        'plan': null,
      };
    }
  }

  /// Get nearby destinations around a location
  Future<List<Map<String, dynamic>>> getNearbyDestinations({
    required double latitude,
    required double longitude,
    double radiusKm = 100,
    List<String>? categories,
    int limit = 20,
  }) async {
    try {
      var query = _supabase
          .from('destinations')
          .select('*')
          .eq('is_active', true);

      if (categories != null && categories.isNotEmpty) {
        query = query.or(
          categories.map((cat) => 'categories.cs.{$cat}').join(',')
        );
      }

      final response = await query.limit(100);
      
      if (response == null) return [];

      List<Map<String, dynamic>> destinations = (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();

      // Filter by distance
      destinations = destinations.where((dest) {
        final lat = (dest['latitude'] as num).toDouble();
        final lng = (dest['longitude'] as num).toDouble();
        final distance = _calculateDistance(latitude, longitude, lat, lng);
        dest['distance_km'] = distance;
        return distance <= radiusKm;
      }).toList();

      // Sort by distance
      destinations.sort((a, b) {
        final distA = a['distance_km'] as double;
        final distB = b['distance_km'] as double;
        return distA.compareTo(distB);
      });

      return destinations.take(limit).toList();
    } catch (e) {
      print('❌ Error fetching nearby destinations: $e');
      return [];
    }
  }

  /// Search destinations by name, city, or state
  Future<List<Map<String, dynamic>>> searchDestinations({
    String? searchTerm,
    String? city,
    String? state,
    List<String>? categories,
    int limit = 50,
  }) async {
    try {
      var query = _supabase
          .from('destinations')
          .select('*')
          .eq('is_active', true);

      if (searchTerm != null && searchTerm.isNotEmpty) {
        query = query.or(
          'name.ilike.%$searchTerm%,city.ilike.%$searchTerm%,state.ilike.%$searchTerm%,description.ilike.%$searchTerm%'
        );
      }

      if (city != null) {
        query = query.eq('city', city);
      }

      if (state != null) {
        query = query.eq('state', state);
      }

      if (categories != null && categories.isNotEmpty) {
        query = query.or(
          categories.map((cat) => 'categories.cs.{$cat}').join(',')
        );
      }

      final response = await query.limit(limit);
      
      if (response == null) return [];

      return (response as List)
          .map((e) => e as Map<String, dynamic>)
          .toList();
    } catch (e) {
      print('❌ Error searching destinations: $e');
      return [];
    }
  }

  /// Get all unique cities from destinations
  Future<List<String>> getAllCities() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select('city')
          .eq('is_active', true);

      if (response == null) return [];

      final cities = (response as List)
          .map((e) => e['city'] as String)
          .toSet()
          .toList();

      cities.sort();
      return cities;
    } catch (e) {
      print('❌ Error fetching cities: $e');
      return [];
    }
  }

  /// Get all unique states from destinations
  Future<List<String>> getAllStates() async {
    try {
      final response = await _supabase
          .from('destinations')
          .select('state')
          .eq('is_active', true);

      if (response == null) return [];

      final states = (response as List)
          .map((e) => e['state'] as String)
          .toSet()
          .toList();

      states.sort();
      return states;
    } catch (e) {
      print('❌ Error fetching states: $e');
      return [];
    }
  }
}
