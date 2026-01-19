import 'package:flutter/material.dart';
import '../models/trip_plan_model.dart';
import '../utils/app_constants.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({Key? key}) : super(key: key);

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  late DateTime _startDate;
  late DateTime _endDate;
  late TextEditingController _budgetController;
  late TextEditingController _cityController;
  late Set<String> _selectedPreferences;
  String? _selectedCity;
  List<String> _availableCities = [];
  bool _citiesLoading = false;
  String? _cityError;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime.now();
    _endDate = DateTime.now().add(const Duration(days: 7));
    _budgetController = TextEditingController();
    _cityController = TextEditingController();
    _selectedPreferences = {};
    _loadAvailableCities();
  }

  Future<void> _loadAvailableCities() async {
    // Hardcoded list of cities from the database
    final citiesList = [
      'Srinagar',
      'Gulmarg',
      'Pahalgam',
      'Sonmarg',
      'Leh',
      'Nubra',
      'Changthang',
      'Shimla',
      'Manali',
      'Dharamshala',
      'Spiti',
      'Dalhousie',
      'Rishikesh',
      'Haridwar',
      'Nainital',
      'Mussoorie',
      'Auli',
      'Uttarkashi',
      'Kedarnath',
      'Badrinath',
      'Delhi',
      'Agra',
      'Varanasi',
      'Lucknow',
      'Mathura',
      'Ayodhya',
      'Jaipur',
      'Udaipur',
      'Jodhpur',
      'Jaisalmer',
      'Chittorgarh',
      'Ranthambore',
      'Kevadia',
      'Kutch',
      'Ahmedabad',
      'Junagadh',
      'Somnath',
      'Dwarka',
      'Mumbai',
      'Aurangabad',
      'Pune',
      'Lonavala',
      'Shirdi',
      'Mahabaleshwar',
      'Goa',
    ];

    setState(() {
      _availableCities = citiesList..sort();
      if (_availableCities.isNotEmpty) {
        _selectedCity = _availableCities.first;
        print('🏙️ Cities loaded: ${_availableCities.length}');
      }
    });
  }

  @override
  void dispose() {
    _budgetController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked.isBefore(_endDate)) {
      setState(() {
        _startDate = picked;
      });
    }
  }

  Future<void> _selectEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: AppColors.surface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked.isAfter(_startDate)) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  int get _tripDuration {
    return _endDate.difference(_startDate).inDays + 1;
  }

  double get _budgetPerDay {
    final budget = double.tryParse(_budgetController.text) ?? 0;
    return _tripDuration > 0 ? budget / _tripDuration : 0;
  }

  void _createTripPlan() {
    // Validate city
    if (!_validateCity(_cityController.text)) {
      return;
    }

    final budget = double.tryParse(_budgetController.text);

    if (budget == null || budget <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid budget'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_selectedPreferences.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one preference'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final tripPlan = TripPlan(
      startDate: _startDate,
      endDate: _endDate,
      budget: budget,
      preferences: _selectedPreferences.toList(),
    );

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Trip planned from $_selectedCity! Duration: $_tripDuration days'),
        backgroundColor: AppColors.success,
      ),
    );

    // For now, just log the trip plan
    print('Trip Plan Created: ${tripPlan.toJson()}');

    // Later we'll integrate with backend and recommendation engine
    // For now, we can navigate to a trip recommendations screen
    // Navigator.pushNamed(context, '/trip-recommendations', arguments: tripPlan);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.surface,
        title: const Text(
          'Plan Your Trip',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Trip Duration Overview
            _buildDurationOverview(),
            const SizedBox(height: AppSpacing.xl),

            // Starting City Section
            _buildCitySelectionSection(),
            const SizedBox(height: AppSpacing.xl),

            // Date Selection Section
            _buildDateSection(),
            const SizedBox(height: AppSpacing.xl),

            // Budget Section
            _buildBudgetSection(),
            const SizedBox(height: AppSpacing.xl),

            // Preferences Section
            _buildPreferencesSection(),
            const SizedBox(height: AppSpacing.xl),

            // Plan Trip Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createTripPlan,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                child: const Text(
                  'Plan My Trip',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  Widget _buildDurationOverview() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Trip Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildOverviewItem(
                icon: Icons.calendar_today,
                label: 'Duration',
                value: '$_tripDuration days',
              ),
              _buildOverviewItem(
                icon: Icons.money,
                label: 'Budget/Day',
                value: '\₹${_budgetPerDay.toStringAsFixed(0)}',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
bool _validateCity(String city) {
    if (city.isEmpty) {
      setState(() {
        _cityError = 'Please enter a city';
      });
      return false;
    }
    
    // Check if city exists in database (case-insensitive)
    final cityLower = city.toLowerCase().trim();
    final isValid = _availableCities.any((c) => c.toLowerCase() == cityLower);
    
    if (!isValid) {
      setState(() {
        _cityError = 'City not found in database. Available cities: ${_availableCities.take(10).join(", ")}...';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ "$city" is not in our database. Please choose from: ${_availableCities.join(", ")}'),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return false;
    }
    
    setState(() {
      _cityError = null;
      _selectedCity = _availableCities.firstWhere(
        (c) => c.toLowerCase() == cityLower,
      );
    });
    return true;
  }

  Widget _buildCitySelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Based city',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          controller: _cityController,
          onChanged: (value) {
            // Clear error when user starts typing
            if (_cityError != null) {
              setState(() {
                _cityError = null;
              });
            }
          },
          decoration: InputDecoration(
            hintText: 'Enter your starting city',
            prefixIcon: const Icon(Icons.location_on, color: AppColors.primary),
            errorText: _cityError,
            errorMaxLines: 3,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
            filled: true,
            fillColor: AppColors.surface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Available cities: ${_availableCities.take(5).join(", ")}...',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Travel Dates',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildDateCard(
                title: 'Start Date',
                date: _startDate,
                onTap: _selectStartDate,
                icon: Icons.date_range,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildDateCard(
                title: 'End Date',
                date: _endDate,
                onTap: _selectEndDate,
                icon: Icons.date_range,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateCard({
    required String title,
    required DateTime date,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.md),
          color: AppColors.surfaceAlt,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.primary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _formatDate(date),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day} ${_getMonthName(date.month)} ${date.year}';
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  Widget _buildBudgetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Budget',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.md),
            color: AppColors.surface,
          ),
          child: TextField(
            controller: _budgetController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter total budget (₹)',
              hintStyle: const TextStyle(color: AppColors.textHint),
              prefixIcon: const Icon(Icons.currency_rupee, color: AppColors.primary),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
            ),
            onChanged: (_) {
              setState(() {});
            },
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Trip Preferences',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Select what interests you',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: tripPreferenceCategories.map((category) {
            final isSelected = _selectedPreferences.contains(category);
            return _buildPreferenceChip(
              label: category,
              isSelected: isSelected,
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedPreferences.remove(category);
                  } else {
                    _selectedPreferences.add(category);
                  }
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPreferenceChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.circle),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surfaceAlt,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
          borderRadius: BorderRadius.circular(AppRadius.circle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected)
              const Icon(
                Icons.check,
                size: 16,
                color: Colors.white,
              ),
            if (isSelected) const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
