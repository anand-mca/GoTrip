import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'utils/app_theme.dart';
import 'screens/login_screen.dart';
import 'screens/signup_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/trip_detail_screen.dart';
import 'screens/trip_planning_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/journey_tracking_screen.dart';
import 'screens/travel_history_screen.dart';
import 'screens/main_navigation_shell.dart';
import 'screens/go_buddy_screen.dart';
import 'config/supabase_config.dart';
import 'services/supabase_service.dart';
import 'providers/auth_provider.dart';
import 'providers/trip_provider.dart';
import 'providers/destination_provider.dart';
import 'providers/destination_api_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: SUPABASE_URL,
      anonKey: SUPABASE_ANON_KEY,
    );
  } catch (e) {
    print('Supabase initialization error: $e');
    print('Make sure to add your Supabase credentials in lib/config/supabase_config.dart');
  }
  
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const GoTripApp());
}

class GoTripApp extends StatefulWidget {
  const GoTripApp({Key? key}) : super(key: key);

  @override
  State<GoTripApp> createState() => _GoTripAppState();
}

class _GoTripAppState extends State<GoTripApp> {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => TripProvider()),
        ChangeNotifierProvider(create: (_) => DestinationProvider()),
        ChangeNotifierProvider(create: (_) => DestinationAPIProvider()),
      ],
      child: MaterialApp(
        title: 'GoTrip',
        theme: AppTheme.lightTheme,
        debugShowCheckedModeBanner: false,
        home: SupabaseService().getCurrentUser() != null 
            ? const MainNavigationShell() 
            : const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const MainNavigationShell(),
          '/explore': (context) => const ExploreScreen(),
          '/bookings': (context) => const BookingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/plan-trip': (context) => const TripPlanningScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
          '/travel-history': (context) => const TravelHistoryScreen(),
          '/go-buddy': (context) => const GoBuddyScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/trip-detail') {
            final argument = settings.arguments;
            return MaterialPageRoute(
              builder: (context) => TripDetailScreen(trip: argument),
            );
          }
          if (settings.name == '/journey-tracking') {
            final tripPlan = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (context) => JourneyTrackingScreen(tripPlan: tripPlan),
            );
          }
          return null;
        },
      ),
    );
  }
}
