class Destination {
  final String id;
  final String title;
  final String location;
  final String description;
  final String image;
  final double rating;
  final int reviews;
  final double price;
  final int duration;
  final String difficulty;
  final List<String> highlights;
  final List<String> amenities;
  final int groupSize;
  final String category;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime updatedAt;

  Destination({
    required this.id,
    required this.title,
    required this.location,
    required this.description,
    required this.image,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.duration,
    required this.difficulty,
    required this.highlights,
    required this.amenities,
    required this.groupSize,
    required this.category,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Destination.fromJson(Map<String, dynamic> json) {
    // Parse duration - can be int or string like "4-5 hours"
    int parsedDuration = 0;
    if (json['duration'] != null) {
      if (json['duration'] is int) {
        parsedDuration = json['duration'];
      } else if (json['duration'] is String) {
        // Try to extract first number from string like "4-5 hours"
        final str = json['duration'].toString();
        final match = RegExp(r'\d+').firstMatch(str);
        if (match != null) {
          parsedDuration = int.parse(match.group(0) ?? '0');
        }
      }
    }

    return Destination(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      location: json['location'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      duration: parsedDuration,
      difficulty: json['difficulty'] ?? 'Easy',
      highlights: _parseList(json['highlights']),
      amenities: _parseList(json['amenities']),
      groupSize: json['groupSize'] ?? json['group_size'] ?? json['groupsize'] ?? 0,
      category: json['category'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : DateTime.now(),
    );
  }

  // Helper to parse lists that might be strings or arrays
  static List<String> _parseList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) {
      // Try to parse as comma-separated or from JSON array string
      return value.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'location': location,
      'description': description,
      'image': image,
      'rating': rating,
      'reviews': reviews,
      'price': price,
      'duration': duration,
      'difficulty': difficulty,
      'highlights': highlights,
      'amenities': amenities,
      'groupSize': groupSize,
      'category': category,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
