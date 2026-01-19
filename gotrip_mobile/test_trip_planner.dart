import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'services/trip_planner_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  await Supabase.initialize(
    url: SUPABASE_URL,
    anonKey: SUPABASE_ANON_KEY,
  );

  runApp(const TripPlannerTestApp());
}

class TripPlannerTestApp extends StatelessWidget {
  const TripPlannerTestApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trip Planner Test',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const TestScreen(),
    );
  }
}

class TestScreen extends StatefulWidget {
  const TestScreen({Key? key}) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  String status = 'Ready to test...';
  bool isLoading = false;
  Map<String, dynamic>? testResult;

  Future<void> _testDatabaseConnection() async {
    setState(() {
      isLoading = true;
      status = 'Testing database connection...';
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Test 1: Check if destinations table exists and has data
      final count = await supabase
          .from('destinations')
          .select('id', count: CountOption.exact)
          .limit(1);
      
      setState(() {
        status = '✅ Database connected! Found destinations in table.';
      });
    } catch (e) {
      setState(() {
        status = '❌ Database error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _testTripPlanning() async {
    setState(() {
      isLoading = true;
      status = 'Planning test trip...';
      testResult = null;
    });

    try {
      final service = TripPlannerService();
      
      final result = await service.planTrip(
        startLocation: {
          'name': 'Mumbai',
          'lat': 19.0760,
          'lng': 72.8777,
        },
        preferences: ['beach', 'nature', 'history'],
        budget: 15000,
        startDate: '2026-02-01T00:00:00Z',
        endDate: '2026-02-03T23:59:59Z',
        returnToStart: true,
      );

      setState(() {
        testResult = result;
        if (result['success'] == true) {
          final plan = result['plan'];
          status = '✅ ${result['message']}\n'
                   'Total Cost: ₹${plan['total_cost']}\n'
                   'Destinations: ${(plan['destinations'] as List).length}\n'
                   'Distance: ${plan['total_distance_km'].toStringAsFixed(1)} km';
        } else {
          status = '⚠️ ${result['message']}';
        }
      });
    } catch (e) {
      setState(() {
        status = '❌ Error: $e';
      });
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip Planner Test')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Status',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(status),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: isLoading ? null : _testDatabaseConnection,
              child: const Text('1. Test Database Connection'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: isLoading ? null : _testTripPlanning,
              child: const Text('2. Test Trip Planning'),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator()),
            if (testResult != null && testResult!['success'] == true) ...[
              const Text(
                'Trip Details:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: (testResult!['plan']['destinations'] as List).length,
                  itemBuilder: (context, index) {
                    final dest = (testResult!['plan']['destinations'] as List)[index];
                    return Card(
                      child: ListTile(
                        title: Text(dest['name']),
                        subtitle: Text('${dest['city']}, ${dest['state']}'),
                        trailing: Text('⭐ ${dest['rating']}'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
