import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/destination_provider.dart';
import '../providers/theme_provider.dart';

class FavouriteDestinationsScreen extends StatelessWidget {
  const FavouriteDestinationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favourite Destinations',
          style: TextStyle(color: textOnPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
      ),
      body: Consumer<DestinationProvider>(
        builder: (context, provider, _) {
          final favorites = provider.favoriteDestinations;
          
          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.favorite_border,
                    size: 80,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No Favourites Yet',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Start exploring and add destinations\nto your favourites!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final destination = favorites[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: themeProvider.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor, width: 1),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.location_on,
                      color: primaryColor,
                      size: 28,
                    ),
                  ),
                  title: Text(
                    destination.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: themeProvider.textColor,
                    ),
                  ),
                  subtitle: Text(
                    destination.location,
                    style: TextStyle(
                      color: themeProvider.textColor.withOpacity(0.7),
                      fontSize: 13,
                    ),
                  ),
                  trailing: Icon(
                    Icons.favorite,
                    color: primaryColor,
                  ),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/trip-detail',
                      arguments: destination,
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
