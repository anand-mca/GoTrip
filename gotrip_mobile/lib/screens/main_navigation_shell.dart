import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/journey_service.dart';
import '../providers/theme_provider.dart';
import 'home_screen.dart';
import 'explore_screen.dart';
import 'trip_planning_screen.dart';
import 'go_buddy_screen.dart';
import 'journey_tracking_screen.dart';

class MainNavigationShell extends StatefulWidget {
  final int initialIndex;
  
  const MainNavigationShell({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainNavigationShell> createState() => _MainNavigationShellState();
}

class _MainNavigationShellState extends State<MainNavigationShell> {
  late int _currentIndex;
  final JourneyService _journeyService = JourneyService();
  Map<String, dynamic>? _activeTrip;
  bool _checkingActiveTrip = true;

  // Page controller for smooth transitions
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _currentIndex);
    _checkActiveTrip();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _checkActiveTrip() async {
    try {
      final activeTrip = await _journeyService.getActiveTrip();
      if (mounted) {
        setState(() {
          _activeTrip = activeTrip;
          _checkingActiveTrip = false;
        });
      }
    } catch (e) {
      print('Error checking active trip: $e');
      if (mounted) {
        setState(() => _checkingActiveTrip = false);
      }
    }
  }

  void _onTabTapped(int index) {
    // Handle "Your Journey" tab (index 3)
    if (index == 3) {
      if (_activeTrip != null) {
        // Navigate to journey tracking if there's an active trip
        final tripPlan = _journeyService.convertDbTripToAppFormat(_activeTrip!);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => JourneyTrackingScreen(
              tripPlan: tripPlan,
              fromDatabase: true,
            ),
          ),
        ).then((_) => _checkActiveTrip());
      } else {
        // Show message if no active trip
        _showNoActiveTripDialog();
      }
      return;
    }

    // Handle Plan Trip tab (index 2) - check for active trip
    if (index == 2 && _activeTrip != null) {
      _showActiveTripDialog();
      return;
    }

    setState(() {
      _currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  void _showNoActiveTripDialog() {
    final themeProvider = context.read<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textColor = themeProvider.textColor;
    final surfaceColor = themeProvider.surfaceColor;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.map_outlined, color: primaryColor),
            ),
            const SizedBox(width: 12),
            Text('No Active Journey', style: TextStyle(color: textColor)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "You don't have an active journey yet!",
              style: TextStyle(fontSize: 16, color: textColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Plan a trip and tap "Start Journey" to begin tracking!',
                      style: TextStyle(fontSize: 13, color: textColor),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close', style: TextStyle(color: textColor.withOpacity(0.6))),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _currentIndex = 2);
              _pageController.jumpToPage(2);
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Plan a Trip'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _showActiveTripDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('Active Trip Exists'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You already have an active journey in progress!',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.map, color: Colors.blue.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _activeTrip!['trip_name'] ?? 'Your Trip',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Please end your current journey before planning a new trip.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              final tripPlan = _journeyService.convertDbTripToAppFormat(_activeTrip!);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => JourneyTrackingScreen(
                    tripPlan: tripPlan,
                    fromDatabase: true,
                  ),
                ),
              ).then((_) => _checkActiveTrip());
            },
            icon: const Icon(Icons.directions_walk, size: 18),
            label: const Text('Continue Journey'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    final surfaceColor = themeProvider.surfaceColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          HomeContentScreen(
            activeTrip: _activeTrip,
            onActiveTripChanged: _checkActiveTrip,
          ),
          const ExploreScreen(),
          const TripPlanningScreen(),
          // This is a placeholder - journey tracking opens as a separate screen
          const _JourneyPlaceholder(),
          const GoBuddyScreen(),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_outlined, Icons.home, 'Home', primaryColor, textColor),
                _buildNavItem(1, Icons.explore_outlined, Icons.explore, 'Explore', primaryColor, textColor),
                _buildNavItem(2, Icons.map_outlined, Icons.map, 'Plan Trip', primaryColor, textColor),
                _buildJourneyNavItem(primaryColor, textColor),
                _buildNavItem(4, Icons.smart_toy_outlined, Icons.smart_toy, 'GoBuddy', primaryColor, textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, IconData activeIcon, String label, Color primaryColor, Color textColor) {
    final isSelected = _currentIndex == index;
    
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : textColor.withOpacity(0.6),
              size: 24,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyNavItem(Color primaryColor, Color textColor) {
    final hasActiveTrip = _activeTrip != null;
    final isSelected = _currentIndex == 3;
    
    return GestureDetector(
      onTap: () => _onTabTapped(3),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 16 : 12,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: hasActiveTrip 
              ? Colors.green.withOpacity(0.15) 
              : (isSelected ? primaryColor.withOpacity(0.15) : Colors.transparent),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                Icon(
                  hasActiveTrip ? Icons.directions_walk : Icons.directions_walk_outlined,
                  color: hasActiveTrip 
                      ? Colors.green 
                      : (isSelected ? primaryColor : textColor.withOpacity(0.6)),
                  size: 24,
                ),
                if (hasActiveTrip)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            if (isSelected || hasActiveTrip) ...[
              const SizedBox(width: 8),
              Text(
                'Journey',
                style: TextStyle(
                  color: hasActiveTrip 
                      ? Colors.green 
                      : primaryColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Placeholder widget for journey tab
class _JourneyPlaceholder extends StatelessWidget {
  const _JourneyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Loading...'),
      ),
    );
  }
}
