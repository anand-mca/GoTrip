class TripPlan {
  final String? id;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final List<String> preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TripPlan({
    this.id,
    required this.startDate,
    required this.endDate,
    required this.budget,
    required this.preferences,
    DateTime? createdAt,
    this.updatedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Calculate trip duration in days
  int get tripDuration {
    return endDate.difference(startDate).inDays + 1;
  }

  // Calculate budget per day
  double get budgetPerDay {
    return tripDuration > 0 ? budget / tripDuration : 0;
  }

  // Convert to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'budget': budget,
      'preferences': preferences,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory TripPlan.fromJson(Map<String, dynamic> json) {
    return TripPlan(
      id: json['id'],
      startDate: DateTime.parse(json['start_date']),
      endDate: DateTime.parse(json['end_date']),
      budget: (json['budget'] as num).toDouble(),
      preferences: List<String>.from(json['preferences'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }
}

// Available preference categories
const List<String> tripPreferenceCategories = [
  'Beaches',
  'Mountains',
  'Adventure',
  'Nature',
  'Heritage',
  'Culture',
  'Food',
  'Shopping',
  'Nightlife',
  'Wellness',
  'Art',
  'Photography',
];
