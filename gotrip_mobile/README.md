# GoTrip - Travel Booking Mobile App

A beautiful Flutter mobile application for discovering and booking amazing trips around the world.

## 🎨 Features

### Authentication & User Management
- **Login Screen**: Email/password authentication with social login options (Google, Apple)
- **Sign Up Screen**: User registration with email verification
- **Profile Screen**: User profile with personal information, preferences, and account settings

### Trip Discovery & Exploration
- **Home Screen**: Featured trips carousel, category filters, and popular trips
- **Explore Screen**: Advanced search with filters for difficulty, price range, and categories
- **Trip Detail Screen**: Comprehensive trip information including highlights, amenities, ratings, and booking

### Bookings & Management
- **Bookings Screen**: View upcoming, completed, and cancelled bookings
- **Booking Status**: Real-time booking status updates

### UI/UX Excellence
- Modern gradient backgrounds with attractive color scheme
- Smooth animations and transitions
- Responsive design for all screen sizes
- Bottom navigation for easy page navigation
- Custom reusable widgets and components

## 📁 Project Structure

```
gotrip_mobile/
├── lib/
│   ├── main.dart                 # App entry point and routing
│   ├── models/
│   │   ├── trip_model.dart      # Trip data model
│   │   └── user_model.dart      # User data model
│   ├── screens/
│   │   ├── login_screen.dart    # Login page
│   │   ├── signup_screen.dart   # Sign up page
│   │   ├── home_screen.dart     # Home page with featured trips
│   │   ├── explore_screen.dart  # Trip exploration & search
│   │   ├── trip_detail_screen.dart  # Trip details
│   │   ├── bookings_screen.dart # User bookings
│   │   └── profile_screen.dart  # User profile
│   ├── widgets/
│   │   ├── trip_card.dart       # Reusable trip card widget
│   │   ├── custom_button.dart   # Custom styled button
│   │   └── custom_text_field.dart # Custom text input
│   ├── utils/
│   │   ├── app_constants.dart   # Colors, spacing, and constants
│   │   └── app_theme.dart       # Theme and styling configuration
│   ├── services/                # API services (for future implementation)
│   └── models/                  # Data models
├── android/                     # Android platform code
├── ios/                         # iOS platform code
└── pubspec.yaml                 # Project dependencies

```

## 🎨 Design System

### Color Palette
- **Primary**: `#6C5CE7` (Purple)
- **Primary Dark**: `#5F3DC4` (Dark Purple)
- **Accent**: `#FF6B6B` (Red)
- **Accent Light**: `#FFE66D` (Yellow)
- **Background**: `#FAFAFA` (Light Gray)

### Typography
- **Display Large**: 32px Bold
- **Heading Medium**: 20px Semi-Bold
- **Title Large**: 16px Semi-Bold
- **Body Medium**: 14px Regular

## 📱 Screens

### 1. Login Screen
- Email and password input fields
- Social login options
- "Forgot Password" link
- Sign up navigation

### 2. Sign Up Screen
- Full name, email, password fields
- Password confirmation
- Terms & conditions checkbox
- Responsive form validation

### 3. Home Screen
- Search bar with location suggestions
- Featured trips carousel
- Category chips (Mountain, Beach, City, Adventure)
- Popular trips section
- Bottom navigation for app navigation

### 4. Explore Screen
- Advanced search functionality
- Filter by difficulty level
- Price range slider
- Category selection
- Trip listing with sorting

### 5. Trip Detail Screen
- Large trip image with interactive header
- Rating and review count
- Trip information tabs (Overview, Highlights, Amenities)
- Quick info cards (duration, group size, difficulty)
- Booking section with price and CTA button

### 6. Bookings Screen
- Tabbed interface (Upcoming, Completed, Cancelled)
- Booking cards with status indicators
- Booking ID and total price information
- View details button for each booking

### 7. Profile Screen
- User avatar and basic information
- Personal statistics (trips, reviews, saved)
- Personal information section
- Notification preferences
- Saved trips collection
- Account settings and logout

## 🛠️ Dependencies

Key packages used:
- `google_fonts`: Beautiful font library
- `carousel_slider`: Image carousel for featured trips
- `intl`: Internationalization support
- `provider`: State management (ready for implementation)
- `http`: API communication
- `shared_preferences`: Local data persistence
- `flutter_svg`: SVG image support
- `badges`: Notification badges

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.0.0 or higher)
- Dart SDK
- Android Studio or Xcode for platform-specific setup

### Installation

1. Navigate to project directory:
```bash
cd gotrip_mobile
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

4. For Android:
```bash
flutter run -d android
```

5. For iOS:
```bash
flutter run -d ios
```

## 📝 Implementation Notes

### For Backend Integration
The app is designed to work with REST APIs. Update the following areas:
1. Add API endpoints in `lib/services/` directory
2. Implement API models in `lib/models/`
3. Add authentication tokens to shared preferences
4. Update navigation after successful login

### State Management
Currently using `setState()` for simplicity. For production:
- Replace with Provider for better state management
- Or implement BLoC architecture for complex state

### API Integration Points
- Login/Signup: `/auth/login`, `/auth/signup`
- Trips: `/trips`, `/trips/{id}`
- Bookings: `/bookings`, `/bookings/{id}`
- User Profile: `/users/{id}`, `/users/{id}/update`

## 🎨 Customization

### Changing Colors
Edit `lib/utils/app_constants.dart`:
```dart
static const Color primary = Color(0xFF6C5CE7);
```

### Modifying Theme
Update `lib/utils/app_theme.dart` for comprehensive theme changes.

### Adding New Screens
1. Create new screen file in `lib/screens/`
2. Add route in `main.dart`
3. Update bottom navigation if needed

## 📦 Building for Release

### Android:
```bash
flutter build apk --release
```

### iOS:
```bash
flutter build ios --release
```

## 🔐 Security Considerations

- Use secure HTTP connections (HTTPS)
- Implement proper authentication token management
- Use keystore for API keys
- Implement certificate pinning for sensitive data
- Validate all user inputs

## 📄 License

This project is part of the GoTrip application suite.

## 👥 Support

For issues and feature requests, please contact the development team.

---

**Version**: 1.0.0
**Created**: 2024
**Platform**: Flutter (Android & iOS)
