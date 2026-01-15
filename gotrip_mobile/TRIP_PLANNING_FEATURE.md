# Trip Planning Feature - Frontend Implementation

## Overview
The Trip Planning feature allows users to create personalized trip plans by specifying travel dates, budget, and preferences. This is the frontend implementation ready for backend and recommendation engine integration.

## Features Implemented

### 1. **Plan Trip Screen** (`plan_trip_screen.dart`)
The main page where users can plan their trips with the following sections:

#### Date Selection
- **Start Date**: Pick the beginning date of the trip
- **End Date**: Pick the end date of the trip
- Date picker uses Material design with theme colors
- Prevents selecting invalid date ranges (end date must be after start date)

#### Budget Input
- **Total Budget**: Users enter their total budget in ₹ (Rupees)
- Real-time budget per day calculation
- Shows daily budget based on trip duration

#### Trip Preferences
- Users can select multiple preference categories:
  - Beaches
  - Mountains
  - Adventure
  - Nature
  - Heritage
  - Culture
  - Food
  - Shopping
  - Nightlife
  - Wellness
  - Art
  - Photography

#### Trip Overview
- Displays real-time trip duration calculation
- Shows budget per day automatically
- Visual gradient card with key metrics

### 2. **Trip Plan Model** (`trip_plan_model.dart`)
Data model for storing trip plan information:

```dart
class TripPlan {
  final String? id;
  final DateTime startDate;
  final DateTime endDate;
  final double budget;
  final List<String> preferences;
  final DateTime createdAt;
  final DateTime? updatedAt;
}
```

Features:
- Automatic trip duration calculation
- Budget per day calculation
- JSON serialization (for API integration)
- JSON deserialization (for API responses)

### 3. **Home Screen Integration**
Added a prominent "Plan Your Perfect Trip" CTA button on the home screen with:
- Eye-catching accent color gradient
- Clear call-to-action text
- Easy navigation to Plan Trip screen

## UI/UX Details

### Design System Used
- **Colors**: Primary purple (#6C5CE7), Accent red (#FF6B6B)
- **Spacing**: Consistent 4px-48px scale
- **Border Radius**: Smooth 8px-24px rounded corners
- **Typography**: Bold headers, clear descriptions

### Components
1. **Date Cards**: Clickable cards showing selected dates
2. **Budget Input**: Text field with currency icon
3. **Preference Chips**: Toggle-able preference tags
4. **Overview Card**: Gradient card showing key metrics
5. **Plan Button**: Full-width CTA button

## Navigation

### Added Routes
- `/plan-trip`: Opens the Plan Trip screen

### Screen Connections
1. **Home Screen** → Plan Trip Screen (via "Start Planning" button)
2. Plan Trip → Backend (to be implemented)

## Current Workflow

1. User taps "Plan Your Perfect Trip" on Home Screen
2. User selects start and end dates
3. User enters total budget
4. User selects preferences (can select multiple)
5. Trip overview updates in real-time
6. User taps "Plan My Trip"
7. Validation checks:
   - Budget must be > 0
   - At least one preference must be selected
8. Success message displayed
9. Trip plan data is logged (ready for backend integration)

## Data Structure Example

When user creates a trip plan:
```json
{
  "id": null,
  "start_date": "2026-02-01T00:00:00.000000",
  "end_date": "2026-02-08T00:00:00.000000",
  "budget": 50000,
  "preferences": ["Beaches", "Adventure", "Food"],
  "created_at": "2026-01-15T12:30:45.123456",
  "updated_at": null
}
```

## Next Steps - Backend Integration

### What Needs to be Implemented:
1. **Trip Provider** (in `providers/trip_provider.dart`):
   - Save trip plan to Supabase
   - Fetch user's saved trip plans
   - Update trip plans

2. **Supabase Schema** (trips table):
   - id (UUID)
   - user_id (FK)
   - start_date (timestamp)
   - end_date (timestamp)
   - budget (decimal)
   - preferences (array)
   - created_at (timestamp)
   - updated_at (timestamp)

3. **Trip Recommendation Engine**:
   - Use trip plan data (dates, budget, preferences)
   - Fetch destinations matching preferences
   - Apply budget filtering
   - Consider trip duration
   - Create a Trip Recommendations screen

4. **Screens to Create**:
   - `trip_recommendations_screen.dart`: Show AI-recommended destinations based on trip plan
   - `saved_trips_screen.dart`: Show user's previously created trip plans

## Usage

### To Navigate to Plan Trip Screen:
```dart
Navigator.pushNamed(context, '/plan-trip');
```

### To Use the Trip Plan Model:
```dart
final tripPlan = TripPlan(
  startDate: DateTime.now(),
  endDate: DateTime.now().add(Duration(days: 7)),
  budget: 50000,
  preferences: ['Beaches', 'Food'],
);

// Convert to JSON for API
final json = tripPlan.toJson();

// Create from JSON response
final tripPlan = TripPlan.fromJson(apiResponse);
```

## Files Modified/Created

### New Files:
- `lib/screens/plan_trip_screen.dart` - Main Plan Trip screen
- `lib/models/trip_plan_model.dart` - Trip Plan data model

### Modified Files:
- `lib/main.dart` - Added route for `/plan-trip`
- `lib/screens/home_screen.dart` - Added Plan Trip CTA button

## Styling Notes

- All colors use `AppColors` constants from `app_constants.dart`
- All spacing uses `AppSpacing` constants
- All border radius uses `AppRadius` constants
- Consistent with existing design system
- Responsive and works on all screen sizes

## Validation

The Plan Trip screen validates:
1. ✅ Budget > 0
2. ✅ At least one preference selected
3. ✅ End date >= start date (enforced by date picker)

Error messages are shown via SnackBars with appropriate colors.

## Future Enhancements

1. Add trip duration categories (Weekend, Week, Two Weeks, etc.)
2. Add budget categories (Budget, Mid-range, Luxury)
3. Add trip type selection (Adventure, Relaxation, Business, etc.)
4. Add estimated per-category budget breakdown
5. Save draft trip plans
6. Edit previously created trip plans
