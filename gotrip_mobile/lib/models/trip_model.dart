class Trip {
  final String id;
  final String title;
  final String description;
  final String image;
  final String location;
  final double rating;
  final int reviews;
  final double price;
  final int duration;
  final String difficulty;
  final String category;
  final List<String> highlights;
  final List<String> amenities;
  final int groupSize;
  final DateTime createdAt;
  final String createdBy;

  Trip({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.location,
    required this.rating,
    required this.reviews,
    required this.price,
    required this.duration,
    required this.difficulty,
    required this.category,
    required this.highlights,
    required this.amenities,
    required this.groupSize,
    required this.createdAt,
    required this.createdBy,
  });

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      image: json['image'] ?? '',
      location: json['location'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviews: json['reviews'] ?? 0,
      price: (json['price'] ?? 0.0).toDouble(),
      duration: json['duration'] is int ? json['duration'] : 0,
      difficulty: (json['difficulty'] ?? 'easy').toString().toLowerCase(),
      category: json['category'] ?? 'Other',
      highlights: List<String>.from(json['highlights'] ?? []),
      amenities: List<String>.from(json['amenities'] ?? []),
      groupSize: json['groupSize'] ?? 0,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'image': image,
    'location': location,
    'rating': rating,
    'reviews': reviews,
    'price': price,
    'duration': duration,
    'difficulty': difficulty,
    'category': category,
    'highlights': highlights,
    'amenities': amenities,
    'group_size': groupSize,
    'created_at': createdAt.toIso8601String(),
    'created_by': createdBy,
  };
}

