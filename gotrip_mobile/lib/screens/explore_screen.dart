import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../models/trip_model.dart';
import '../widgets/trip_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final List<String> savedTrips = [];
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';
  RangeValues _priceRange = const RangeValues(0, 3000);

  final List<String> _categories = ['All', 'Mountain', 'Beach', 'City', 'Adventure'];
  final List<String> _difficulties = ['All', 'Easy', 'Moderate', 'Hard'];

  final List<Trip> _allTrips = [
    Trip(
      id: '1',
      title: 'Swiss Alps Adventure',
      description: 'Experience the majestic Swiss Alps',
      image: 'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=500&h=400&fit=crop',
      location: 'Switzerland',
      rating: 4.8,
      reviews: 234,
      price: 1299.99,
      duration: 7,
      difficulty: 'Moderate',
      highlights: [],
      amenities: [],
      groupSize: 12,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '2',
      title: 'Tropical Paradise',
      description: 'Relax on pristine beaches',
      image: 'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=500&h=400&fit=crop',
      location: 'Maldives',
      rating: 4.9,
      reviews: 567,
      price: 1899.99,
      duration: 5,
      difficulty: 'Easy',
      highlights: [],
      amenities: [],
      groupSize: 20,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '3',
      title: 'Ancient Wonders',
      description: 'Explore historical sites',
      image: 'https://images.unsplash.com/photo-1499856871957-5b8620a56b38?w=500&h=400&fit=crop',
      location: 'Egypt',
      rating: 4.7,
      reviews: 345,
      price: 999.99,
      duration: 6,
      difficulty: 'Easy',
      highlights: [],
      amenities: [],
      groupSize: 15,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '4',
      title: 'Amazon Rainforest',
      description: 'Wildlife expedition',
      image: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=500&h=400&fit=crop',
      location: 'Brazil',
      rating: 4.6,
      reviews: 289,
      price: 2499.99,
      duration: 10,
      difficulty: 'Hard',
      highlights: [],
      amenities: [],
      groupSize: 8,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
    Trip(
      id: '5',
      title: 'Tokyo Modern',
      description: 'Blend of tradition and tech',
      image: 'https://images.unsplash.com/photo-1540959375944-7049f642e9f1?w=500&h=400&fit=crop',
      location: 'Japan',
      rating: 4.8,
      reviews: 456,
      price: 1499.99,
      duration: 7,
      difficulty: 'Easy',
      highlights: [],
      amenities: [],
      groupSize: 18,
      createdAt: DateTime.now(),
      createdBy: 'admin',
    ),
  ];

  List<Trip> get _filteredTrips {
    return _allTrips.where((trip) {
      final matchesSearch = trip.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          trip.location.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesPrice = trip.price >= _priceRange.start && trip.price <= _priceRange.end;
      final matchesDifficulty = _selectedDifficulty == 'All' || trip.difficulty == _selectedDifficulty;
      return matchesSearch && matchesPrice && matchesDifficulty;
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Trips'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    setState(() {});
                  },
                  decoration: InputDecoration(
                    hintText: 'Search destination...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: const Icon(Icons.clear),
                    )
                        : null,
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                // Filter Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      _showFilterBottomSheet(context);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white),
                      foregroundColor: Colors.white,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune),
                        SizedBox(width: AppSpacing.sm),
                        Text('Filters'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Category Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: _categories.map((category) {
                final isSelected = _selectedCategory == category;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    backgroundColor: AppColors.surfaceAlt,
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Results
          Expanded(
            child: _filteredTrips.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.explore,
                    size: 64,
                    color: AppColors.border,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'No trips found',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Try adjusting your filters',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: _filteredTrips.length,
              itemBuilder: (context, index) {
                final trip = _filteredTrips[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: TripCard(
                    title: trip.title,
                    location: trip.location,
                    image: trip.image,
                    price: trip.price,
                    rating: trip.rating,
                    reviews: trip.reviews,
                    isSaved: savedTrips.contains(trip.id),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/trip-detail',
                        arguments: trip,
                      );
                    },
                    onSavePressed: () {
                      setState(() {
                        if (savedTrips.contains(trip.id)) {
                          savedTrips.remove(trip.id);
                        } else {
                          savedTrips.add(trip.id);
                        }
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filters',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Difficulty Filter
                  Text(
                    'Difficulty',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: AppSpacing.md,
                    children: _difficulties.map((difficulty) {
                      return FilterChip(
                        label: Text(difficulty),
                        selected: _selectedDifficulty == difficulty,
                        onSelected: (selected) {
                          setModalState(() {
                            _selectedDifficulty = difficulty;
                          });
                          setState(() {
                            _selectedDifficulty = difficulty;
                          });
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Price Filter
                  Text(
                    'Price Range: \$${_priceRange.start.toStringAsFixed(0)} - \$${_priceRange.end.toStringAsFixed(0)}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 3000,
                    divisions: 30,
                    onChanged: (RangeValues values) {
                      setModalState(() {
                        _priceRange = values;
                      });
                      setState(() {
                        _priceRange = values;
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
