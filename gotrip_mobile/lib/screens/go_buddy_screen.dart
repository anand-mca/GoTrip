import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/destination_classifier.dart';
import '../providers/theme_provider.dart';
import '../services/groq_service.dart';

class GoBuddyScreen extends StatefulWidget {
  const GoBuddyScreen({Key? key}) : super(key: key);

  @override
  State<GoBuddyScreen> createState() => _GoBuddyScreenState();
}

class _GoBuddyScreenState extends State<GoBuddyScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  final DestinationClassifier _classifier = DestinationClassifier.instance;
  bool _isLoading = false;
  bool _isClassifierReady = false;
  bool _isGeneratingDescription = false;
  String? _pendingImagePath; // Store pending image when app is paused

  @override
  bool get wantKeepAlive => true; // Keep state alive

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Add lifecycle observer
    _initializeClassifier();
    _checkCameraSessionRecovery(); // Check if returning from killed camera session
    // Add welcome message
    _messages.add(ChatMessage(
      isUser: false,
      text: "Hey there, traveler! 👋 I'm GoBuddy, your friendly travel companion!\n\nSnap a photo of any famous Indian monument or landmark, and I'll identify it for you!\n\nI can recognize 24 famous destinations including:\n🏛️ Taj Mahal, Gateway of India, Qutub Minar\n🕌 Hawa Mahal, Charminar, Golden Temple\n🏰 Mysore Palace, Victoria Memorial\n...and many more!\n\n📸 **Camera Tip:** If the app restarts when using camera, please use the **Gallery** option instead to upload photos!\n\nTap the camera button below to get started! 📸",
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('🔄 App lifecycle state: $state');
    
    if (state == AppLifecycleState.resumed) {
      // Clear camera session flag when app resumes normally
      _clearCameraSession();
      
      if (_pendingImagePath != null) {
        // Process pending image after returning from camera
        print('✅ Processing pending image from camera');
        final imagePath = _pendingImagePath;
        _pendingImagePath = null;
        
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) {
            _classifyImage(File(imagePath!));
          }
        });
      }
    } else if (state == AppLifecycleState.paused) {
      // App is going to background - might be opening camera
      print('⏸️ App paused (camera opening?)');
    }
  }
  
  /// Save camera session state before opening camera
  Future<void> _saveCameraSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gobuddy_camera_active', true);
      await prefs.setInt('gobuddy_camera_timestamp', DateTime.now().millisecondsSinceEpoch);
      print('💾 Saved camera session');
    } catch (e) {
      print('❌ Error saving camera session: $e');
    }
  }
  
  /// Clear camera session state
  Future<void> _clearCameraSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('gobuddy_camera_active');
      await prefs.remove('gobuddy_camera_timestamp');
    } catch (e) {
      print('❌ Error clearing camera session: $e');
    }
  }
  
  /// Check if app was killed during camera session and show recovery message
  Future<void> _checkCameraSessionRecovery() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cameraActive = prefs.getBool('gobuddy_camera_active') ?? false;
      final timestamp = prefs.getInt('gobuddy_camera_timestamp') ?? 0;
      
      if (cameraActive && timestamp > 0) {
        final elapsed = DateTime.now().millisecondsSinceEpoch - timestamp;
        // If less than 2 minutes ago, app was likely killed by camera
        if (elapsed < 120000) {
          print('⚠️ Detected app was killed during camera session');
          
          // Clear the session
          await _clearCameraSession();
          
          // Show recovery message
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              setState(() {
                _messages.add(ChatMessage(
                  isUser: false,
                  text: "⚠️ **Camera Session Interrupted**\n\n"
                      "It looks like the app was restarted when opening the camera. "
                      "This can happen on devices with limited memory.\n\n"
                      "📱 **Recommended Solution:**\n"
                      "• Use the **Gallery** button to select photos\n"
                      "• Take photos with your device camera app first\n"
                      "• Then upload them here using Gallery option\n\n"
                      "This gives better results and won't restart the app! ✨",
                  timestamp: DateTime.now(),
                ));
              });
              _scrollToBottom();
            }
          });
        } else {
          // Old session, just clear it
          await _clearCameraSession();
        }
      }
    } catch (e) {
      print('❌ Error checking camera session: $e');
    }
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
      // For camera, save state before launching to detect if app gets killed
      if (source == ImageSource.camera) {
        print('📸 Launching camera...');
        await _saveCameraSession(); // Save session BEFORE opening camera
      }

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      // Clear camera session if we got here successfully
      if (source == ImageSource.camera) {
        await _clearCameraSession();
      }

      if (image != null && mounted) {
        print('✅ Image captured: ${image.path}');
        
        setState(() {
          _messages.add(ChatMessage(
            isUser: true,
            imagePath: image.path,
            timestamp: DateTime.now(),
          ));
          _isLoading = true;
        });

        _scrollToBottom();

        // Small delay to ensure UI updates before processing
        await Future.delayed(const Duration(milliseconds: 200));

        // Classify the image using TFLite model
        if (mounted) {
          await _classifyImage(File(image.path));
        }
      } else {
        print('⚠️ No image selected or context not mounted');
        // Clear camera session even if cancelled
        if (source == ImageSource.camera) {
          await _clearCameraSession();
        }
      }
    } catch (e) {
      print('❌ Error picking image: $e');
      // Clear camera session on error
      if (source == ImageSource.camera) {
        await _clearCameraSession();
      }
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
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
      
      // Handle classification results
      if (!mounted) return;
      
      setState(() {
        _isLoading = false;
      });
      
      // Handle web platform fallback
      if (result.isWebFallback) {
        setState(() {
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
        });
        _scrollToBottom();
        return;
      }
      
      if (result.isConfident(threshold: 0.5)) {
        // Confident prediction - show initial message and generate description
        final destination = result.topPredictions[0].displayLabel;
        final confidence = result.topPredictions[0].confidencePercent;
        
        // First, show recognition message
        String initialText = "✨ **Wonderful! I know this place!**\n\n"
            "📍 **${destination}**\n"
            "🎯 Confidence: $confidence\n\n";
        
        // Add alternative predictions if available
        if (result.topPredictions.length > 1 && result.topPredictions[1].confidencePercent.contains('%')) {
          initialText += "**Could also be:**\n";
          for (int i = 1; i < result.topPredictions.length && i < 3; i++) {
            initialText += "• ${result.topPredictions[i].displayLabel} (${result.topPredictions[i].confidencePercent})\n";
          }
          initialText += "\n";
        }
        
        initialText += "📝 Generating detailed description...";
        
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            text: initialText,
            timestamp: DateTime.now(),
            recognizedDestination: destination,
          ));
          _isGeneratingDescription = true;
        });
        
        _scrollToBottom();
        
        // Generate AI description asynchronously (outside setState)
        try {
          final description = await GroqService.generateDestinationDescription(destination);
          
          if (mounted) {
            setState(() {
              _isGeneratingDescription = false;
              
              // Add the detailed description message
              String finalText = "🏛️ **About ${destination}:**\n\n"
                  "$description\n\n"
                  "💡 Want to know more? Ask me anything about this destination! 🗺️";
              
              _messages.add(ChatMessage(
                isUser: false,
                text: finalText,
                timestamp: DateTime.now(),
              ));
            });
            _scrollToBottom();
          }
        } catch (e) {
          print('❌ Error generating description: $e');
          if (mounted) {
            setState(() {
              _isGeneratingDescription = false;
              _messages.add(ChatMessage(
                isUser: false,
                text: "⚠️ I had trouble generating a detailed description. \n\n"
                    "But I can confirm this is **${destination}**! 🏛️\n\n"
                    "It's a wonderful place worth visiting! ✨",
                timestamp: DateTime.now(),
              ));
            });
            _scrollToBottom();
          }
        }
      } else {
        // Low confidence - cannot analyze
        setState(() {
          _messages.add(ChatMessage(
            isUser: false,
            text: "📷 **Image cannot be analysed**\n\n"
                "Please retake a more clearer picture.\n\n"
                "Tips for better results:\n"
                "• Make sure the landmark is clearly visible\n"
                "• Try taking the photo from a different angle\n"
                "• Ensure good lighting\n"
                "• Get closer to the destination\n\n"
                "I work best with famous Indian monuments and tourist spots! 🏛️",
            timestamp: DateTime.now(),
          ));
        });
        _scrollToBottom();
      }

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
  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final themeProvider = context.watch<ThemeProvider>();
    final primaryColor = themeProvider.primaryColor;
    final textOnPrimary = themeProvider.textOnPrimaryColor;
    final backgroundColor = themeProvider.backgroundColor;
    final textColor = themeProvider.textColor;
    
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            // Cute robot logo
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: textOnPrimary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '🤖',
                style: const TextStyle(fontSize: 20),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GoBuddy',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textOnPrimary,
                  ),
                ),
                Text(
                  'Your AI Travel Companion',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.normal,
                    color: textOnPrimary.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ],
        ),
        backgroundColor: primaryColor,
        foregroundColor: textOnPrimary,
        elevation: 0,
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
              color: themeProvider.surfaceColor,
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
                        color: backgroundColor,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: primaryColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.camera_alt, color: textColor.withOpacity(0.5), size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Snap a place to learn about it...',
                            style: TextStyle(
                              color: textColor.withOpacity(0.5),
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
                        color: primaryColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.add_a_photo,
                        color: textOnPrimary,
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
    final themeProvider = context.watch<ThemeProvider>();
    final surfaceColor = themeProvider.surfaceColor;
    final textColor = themeProvider.textColor;
    final primaryColor = themeProvider.primaryColor;
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
                color: primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Text('🤖', style: TextStyle(fontSize: 16)),
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
                color: isUser ? primaryColor : surfaceColor,
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
                        color: textColor,
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
              backgroundColor: primaryColor.withOpacity(0.2),
              child: Icon(Icons.person, size: 18, color: primaryColor),
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
