import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../utils/app_constants.dart';
import '../models/trip_model.dart';
import '../models/destination_model.dart';
import '../widgets/custom_button.dart';
import '../providers/theme_provider.dart';
import '../providers/destination_api_provider.dart';

class TripDetailScreen extends StatefulWidget {
  final dynamic trip; // Can be Trip or Destination

  const TripDetailScreen({Key? key, required this.trip}) : super(key: key);

  @override
  State<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends State<TripDetailScreen> {
  bool _isSaved = false;
  int _selectedTabIndex = 0;
  bool _isLoadingDetails = false;
  Map<String, dynamic>? _apiDestinationDetails;
  bool _imageLoadError = false;

  @override
  void initState() {
    super.initState();
    _fetchDestinationDetails();
  }

  /// Fetch destination details from API
  Future<void> _fetchDestinationDetails() async {
    // Try to get destination ID or name to fetch details
    if (widget.trip is Destination) {
      final destination = widget.trip as Destination;
      // If destination has an ID, fetch from API
      if (destination.id != null && destination.id!.isNotEmpty) {
        setState(() => _isLoadingDetails = true);
        try {
          final apiProvider = context.read<DestinationAPIProvider>();
          final details = await apiProvider.getDestinationDetails(destination.id!);
          if (details.isNotEmpty && mounted) {
            setState(() {
              _apiDestinationDetails = details;
              _isLoadingDetails = false;
            });
          } else {
            setState(() => _isLoadingDetails = false);
          }
        } catch (e) {
          print('Error fetching destination details: $e');
          setState(() => _isLoadingDetails = false);
        }
      }
    }
  }

  /// Get category icon based on destination category
  IconData _getCategoryIcon(String category) {
    final categoryLower = category.toLowerCase();
    if (categoryLower.contains('beach')) return Icons.beach_access;
    if (categoryLower.contains('history') || categoryLower.contains('historical')) return Icons.account_balance;
    if (categoryLower.contains('adventure')) return Icons.terrain;
    if (categoryLower.contains('food')) return Icons.restaurant;
    if (categoryLower.contains('shopping')) return Icons.shopping_bag;
    if (categoryLower.contains('nature') || categoryLower.contains('wildlife')) return Icons.nature;
    if (categoryLower.contains('religious') || categoryLower.contains('temple') || categoryLower.contains('spiritual')) return Icons.temple_hindu;
    if (categoryLower.contains('cultural') || categoryLower.contains('culture')) return Icons.museum;
    return Icons.place; // Default icon
  }

  String get _category => widget.trip is Destination 
      ? (widget.trip as Destination).category 
      : (widget.trip as Trip).category;

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
  
  List<String> get _amenities {
    // Use API data if available, otherwise use model data
    if (_apiDestinationDetails != null && _apiDestinationDetails!['amenities'] != null) {
      final apiAmenities = _apiDestinationDetails!['amenities'];
      if (apiAmenities is List) {
        return apiAmenities.map((e) => e.toString()).toList();
      }
    }
    return widget.trip is Destination 
        ? (widget.trip as Destination).amenities 
        : (widget.trip as Trip).amenities;
  }

  String get _finalDescription {
    // Use API data if available
    if (_apiDestinationDetails != null && _apiDestinationDetails!['description'] != null) {
      return _apiDestinationDetails!['description'].toString();
    }
    return _description;
  }

  List<String> get _finalHighlights {
    // Use API data if available
    if (_apiDestinationDetails != null && _apiDestinationDetails!['highlights'] != null) {
      final apiHighlights = _apiDestinationDetails!['highlights'];
      if (apiHighlights is List) {
        return apiHighlights.map((e) => e.toString()).toList();
      }
    }
    return _highlights;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final surfaceColor = themeProvider.surfaceColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image or Category Icon
          SliverAppBar(
            expandedHeight: 300,
            floating: false,
            pinned: true,
            backgroundColor: surfaceColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Try to load image, fallback to category icon
                  _imageLoadError
                      ? Container(
                          color: surfaceColor,
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(_category),
                              size: 120,
                              color: primaryColor.withOpacity(0.5),
                            ),
                          ),
                        )
                      : Image.network(
                          _image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            // On error, show category icon
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (mounted && !_imageLoadError) {
                                setState(() => _imageLoadError = true);
                              }
                            });
                            return Container(
                              color: surfaceColor,
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(_category),
                                  size: 120,
                                  color: primaryColor.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
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
                  color: surfaceColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: IconButton(
                  icon: Icon(
                    _isSaved ? Icons.favorite : Icons.favorite_border,
                    color: _isSaved ? primaryColor : textColor,
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
                              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                color: textColor,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  _location,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: textColor,
                                  ),
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
                              color: primaryColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 16,
                                  color: primaryColor,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  '$_rating',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '$_reviews reviews',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: textColor.withOpacity(0.7),
                            ),
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
                      'About This Destination',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _isLoadingDetails 
                        ? Center(child: CircularProgressIndicator(color: primaryColor))
                        : Text(
                            _finalDescription,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: textColor,
                            ),
                          ),
                  ] else if (_selectedTabIndex == 1) ...[
                    Text(
                      'Highlights',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _isLoadingDetails
                        ? Center(child: CircularProgressIndicator(color: primaryColor))
                        : Column(
                            children: _finalHighlights.map((highlight) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      color: primaryColor,
                                      size: 20,
                                    ),
                                    const SizedBox(width: AppSpacing.md),
                                    Expanded(
                                      child: Text(
                                        highlight,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                  ] else if (_selectedTabIndex == 2) ...[
                    Text(
                      'What\'s Included',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _isLoadingDetails
                        ? Center(child: CircularProgressIndicator(color: primaryColor))
                        : Wrap(
                            spacing: AppSpacing.md,
                            runSpacing: AppSpacing.md,
                            children: _amenities.map((amenity) {
                              return Chip(
                                label: Text(
                                  amenity,
                                  style: TextStyle(
                                    color: textColor,
                                  ),
                                ),
                                backgroundColor: surfaceColor,
                                side: BorderSide(
                                  color: primaryColor.withOpacity(0.3),
                                  width: 1,
                                ),
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
    );
  }

  Widget _buildInfoCard(String label, IconData icon) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final surfaceColor = themeProvider.surfaceColor;
    final textColor = themeProvider.textColor;
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryColor),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final surfaceColor = themeProvider.surfaceColor;
    final textColor = themeProvider.textColor;
    final isDarkMode = themeProvider.isDarkMode;
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
          color: isSelected ? primaryColor : surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: isSelected 
              ? null 
              : Border.all(
                  color: primaryColor.withOpacity(0.3),
                  width: 1,
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
                ? (isDarkMode ? Colors.black : Colors.white)
                : textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
