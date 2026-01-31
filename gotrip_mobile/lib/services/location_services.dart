import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Service for fetching weather, restaurants, hotels, and attractions
/// Uses free APIs: Open-Meteo (weather) and OpenStreetMap Overpass (POIs)
class LocationServices {
  static final LocationServices _instance = LocationServices._internal();
  factory LocationServices() => _instance;
  LocationServices._internal();

  // Cache for API responses to reduce calls
  final Map<String, _CachedData> _cache = {};
  static const Duration _cacheDuration = Duration(minutes: 30);

  // ==================== WEATHER SERVICES ====================
  
  /// Get weather alert for a location using Open-Meteo API (completely free, no key needed)
  Future<WeatherAlert> getWeatherAlert(double latitude, double longitude) async {
    final cacheKey = 'weather_${latitude.toStringAsFixed(2)}_${longitude.toStringAsFixed(2)}';
    
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      return _cache[cacheKey]!.data as WeatherAlert;
    }

    try {
      // Open-Meteo API - completely free, unlimited calls
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast'
        '?latitude=$latitude'
        '&longitude=$longitude'
        '&current=temperature_2m,relative_humidity_2m,precipitation,rain,weather_code,wind_speed_10m'
        '&daily=uv_index_max,precipitation_sum,weather_code'
        '&timezone=auto'
        '&forecast_days=1'
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final alert = _parseWeatherAlert(data);
        _cache[cacheKey] = _CachedData(alert, DateTime.now());
        return alert;
      } else {
        throw Exception('Weather API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weather: $e');
      return WeatherAlert(
        message: 'Unable to fetch weather data. Please check your connection.',
        alertType: AlertType.info,
        icon: '🌤️',
      );
    }
  }

  WeatherAlert _parseWeatherAlert(Map<String, dynamic> data) {
    try {
      final current = data['current'] ?? {};
      final daily = data['daily'] ?? {};
      
      final temperature = current['temperature_2m'] ?? 0;
      final humidity = current['relative_humidity_2m'] ?? 0;
      final precipitation = current['precipitation'] ?? 0;
      final rain = current['rain'] ?? 0;
      final windSpeed = current['wind_speed_10m'] ?? 0;
      final weatherCode = current['weather_code'] ?? 0;
      
      // Get UV index from daily forecast
      final uvIndexList = daily['uv_index_max'] as List?;
      final uvIndex = uvIndexList != null && uvIndexList.isNotEmpty 
          ? (uvIndexList[0] ?? 0).toDouble() 
          : 0.0;

      List<String> alerts = [];
      String icon = '☀️';
      AlertType alertType = AlertType.safe;

      // Check for severe weather codes
      // WMO Weather codes: https://open-meteo.com/en/docs
      if (weatherCode >= 95) {
        // Thunderstorm
        alerts.add('⚡ Thunderstorm warning! Stay indoors if possible.');
        icon = '⛈️';
        alertType = AlertType.danger;
      } else if (weatherCode >= 80) {
        // Rain showers
        alerts.add('🌧️ Rain expected. Carry an umbrella!');
        icon = '🌧️';
        alertType = AlertType.warning;
      } else if (weatherCode >= 71) {
        // Snow
        alerts.add('❄️ Snowfall expected. Dress warmly!');
        icon = '❄️';
        alertType = AlertType.warning;
      } else if (weatherCode >= 61) {
        // Rain
        alerts.add('🌧️ Rainy conditions. Be careful on roads.');
        icon = '🌧️';
        alertType = AlertType.warning;
      } else if (weatherCode >= 51) {
        // Drizzle
        alerts.add('🌦️ Light drizzle expected.');
        icon = '🌦️';
        alertType = AlertType.info;
      } else if (weatherCode >= 45) {
        // Fog
        alerts.add('🌫️ Foggy conditions. Drive carefully!');
        icon = '🌫️';
        alertType = AlertType.warning;
      }

      // UV Index check (especially important for India)
      if (uvIndex >= 11) {
        alerts.add('☀️ EXTREME UV Index ($uvIndex)! Avoid outdoor exposure between 10am-4pm.');
        alertType = AlertType.danger;
        icon = '🔥';
      } else if (uvIndex >= 8) {
        alerts.add('☀️ Very high UV Index ($uvIndex)! Use SPF 50+, wear sunglasses and a hat.');
        if (alertType != AlertType.danger) alertType = AlertType.warning;
      } else if (uvIndex >= 6) {
        alerts.add('🌤️ High UV Index ($uvIndex). Apply sunscreen and seek shade during midday.');
        if (alertType == AlertType.safe) alertType = AlertType.info;
      }

      // High temperature check
      if (temperature >= 40) {
        alerts.add('🌡️ Extreme heat ($temperature°C)! Stay hydrated and avoid prolonged outdoor activities.');
        alertType = AlertType.danger;
      } else if (temperature >= 35) {
        alerts.add('🌡️ High temperature ($temperature°C). Stay hydrated!');
        if (alertType != AlertType.danger) alertType = AlertType.warning;
      }

      // High wind check
      if (windSpeed >= 50) {
        alerts.add('💨 Strong winds ($windSpeed km/h)! Be cautious outdoors.');
        if (alertType != AlertType.danger) alertType = AlertType.warning;
      }

      // Humidity check
      if (humidity >= 85) {
        alerts.add('💧 High humidity ($humidity%). It may feel hotter than actual temperature.');
      }

      // If no alerts, it's a good day!
      if (alerts.isEmpty) {
        return WeatherAlert(
          message: '✨ The weather looks great! Enjoy your destination.\n'
              '🌡️ Temperature: ${temperature.toStringAsFixed(1)}°C\n'
              '☀️ UV Index: ${uvIndex.toStringAsFixed(1)}',
          alertType: AlertType.safe,
          icon: icon,
          temperature: temperature.toDouble(),
          uvIndex: uvIndex,
          humidity: humidity.toDouble(),
        );
      }

      return WeatherAlert(
        message: alerts.join('\n'),
        alertType: alertType,
        icon: icon,
        temperature: temperature.toDouble(),
        uvIndex: uvIndex,
        humidity: humidity.toDouble(),
      );
    } catch (e) {
      print('Error parsing weather: $e');
      return WeatherAlert(
        message: 'Weather data unavailable',
        alertType: AlertType.info,
        icon: '🌤️',
      );
    }
  }

  // ==================== RESTAURANT SERVICES ====================
  
  /// Get nearby restaurants using OpenStreetMap Overpass API (completely free)
  Future<List<Restaurant>> getNearbyRestaurants(double latitude, double longitude, {String? placeName}) async {
    final cacheKey = 'restaurants_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      return _cache[cacheKey]!.data as List<Restaurant>;
    }

    try {
      // Search radius in meters (2km for restaurants)
      const radius = 2000;
      
      // Overpass API query for restaurants
      final query = '''
[out:json][timeout:25];
(
  node["amenity"="restaurant"](around:$radius,$latitude,$longitude);
  way["amenity"="restaurant"](around:$radius,$latitude,$longitude);
  node["amenity"="fast_food"](around:$radius,$latitude,$longitude);
  node["amenity"="cafe"]["cuisine"](around:$radius,$latitude,$longitude);
);
out body center 15;
''';

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(
        url,
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final restaurants = _parseRestaurants(data, latitude, longitude);
        _cache[cacheKey] = _CachedData(restaurants, DateTime.now());
        return restaurants;
      } else {
        throw Exception('Overpass API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching restaurants: $e');
      return [];
    }
  }

  List<Restaurant> _parseRestaurants(Map<String, dynamic> data, double refLat, double refLon) {
    final elements = data['elements'] as List? ?? [];
    List<Restaurant> restaurants = [];

    for (var element in elements) {
      try {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'];
        if (name == null || name.toString().isEmpty) continue;

        double lat = element['lat']?.toDouble() ?? 
                     element['center']?['lat']?.toDouble() ?? 0;
        double lon = element['lon']?.toDouble() ?? 
                     element['center']?['lon']?.toDouble() ?? 0;

        // Calculate distance
        final distance = _calculateDistance(refLat, refLon, lat, lon);

        // Determine if vegetarian
        final cuisine = (tags['cuisine'] ?? '').toString().toLowerCase();
        final dietVegetarian = tags['diet:vegetarian'] ?? '';
        final dietVegan = tags['diet:vegan'] ?? '';
        
        bool isVegetarian = cuisine.contains('vegetarian') || 
                           cuisine.contains('vegan') ||
                           cuisine.contains('indian_vegetarian') ||
                           dietVegetarian == 'yes' || 
                           dietVegetarian == 'only' ||
                           dietVegan == 'yes' ||
                           dietVegan == 'only';

        // Try to get rating info (if available from OSM)
        final rating = tags['stars'] ?? tags['rating'];
        double? ratingValue;
        if (rating != null) {
          ratingValue = double.tryParse(rating.toString());
        }

        restaurants.add(Restaurant(
          name: name.toString(),
          cuisine: _formatCuisine(cuisine),
          distance: distance,
          isVegetarian: isVegetarian,
          rating: ratingValue,
          address: tags['addr:street'] ?? tags['addr:full'] ?? '',
          phone: tags['phone'] ?? tags['contact:phone'],
        ));
      } catch (e) {
        continue;
      }
    }

    // Sort by distance
    restaurants.sort((a, b) => a.distance.compareTo(b.distance));

    // Return top 3
    return restaurants.take(3).toList();
  }

  String _formatCuisine(String cuisine) {
    if (cuisine.isEmpty) return 'Restaurant';
    // Format cuisine string
    return cuisine
        .split(';')
        .first
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1)}' 
            : '')
        .join(' ');
  }

  // ==================== HOTEL/ACCOMMODATION SERVICES ====================
  
  /// Get nearby hotels/accommodations using OpenStreetMap Overpass API
  Future<List<Hotel>> getNearbyHotels(double latitude, double longitude) async {
    final cacheKey = 'hotels_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      return _cache[cacheKey]!.data as List<Hotel>;
    }

    try {
      const radius = 3000; // 3km for hotels
      
      final query = '''
[out:json][timeout:25];
(
  node["tourism"="hotel"](around:$radius,$latitude,$longitude);
  way["tourism"="hotel"](around:$radius,$latitude,$longitude);
  node["tourism"="guest_house"](around:$radius,$latitude,$longitude);
  node["tourism"="hostel"](around:$radius,$latitude,$longitude);
  node["tourism"="motel"](around:$radius,$latitude,$longitude);
  way["tourism"="guest_house"](around:$radius,$latitude,$longitude);
);
out body center 15;
''';

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(
        url,
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final hotels = _parseHotels(data, latitude, longitude);
        _cache[cacheKey] = _CachedData(hotels, DateTime.now());
        return hotels;
      } else {
        throw Exception('Overpass API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching hotels: $e');
      return [];
    }
  }

  List<Hotel> _parseHotels(Map<String, dynamic> data, double refLat, double refLon) {
    final elements = data['elements'] as List? ?? [];
    List<Hotel> hotels = [];

    for (var element in elements) {
      try {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'];
        if (name == null || name.toString().isEmpty) continue;

        double lat = element['lat']?.toDouble() ?? 
                     element['center']?['lat']?.toDouble() ?? 0;
        double lon = element['lon']?.toDouble() ?? 
                     element['center']?['lon']?.toDouble() ?? 0;

        final distance = _calculateDistance(refLat, refLon, lat, lon);

        // Get hotel type
        final tourism = tags['tourism'] ?? 'hotel';
        String type = 'Hotel';
        if (tourism == 'guest_house') type = 'Homestay';
        else if (tourism == 'hostel') type = 'Hostel';
        else if (tourism == 'motel') type = 'Motel';

        // Try to get rating/stars
        final stars = tags['stars'];
        int? starRating;
        if (stars != null) {
          starRating = int.tryParse(stars.toString());
        }

        // Price estimation based on type and stars (rough estimate for India)
        int? estimatedPrice;
        if (starRating != null) {
          if (starRating >= 5) estimatedPrice = 8000;
          else if (starRating >= 4) estimatedPrice = 4000;
          else if (starRating >= 3) estimatedPrice = 2000;
          else estimatedPrice = 1000;
        } else if (type == 'Hostel') {
          estimatedPrice = 500;
        } else if (type == 'Homestay') {
          estimatedPrice = 1500;
        }

        hotels.add(Hotel(
          name: name.toString(),
          type: type,
          distance: distance,
          starRating: starRating,
          estimatedPrice: estimatedPrice,
          address: tags['addr:street'] ?? tags['addr:full'] ?? '',
          phone: tags['phone'] ?? tags['contact:phone'],
        ));
      } catch (e) {
        continue;
      }
    }

    // Sort by distance
    hotels.sort((a, b) => a.distance.compareTo(b.distance));

    return hotels.take(3).toList();
  }

  // ==================== ATTRACTIONS SERVICES ====================
  
  /// Get nearby attractions using OpenStreetMap Overpass API
  Future<List<Attraction>> getNearbyAttractions(double latitude, double longitude) async {
    final cacheKey = 'attractions_${latitude.toStringAsFixed(3)}_${longitude.toStringAsFixed(3)}';
    
    if (_cache.containsKey(cacheKey) && !_cache[cacheKey]!.isExpired) {
      return _cache[cacheKey]!.data as List<Attraction>;
    }

    try {
      const radius = 5000; // 5km for attractions
      
      final query = '''
[out:json][timeout:25];
(
  node["tourism"="attraction"](around:$radius,$latitude,$longitude);
  node["tourism"="viewpoint"](around:$radius,$latitude,$longitude);
  node["tourism"="museum"](around:$radius,$latitude,$longitude);
  node["historic"](around:$radius,$latitude,$longitude);
  node["leisure"="park"]["name"](around:$radius,$latitude,$longitude);
  node["natural"="beach"](around:$radius,$latitude,$longitude);
  node["amenity"="place_of_worship"]["name"](around:$radius,$latitude,$longitude);
  way["tourism"="attraction"](around:$radius,$latitude,$longitude);
  way["tourism"="viewpoint"](around:$radius,$latitude,$longitude);
  way["leisure"="park"]["name"](around:$radius,$latitude,$longitude);
);
out body center 15;
''';

      final url = Uri.parse('https://overpass-api.de/api/interpreter');
      final response = await http.post(
        url,
        body: {'data': query},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final attractions = _parseAttractions(data, latitude, longitude);
        _cache[cacheKey] = _CachedData(attractions, DateTime.now());
        return attractions;
      } else {
        throw Exception('Overpass API error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching attractions: $e');
      return [];
    }
  }

  List<Attraction> _parseAttractions(Map<String, dynamic> data, double refLat, double refLon) {
    final elements = data['elements'] as List? ?? [];
    List<Attraction> attractions = [];
    Set<String> addedNames = {}; // Avoid duplicates

    for (var element in elements) {
      try {
        final tags = element['tags'] as Map<String, dynamic>? ?? {};
        final name = tags['name'];
        if (name == null || name.toString().isEmpty) continue;
        
        // Skip if already added (by similar name)
        final normalizedName = name.toString().toLowerCase().trim();
        if (addedNames.contains(normalizedName)) continue;
        addedNames.add(normalizedName);

        double lat = element['lat']?.toDouble() ?? 
                     element['center']?['lat']?.toDouble() ?? 0;
        double lon = element['lon']?.toDouble() ?? 
                     element['center']?['lon']?.toDouble() ?? 0;

        final distance = _calculateDistance(refLat, refLon, lat, lon);

        // Determine type
        String type = 'Attraction';
        String icon = '📍';
        
        if (tags['tourism'] == 'viewpoint') {
          type = 'Viewpoint';
          icon = '🏔️';
        } else if (tags['tourism'] == 'museum') {
          type = 'Museum';
          icon = '🏛️';
        } else if (tags['historic'] != null) {
          type = 'Historic Site';
          icon = '🏰';
        } else if (tags['leisure'] == 'park') {
          type = 'Park';
          icon = '🌳';
        } else if (tags['natural'] == 'beach') {
          type = 'Beach';
          icon = '🏖️';
        } else if (tags['amenity'] == 'place_of_worship') {
          type = 'Temple/Shrine';
          icon = '🛕';
        } else if (tags['shop'] != null) {
          type = 'Shopping';
          icon = '🛍️';
        }

        attractions.add(Attraction(
          name: name.toString(),
          type: type,
          icon: icon,
          distance: distance,
          description: tags['description'] ?? tags['tourism:description'],
        ));
      } catch (e) {
        continue;
      }
    }

    // Sort by distance
    attractions.sort((a, b) => a.distance.compareTo(b.distance));

    return attractions.take(3).toList();
  }

  // ==================== GEOCODING SERVICES ====================
  
  /// Get coordinates for a place name using Nominatim (free, but respect usage policy)
  Future<Map<String, double>?> getCoordinates(String placeName, {String? state, String? city}) async {
    try {
      String searchQuery = placeName;
      if (city != null && city.isNotEmpty) {
        searchQuery += ', $city';
      }
      if (state != null && state.isNotEmpty) {
        searchQuery += ', $state';
      }
      searchQuery += ', India';

      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(searchQuery)}'
        '&format=json'
        '&limit=1'
      );

      final response = await http.get(
        url,
        headers: {'User-Agent': 'GoTrip-Mobile-App/1.0'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          return {
            'latitude': double.parse(data[0]['lat']),
            'longitude': double.parse(data[0]['lon']),
          };
        }
      }
      return null;
    } catch (e) {
      print('Error geocoding: $e');
      return null;
    }
  }

  // ==================== UTILITY FUNCTIONS ====================
  
  /// Calculate distance between two points using Haversine formula
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // km
    
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    
    final a = _sin(dLat / 2) * _sin(dLat / 2) +
              _cos(_toRadians(lat1)) * _cos(_toRadians(lat2)) *
              _sin(dLon / 2) * _sin(dLon / 2);
    
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    
    return earthRadius * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double x) => _taylorSin(x);
  double _cos(double x) => _taylorSin(x + 3.14159265359 / 2);
  double _sqrt(double x) => _newtonSqrt(x);
  double _atan2(double y, double x) => _approximateAtan2(y, x);

  // Taylor series approximation for sin
  double _taylorSin(double x) {
    // Normalize to -pi to pi
    while (x > 3.14159265359) x -= 2 * 3.14159265359;
    while (x < -3.14159265359) x += 2 * 3.14159265359;
    
    double result = x;
    double term = x;
    for (int i = 1; i <= 10; i++) {
      term *= -x * x / ((2 * i) * (2 * i + 1));
      result += term;
    }
    return result;
  }

  // Newton's method for square root
  double _newtonSqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }

  // Approximate atan2
  double _approximateAtan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.14159265359;
    if (x < 0 && y < 0) return _atan(y / x) - 3.14159265359;
    if (x == 0 && y > 0) return 3.14159265359 / 2;
    if (x == 0 && y < 0) return -3.14159265359 / 2;
    return 0;
  }

  double _atan(double x) {
    // Taylor series for atan (works best for |x| < 1)
    if (x.abs() > 1) {
      return (x > 0 ? 1 : -1) * 3.14159265359 / 2 - _atan(1 / x);
    }
    double result = 0;
    double term = x;
    for (int i = 0; i < 50; i++) {
      result += term / (2 * i + 1);
      term *= -x * x;
    }
    return result;
  }
}

// ==================== DATA MODELS ====================

class _CachedData {
  final dynamic data;
  final DateTime timestamp;
  
  _CachedData(this.data, this.timestamp);
  
  bool get isExpired => 
    DateTime.now().difference(timestamp) > LocationServices._cacheDuration;
}

enum AlertType { safe, info, warning, danger }

class WeatherAlert {
  final String message;
  final AlertType alertType;
  final String icon;
  final double? temperature;
  final double? uvIndex;
  final double? humidity;

  WeatherAlert({
    required this.message,
    required this.alertType,
    required this.icon,
    this.temperature,
    this.uvIndex,
    this.humidity,
  });

  Color get alertColor {
    switch (alertType) {
      case AlertType.safe:
        return const Color(0xFF4CAF50); // Green
      case AlertType.info:
        return const Color(0xFF2196F3); // Blue
      case AlertType.warning:
        return const Color(0xFFFF9800); // Orange
      case AlertType.danger:
        return const Color(0xFFF44336); // Red
    }
  }
}

class Restaurant {
  final String name;
  final String cuisine;
  final double distance;
  final bool isVegetarian;
  final double? rating;
  final String? address;
  final String? phone;

  Restaurant({
    required this.name,
    required this.cuisine,
    required this.distance,
    required this.isVegetarian,
    this.rating,
    this.address,
    this.phone,
  });

  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).toInt()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}

class Hotel {
  final String name;
  final String type;
  final double distance;
  final int? starRating;
  final int? estimatedPrice;
  final String? address;
  final String? phone;

  Hotel({
    required this.name,
    required this.type,
    required this.distance,
    this.starRating,
    this.estimatedPrice,
    this.address,
    this.phone,
  });

  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).toInt()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }

  String get priceText {
    if (estimatedPrice == null) return '';
    return '₹$estimatedPrice/night';
  }
}

class Attraction {
  final String name;
  final String type;
  final String icon;
  final double distance;
  final String? description;

  Attraction({
    required this.name,
    required this.type,
    required this.icon,
    required this.distance,
    this.description,
  });

  String get distanceText {
    if (distance < 1) {
      return '${(distance * 1000).toInt()} m';
    }
    return '${distance.toStringAsFixed(1)} km';
  }
}
