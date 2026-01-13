import 'package:flutter/material.dart';
import '../utils/app_constants.dart';
import '../models/trip_model.dart';
import '../models/destination_model.dart';
import '../widgets/custom_button.dart';

class TripDetailScreen extends StatefulWidget {
  final dynamic trip; // Can be Trip or Destination

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _isSaved = false;
  int _selectedTabIndex = 0;

  String get _title => widget.trip is Destination 
      ? (widget.trip as Destination).title 
      : (widget.trip as Trip).title;
  
  String get _image => widget.trip is Destination 
      ? (widget.trip as Destination).image 
      : (widget.trip as Trip).image;
  
  String get _location => widget.trip is Destination 
      ? (widget.trip as Destination).location 
      : (widget.trip as Trip).location;
  
  double get _rating => widget.trip is Destination 
      ? (widget.trip as Destination).rating 
      : (widget.trip as Trip).rating;
  
  int get _reviews => widget.trip is Destination 
      ? (widget.trip as Destination).reviews 
      : (widget.trip as Trip).reviews;
  
  int get _duration => widget.trip is Destination 
      ? (widget.trip as Destination).duration 
      : (widget.trip as Trip).duration;
  
  int get _groupSize => widget.trip is Destination 
      ? (widget.trip as Destination).groupSize 
      : (widget.trip as Trip).groupSize;
  
  String get _difficulty => widget.trip is Destination 
      ? (widget.trip as Destination).difficulty 
      : (widget.trip as Trip).difficulty;
  
  String get _description => widget.trip is Destination 
      ? (widget.trip as Destination).description 
      : (widget.trip as Trip).description;
  
  List<String> get _highlights => widget.trip is Destination 
      ? (widget.trip as Destination).highlights 
      : (widget.trip as Trip).highlights;
  
  List<String> get _amenities => widget.trip is Destination 
      ? (widget.trip as Destination).amenities 
      : (widget.trip as Trip).amenities;
  
  double get _price => widget.trip is Destination 
      ? (widget.trip as Destination).price 
      : (widget.trip as Trip).price;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    _image,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.4),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isSaved ? Icons.favorite : Icons.favorite_border,
                    color: _isSaved ? AppColors.accent : AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSaved = !_isSaved;
                    });
                  },
                ),
              ),
            ],
          ),
          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _title,
                              style: Theme.of(context).textTheme.displayMedium,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: AppColors.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _location,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: AppSpacing.sm,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accentLight.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.star,
                                  size: 16,
                                  color: AppColors.accentLight,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '$_rating',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.accentLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '$_reviews reviews',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Quick Info Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoCard('$_duration Days', Icons.calendar_today),
                      _buildInfoCard('$_groupSize People', Icons.group),
                      _buildInfoCard(_difficulty, Icons.trending_up),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Tabs
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildTab('Overview', 0),
                        const SizedBox(width: AppSpacing.md),
                        _buildTab('Highlights', 1),
                        const SizedBox(width: AppSpacing.md),
                        _buildTab('Amenities', 2),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  // Tab Content
                  if (_selectedTabIndex == 0) ...[
                    Text(
                      'About This Trip',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ] else if (_selectedTabIndex == 1) ...[
                    Text(
                      'Highlights',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Column(
                      children: _highlights.map((highlight) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 20,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                highlight,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ] else if (_selectedTabIndex == 2) ...[
                    Text(
                      'What\'s Included',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.md,
                      children: _amenities.map((amenity) {
                        return Chip(
                          label: Text(amenity),
                          backgroundColor: AppColors.surfaceAlt,
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
            ),
          ],
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price per person',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '\$$_price',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  CustomButton(
                    label: 'Book Now',
                    width: 150,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Proceeding to booking...')),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
