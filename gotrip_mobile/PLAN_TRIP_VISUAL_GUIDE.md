# Plan Trip Feature - Visual Guide & UI Walkthrough

## 🎯 User Journey

```
Home Screen
    ↓
[See CTA Card: "Plan Your Perfect Trip"]
    ↓
Tap "Start Planning" Button
    ↓
Navigate to Plan Trip Screen
```

---

## 📱 Screen Layout

### Plan Trip Screen Structure:

```
┌─────────────────────────────────────┐
│  ← Plan Your Trip                   │  ← AppBar
├─────────────────────────────────────┤
│                                     │
│  ┌───────────────────────────────┐  │
│  │  Trip Overview  (Gradient)    │  │ ← Real-time overview
│  │                               │  │
│  │  📅 Duration: 7 days          │  │
│  │  💰 Budget/Day: ₹7,142        │  │
│  └───────────────────────────────┘  │
│                                     │
│  Travel Dates                       │
│  ┌──────────────────────────────┐   │
│  │ 📅 Start Date  │ 📅 End Date │   │ ← Clickable date cards
│  │ 15 Jan 2026    │ 22 Jan 2026 │   │
│  └──────────────────────────────┘   │
│                                     │
│  Budget                             │
│  ┌───────────────────────────────┐  │
│  │ 💵 Enter total budget (₹)    │   │
│  │ [50000________________]       │   │ ← Real-time input
│  └───────────────────────────────┘  │
│                                     │
│  Trip Preferences                   │
│  Select what interests you          │ ← Multi-select section
│  [Beaches] [Mountains] [Adventure]  │
│  [Nature] [Heritage] [Culture]      │
│  [Food] [Shopping] [Nightlife]      │
│  [Wellness] [Art] [Photography]     │
│                                     │
│  ┌───────────────────────────────┐  │
│  │ 🗺️  PLAN MY TRIP             │   │ ← Main CTA
│  └───────────────────────────────┘  │
│                                     │
└─────────────────────────────────────┘
```

---

## 🎨 Color Scheme

### Trip Overview Card:
```
┌──────────────────────────────────────┐
│ Gradient: Purple → Dark Purple       │
│ Trip Overview                        │
│                                      │
│ 📅 7 days          💰 ₹7,142/day    │
└──────────────────────────────────────┘
```

### Preference Chips:

**Unselected:**
```
┌─────────────┐
│ Beaches     │  ← Light background, primary border
└─────────────┘
```

**Selected:**
```
┌─────────────┐
│ ✓ Beaches   │  ← Purple background, white checkmark
└─────────────┘
```

### Buttons:

**Plan My Trip Button:**
```
┌────────────────────────────────┐
│ 🗺️  PLAN MY TRIP               │  ← Purple background, white text
└────────────────────────────────┘
```

### Date Cards:
```
┌──────────────────┐
│ 📅 Start Date    │
│ 15 Jan 2026      │
└──────────────────┘
```

---

## ⚙️ Functionality Flow

### When User Interacts:

#### 1️⃣ Change Start Date
```
User Taps Start Date Card
         ↓
Material Date Picker Opens (Themed Purple)
         ↓
User Selects Date
         ↓
If date < end date → Update & refresh screen
If date ≥ end date → Show previous date
```

#### 2️⃣ Change End Date
```
User Taps End Date Card
         ↓
Material Date Picker Opens (Themed Purple)
         ↓
User Selects Date
         ↓
If date > start date → Update & refresh screen
If date ≤ start date → Show previous date
         ↓
Trip duration auto-recalculates
```

#### 3️⃣ Enter Budget
```
User Types Budget Amount (₹)
         ↓
TextField updates in real-time
         ↓
Budget/Day calculation updates
         ↓
Trip Overview card refreshes
```

#### 4️⃣ Select Preferences
```
User Taps Preference Chip
         ↓
If unselected → Add to selection, turn purple
If selected → Remove from selection, turn light
         ↓
Multiple selections allowed
```

#### 5️⃣ Submit Trip Plan
```
User Taps "Plan My Trip" Button
         ↓
Validation Check:
  ✓ Budget > 0?
  ✓ At least 1 preference selected?
         ↓
If Invalid → Show SnackBar error message (Red)
If Valid → Show success message (Green)
         ↓
Trip data logged (ready for backend)
```

---

## 📊 Real-time Calculations

### Trip Duration:
```
Duration = EndDate - StartDate + 1 day

Example:
Start: 15 Jan
End:   22 Jan
Duration = 7 days
```

### Daily Budget:
```
BudgetPerDay = TotalBudget / TripDuration

Example:
Total Budget: ₹50,000
Trip Duration: 7 days
Budget/Day: ₹7,142 (rounded)
```

---

## 🔄 State Management

The screen uses **StatefulWidget** with `setState()` to:
- Update dates when picker changes
- Recalculate budget/day on budget input change
- Toggle preferences on and off
- Update UI in real-time

---

## ✅ Validation Rules

| Field | Validation | Error Message |
|-------|-----------|---------------|
| Budget | > 0 | "Please enter a valid budget" |
| Preferences | At least 1 | "Please select at least one preference" |
| Start Date | Not set | Cannot be after end date (enforced by picker) |
| End Date | Not set | Must be after start date (enforced by picker) |

---

## 🎯 Preference Categories

The app includes 12 preference categories:

| Category | Icon | Use Case |
|----------|------|----------|
| Beaches | 🏖️ | Coastal trips |
| Mountains | ⛰️ | Hill stations, hiking |
| Adventure | 🪂 | Action activities |
| Nature | 🌲 | Outdoor experiences |
| Heritage | 🏛️ | Historical sites |
| Culture | 🎭 | Museums, local experiences |
| Food | 🍛 | Food tours, local cuisine |
| Shopping | 🛍️ | Markets, shopping centers |
| Nightlife | 🎉 | Bars, clubs, events |
| Wellness | 🧘 | Spas, yoga retreats |
| Art | 🎨 | Galleries, art installations |
| Photography | 📸 | Scenic locations |

---

## 🎨 Design Tokens

### Colors:
```dart
Primary Purple: #6C5CE7
Primary Dark: #5F3DC4
Accent Red: #FF6B6B
Text Primary: #2D3436
Text Secondary: #636E72
Background: #FAFAFA
```

### Spacing:
```dart
xs: 4dp
sm: 8dp
md: 16dp
lg: 24dp
xl: 32dp
xxl: 48dp
```

### Border Radius:
```dart
sm: 8dp
md: 12dp
lg: 16dp
xl: 24dp
circle: 999dp
```

---

## 📱 Responsive Behavior

The screen is fully responsive:
- **Single Column Layout** on all devices
- **Full-width components** with padding
- **Flexible wrapping** for preference chips
- **Adapts** to different screen sizes
- **Scrollable** content when needed

---

## 🔜 Next Phase - Recommendation Engine

After the user creates a trip plan:

```
Trip Plan Created
         ↓
[Future] Navigate to Recommendations Screen
         ↓
Show destinations matching:
  • Selected preferences
  • Budget constraints
  • Trip duration
  • Available dates
         ↓
Allow user to:
  • View recommendations
  • Filter by price/rating
  • Save favorites
  • Finalize itinerary
```

---

## 💾 Data Structure (What Gets Saved)

```json
{
  "start_date": "2026-01-15T00:00:00Z",
  "end_date": "2026-01-22T00:00:00Z",
  "budget": 50000,
  "preferences": ["Beaches", "Adventure", "Food"],
  "created_at": "2026-01-15T12:30:45Z"
}
```

This data will be:
- ✅ Sent to backend API
- ✅ Stored in Supabase
- ✅ Used for recommendations
- ✅ Displayed in trip history

---

## 🚀 Quick Start for Testing

1. **Open App** → Home Screen
2. **Tap** "Start Planning" button
3. **Pick Dates** using the date pickers
4. **Enter Budget** (try ₹50,000)
5. **Select Preferences** (pick 2-3 categories)
6. **Watch** budget/day calculate automatically
7. **Tap** "Plan My Trip"
8. **See** success message

---

## 📚 Code References

### Main Files:
- `lib/screens/plan_trip_screen.dart` - UI implementation
- `lib/models/trip_plan_model.dart` - Data model
- `lib/utils/app_constants.dart` - Design system

### Key Methods:
- `_selectStartDate()` - Date picker for start date
- `_selectEndDate()` - Date picker for end date
- `_createTripPlan()` - Validation & submission
- `_buildPreferenceChip()` - Preference chip widget
- `_buildDateCard()` - Date display card

---

**Visual Guide Complete!** Ready to build the backend and recommendation engine! 🎯
