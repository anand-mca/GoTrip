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

  Future<void> addToFavorites(String userId, String destinationId) async {
    try {
      await _supabaseService.addToFavorites(userId, destinationId);
      _favorites.add(destinationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFromFavorites(String userId, String destinationId) async {
    try {
      await _supabaseService.removeFromFavorites(userId, destinationId);
      _favorites.remove(destinationId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> checkFavorites(String userId) async {
    try {
      _favorites.clear();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
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
