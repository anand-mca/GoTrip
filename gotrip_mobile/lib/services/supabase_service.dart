import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();

  factory SupabaseService() {
    return _instance;
  }

  SupabaseService._internal();

  late SupabaseClient _client;

  SupabaseClient get client => Supabase.instance.client;

  Future<void> initialize(String url, String anonKey) async {
    _client = Supabase.instance.client;
  }

  // Auth Methods
  Future<AuthResponse> signUp(String email, String password, String name) async {
    final response = await client.auth.signUp(
      email: email,
      password: password,
      data: {
        'name': name,
        'avatar_url': '',
      },
    );
    return response;
  }

  Future<AuthResponse> signIn(String email, String password) async {
    final response = await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? getCurrentUser() {
    return client.auth.currentUser;
  }

  Stream<AuthState> authStateChanges() {
    return client.auth.onAuthStateChange;
  }

  // User Profile Methods
  Future<void> createUserProfile(String userId, String name, String email) async {
    try {
      await client.from('profiles').insert({
        'id': userId,
        'name': name,
        'email': email,
        'phone': '',
        'bio': '',
        'profile_image': '',
        'saved_trips': [],
        'booked_trips': [],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  Future<void> updateUserProfile(String userId, Map<String, dynamic> updates) async {
    await client
        .from('profiles')
        .update(updates)
        .eq('id', userId);
  }

  // Trip Methods
  Future<List<Map<String, dynamic>>> getAllTrips() async {
    try {
      final response = await client
          .from('trips')
          .select()
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching trips: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getTripById(String tripId) async {
    try {
      final response = await client
          .from('trips')
          .select()
          .eq('id', tripId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching trip: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> searchTrips(String query) async {
    try {
      final response = await client
          .from('trips')
          .select()
          .ilike('title', '%$query%')
          .or('location.ilike.%$query%');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching trips: $e');
      return [];
    }
  }

  // Booking Methods
  Future<void> createBooking(String userId, String tripId, Map<String, dynamic> bookingData) async {
    try {
      await client.from('bookings').insert({
        'user_id': userId,
        'trip_id': tripId,
        ...bookingData,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating booking: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserBookings(String userId) async {
    try {
      final response = await client
          .from('bookings')
          .select('*, trips(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching bookings: $e');
      return [];
    }
  }

  // Image Upload Methods
  Future<String?> uploadImage(String bucket, File imageFile, String userId) async {
    try {
      final fileName = '${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final bytes = await imageFile.readAsBytes();
      
      await client.storage
          .from(bucket)
          .uploadBinary(fileName, bytes);

      final publicUrl = client.storage
          .from(bucket)
          .getPublicUrl(fileName);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      rethrow;
    }
  }

  Future<List<FileObject>> listImages(String bucket, String userId) async {
    try {
      final files = await client.storage
          .from(bucket)
          .list(path: userId);
      return files;
    } catch (e) {
      print('Error listing images: $e');
      return [];
    }
  }

  Future<void> deleteImage(String bucket, String fileName) async {
    try {
      await client.storage
          .from(bucket)
          .remove([fileName]);
    } catch (e) {
      print('Error deleting image: $e');
      rethrow;
    }
  }

  // Favorites Methods
  Future<void> addToFavorites(String userId, String tripId) async {
    try {
      await client.from('favorites').insert({
        'user_id': userId,
        'trip_id': tripId,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error adding to favorites: $e');
      rethrow;
    }
  }

  Future<void> removeFromFavorites(String userId, String tripId) async {
    try {
      await client
          .from('favorites')
          .delete()
          .eq('user_id', userId)
          .eq('trip_id', tripId);
    } catch (e) {
      print('Error removing from favorites: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getUserFavorites(String userId) async {
    try {
      final response = await client
          .from('favorites')
          .select('*, trips(*)')
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching favorites: $e');
      return [];
    }
  }

  Future<bool> isFavorite(String userId, String tripId) async {
    try {
      final response = await client
          .from('favorites')
          .select()
          .eq('user_id', userId)
          .eq('trip_id', tripId);
      return response.isNotEmpty;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }
}
