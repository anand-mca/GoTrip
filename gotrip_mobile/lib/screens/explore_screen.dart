import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../models/destination_model.dart';
import '../providers/destination_provider.dart';
import '../widgets/trip_card.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({Key? key}) : super(key: key);

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _searchController = TextEditingController();
  final List<String> savedDestinations = [];
  String _selectedCategory = 'All';
  String _selectedDifficulty = 'All';

  final List<String> _difficulties = ['All', 'easy', 'moderate', 'hard']; 

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DestinationProvider>().fetchAllDestinations();
    });
  }

  List<String> get _categories {
    final provider = context.read<DestinationProvider>();
    final categorySet = <String>{'All'};
    
    // Only add categories that have destinations in the database
    for (var destination in provider.destinations) {
      categorySet.add(destination.category);
    }
    
    return categorySet.toList();
  }

  List<Destination> _getFilteredDestinations(List<Destination> destinations) {
    return destinations.where((destination) {
      final matchesSearch = destination.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          destination.location.toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesDifficulty = _selectedDifficulty == 'All' || destination.difficulty.toLowerCase() == _selectedDifficulty.toLowerCase();
      
      // Simple direct matching with lowercase comparison
      final matchesCategory = _selectedCategory == 'All' || 
          destination.category.toLowerCase() == _selectedCategory.toLowerCase();
      
      return matchesSearch && matchesDifficulty && matchesCategory;
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
      body: Consumer<DestinationProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final filteredDestinations = _getFilteredDestinations(provider.destinations);

          return Column(
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
                child: filteredDestinations.isEmpty
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
                  itemCount: filteredDestinations.length,
                  itemBuilder: (context, index) {
                    final destination = filteredDestinations[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: TripCard(
                        title: destination.title,
                        location: destination.location,
                        image: destination.image,
                        price: destination.price,
                        rating: destination.rating,
                        reviews: destination.reviews,
                        isSaved: savedDestinations.contains(destination.id),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/trip-detail',
                            arguments: destination,
                          );
                        },
                        onSavePressed: () {
                          setState(() {
                            if (savedDestinations.contains(destination.id)) {
                              savedDestinations.remove(destination.id);
                            } else {
                              savedDestinations.add(destination.id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
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
