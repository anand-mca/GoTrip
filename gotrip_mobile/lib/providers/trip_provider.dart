import 'package:flutter/material.dart';
import '../models/trip_model.dart';
import '../services/supabase_service.dart';

class TripProvider extends ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();
  
  List<Trip> _trips = [];
  List<Trip> _filteredTrips = [];
  bool _isLoading = false;
  String? _error;
  Set<String> _favorites = {};

  List<Trip> get trips => _trips;
  List<Trip> get filteredTrips => _filteredTrips;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get favorites => _favorites;

  Future<void> fetchAllTrips() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final tripsData = await _supabaseService.getAllTrips();
      _trips = tripsData.map((data) => Trip.fromJson(data)).toList();
      _filteredTrips = _trips;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> searchTrips(String query) async {
    if (query.isEmpty) {
      _filteredTrips = _trips;
    } else {
      try {
        final results = await _supabaseService.searchTrips(query);
        _filteredTrips = results.map((data) => Trip.fromJson(data)).toList();
      } catch (e) {
        _error = e.toString();
      }
    }
    notifyListeners();
  }

  void filterTrips({
    String? difficulty,
    String? category,
    double? maxPrice,
  }) {
    _filteredTrips = _trips.where((trip) {
      if (difficulty != null && difficulty != 'All' && trip.difficulty != difficulty) {
        return false;
      }
      if (maxPrice != null && trip.price > maxPrice) {
        return false;
      }
      return true;
    }).toList();
    notifyListeners();
  }

  Future<Trip?> getTripById(String tripId) async {
    try {
      final tripData = await _supabaseService.getTripById(tripId);
      if (tripData != null) {
        return Trip.fromJson(tripData);
      }
    } catch (e) {
      _error = e.toString();
    }
    return null;
  }

  Future<void> addToFavorites(String userId, String tripId) async {
    try {
      await _supabaseService.addToFavorites(userId, tripId);
      _favorites.add(tripId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> removeFromFavorites(String userId, String tripId) async {
    try {
      await _supabaseService.removeFromFavorites(userId, tripId);
      _favorites.remove(tripId);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadUserFavorites(String userId) async {
    try {
      final favorites = await _supabaseService.getUserFavorites(userId);
      _favorites = favorites.map((fav) => fav['trip_id'] as String).toSet();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isFavorite(String tripId) {
    return _favorites.contains(tripId);
  }

  void reset() {
    _trips = [];
    _filteredTrips = [];
    _isLoading = false;
    _error = null;
    _favorites = {};
    notifyListeners();
  }
}
