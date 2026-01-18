import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class RoutingService {
  // OpenRouteService API - FREE (requires registration at openrouteservice.org)
  // Leave empty for now - user will add when ready
  static const String _openRouteApiKey = '';
  
  // Fallback to OSRM public instance (free, no key needed)
  static const String _osrmBaseUrl = 'https://router.project-osrm.org';
  static const String _openRouteBaseUrl = 'https://api.openrouteservice.org';

  /// Calculate distance, duration, and cost between two points
  /// Returns: {distance_km, duration_hours, estimated_cost}
  Future<Map<String, dynamic>> calculateRoute({
    required double fromLat,
    required double fromLng,
    required double toLat,
    required double toLng,
    String mode = 'driving', // driving, walking, cycling
  }) async {
    try {
      // Use OSRM (free, no key) if OpenRoute key not provided
      if (_openRouteApiKey.isEmpty) {
        return await _calculateRouteOSRM(fromLat, fromLng, toLat, toLng);
      } else {
        return await _calculateRouteOpenRoute(fromLat, fromLng, toLat, toLng, mode);
      }
    } catch (e) {
      print('Routing error: $e');
      // Fallback to straight-line distance estimation
      return _estimateRoute(fromLat, fromLng, toLat, toLng);
    }
  }

  /// Using OSRM public instance (no API key needed)
  Future<Map<String, dynamic>> _calculateRouteOSRM(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) async {
    final url = '$_osrmBaseUrl/route/v1/driving/$fromLng,$fromLat;$toLng,$toLat?overview=false';
    
    final response = await http.get(Uri.parse(url)).timeout(
      const Duration(seconds: 10),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['routes'][0];
      
      final distanceMeters = route['distance']; // meters
      final durationSeconds = route['duration']; // seconds
      
      final distanceKm = distanceMeters / 1000;
      final durationHours = durationSeconds / 3600;
      
      // Estimate cost: ₹8 per km (average in India)
      final estimatedCost = distanceKm * 8;
      
      return {
        'distance_km': distanceKm.toDouble(),
        'duration_hours': durationHours.toDouble(),
        'estimated_cost': estimatedCost.toDouble(),
        'source': 'osrm',
      };
    } else {
      throw Exception('OSRM API error: ${response.statusCode}');
    }
  }

  /// Using OpenRouteService (free API key required)
  Future<Map<String, dynamic>> _calculateRouteOpenRoute(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
    String mode,
  ) async {
    final profile = mode == 'walking' ? 'foot-walking' : 'driving-car';
    final url = '$_openRouteBaseUrl/v2/directions/$profile?start=$fromLng,$fromLat&end=$toLng,$toLat';
    
    final response = await http.get(
      Uri.parse(url),
      headers: {'Authorization': _openRouteApiKey},
    ).timeout(const Duration(seconds: 10));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final route = data['features'][0]['properties']['segments'][0];
      
      final distanceMeters = route['distance'];
      final durationSeconds = route['duration'];
      
      final distanceKm = distanceMeters / 1000;
      final durationHours = durationSeconds / 3600;
      
      // Estimate cost based on mode
      double costPerKm = mode == 'walking' ? 0 : 8;
      final estimatedCost = distanceKm * costPerKm;
      
      return {
        'distance_km': distanceKm.toDouble(),
        'duration_hours': durationHours.toDouble(),
        'estimated_cost': estimatedCost.toDouble(),
        'source': 'openroute',
      };
    } else {
      throw Exception('OpenRouteService API error: ${response.statusCode}');
    }
  }

  /// Fallback: Haversine formula for straight-line distance
  Map<String, dynamic> _estimateRoute(
    double fromLat,
    double fromLng,
    double toLat,
    double toLng,
  ) {
    final distanceKm = _calculateHaversineDistance(fromLat, fromLng, toLat, toLng);
    
    // Multiply by 1.3 for road distance approximation
    final roadDistanceKm = distanceKm * 1.3;
    
    // Average speed: 50 km/h
    final durationHours = roadDistanceKm / 50;
    
    // ₹8 per km
    final estimatedCost = roadDistanceKm * 8;
    
    return {
      'distance_km': roadDistanceKm,
      'duration_hours': durationHours,
      'estimated_cost': estimatedCost,
      'source': 'estimated',
    };
  }

  /// Haversine formula for calculating distance between two coordinates
  double _calculateHaversineDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = 
      sin(dLat / 2) * sin(dLat / 2) +
      cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
    
    final c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) {
    return degrees * pi / 180;
  }

  /// Calculate total route for multiple destinations
  /// Optimizes order to minimize travel distance
  Future<Map<String, dynamic>> optimizeRoute({
    required Map<String, dynamic> startPoint, // {lat, lng, name}
    required List<Map<String, dynamic>> destinations, // [{id, lat, lng, name, days}]
    required Map<String, dynamic>? endPoint, // Optional return point
  }) async {
    if (destinations.isEmpty) {
      return {
        'optimized_order': <Map<String, dynamic>>[],
        'total_distance_km': 0.0,
        'total_duration_hours': 0.0,
        'total_travel_cost': 0.0,
        'route_segments': <Map<String, dynamic>>[],
      };
    }

    // For small number of destinations, use nearest neighbor algorithm
    // For larger sets, this is a simplified TSP solution
    final optimizedOrder = await _nearestNeighborOptimization(
      startPoint,
      destinations,
      endPoint,
    );

    return optimizedOrder;
  }

  /// Nearest Neighbor algorithm for route optimization
  Future<Map<String, dynamic>> _nearestNeighborOptimization(
    Map<String, dynamic> startPoint,
    List<Map<String, dynamic>> destinations,
    Map<String, dynamic>? endPoint,
  ) async {
    final visited = <Map<String, dynamic>>[];
    final remaining = List<Map<String, dynamic>>.from(destinations);
    final routeSegments = <Map<String, dynamic>>[];
    
    double totalDistance = 0;
    double totalDuration = 0;
    double totalCost = 0;
    
    var currentPoint = startPoint;
    
    // Visit each destination, always choosing the nearest unvisited one
    while (remaining.isNotEmpty) {
      // Find nearest destination
      Map<String, dynamic>? nearest;
      double nearestDistance = double.infinity;
      Map<String, dynamic>? nearestRoute;
      
      for (var dest in remaining) {
        final route = await calculateRoute(
          fromLat: currentPoint['lat'],
          fromLng: currentPoint['lng'],
          toLat: dest['lat'],
          toLng: dest['lng'],
        );
        
        if (route['distance_km'] < nearestDistance) {
          nearestDistance = route['distance_km'];
          nearest = dest;
          nearestRoute = route;
        }
      }
      
      if (nearest != null && nearestRoute != null) {
        visited.add(nearest);
        remaining.remove(nearest);
        
        routeSegments.add({
          'from': currentPoint['name'],
          'to': nearest['name'],
          'distance_km': nearestRoute['distance_km'],
          'duration_hours': nearestRoute['duration_hours'],
          'cost': nearestRoute['estimated_cost'],
        });
        
        totalDistance += nearestRoute['distance_km'] as double;
        totalDuration += nearestRoute['duration_hours'] as double;
        totalCost += nearestRoute['estimated_cost'] as double;
        
        currentPoint = nearest;
      }
    }
    
    // Add return journey if specified
    if (endPoint != null) {
      final returnRoute = await calculateRoute(
        fromLat: currentPoint['lat'],
        fromLng: currentPoint['lng'],
        toLat: endPoint['lat'],
        toLng: endPoint['lng'],
      );
      
      routeSegments.add({
        'from': currentPoint['name'],
        'to': endPoint['name'],
        'distance_km': returnRoute['distance_km'],
        'duration_hours': returnRoute['duration_hours'],
        'cost': returnRoute['estimated_cost'],
      });
      
      totalDistance += returnRoute['distance_km'] as double;
      totalDuration += returnRoute['duration_hours'] as double;
      totalCost += returnRoute['estimated_cost'] as double;
    }
    
    return {
      'optimized_order': visited,
      'total_distance_km': totalDistance,
      'total_duration_hours': totalDuration,
      'total_travel_cost': totalCost,
      'route_segments': routeSegments,
    };
  }
}
