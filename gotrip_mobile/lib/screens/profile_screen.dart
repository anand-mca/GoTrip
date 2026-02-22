import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/auth_provider.dart';
import '../providers/destination_provider.dart';
import '../providers/theme_provider.dart';
import '../services/supabase_service.dart';
import '../services/journey_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userProfile;
  bool _isLoading = true;
  bool _notificationsEnabled = true;
  
  // Stats
  int _completedTrips = 0;
  int _destinationsVisited = 0;
  int _favouritesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadStats();
  }

  Future<void> _loadUserProfile() async {
    try {
      final supabaseService = SupabaseService();
      final authUser = supabaseService.getCurrentUser();
      
      if (authUser != null) {
        final profile = await supabaseService.getUserProfile(authUser.id);
        
        if (profile != null && mounted) {
          setState(() {
            _userProfile = profile;
            _isLoading = false;
          });
        } else if (mounted) {
          setState(() => _isLoading = false);
        }
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('ERROR loading profile: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final journeyService = JourneyService();
      final history = await journeyService.getTripHistory();
      
      int totalDestinations = 0;
      for (var trip in history) {
        final itineraries = trip['daily_itineraries'] as List? ?? [];
        for (var day in itineraries) {
          final destinations = day['destinations'] as List? ?? [];
          for (var dest in destinations) {
            if (dest['is_visited'] == true) {
              totalDestinations++;
            }
          }
        }
      }
      
      final destinationProvider = context.read<DestinationProvider>();
      
      if (mounted) {
        setState(() {
          _completedTrips = history.length;
          _destinationsVisited = totalDestinations;
          _favouritesCount = destinationProvider.favorites.length;
        });
      }
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<void> _openEmailSupport() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'anandvijayan124@gmail.com',
      queryParameters: {
        'subject': 'GoTrip App Support Request',
        'body': 'Hi GoTrip Support Team,\n\n[Describe your issue here]\n\nBest regards,\n${_userProfile?['name'] ?? 'User'}',
      },
    );
    
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open email app')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Profile', style: TextStyle(color: textOnPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: primaryColor))
          : SingleChildScrollView(
        child: Column(
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: primaryColor,
              ),
              child: Column(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode ? Colors.black : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _userProfile?['name'] ?? 'User',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textOnPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _userProfile?['email'] ?? 'email@example.com',
                    style: TextStyle(
                      color: textOnPrimary.withOpacity(0.8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildStatCard('$_completedTrips', 'Trips', textOnPrimary),
                      _buildStatCard('$_destinationsVisited', 'Visited', textOnPrimary),
                      _buildStatCard('$_favouritesCount', 'Favourites', textOnPrimary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Profile Sections
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Personal Information
                  Text(
                    'Personal Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildInfoTile('Phone', _userProfile?['phone'] ?? 'Not set', Icons.phone, primaryColor, textColor),
                  _buildInfoTile('Bio', _userProfile?['bio'] ?? 'No bio added', Icons.description, primaryColor, textColor),
                  const SizedBox(height: 24),
                  
                  // Preferences
                  Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPreferenceTile('Notifications', _notificationsEnabled, (value) {
                    setState(() => _notificationsEnabled = value);
                  }, primaryColor, textColor),
                  _buildPreferenceTile('Dark Mode', themeProvider.isDarkMode, (value) {
                    themeProvider.toggleTheme(value);
                  }, primaryColor, textColor),
                  const SizedBox(height: 24),
                  
                  // Favourite Destinations
                  Text(
                    'Favourite Destinations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/favourite-destinations'),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: themeProvider.surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: primaryColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.favorite, color: primaryColor, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'You have $_favouritesCount favourite destinations',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Tap to view your collection',
                                  style: TextStyle(
                                    color: textColor.withOpacity(0.6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Account
                  Text(
                    'Account',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAccountTile('Edit Profile', Icons.edit, primaryColor, textColor, () => _showEditProfileDialog(context)),
                  _buildAccountTile('Change Password', Icons.lock, primaryColor, textColor, () => _showChangePasswordDialog(context)),
                  _buildAccountTile('Help & Support', Icons.help, primaryColor, textColor, _openEmailSupport),
                  _buildAccountTile('Logout', Icons.logout, Colors.red, textColor, () => _showLogoutDialog(context), isLogout: true),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String value, String label, Color textColor) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: textColor.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: textColor.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceTile(String title, bool value, Function(bool) onChanged, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: TextStyle(color: textColor)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTile(String title, IconData icon, Color iconColor, Color textColor, VoidCallback onTap, {bool isLogout = false}) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(color: isLogout ? Colors.red : textColor),
      ),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: textColor.withOpacity(0.5)),
      onTap: onTap,
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final nameController = TextEditingController(text: _userProfile?['name'] ?? '');
    final phoneController = TextEditingController(text: _userProfile?['phone'] ?? '');
    final bioController = TextEditingController(text: _userProfile?['bio'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeProvider.surfaceColor,
          title: Text('Edit Profile', style: TextStyle(color: themeProvider.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  style: TextStyle(color: themeProvider.textColor),
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneController,
                  style: TextStyle(color: themeProvider.textColor),
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: bioController,
                  style: TextStyle(color: themeProvider.textColor),
                  decoration: InputDecoration(
                    labelText: 'Bio',
                    border: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: themeProvider.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final supabaseService = SupabaseService();
                  final user = supabaseService.getCurrentUser();
                  
                  if (user != null) {
                    await supabaseService.updateUserProfile(user.id, {
                      'name': nameController.text,
                      'phone': phoneController.text,
                      'bio': bioController.text,
                      'updated_at': DateTime.now().toIso8601String(),
                    });
                    
                    if (mounted) {
                      Navigator.pop(context);
                      await _loadUserProfile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Profile updated!'), backgroundColor: themeProvider.primaryColor),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: themeProvider.primaryColor),
              child: Text('Save', style: TextStyle(color: themeProvider.textOnPrimaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeProvider.surfaceColor,
          title: Text('Change Password', style: TextStyle(color: themeProvider.textColor)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: newPasswordController,
                  obscureText: true,
                  style: TextStyle(color: themeProvider.textColor),
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    border: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: true,
                  style: TextStyle(color: themeProvider.textColor),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    border: OutlineInputBorder(borderSide: BorderSide(color: themeProvider.primaryColor)),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: themeProvider.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match!')),
                  );
                  return;
                }

                try {
                  final supabaseService = SupabaseService();
                  await supabaseService.client.auth.updateUser(
                    UserAttributes(password: newPasswordController.text),
                  );
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Password changed!'), backgroundColor: themeProvider.primaryColor),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: themeProvider.primaryColor),
              child: Text('Update', style: TextStyle(color: themeProvider.textOnPrimaryColor)),
            ),
          ],
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: themeProvider.surfaceColor,
          title: Text('Logout', style: TextStyle(color: themeProvider.textColor)),
          content: Text('Are you sure you want to logout?', style: TextStyle(color: themeProvider.textColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: themeProvider.primaryColor)),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  final authProvider = context.read<AuthProvider>();
                  await authProvider.signOut();
                  
                  if (mounted) {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/login');
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Logout', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }
}

