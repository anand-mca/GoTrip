import 'package:flutter/material.dart';
import '../models/destination_model.dart';
import '../services/supabase_service.dart';

class DestinationProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Destination> _destinations = [];
  List<Destination> _filteredDestinations = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _favorites = {};

  List<Destination> get destinations => _destinations;
  List<Destination> get filteredDestinations => _filteredDestinations;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get favorites => _favorites;

  // Check if a destination is in favorites
  bool isFavorite(String destinationId) {
    return _favorites.contains(destinationId);
  }

  // Load user's favorites from Supabase
  Future<void> loadUserFavorites(String userId) async {
    try {
      final favoriteIds = await _supabaseService.getUserFavoriteIds(userId);
      _favorites = Set<String>.from(favoriteIds);
      print('✓ Loaded ${_favorites.length} favorites for user');
      notifyListeners();
    } catch (e) {
      print('✗ Error loading favorites: $e');
      _error = e.toString();
    }
  }

  // Toggle favorite status for a destination
  Future<void> toggleFavorite(String userId, String destinationId) async {
    try {
      if (_favorites.contains(destinationId)) {
        await _supabaseService.removeFromFavorites(userId, destinationId);
        _favorites.remove(destinationId);
        print('✓ Removed from favorites: $destinationId');
      } else {
        await _supabaseService.addToFavorites(userId, destinationId);
        _favorites.add(destinationId);
        print('✓ Added to favorites: $destinationId');
      }
      notifyListeners();
    } catch (e) {
      print('✗ Error toggling favorite: $e');
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchAllDestinations() async {
    _isLoading = true;
    _error = null;

    try {
      final destinationsData = await _supabaseService.getDestinations();
      print('✓ Fetched ${destinationsData.length} destinations from Supabase');
      _destinations = destinationsData.map((data) => Destination.fromJson(data)).toList();
      _filteredDestinations = _destinations;
      print('✓ Converted to Destination models: ${_destinations.length}');
    } catch (e) {
      print('✗ Error fetching destinations: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchDestinations(String query) async {
    if (query.isEmpty) {
      _filteredDestinations = _destinations;
    } else {
      try {
        final results = await _supabaseService.searchDestinations(query);
        _filteredDestinations = results.map((data) => Destination.fromJson(data)).toList();
      } catch (e) {
        _error = e.toString();
      }
    }
    notifyListeners();
  }

  void filterDestinations({
    String? difficulty,
    String? category,
    double? maxPrice,
  }) {
    _filteredDestinations = _destinations.where((destination) {
      if (difficulty != null && difficulty != 'All' && destination.difficulty != difficulty) {
        return false;
      }
      if (category != null && category != 'All' && destination.category != category) {
        return false;
      }
      if (maxPrice != null && destination.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  Future<Destination?> getDestinationById(String destinationId) async {
    try {
      final destinationData = await _supabaseService.getDestinationById(destinationId);
      if (destinationData != null) {
        return Destination.fromJson(destinationData);
      }
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  // Get list of favorite destinations as Destination objects
  List<Destination> get favoriteDestinations {
    return _destinations.where((d) => _favorites.contains(d.id)).toList();
  }

  Future<void> addDestination(Destination destination) async {
    try {
      await _supabaseService.addDestination(destination);
      _destinations.add(destination);
      _filteredDestinations = _destinations;
      notifyListeners();
      print('✓ Destination added successfully: ${destination.title}');
    } catch (e) {
      _error = e.toString();
      print('✗ Error adding destination: $e');
      notifyListeners();
      rethrow;
    }
  }
}
