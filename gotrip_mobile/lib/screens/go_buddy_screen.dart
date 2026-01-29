import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../services/destination_classifier.dart';

class GoBuddyScreen extends StatefulWidget {
  const GoBuddyScreen({Key? key}) : super(key: key);

  @override
  State<GoBuddyScreen> createState() => _GoBuddyScreenState();
}

class _GoBuddyScreenState extends State<GoBuddyScreen> {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final DestinationClassifier _classifier = DestinationClassifier.instance;
  bool _isLoading = false;
  bool _isClassifierReady = false;

  @override
  void initState() {
    super.initState();
    _initializeClassifier();
    // Add welcome message
    _messages.add(ChatMessage(
      isUser: false,
      text: "Hey there, traveler! 👋 I'm GoBuddy, your friendly travel companion!\n\nSnap a photo of any famous Indian monument or landmark, and I'll identify it for you!\n\nI can recognize 24 famous destinations including:\n🏛️ Taj Mahal, Gateway of India, Qutub Minar\n🕌 Hawa Mahal, Charminar, Golden Temple\n🏰 Mysore Palace, Victoria Memorial\n...and many more!\n\nTap the camera button below to get started! 📸",
      timestamp: DateTime.now(),
    ));
  }

  Future<void> _initializeClassifier() async {
    try {
      await _classifier.initialize();
      setState(() {
        _isClassifierReady = true;
      });
      print('✅ Classifier ready!');
    } catch (e) {
      print('❌ Failed to initialize classifier: $e');
      setState(() {
        _messages.add(ChatMessage(
          isUser: false,
          text: "⚠️ I'm having trouble loading my recognition model. Please make sure the model file is properly set up.",
          timestamp: DateTime.now(),
        ));
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _messages.add(ChatMessage(
            isUser: true,
            imagePath: image.path,
            timestamp: DateTime.now(),
          ));
          _isLoading = true;
        });

        _scrollToBottom();

        // Classify the image using TFLite model
        await _classifyImage(File(image.path));
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _classifyImage(File imageFile) async {
    try {
      if (!_isClassifierReady) {
        setState(() {
          _isLoading = false;
          _messages.add(ChatMessage(
            isUser: false,
            text: "⚠️ The recognition model is still loading. Please try again in a moment.",
            timestamp: DateTime.now(),
          ));
        });
        return;
      }

      // Run classification
      final result = await _classifier.classifyImage(imageFile);
      
      setState(() {
        _isLoading = false;
        
        // Handle web platform fallback
        if (result.isWebFallback) {
          _messages.add(ChatMessage(
            isUser: false,
            text: "🌐 **Web Browser Detected**\n\n"
                "The image recognition feature requires a mobile device (Android/iOS) to work.\n\n"
                "📱 To use GoBuddy's full capabilities:\n"
                "• Run the app on an Android device or emulator\n"
                "• Run the app on an iOS device or simulator\n\n"
                "The TFLite model can only run on native mobile platforms.\n\n"
                "💡 _Coming soon: Web support with TensorFlow.js!_",
            timestamp: DateTime.now(),
          ));
          return;
        }
        
        if (result.isConfident(threshold: 0.3)) {
          // Confident prediction
          final destination = result.topPredictions[0].displayLabel;
          final confidence = result.topPredictions[0].confidencePercent;
          
          String responseText = "🎯 **I recognize this place!**\n\n"
              "📍 **${destination}**\n"
              "🎯 Confidence: $confidence\n\n";
          
          // Add top 3 predictions if there are alternatives
          if (result.topPredictions.length > 1) {
            responseText += "Other possibilities:\n";
            for (int i = 1; i < result.topPredictions.length && i < 3; i++) {
              responseText += "• ${result.topPredictions[i].displayLabel} (${result.topPredictions[i].confidencePercent})\n";
            }
            responseText += "\n";
          }
          
          responseText += "💡 _Coming soon: Detailed history, facts, and nearby attractions powered by AI!_";
          
          _messages.add(ChatMessage(
            isUser: false,
            text: responseText,
            timestamp: DateTime.now(),
            recognizedDestination: destination,
          ));
        } else {
          // Low confidence
          _messages.add(ChatMessage(
            isUser: false,
            text: "🤔 I'm not quite sure about this one...\n\n"
                "My best guess is **${result.topPredictions[0].displayLabel}** "
                "(${result.topPredictions[0].confidencePercent} confidence)\n\n"
                "Tips for better results:\n"
                "• Make sure the landmark is clearly visible\n"
                "• Try taking the photo from a different angle\n"
                "• Ensure good lighting\n\n"
                "I can recognize famous Indian monuments like Taj Mahal, Gateway of India, Qutub Minar, and more!",
            timestamp: DateTime.now(),
          ));
        }
      });

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _messages.add(ChatMessage(
          isUser: false,
          text: "❌ Sorry, I encountered an error while analyzing the image.\n\nError: $e\n\nPlease try again with a different image.",
          timestamp: DateTime.now(),
        ));
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildImageSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.blue,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                _buildImageSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSourceOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 32, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.pink.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GoBuddy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Your AI Travel Companion',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Chat Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return _buildTypingIndicator();
                }
                return _buildMessageBubble(_messages[index]);
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt, color: Colors.grey[500], size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Snap a place to learn about it...',
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showImageSourceDialog,
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade400, Colors.pink.shade400],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.add_a_photo,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.orange.shade400, Colors.pink.shade400],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: message.imagePath != null
                  ? const EdgeInsets.all(4)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade500 : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isUser ? 20 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.imagePath != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(message.imagePath!),
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      message.text ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue.shade100,
              child: Icon(Icons.person, size: 18, color: Colors.blue.shade700),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.pink.shade400],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                const SizedBox(width: 4),
                _buildDot(1),
                const SizedBox(width: 4),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + (index * 200)),
      builder: (context, value, child) {
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.4 + (0.6 * value)),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final bool isUser;
  final String? text;
  final String? imagePath;
  final DateTime timestamp;
  final String? recognizedDestination;

  ChatMessage({
    required this.isUser,
    this.text,
    this.imagePath,
    required this.timestamp,
    this.recognizedDestination,
  });
}
