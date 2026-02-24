import 'package:http/http.dart' as http;
import 'dart:convert';

class GroqService {
  // Groq API key - Get free API key from: https://console.groq.com/keys
  // TODO: Add your API key here for local development
  static const String _apiKey = 'YOUR_GROQ_API_KEY_HERE';
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  /// Generate detailed destination description using Groq LLM
  static Future<String> generateDestinationDescription(String destinationName) async {
    // Check if API key is set
    if (_apiKey == 'YOUR_GROQ_API_KEY_HERE' || _apiKey.isEmpty) {
      print('⚠️ Groq API key not configured');
      return _getFallbackDescription(destinationName);
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile', // Fast and powerful model
          'messages': [
            {
              'role': 'system',
              'content': 'You are an enthusiastic and knowledgeable travel guide with expertise in Indian tourism. '
                  'Provide engaging, friendly, and informative descriptions of tourist destinations. '
                  'Include historical facts, cultural significance, best time to visit, and practical tips. '
                  'Use emojis to make it fun and engaging. Keep it conversational and exciting. '
                  'Format the response in 3-4 short paragraphs, around 150-200 words total.'
            },
            {
              'role': 'user',
              'content': 'Tell me about $destinationName as a tourist destination in India. '
                  'Include what makes it special, key attractions, historical significance, '
                  'visiting tips, and why travelers should visit. Be enthusiastic and engaging!'
            }
          ],
          'temperature': 0.7,
          'max_tokens': 400,
          'top_p': 0.9,
        }),
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          print('⏱️ Groq API timeout');
          throw Exception('Request timeout');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;
        print('✅ Generated description for $destinationName');
        return content.trim();
      } else if (response.statusCode == 401) {
        print('❌ Invalid Groq API key');
        return _getFallbackDescription(destinationName);
      } else if (response.statusCode == 429) {
        print('⚠️ Groq API rate limit reached');
        return _getFallbackDescription(destinationName);
      } else {
        print('❌ Groq API error: ${response.statusCode}');
        return _getFallbackDescription(destinationName);
      }
    } catch (e) {
      print('❌ Error calling Groq API: $e');
      return _getFallbackDescription(destinationName);
    }
  }

  /// Fallback description when API fails or is not configured
  static String _getFallbackDescription(String destinationName) {
    final predefinedDescriptions = {
      'Taj Mahal': "🌟 One of the Seven Wonders of the World! This stunning white marble mausoleum was built by Emperor Shah Jahan in memory of his beloved wife Mumtaz Mahal. Visit during sunrise or sunset for the most magical experience! Don't miss the intricate marble inlay work and beautiful gardens. 🏛️✨",
      
      'Gateway of India': "🌊 Mumbai's iconic landmark! Built in 1924 to commemorate King George V's visit, this magnificent archway stands proudly facing the Arabian Sea. Perfect spot for evening walks, boat rides to Elephanta Caves, and some delicious street food nearby! 🚢🎭",
      
      'Qutub Minar': "🗼 Delhi's towering marvel! This 73-meter tall victory tower is a masterpiece of Indo-Islamic architecture dating back to 1193. The complex includes beautiful iron pillar, intricate carvings, and peaceful gardens. History buffs will love this UNESCO World Heritage site! 📚🏛️",
      
      'Golden Temple': "🕌 Amritsar's spiritual crown jewel! The holiest Gurdwara of Sikhism, this breathtaking golden shrine sits in the middle of a sacred pool. Open 24/7, free for all regardless of faith. Don't miss the amazing langar (free community kitchen) serving 100,000 people daily! 🙏✨",
      
      'Hawa Mahal': "🏰 The Palace of Winds in Jaipur! This stunning pink sandstone structure with 953 tiny windows was built for royal ladies to observe street festivals while remaining unseen. The unique honeycomb design keeps it cool even in scorching heat! Perfect for photography! 📸💗",
      
      'Red Fort': "🏰 Delhi's majestic Mughal masterpiece! This massive red sandstone fort complex served as the main residence of Mughal emperors for 200 years. Explore beautiful palaces, museums, and the famous Diwan-i-Aam. The Light & Sound show in evenings is spectacular! 🎭✨",
      
      'India Gate': "🎖️ Delhi's war memorial! Standing 42 meters tall, this archway commemorates 70,000 Indian soldiers who died in World War I. Perfect for evening picnics, boat rides in nearby fountains, and trying delicious street food. Beautifully illuminated at night! 🌙✨",
      
      'Mysore Palace': "👑 India's most visited palace! This royal residence is a stunning blend of Hindu, Muslim, Rajput, and Gothic styles. Visit on Sundays or festivals when 100,000 lights illuminate the palace - absolutely magical! The intricate interiors will leave you speechless! ✨🏛️",
      
      'Charminar': "🕌 Hyderabad's iconic symbol! Built in 1591, this magnificent monument features four grand arches and stunning minarets. Surrounded by bustling bazaars perfect for shopping bangles, pearls, and enjoying delicious Hyderabadi biryani! A must-visit at night when beautifully lit! 🌙🌟",
      
      'Victoria Memorial': "🏛️ Kolkata's crown jewel! This stunning white marble building set in lush gardens is dedicated to Queen Victoria. Houses an amazing museum with British Raj artifacts, paintings, and weapons. Visit early morning for peaceful walks and beautiful photography! 📸🌿",
    };

    return predefinedDescriptions[destinationName] ?? 
        "✨ What an amazing destination! $destinationName is rich in history, culture, and beauty. "
        "This place offers unique experiences and unforgettable memories. "
        "Definitely worth exploring in person to experience its charm and significance. "
        "Check out local guides for the best times to visit and hidden gems nearby! 🗺️📸";
  }

  /// Get latitude and longitude for any Indian city/town/district.
  /// Uses Nominatim (OpenStreetMap) as primary — free, no key needed, covers every Indian location.
  /// Falls back to Groq LLM if Nominatim fails, then to hardcoded list.
  static Future<Map<String, double>?> getCityCoordinates(String cityName) async {
    // ── Step 1: Try Nominatim (OpenStreetMap) — always works, no API key required ──
    try {
      final query = Uri.encodeComponent('$cityName, India');
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=$query'
        '&format=json'
        '&limit=1'
        '&countrycodes=in',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'GoTripApp/1.0'},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final List<dynamic> results = jsonDecode(response.body);
        if (results.isNotEmpty) {
          final lat = double.tryParse(results[0]['lat'].toString());
          final lng = double.tryParse(results[0]['lon'].toString());
          if (lat != null && lng != null &&
              lat >= 6.0 && lat <= 38.0 &&
              lng >= 68.0 && lng <= 98.0) {
            print('✅ Nominatim geocoded "$cityName" → lat=$lat, lng=$lng');
            return {'lat': lat, 'lng': lng};
          }
        }
        print('⚠️ Nominatim found no India result for "$cityName"');
      }
    } catch (e) {
      print('⚠️ Nominatim geocoding error: $e');
    }

    // ── Step 2: Try Groq LLM (only if API key configured) ──
    if (_apiKey != 'YOUR_GROQ_API_KEY_HERE' && _apiKey.isNotEmpty) {
      try {
        final response = await http.post(
          Uri.parse(_baseUrl),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_apiKey',
          },
          body: jsonEncode({
            'model': 'llama-3.3-70b-versatile',
            'messages': [
              {
                'role': 'system',
                'content': 'You are a precise geocoding assistant. '
                    'When given an Indian city or location name, respond with ONLY a valid JSON object '
                    'containing the decimal latitude and longitude. '
                    'Format: {"lat": 12.3456, "lng": 78.9012} '
                    'Do not include any other text, explanation, or markdown. '
                    'Only respond with the raw JSON object.'
              },
              {
                'role': 'user',
                'content': 'What are the latitude and longitude coordinates of $cityName, India?'
              }
            ],
            'temperature': 0.1,
            'max_tokens': 60,
          }),
        ).timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = (data['choices'][0]['message']['content'] as String).trim();
          final cleaned = content
              .replaceAll(RegExp(r'```json\s*'), '')
              .replaceAll(RegExp(r'```\s*'), '')
              .trim();
          final coords = jsonDecode(cleaned);
          final lat = (coords['lat'] as num?)?.toDouble();
          final lng = (coords['lng'] as num?)?.toDouble();
          if (lat != null && lng != null &&
              lat >= 6.0 && lat <= 38.0 &&
              lng >= 68.0 && lng <= 98.0) {
            print('✅ Groq geocoded "$cityName" → lat=$lat, lng=$lng');
            return {'lat': lat, 'lng': lng};
          }
        }
      } catch (e) {
        print('⚠️ Groq geocoding error: $e');
      }
    }

    // ── Step 3: Hardcoded fallback for most common cities ──
    return _getFallbackCoordinates(cityName);
  }

  /// Fallback coordinates for common Indian cities (used when Groq API is unavailable)
  static Map<String, double>? _getFallbackCoordinates(String cityName) {
    final fallback = <String, Map<String, double>>{
      'mumbai': {'lat': 19.0760, 'lng': 72.8777},
      'delhi': {'lat': 28.6139, 'lng': 77.2090},
      'bangalore': {'lat': 12.9716, 'lng': 77.5946},
      'bengaluru': {'lat': 12.9716, 'lng': 77.5946},
      'kolkata': {'lat': 22.5726, 'lng': 88.3639},
      'chennai': {'lat': 13.0827, 'lng': 80.2707},
      'hyderabad': {'lat': 17.3850, 'lng': 78.4867},
      'pune': {'lat': 18.5204, 'lng': 73.8567},
      'ahmedabad': {'lat': 23.0225, 'lng': 72.5714},
      'jaipur': {'lat': 26.9124, 'lng': 75.7873},
      'goa': {'lat': 15.2993, 'lng': 74.1240},
      'panaji': {'lat': 15.4989, 'lng': 73.8278},
      'munnar': {'lat': 10.0889, 'lng': 77.0595},
      'manali': {'lat': 32.2432, 'lng': 77.1892},
      'shimla': {'lat': 31.1048, 'lng': 77.1734},
      'rishikesh': {'lat': 30.0869, 'lng': 78.2676},
      'udaipur': {'lat': 24.5854, 'lng': 73.7125},
      'kochi': {'lat': 9.9312, 'lng': 76.2673},
      'cochin': {'lat': 9.9312, 'lng': 76.2673},
      'agra': {'lat': 27.1767, 'lng': 78.0081},
      'varanasi': {'lat': 25.3176, 'lng': 82.9739},
      'pondicherry': {'lat': 11.9416, 'lng': 79.8083},
      'puducherry': {'lat': 11.9416, 'lng': 79.8083},
      'darjeeling': {'lat': 27.0360, 'lng': 88.2627},
      'amritsar': {'lat': 31.6340, 'lng': 74.8723},
      'lucknow': {'lat': 26.8467, 'lng': 80.9462},
      'surat': {'lat': 21.1702, 'lng': 72.8311},
      'indore': {'lat': 22.7196, 'lng': 75.8577},
      'bhopal': {'lat': 23.2599, 'lng': 77.4126},
      'patna': {'lat': 25.5941, 'lng': 85.1376},
      'nagpur': {'lat': 21.1458, 'lng': 79.0882},
      'coimbatore': {'lat': 11.0168, 'lng': 76.9558},
      'madurai': {'lat': 9.9252, 'lng': 78.1198},
      'visakhapatnam': {'lat': 17.6868, 'lng': 83.2185},
      'vijayawada': {'lat': 16.5062, 'lng': 80.6480},
      'thiruvananthapuram': {'lat': 8.5241, 'lng': 76.9366},
      'trivandrum': {'lat': 8.5241, 'lng': 76.9366},
      'mysore': {'lat': 12.2958, 'lng': 76.6394},
      'mysuru': {'lat': 12.2958, 'lng': 76.6394},
      'ooty': {'lat': 11.4064, 'lng': 76.6932},
      'kodaikanal': {'lat': 10.2381, 'lng': 77.4892},
      'mount abu': {'lat': 24.5926, 'lng': 72.7156},
      'jodhpur': {'lat': 26.2389, 'lng': 73.0243},
      'pushkar': {'lat': 26.4898, 'lng': 74.5511},
      'haridwar': {'lat': 29.9457, 'lng': 78.1642},
      'dehradun': {'lat': 30.3165, 'lng': 78.0322},
      'kasauli': {'lat': 30.9005, 'lng': 76.9674},
      'mcleod ganj': {'lat': 32.2432, 'lng': 76.3217},
      'dharamshala': {'lat': 32.2190, 'lng': 76.3234},
      'spiti': {'lat': 32.2461, 'lng': 78.0333},
      'leh': {'lat': 34.1526, 'lng': 77.5771},
      'ladakh': {'lat': 34.1526, 'lng': 77.5771},
    };
    final key = cityName.trim().toLowerCase();
    return fallback[key];
  }

  /// Check if Groq API is configured
  static bool isConfigured() {
    return _apiKey != 'YOUR_GROQ_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}
