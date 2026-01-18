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
import 'screens/plan_trip_screen.dart';
import 'screens/admin_dashboard_screen.dart';
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
            ? const HomeScreen() 
            : const LoginScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/signup': (context) => const SignupScreen(),
          '/home': (context) => const HomeScreen(),
          '/explore': (context) => const ExploreScreen(),
          '/bookings': (context) => const BookingsScreen(),
          '/profile': (context) => const ProfileScreen(),
          '/plan-trip': (context) => const TripPlanningScreen(),
          '/admin': (context) => const AdminDashboardScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/trip-detail') {
            final argument = settings.arguments;
            return MaterialPageRoute(
              builder: (context) => TripDetailScreen(trip: argument),
            );
          }
          return null;
        },
      ),
    );
  }
}
