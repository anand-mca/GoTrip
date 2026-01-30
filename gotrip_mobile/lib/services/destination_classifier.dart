import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class DestinationClassifier {
  static DestinationClassifier? _instance;
  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isInitialized = false;
  bool _isWebPlatform = false;

  // Model input size (MobileNetV2 uses 224x224)
  static const int inputSize = 224;
  
  // Singleton pattern
  static DestinationClassifier get instance {
    _instance ??= DestinationClassifier._();
    return _instance!;
  }

  DestinationClassifier._();

  bool get isInitialized => _isInitialized;
  bool get isWebPlatform => _isWebPlatform;

  /// Initialize the classifier by loading the model and labels
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Check if running on web - TFLite doesn't work on web
    _isWebPlatform = kIsWeb;
    
    if (_isWebPlatform) {
      print('⚠️ TFLite not supported on web platform. Using fallback mode.');
      // Load labels anyway for display purposes
      try {
        final labelsData = await rootBundle.loadString('assets/models/labels.txt');
        _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      } catch (e) {
        print('Failed to load labels: $e');
      }
      _isInitialized = true;
      return;
    }

    try {
      print('🔄 Loading TFLite model...');
      
      // Copy model from assets to app cache directory
      final modelFileName = 'destination_model.tflite';
      final appDir = await getApplicationCacheDirectory();
      final modelPath = File('${appDir.path}/$modelFileName');
      
      // If model doesn't exist in cache, copy it from assets
      if (!modelPath.existsSync()) {
        print('📦 Copying model from assets to ${modelPath.path}...');
        final byteData = await rootBundle.load('assets/models/$modelFileName');
        await modelPath.writeAsBytes(byteData.buffer.asUint8List());
        print('✅ Model copied to cache');
      } else {
        print('✅ Model found in cache');
      }
      
      // Load the model from the cache path
      _interpreter = await Interpreter.fromFile(modelPath);
      print('✅ Model loaded successfully!');
      
      // Load labels
      final labelsData = await rootBundle.loadString('assets/models/labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      
      _isInitialized = true;
      print('✅ Destination classifier initialized with ${_labels.length} classes');
      print('📊 Model input tensors: ${_interpreter!.getInputTensors()}');
      print('📊 Model output tensors: ${_interpreter!.getOutputTensors()}');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize classifier: $e');
      print('📜 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Classify an image from file path
  Future<ClassificationResult> classifyImage(File imageFile) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Handle web platform - return mock result
    if (_isWebPlatform) {
      return ClassificationResult(
        topPrediction: 'Web Not Supported',
        confidence: 0.0,
        topPredictions: [],
        isWebFallback: true,
      );
    }

    try {
      // Read and decode image
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image');
      }

      // Preprocess image
      final input = _preprocessImage(image);
      
      // Run inference
      final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);
      
      // Get results
      final probabilities = output[0] as List<double>;
      
      // Find top prediction
      int maxIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      // Get top 3 predictions
      final sortedIndices = List.generate(probabilities.length, (i) => i);
      sortedIndices.sort((a, b) => probabilities[b].compareTo(probabilities[a]));
      
      final topPredictions = sortedIndices.take(3).map((index) {
        return Prediction(
          label: _labels[index],
          confidence: probabilities[index],
        );
      }).toList();

      return ClassificationResult(
        topPrediction: _labels[maxIndex],
        confidence: maxProb,
        topPredictions: topPredictions,
      );
    } catch (e) {
      print('❌ Classification error: $e');
      rethrow;
    }
  }

  /// Classify image from bytes (for web/camera)
  Future<ClassificationResult> classifyImageBytes(Uint8List imageBytes) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final image = img.decodeImage(imageBytes);
      
      if (image == null) {
        throw Exception('Failed to decode image bytes');
      }

      final input = _preprocessImage(image);
      
      final output = List.filled(1 * _labels.length, 0.0).reshape([1, _labels.length]);
      _interpreter!.run(input, output);
      
      final probabilities = output[0] as List<double>;
      
      int maxIndex = 0;
      double maxProb = probabilities[0];
      for (int i = 1; i < probabilities.length; i++) {
        if (probabilities[i] > maxProb) {
          maxProb = probabilities[i];
          maxIndex = i;
        }
      }

      final sortedIndices = List.generate(probabilities.length, (i) => i);
      sortedIndices.sort((a, b) => probabilities[b].compareTo(probabilities[a]));
      
      final topPredictions = sortedIndices.take(3).map((index) {
        return Prediction(
          label: _labels[index],
          confidence: probabilities[index],
        );
      }).toList();

      return ClassificationResult(
        topPrediction: _labels[maxIndex],
        confidence: maxProb,
        topPredictions: topPredictions,
      );
    } catch (e) {
      print('❌ Classification error: $e');
      rethrow;
    }
  }

  /// Preprocess image for MobileNetV2
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // Resize image to model input size
    final resizedImage = img.copyResize(
      image,
      width: inputSize,
      height: inputSize,
      interpolation: img.Interpolation.linear,
    );

    // Convert to normalized float array
    // MobileNetV2 expects values in range [-1, 1] or [0, 1] depending on training
    // Adjust normalization based on how you trained your model
    final input = List.generate(
      1,
      (batch) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            // Normalize to [0, 1] - adjust if your model uses different normalization
            return [
              pixel.r / 255.0,
              pixel.g / 255.0,
              pixel.b / 255.0,
            ];
          },
        ),
      ),
    );

    return input;
  }

  /// Get list of all labels
  List<String> get labels => List.unmodifiable(_labels);

  /// Clean up resources
  void dispose() {
    _interpreter?.close();
    _isInitialized = false;
  }
}

/// Result of image classification
class ClassificationResult {
  final String topPrediction;
  final double confidence;
  final List<Prediction> topPredictions;
  final bool isWebFallback;

  ClassificationResult({
    required this.topPrediction,
    required this.confidence,
    required this.topPredictions,
    this.isWebFallback = false,
  });

  /// Get confidence as percentage string
  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Check if prediction is confident enough (above threshold)
  bool isConfident({double threshold = 0.5}) => confidence >= threshold;

  @override
  String toString() {
    return 'ClassificationResult(prediction: $topPrediction, confidence: $confidencePercent)';
  }
}

/// Individual prediction with label and confidence
class Prediction {
  final String label;
  final double confidence;

  Prediction({
    required this.label,
    required this.confidence,
  });

  String get confidencePercent => '${(confidence * 100).toStringAsFixed(1)}%';

  /// Format label for display (clean up underscores, etc.)
  String get displayLabel {
    return label
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isNotEmpty 
            ? '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}'
            : '')
        .join(' ');
  }
}
