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

  // Destination Methods
  Future<List<Map<String, dynamic>>> getDestinations() async {
    try {
      print('📍 Querying destinations table...');
      final response = await client
          .from('destinations')
          .select()
          .order('name', ascending: true);
      print('✓ Query success! Got ${response.length} rows');
      if (response.isEmpty) {
        print('⚠️  Table is empty or data not available');
      } else {
        print('✓ First destination: ${response[0]}');
      }
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('✗ Error fetching destinations: $e');
      print('✗ Error type: ${e.runtimeType}');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> searchDestinations(String query) async {
    try {
      final response = await client
          .from('destinations')
          .select()
          .or('name.ilike.%$query%,city.ilike.%$query%,state.ilike.%$query%');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error searching destinations: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> getDestinationById(String destinationId) async {
    try {
      final response = await client
          .from('destinations')
          .select()
          .eq('id', destinationId)
          .single();
      return response;
    } catch (e) {
      print('Error fetching destination: $e');
      return null;
    }
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

  // Seed Indian destinations into trips table
  Future<void> seedIndianDestinations() async {
    try {
      print('Starting to seed Indian destinations...');
      
      // Sample Indian destinations
      final destinations = [
        {
          'title': 'Taj Mahal',
          'location': 'Agra, Uttar Pradesh',
          'description': 'The Taj Mahal is an ivory-white marble mausoleum located on the banks of the Yamuna River. Built by Mughal emperor Shah Jahan in memory of his wife Mumtaz Mahal, it is considered one of the most beautiful buildings in the world.',
          'image': 'https://images.unsplash.com/photo-1564507592333-c60657eea523?w=500&h=400&fit=crop',
          'rating': 4.9,
          'reviews': 2847,
          'price': 250,
          'duration': '4-6 hours',
          'difficulty': 'easy',
          'highlights': 'UNESCO World Heritage Site, Marble Architecture, Sunrise View, Night Illumination',
          'amenities': 'Restaurant, Parking, Rest Areas, Photography Allowed',
          'groupSize': 50,
          'category': 'Heritage',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Kerala Backwaters',
          'location': 'Kochi, Kerala',
          'description': 'A network of lagoons and lakes formed by action of monsoon winds and sea waves. The backwaters are known for their scenic beauty, houseboats, and rich biodiversity.',
          'image': 'https://images.unsplash.com/photo-1512343279214-4d1c16c2d008?w=500&h=400&fit=crop',
          'rating': 4.8,
          'reviews': 1923,
          'price': 3500,
          'duration': '2-3 days',
          'difficulty': 'easy',
          'highlights': 'Houseboat Cruise, Sunset Views, Coconut Plantations, Bird Watching',
          'amenities': 'Houseboat Stay, Restaurant, Fishing Tours, Ayurveda Spa',
          'groupSize': 30,
          'category': 'Nature',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Goa Beaches',
          'location': 'Goa',
          'description': 'Goa is known for its pristine beaches, vibrant nightlife, and Portuguese colonial architecture. With white sand beaches, water sports, and beachside shacks, Goa offers the perfect beach vacation experience.',
          'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&h=400&fit=crop',
          'rating': 4.7,
          'reviews': 2156,
          'price': 2000,
          'duration': '3-5 days',
          'difficulty': 'easy',
          'highlights': 'Beach Parties, Water Sports, Seafood Cuisine, Fort Visits',
          'amenities': 'Beach Resorts, Restaurant, Water Sports, Nightlife',
          'groupSize': 40,
          'category': 'Beach',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Himalayan Treks',
          'location': 'Himachal Pradesh & Uttarakhand',
          'description': 'The Himalayas offer some of the most breathtaking trekking routes in the world. From snow-covered peaks to lush green valleys, experience the raw beauty of nature at its finest.',
          'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop',
          'rating': 4.9,
          'reviews': 1654,
          'price': 4500,
          'duration': '5-7 days',
          'difficulty': 'hard',
          'highlights': 'Snow Peaks, Alpine Meadows, Mountain Views, Wildlife',
          'amenities': 'Mountain Lodges, Guides Available, Camping, Local Cuisine',
          'groupSize': 15,
          'category': 'Adventure',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Jaipur City Palace',
          'location': 'Jaipur, Rajasthan',
          'description': 'The City Palace is a magnificent blend of Rajasthani and Mughal architecture. Still partially inhabited by the royal family, it stands as a symbol of royal heritage and architectural brilliance.',
          'image': 'https://images.unsplash.com/photo-1571997477406-f935529e4a96?w=500&h=400&fit=crop',
          'rating': 4.6,
          'reviews': 1432,
          'price': 500,
          'duration': '3-4 hours',
          'difficulty': 'easy',
          'highlights': 'Royal Architecture, Museum Tour, Photography, Cultural Insights',
          'amenities': 'Guided Tours, Museum, Cafe, Gift Shop',
          'groupSize': 60,
          'category': 'Heritage',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Varanasi Ghats',
          'location': 'Varanasi, Uttar Pradesh',
          'description': 'The holy city of Varanasi is situated on the banks of the sacred Ganges River. The ghats are lined with ancient temples and are believed to be one of the holiest pilgrimage sites in Hinduism.',
          'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop',
          'rating': 4.7,
          'reviews': 2134,
          'price': 1500,
          'duration': '2-3 days',
          'difficulty': 'easy',
          'highlights': 'Ganges Aarti, Boat Rides, Temple Visits, Spiritual Experience',
          'amenities': 'Ghats Access, Boat Tours, Lodges, Restaurants',
          'groupSize': 35,
          'category': 'Religious',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Udaipur Lakes',
          'location': 'Udaipur, Rajasthan',
          'description': 'The City of Lakes, Udaipur is a romantic destination surrounded by beautiful lakes and palaces. Lake Pichola with the stunning City Palace reflected in its waters is a sight to behold.',
          'image': 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=500&h=400&fit=crop',
          'rating': 4.8,
          'reviews': 1765,
          'price': 2500,
          'duration': '3-4 days',
          'difficulty': 'easy',
          'highlights': 'Lake Cruises, Palace Tours, Sunset Views, Folk Performances',
          'amenities': 'Lake Resorts, Boat Services, Restaurants, Heritage Hotels',
          'groupSize': 45,
          'category': 'Heritage',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Munnar Tea Plantations',
          'location': 'Munnar, Kerala',
          'description': 'Munnar is a picturesque hill station known for its tea plantations, mist-covered mountains, and misty mornings. It\'s a perfect destination for nature lovers and adventure seekers.',
          'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop',
          'rating': 4.6,
          'reviews': 1543,
          'price': 2000,
          'duration': '2-3 days',
          'difficulty': 'easy',
          'highlights': 'Tea Plantation Tours, Mountain Trekking, Scenic Views, Local Cuisine',
          'amenities': 'Tea Estate Stays, Guided Tours, Restaurants, Trekking Guides',
          'groupSize': 25,
          'category': 'Nature',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Andaman Islands',
          'location': 'Andaman and Nicobar Islands',
          'description': 'A tropical paradise with pristine beaches, coral reefs, and crystal clear waters. Andaman is perfect for beach lovers, divers, and those seeking adventure and tranquility.',
          'image': 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&h=400&fit=crop',
          'rating': 4.8,
          'reviews': 1654,
          'price': 4000,
          'duration': '4-5 days',
          'difficulty': 'easy',
          'highlights': 'Beach Paradise, Scuba Diving, Island Hopping, Water Sports',
          'amenities': 'Beach Resorts, Diving Centers, Boat Tours, Water Sports',
          'groupSize': 30,
          'category': 'Beach',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
        {
          'title': 'Manali',
          'location': 'Manali, Himachal Pradesh',
          'description': 'A popular hill station known for its scenic beauty, adventure activities, and pleasant climate. Surrounded by mountains, forests, and rivers, Manali is perfect for adventure and nature lovers.',
          'image': 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop',
          'rating': 4.6,
          'reviews': 1876,
          'price': 2000,
          'duration': '3-4 days',
          'difficulty': 'medium',
          'highlights': 'Adventure Sports, Trekking, River Rafting, Mountain Views',
          'amenities': 'Adventure Centers, Hill Resorts, Restaurants, Guides',
          'groupSize': 25,
          'category': 'Adventure',
          'created_by': 'admin',
          'created_at': DateTime.now().toIso8601String(),
        },
      ];

      // Insert all destinations
      for (var destination in destinations) {
        try {
          await client.from('trips').insert(destination);
          print('✓ Inserted: ${destination['title']}');
        } catch (e) {
          print('✗ Error inserting ${destination['title']}: $e');
        }
      }
      
      print('Seeding completed!');
    } catch (e) {
      print('Error seeding destinations: $e');
      rethrow;
    }
  }

  // Admin Methods - Add Destination
  Future<void> addDestination(dynamic destination) async {
    try {
      final destinationJson = destination.toJson();
      await client.from('destinations').insert(destinationJson);
      print('✓ Destination added to database: ${destination.title}');
    } catch (e) {
      print('✗ Error adding destination: $e');
      rethrow;
    }
  }
}
