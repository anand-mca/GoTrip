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

  /// Check if Groq API is configured
  static bool isConfigured() {
    return _apiKey != 'YOUR_GROQ_API_KEY_HERE' && _apiKey.isNotEmpty;
  }
}
