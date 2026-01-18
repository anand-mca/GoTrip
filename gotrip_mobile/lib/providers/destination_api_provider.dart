import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DestinationAPIProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _destinations = [];
  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = false;
  String? _error;
  bool _backendAvailable = false;

  List<Map<String, dynamic>> get destinations => _destinations;
  List<Map<String, dynamic>> get hotels => _hotels;
  List<Map<String, dynamic>> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get backendAvailable => _backendAvailable;

  /// Check if backend is available
  Future<void> checkBackendHealth() async {
    try {
      _backendAvailable = await APIService.healthCheck();
      notifyListeners();
    } catch (e) {
      _backendAvailable = false;
      notifyListeners();
    }
  }

  /// Fetch recommended destinations based on preferences
  Future<void> fetchRecommendedDestinations({
    required List<String> preferences,
    required int budget,
    required int days,
    required String userLocation,
  }) async {
    _isLoading = true;
    _error = null;
    _destinations = [];
    notifyListeners();

    try {
      final destinations = await APIService.fetchDestinationsByPreferences(
        preferences: preferences,
        maxBudget: budget,
        days: days,
        location: userLocation,
      );

      _destinations = destinations;
      if (destinations.isEmpty) {
        _error = 'No destinations found matching your criteria.';
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching destinations: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search destinations by keyword
  Future<void> searchDestinations(String query) async {
    if (query.isEmpty) {
      _destinations = [];
      notifyListeners();
      return;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final results = await APIService.searchDestinations(query);
      _destinations = results;
    } catch (e) {
      _error = e.toString();
      print('Error searching destinations: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get detailed information about a destination
  Future<Map<String, dynamic>> getDestinationDetails(String destinationId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final details = await APIService.getDestinationDetails(destinationId);
      return details;
    } catch (e) {
      _error = e.toString();
      print('Error fetching destination details: $_error');
      return {};
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch hotels for a destination
  Future<void> fetchHotels({
    required String destination,
    required String checkIn,
    required String checkOut,
    int? maxPrice,
  }) async {
    _isLoading = true;
    _error = null;
    _hotels = [];
    notifyListeners();

    try {
      final hotels = await APIService.getHotels(
        destination: destination,
        checkIn: checkIn,
        checkOut: checkOut,
        maxPrice: maxPrice,
      );

      _hotels = hotels;
      if (hotels.isEmpty) {
        _error = 'No hotels found for this destination.';
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching hotels: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch activities for a destination
  Future<void> fetchActivities({
    required String destination,
    required List<String> categories,
    int? maxPrice,
  }) async {
    _isLoading = true;
    _error = null;
    _activities = [];
    notifyListeners();

    try {
      final activities = await APIService.getActivities(
        destination: destination,
        categories: categories,
        maxPrice: maxPrice,
      );

      _activities = activities;
      if (activities.isEmpty) {
        _error = 'No activities found for this destination.';
      }
    } catch (e) {
      _error = e.toString();
      print('Error fetching activities: $_error');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear all data
  void clearAll() {
    _destinations = [];
    _hotels = [];
    _activities = [];
    _error = null;
    notifyListeners();
  }
}
