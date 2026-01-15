# Plan Trip Feature - Backend Integration Guide

## 📋 Overview for Backend Development

This guide helps backend developers integrate the Trip Planning feature with:
- Supabase database
- REST API endpoints
- Trip recommendation engine

---

## 🗂️ Frontend Code Structure

### Models (`lib/models/trip_plan_model.dart`)

```dart
class TripPlan {
  final String? id;                    // UUID from Supabase
  final DateTime startDate;            // ISO format
  final DateTime endDate;              // ISO format
  final double budget;                 // In rupees
  final List<String> preferences;      // Array of category strings
  final DateTime createdAt;            // Timestamp
  final DateTime? updatedAt;           // Timestamp (nullable)

  // Methods:
  int get tripDuration              // Calculated property
  double get budgetPerDay           // Calculated property
  
  Map<String, dynamic> toJson()     // For API calls
  factory TripPlan.fromJson(...)    // From API response
}
```

### Available Preferences

```dart
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
```

---

## 📡 API Endpoints Required

### 1. Create Trip Plan
```
POST /api/trip-plans
Content-Type: application/json
Authorization: Bearer <auth_token>

Request Body:
{
  "start_date": "2026-01-15T00:00:00Z",
  "end_date": "2026-01-22T00:00:00Z",
  "budget": 50000,
  "preferences": ["Beaches", "Adventure", "Food"]
}

Response (201 Created):
{
  "id": "uuid-123456",
  "user_id": "user-uuid",
  "start_date": "2026-01-15T00:00:00Z",
  "end_date": "2026-01-22T00:00:00Z",
  "budget": 50000,
  "preferences": ["Beaches", "Adventure", "Food"],
  "created_at": "2026-01-15T12:30:45Z",
  "updated_at": "2026-01-15T12:30:45Z"
}
```

### 2. Get User's Trip Plans
```
GET /api/trip-plans
Authorization: Bearer <auth_token>

Response (200 OK):
{
  "data": [
    {
      "id": "uuid-123456",
      "start_date": "2026-01-15T00:00:00Z",
      "end_date": "2026-01-22T00:00:00Z",
      "budget": 50000,
      "preferences": ["Beaches", "Adventure", "Food"],
      "created_at": "2026-01-15T12:30:45Z",
      "updated_at": "2026-01-15T12:30:45Z"
    }
  ],
  "count": 1
}
```

### 3. Get Trip Plan by ID
```
GET /api/trip-plans/{trip_plan_id}
Authorization: Bearer <auth_token>

Response (200 OK):
{
  "id": "uuid-123456",
  "user_id": "user-uuid",
  "start_date": "2026-01-15T00:00:00Z",
  "end_date": "2026-01-22T00:00:00Z",
  "budget": 50000,
  "preferences": ["Beaches", "Adventure", "Food"],
  "created_at": "2026-01-15T12:30:45Z",
  "updated_at": "2026-01-15T12:30:45Z"
}
```

### 4. Update Trip Plan
```
PUT /api/trip-plans/{trip_plan_id}
Content-Type: application/json
Authorization: Bearer <auth_token>

Request Body:
{
  "start_date": "2026-01-15T00:00:00Z",
  "end_date": "2026-01-22T00:00:00Z",
  "budget": 60000,
  "preferences": ["Beaches", "Adventure", "Food", "Nightlife"]
}

Response (200 OK):
{
  "id": "uuid-123456",
  "user_id": "user-uuid",
  "start_date": "2026-01-15T00:00:00Z",
  "end_date": "2026-01-22T00:00:00Z",
  "budget": 60000,
  "preferences": ["Beaches", "Adventure", "Food", "Nightlife"],
  "created_at": "2026-01-15T12:30:45Z",
  "updated_at": "2026-01-15T14:45:00Z"
}
```

### 5. Delete Trip Plan
```
DELETE /api/trip-plans/{trip_plan_id}
Authorization: Bearer <auth_token>

Response (204 No Content)
```

### 6. Get Trip Recommendations ⭐ (For Phase 3)
```
GET /api/trip-plans/{trip_plan_id}/recommendations
Authorization: Bearer <auth_token>

Response (200 OK):
{
  "trip_plan_id": "uuid-123456",
  "recommendations": [
    {
      "destination_id": "dest-001",
      "title": "Goa Beach Resort",
      "match_score": 95,
      "matches_preferences": ["Beaches", "Nightlife"],
      "estimated_cost": 2500,
      "duration_days": 3
    },
    {
      "destination_id": "dest-002",
      "title": "Rishikesh Adventure Park",
      "match_score": 88,
      "matches_preferences": ["Adventure", "Nature"],
      "estimated_cost": 1800,
      "duration_days": 2
    }
  ]
}
```

---

## 🗄️ Supabase Database Schema

### trips_plans Table

```sql
CREATE TABLE IF NOT EXISTS trip_plans (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  start_date TIMESTAMP WITH TIME ZONE NOT NULL,
  end_date TIMESTAMP WITH TIME ZONE NOT NULL,
  budget DECIMAL(12, 2) NOT NULL,
  preferences TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  
  -- Constraints
  CONSTRAINT valid_dates CHECK (end_date >= start_date),
  CONSTRAINT positive_budget CHECK (budget > 0),
  
  -- Indexes
  CONSTRAINT non_empty_preferences CHECK (array_length(preferences, 1) > 0)
);

-- Create indexes for common queries
CREATE INDEX idx_trip_plans_user_id ON trip_plans(user_id);
CREATE INDEX idx_trip_plans_created_at ON trip_plans(created_at DESC);
CREATE INDEX idx_trip_plans_start_date ON trip_plans(start_date);

-- Create RLS policies
ALTER TABLE trip_plans ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can only see their own trip plans"
  ON trip_plans FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can create trip plans"
  ON trip_plans FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own trip plans"
  ON trip_plans FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own trip plans"
  ON trip_plans FOR DELETE
  USING (auth.uid() = user_id);
```

---

## 🔌 Frontend Integration Points

### In `lib/providers/trip_provider.dart` (To be created):

```dart
class TripProvider extends ChangeNotifier {
  List<TripPlan> _tripPlans = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<TripPlan> get tripPlans => _tripPlans;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Methods to implement:
  Future<void> createTripPlan(TripPlan plan) async {
    // POST /api/trip-plans
  }

  Future<void> fetchTripPlans() async {
    // GET /api/trip-plans
  }

  Future<TripPlan?> getTripPlanById(String id) async {
    // GET /api/trip-plans/{id}
  }

  Future<void> updateTripPlan(String id, TripPlan plan) async {
    // PUT /api/trip-plans/{id}
  }

  Future<void> deleteTripPlan(String id) async {
    // DELETE /api/trip-plans/{id}
  }

  Future<List<Destination>> getTripRecommendations(String tripPlanId) async {
    // GET /api/trip-plans/{id}/recommendations
  }
}
```

### In `lib/services/supabase_service.dart` (Extend existing):

```dart
class SupabaseService {
  // Add trip plan methods:
  
  Future<Map<String, dynamic>> createTripPlan(TripPlan plan) async {
    return await _supabase
      .from('trip_plans')
      .insert(plan.toJson())
      .select()
      .single();
  }

  Future<List<Map<String, dynamic>>> fetchUserTripPlans() async {
    return await _supabase
      .from('trip_plans')
      .select()
      .order('created_at', ascending: false);
  }

  Future<Map<String, dynamic>> getTripPlanById(String id) async {
    return await _supabase
      .from('trip_plans')
      .select()
      .eq('id', id)
      .single();
  }

  Future<void> updateTripPlan(String id, TripPlan plan) async {
    await _supabase
      .from('trip_plans')
      .update(plan.toJson())
      .eq('id', id);
  }

  Future<void> deleteTripPlan(String id) async {
    await _supabase
      .from('trip_plans')
      .delete()
      .eq('id', id);
  }
}
```

---

## 🤖 Recommendation Engine Logic

### Matching Algorithm:

```
For each destination in database:
  1. Check if destination category matches ANY selected preference
     → Assign base match score (10-100 points)
  
  2. Check if destination price is within budget
     → Add/subtract points based on budget fit
  
  3. Check if destination duration fits trip duration
     → Adjust match score
  
  4. Check if destination has good ratings
     → Add bonus points for high ratings
  
  5. Calculate relevance score = (matches × price_fit × duration_fit × rating)
  
  6. Sort by relevance score (highest first)
  
  7. Return top recommendations
```

### Example Scoring:

```
Trip Plan:
- Dates: 15 Jan - 22 Jan (7 days)
- Budget: ₹50,000
- Preferences: [Beaches, Adventure, Food]

Destination 1: Goa Beach Resort
- Category: Beaches ✓ (matches preference) → +80 points
- Price: ₹2,500 for 3 days → fits budget ✓ → +15 points
- Rating: 4.8/5 → +10 points
- Match Score: 95%

Destination 2: Manali Adventure
- Category: Adventure ✓ (matches preference) → +80 points
- Price: ₹3,500 for 4 days → fits budget ✓ → +10 points
- Rating: 4.6/5 → +8 points
- Match Score: 88%
```

---

## 🔐 Security Considerations

### Client Side (Already Implemented):
- ✅ Basic validation (budget > 0, at least 1 preference)
- ✅ Date validation (end date >= start date)
- ✅ Error handling with user-friendly messages

### Server Side (To Implement):
- ✅ Verify auth token
- ✅ Validate user_id matches auth token
- ✅ Re-validate all input data
- ✅ Implement RLS (Row Level Security)
- ✅ Rate limiting for API calls
- ✅ Audit logging for trip plan changes
- ✅ Sanitize inputs (SQL injection prevention)

---

## 📊 Error Handling

### Frontend Error Scenarios:

```dart
// Budget Validation
if (budget <= 0) {
  Show: "Please enter a valid budget"
}

// Preference Validation
if (preferences.isEmpty) {
  Show: "Please select at least one preference"
}

// Date Validation
if (endDate < startDate) {
  Show: "End date must be after start date"
}

// Network Errors
if (response.statusCode != 200) {
  Show: "Failed to create trip plan. Please try again."
}
```

### Backend Error Responses:

```json
// 400 Bad Request
{
  "error": "Invalid budget amount",
  "details": "Budget must be greater than 0"
}

// 401 Unauthorized
{
  "error": "Unauthorized",
  "message": "Invalid or expired authentication token"
}

// 403 Forbidden
{
  "error": "Forbidden",
  "message": "You don't have permission to access this resource"
}

// 409 Conflict
{
  "error": "Invalid dates",
  "message": "End date must be after start date"
}

// 500 Server Error
{
  "error": "Internal server error",
  "message": "An unexpected error occurred"
}
```

---

## 🧪 Testing Checklist

### For Backend Developer:

- [ ] Create trip plan with valid data
- [ ] Create trip plan with invalid budget (≤ 0)
- [ ] Create trip plan with empty preferences
- [ ] Create trip plan with invalid date range
- [ ] Fetch all trip plans for user
- [ ] Fetch specific trip plan by ID
- [ ] Update trip plan (dates, budget, preferences)
- [ ] Delete trip plan
- [ ] Verify RLS policies
- [ ] Test rate limiting
- [ ] Test with different user accounts
- [ ] Generate recommendations for trip plan
- [ ] Verify preference matching accuracy

---

## 📱 Frontend Usage After Backend Ready

```dart
// In plan_trip_screen.dart - Replace the current log with:

void _createTripPlan() {
  final tripPlan = TripPlan(
    startDate: _startDate,
    endDate: _endDate,
    budget: budget,
    preferences: _selectedPreferences.toList(),
  );

  // Call provider to save to backend
  context.read<TripProvider>()
    .createTripPlan(tripPlan)
    .then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Trip planned successfully!')),
      );
      // Navigate to recommendations
      Navigator.pushNamed(
        context,
        '/trip-recommendations',
        arguments: tripPlan.id,
      );
    })
    .catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${error.message}')),
      );
    });
}
```

---

## 📚 File References

### Frontend Files:
- `lib/models/trip_plan_model.dart` - Data model
- `lib/screens/plan_trip_screen.dart` - UI
- `lib/providers/trip_provider.dart` - To be created
- `lib/services/supabase_service.dart` - To be extended

### Documentation Files:
- `TRIP_PLANNING_FEATURE.md` - Feature overview
- `PLAN_TRIP_VISUAL_GUIDE.md` - UI walkthrough
- This file - Backend integration guide

---

## 🚀 Implementation Phases

### Phase 1: ✅ COMPLETE - Frontend
- ✅ Plan Trip Screen
- ✅ Trip Plan Model
- ✅ Home Screen Integration
- ✅ UI/UX Design

### Phase 2: 🔄 IN PROGRESS - Backend
- [ ] Create Supabase table
- [ ] Implement API endpoints
- [ ] Add RLS policies
- [ ] Implement error handling
- [ ] Create TripProvider
- [ ] Extend SupabaseService

### Phase 3: 📋 PLANNED - Recommendations
- [ ] Build recommendation engine
- [ ] Implement matching algorithm
- [ ] Create recommendations screen
- [ ] Filter/sort results

### Phase 4: 📋 PLANNED - Enhancement
- [ ] Save draft trips
- [ ] Edit existing trips
- [ ] Trip history view
- [ ] Share trips
- [ ] Budget tracking

---

**Backend Integration Guide Complete!** Ready for implementation. 🎯

For questions about frontend implementation, refer to the other documentation files.
