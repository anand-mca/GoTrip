# Updated Trip Planning Screen with Real API Integration

## Current State vs New State

### BEFORE (Mock Data)
```dart
final recommendations = _generateMockRecommendations(
  selectedPreferences,
  duration,
  budget,
);
```

### AFTER (Real API)
```dart
final apiProvider = context.read<DestinationAPIProvider>();
await apiProvider.fetchRecommendedDestinations(
  preferences: selectedPreferences,
  budget: budget,
  days: duration,
  userLocation: 'Delhi',
);
final recommendations = apiProvider.destinations;
```

---

## Complete Updated Method

Replace the `_planTrip()` method in `trip_planning_screen.dart` with:

```dart
Future<void> _planTrip() async {
  if (!_formKey.currentState!.validate()) return;
  if (selectedPreferences.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please select at least one preference')),
    );
    return;
  }

  setState(() {
    isLoading = true;
    tripPlan = null;
    error = null;
  });

  try {
    final startDate = _startDateController.text;
    final endDate = _endDateController.text;
    final budget = int.parse(_budgetController.text);
    
    final start = DateTime.parse(startDate);
    final end = DateTime.parse(endDate);
    final duration = end.difference(start).inDays + 1;
    
    // Get API provider
    final apiProvider = context.read<DestinationAPIProvider>();
    
    // Check if backend is available
    await apiProvider.checkBackendHealth();
    
    if (!apiProvider.backendAvailable) {
      setState(() {
        error = 'Backend API not available. Make sure your server is running on http://localhost:8000';
        isLoading = false;
      });
      _showErrorDialog('Backend Error', error!);
      return;
    }

    // Fetch recommendations from API
    await apiProvider.fetchRecommendedDestinations(
      preferences: selectedPreferences,
      budget: budget,
      days: duration,
      userLocation: 'Delhi', // You can make this dynamic
    );

    // Get recommendations from provider
    final recommendations = apiProvider.destinations;

    if (apiProvider.error != null) {
      setState(() {
        error = apiProvider.error;
        isLoading = false;
      });
      _showErrorDialog('API Error', error!);
      return;
    }

    if (recommendations.isEmpty) {
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No destinations found. Try adjusting your filters.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Calculate totals
    final totalDistance = recommendations.fold<num>(
      0,
      (sum, r) => sum + (r['distance'] ?? 0),
    ) as int;

    // Create trip plan
    setState(() {
      tripPlan = {
        'trip_id': 'trip_${DateTime.now().millisecondsSinceEpoch}',
        'start_date': startDate,
        'end_date': endDate,
        'budget': budget,
        'preferences': selectedPreferences,
        'duration_days': duration,
        'budget_per_day': (budget / duration).toStringAsFixed(2),
        'total_places': recommendations.length,
        'total_distance': totalDistance,
        'recommendations': recommendations,
        'status': 'planned',
        'source': 'api', // Indicates data came from real API
      };
      isLoading = false;
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Found ${recommendations.length} destinations!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );

  } catch (e) {
    setState(() {
      error = e.toString();
      isLoading = false;
    });
    _showErrorDialog('Error', error!);
  }
}

/// Show error dialog
void _showErrorDialog(String title, String message) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
```

---

## Add to State Variables

Add these to your `_TripPlanningScreenState`:

```dart
class _TripPlanningScreenState extends State<TripPlanningScreen> {
  // ... existing variables ...
  
  String? error; // Add this to track errors
}
```

---

## Update Imports

Add this import to `trip_planning_screen.dart`:

```dart
import 'package:provider/provider.dart';
import '../providers/destination_api_provider.dart';
```

---

## Add Error Display UI (Optional)

Add this widget to show errors in the UI:

```dart
// Add to build method, after form:
if (error != null)
  Container(
    margin: const EdgeInsets.all(AppSpacing.large),
    padding: const EdgeInsets.all(AppSpacing.medium),
    decoration: BoxDecoration(
      color: Colors.red.shade50,
      border: Border.all(color: Colors.red),
      borderRadius: BorderRadius.circular(AppRadius.medium),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Error',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          error!,
          style: const TextStyle(color: Colors.red),
        ),
      ],
    ),
  ),
```

---

## Step-by-Step Implementation

### 1. Copy the `_planTrip()` method above
Replace your current `_planTrip()` method with the one provided

### 2. Add error variable to state
Add `String? error;` to your state variables

### 3. Add imports
Add the Provider imports at the top

### 4. Verify API Service
Ensure `lib/services/api_service.dart` exists with all endpoints

### 5. Verify API Provider
Ensure `lib/providers/destination_api_provider.dart` exists

### 6. Update main.dart
Confirm `DestinationAPIProvider` is added to MultiProvider

### 7. Test

```bash
# Terminal 1: Start backend
cd gotrip-backend
npm run dev  # or python main.py

# Terminal 2: Start Flutter app
cd gotrip_mobile
flutter run -d chrome
```

---

## Fallback to Mock Data (Optional)

If backend is not available, you can fallback to mock data:

```dart
// In _planTrip() after checking backend availability:

if (!apiProvider.backendAvailable) {
  print('Backend not available, using mock data');
  final recommendations = _generateMockRecommendations(
    selectedPreferences,
    duration,
    budget,
  );
  // Continue with mock data...
} else {
  // Use real API data...
}
```

---

## Testing Checklist

- [ ] Backend running on `http://localhost:8000`
- [ ] `/api/health` returns success
- [ ] Fill trip form correctly
- [ ] Click "Plan My Trip"
- [ ] See loading indicator
- [ ] Recommendations appear after 2-3 seconds
- [ ] Recommendations match selected preferences
- [ ] All recommendations are within budget
- [ ] No console errors in Flutter

---

## Expected Console Output

### Success:
```
I/flutter: Fetching recommendations from API...
I/flutter: Found 5 destinations matching criteria
```

### Error (Backend not running):
```
E/flutter: Connection error: Could not reach backend. Is it running on http://localhost:8000?
```

### Error (Invalid preferences):
```
E/flutter: No destinations found. Try adjusting filters.
```

---

## Real vs Mock Comparison

| Feature | Mock | Real API |
|---------|------|----------|
| Accuracy | Low (hardcoded) | High (real data) |
| Flexibility | Limited | Unlimited |
| Customization | Hard | Easy |
| Performance | Instant | 1-2 seconds |
| Scalability | Limited | Unlimited |
| User Experience | Static | Dynamic |

---

## Next Steps After Integration

1. **Test thoroughly** with real API
2. **Add caching** to reduce API calls
3. **Implement offline mode** with cached data
4. **Add real data sources** (Google Places, Amadeus, etc.)
5. **Optimize queries** for better performance
6. **Add analytics** to track user preferences
7. **Deploy backend** to production (Heroku, AWS, etc.)

---

