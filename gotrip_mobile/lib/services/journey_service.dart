import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:typed_data';

class JourneyService {
  static final JourneyService _instance = JourneyService._internal();
  factory JourneyService() => _instance;
  JourneyService._internal();

  SupabaseClient get _client => Supabase.instance.client;

  String? get _userId => _client.auth.currentUser?.id;

  // Check if user has an active trip
  Future<Map<String, dynamic>?> getActiveTrip() async {
    if (_userId == null) return null;

    try {
      final response = await _client
          .from('user_trips')
          .select('''
            *,
            trip_days (
              *,
              trip_destinations (*)
            )
          ''')
          .eq('user_id', _userId!)
          .inFilter('status', ['planned', 'in_progress'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      return response;
    } catch (e) {
      print('Error getting active trip: $e');
      return null;
    }
  }

  // Start a new journey - save trip plan to database
  Future<Map<String, dynamic>?> startJourney(Map<String, dynamic> tripPlan) async {
    if (_userId == null) return null;

    try {
      // First check if there's already an active trip
      final existingTrip = await getActiveTrip();
      if (existingTrip != null) {
        throw Exception('You already have an active trip. Please end it before starting a new one.');
      }

      // Create the main trip record
      final tripResponse = await _client.from('user_trips').insert({
        'user_id': _userId,
        'trip_name': 'Trip to ${tripPlan['city_name']}',
        'start_date': tripPlan['start_date'],
        'end_date': tripPlan['end_date'],
        'start_city': tripPlan['city_name'],
        'total_budget': tripPlan['budget'] ?? 0,
        'total_distance_km': tripPlan['total_distance_km'] ?? 0,
        'preferences': tripPlan['preferences'] ?? [],
        'status': 'in_progress',
      }).select().single();

      final tripId = tripResponse['id'];

      // Create trip days and destinations
      final dailyItineraries = tripPlan['daily_itineraries'] as List? ?? [];
      
      for (var dayData in dailyItineraries) {
        final dayNumber = dayData['day'] ?? 1;
        final destinations = dayData['destinations'] as List? ?? [];
        final distance = dayData['total_distance'] ?? 0;
        final budget = dayData['estimated_budget'] ?? 0;

        // Calculate budget from destinations if not provided
        double calculatedBudget = budget > 0 ? budget.toDouble() : 0;
        if (calculatedBudget == 0) {
          for (var dest in destinations) {
            calculatedBudget += (dest['estimated_cost'] ?? dest['cost_per_day'] ?? 0).toDouble();
          }
        }

        // Create trip day
        final dayResponse = await _client.from('trip_days').insert({
          'trip_id': tripId,
          'day_number': dayNumber,
          'total_distance_km': distance,
          'estimated_budget': calculatedBudget,
          'status': 'pending',
        }).select().single();

        final dayId = dayResponse['id'];

        // Create destinations for this day
        for (int i = 0; i < destinations.length; i++) {
          final dest = destinations[i];
          await _client.from('trip_destinations').insert({
            'trip_day_id': dayId,
            'destination_id': dest['id'],
            'destination_name': dest['name'] ?? 'Unknown',
            'city': dest['city'],
            'state': dest['state'],
            'category': dest['category'],
            'latitude': dest['latitude'],
            'longitude': dest['longitude'],
            'estimated_cost': dest['estimated_cost'] ?? dest['cost_per_day'] ?? 0,
            'visit_order': i + 1,
            'is_visited': false,
          });
        }
      }

      // Return the created trip with all related data
      return await getActiveTrip();
    } catch (e) {
      print('Error starting journey: $e');
      rethrow;
    }
  }

  // Mark a destination as visited
  Future<void> markDestinationVisited(String destinationId, bool visited) async {
    try {
      await _client.from('trip_destinations').update({
        'is_visited': visited,
        'visited_at': visited ? DateTime.now().toIso8601String() : null,
      }).eq('id', destinationId);
    } catch (e) {
      print('Error marking destination visited: $e');
      rethrow;
    }
  }

  // Update trip day status
  Future<void> updateDayStatus(String dayId, String status) async {
    try {
      await _client.from('trip_days').update({
        'status': status,
      }).eq('id', dayId);
    } catch (e) {
      print('Error updating day status: $e');
      rethrow;
    }
  }

  // End the current journey
  Future<void> endJourney(String tripId) async {
    try {
      await _client.from('user_trips').update({
        'status': 'completed',
      }).eq('id', tripId);

      // Also mark all pending days as completed
      await _client.from('trip_days').update({
        'status': 'completed',
      }).eq('trip_id', tripId);
    } catch (e) {
      print('Error ending journey: $e');
      rethrow;
    }
  }

  // Cancel a trip
  Future<void> cancelTrip(String tripId) async {
    try {
      await _client.from('user_trips').update({
        'status': 'cancelled',
      }).eq('id', tripId);
    } catch (e) {
      print('Error cancelling trip: $e');
      rethrow;
    }
  }

  // Get trip history (completed trips)
  Future<List<Map<String, dynamic>>> getTripHistory() async {
    if (_userId == null) return [];

    try {
      final response = await _client
          .from('user_trips')
          .select('''
            *,
            trip_days (
              *,
              trip_destinations (*)
            )
          ''')
          .eq('user_id', _userId!)
          .eq('status', 'completed')
          .order('end_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting trip history: $e');
      return [];
    }
  }

  // Get memories/snaps for a trip
  Future<List<Map<String, dynamic>>> getTripMemories(String tripId) async {
    try {
      final response = await _client
          .from('trip_memories')
          .select()
          .eq('trip_id', tripId)
          .order('captured_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error getting trip memories: $e');
      return [];
    }
  }

  // Add a memory/snap to a trip
  Future<void> addMemory({
    required String tripId,
    String? tripDestinationId,
    required String imageUrl,
    String? caption,
    double? latitude,
    double? longitude,
  }) async {
    if (_userId == null) return;

    try {
      await _client.from('trip_memories').insert({
        'user_id': _userId,
        'trip_id': tripId,
        'trip_destination_id': tripDestinationId,
        'image_url': imageUrl,
        'caption': caption,
        'latitude': latitude,
        'longitude': longitude,
        'captured_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding memory: $e');
      rethrow;
    }
  }

  // Upload image to Supabase Storage
  Future<String?> uploadMemoryImage(String tripId, String filePath, String fileName) async {
    if (_userId == null) return null;

    try {
      final file = File(filePath);
      final bytes = await file.readAsBytes();
      final storagePath = 'memories/$_userId/$tripId/$fileName';
      
      await _client.storage.from('trip-memories').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get the public URL
      final publicUrl = _client.storage.from('trip-memories').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  // Upload image from bytes (for web and cross-platform support)
  Future<String?> uploadMemoryImageBytes(String tripId, Uint8List bytes, String fileName) async {
    if (_userId == null) return null;

    try {
      final storagePath = 'memories/$_userId/$tripId/$fileName';
      
      await _client.storage.from('trip-memories').uploadBinary(
        storagePath,
        bytes,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );

      // Get the public URL
      final publicUrl = _client.storage.from('trip-memories').getPublicUrl(storagePath);
      return publicUrl;
    } catch (e) {
      print('Error uploading image bytes: $e');
      return null;
    }
  }

  // Delete a memory image from storage
  Future<bool> deleteMemoryImage(String imageUrl) async {
    try {
      // Extract path from URL
      final uri = Uri.parse(imageUrl);
      final pathSegments = uri.pathSegments;
      final storagePath = pathSegments.skip(pathSegments.indexOf('memories')).join('/');
      
      await _client.storage.from('trip-memories').remove([storagePath]);
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  // Delete a memory record and its image
  Future<void> deleteMemory(String memoryId, String? imageUrl) async {
    try {
      // Delete the record first
      await _client.from('trip_memories').delete().eq('id', memoryId);
      
      // Then try to delete the image from storage if URL exists
      if (imageUrl != null) {
        await deleteMemoryImage(imageUrl);
      }
    } catch (e) {
      print('Error deleting memory: $e');
      rethrow;
    }
  }

  // Convert database trip format to app format for JourneyTrackingScreen
  Map<String, dynamic> convertDbTripToAppFormat(Map<String, dynamic> dbTrip) {
    final tripDays = dbTrip['trip_days'] as List? ?? [];
    
    // Sort days by day_number
    tripDays.sort((a, b) => (a['day_number'] ?? 0).compareTo(b['day_number'] ?? 0));

    final dailyItineraries = tripDays.map((day) {
      final destinations = day['trip_destinations'] as List? ?? [];
      // Sort destinations by visit_order
      destinations.sort((a, b) => (a['visit_order'] ?? 0).compareTo(b['visit_order'] ?? 0));

      return {
        'day': day['day_number'],
        'total_distance': day['total_distance_km'] ?? 0,
        'estimated_budget': day['estimated_budget'] ?? 0,
        'day_id': day['id'],
        'status': day['status'],
        'destinations': destinations.map((dest) => {
          'id': dest['id'],
          'destination_id': dest['destination_id'],
          'name': dest['destination_name'],
          'city': dest['city'],
          'state': dest['state'],
          'category': dest['category'],
          'latitude': dest['latitude'],
          'longitude': dest['longitude'],
          'estimated_cost': dest['estimated_cost'],
          'is_visited': dest['is_visited'] ?? false,
          'visited_at': dest['visited_at'],
          'visit_order': dest['visit_order'],
        }).toList(),
      };
    }).toList();

    return {
      'trip_id': dbTrip['id'],
      'trip_name': dbTrip['trip_name'],
      'city_name': dbTrip['start_city'],
      'start_date': dbTrip['start_date'],
      'end_date': dbTrip['end_date'],
      'duration_days': tripDays.length,
      'budget': dbTrip['total_budget'],
      'total_distance_km': dbTrip['total_distance_km'],
      'preferences': dbTrip['preferences'] ?? [],
      'status': dbTrip['status'],
      'daily_itineraries': dailyItineraries,
    };
  }
}
