import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  File? _selectedImage;
  bool _isLoading = false;
  String? _predictionResult;
  double? _confidence;
  String? _classId;
  Map<String, dynamic>? _apiResponse;
  final ImagePicker _picker = ImagePicker();

  static const String _baseUrl = 'http://10.125.151.234:8000'; //IP Config
  static const String _apiUrl = '$_baseUrl/predict';

  void _resetScan() {
    setState(() {
      _selectedImage = null;
      _predictionResult = null;
      _confidence = null;
      _classId = null;
      _apiResponse = null;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Scan reset successfully!'),
        backgroundColor: Colors.blue,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<bool> _testApiConnection() async {
    print('Testing API connection to: $_baseUrl');

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('API Connection successful!');
        return true;
      } else {
        print('API Connection failed with status: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('API Connection error: $e');
      print('Error type: ${e.runtimeType}');

      // Detailed error analysis
      if (e.toString().contains('SocketException')) {
        print('SOCKET ERROR - Possible causes:');
        print('1. Server not running');
        print('2. Wrong IP address');
        print('3. Firewall blocking');
        print('4. Not on same network');
      }

      return false;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice:
        source == ImageSource.camera ? CameraDevice.rear : CameraDevice.front,
      );

      if (image != null) {
        String fileName = image.name.isNotEmpty ? image.name : path.basename(image.path);
        String fileNameLower = fileName.toLowerCase();
        List<String> validExtensions = ['.jpg', '.jpeg', '.png', '.bmp', '.webp'];

        bool isValidFormat = validExtensions.any((ext) => fileNameLower.endsWith(ext));

        print('Image picked: ${image.path}');
        print('Image name: $fileName');
        print('Image size: ${await File(image.path).length()} bytes');
        print('Valid format: $isValidFormat');

        if (!isValidFormat) {
          _showErrorDialog(
              'Invalid image format. Please use JPG, PNG, or other supported formats.');
          return;
        }

        setState(() {
          _selectedImage = File(image.path);
          _predictionResult = null;
          _confidence = null;
          _classId = null;
          _apiResponse = null;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      _showErrorDialog('Error picking image: $e');
    }
  }

  Future<void> _predictImage() async {
    if (_selectedImage == null) {
      _showErrorDialog('Please select an image first');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      print('Starting image prediction...');
      print('Selected image: ${_selectedImage!.path}');

      if (!await _selectedImage!.exists()) {
        throw Exception('Selected image file does not exist');
      }

      final imageBytes = await _selectedImage!.readAsBytes();
      print('Image size: ${imageBytes.length} bytes');

      if (imageBytes.isEmpty) {
        throw Exception('Selected image file is empty');
      }

      print('Testing API connection...');
      final isConnected = await _testApiConnection();
      if (!isConnected) {
        throw Exception('Cannot connect to local API server!\n\n'
            'Troubleshooting steps:\n'
            '1. FastAPI server running?\n'
            '   → Run: uvicorn main:app --host 0.0.0.0 --port 8000\n\n'
            '2. Correct IP address?\n'
            '   → Check: ipconfig (Windows) or ifconfig (Mac/Linux)\n'
            '   → Current: 192.168.0.100\n\n'
            '3. Same WiFi network?\n'
            '   → Phone and computer must be on same network\n\n'
            '4. Firewall not blocking?\n'
            '   → Allow port 8000 in Windows Firewall\n\n'
            '5. Test from browser:\n'
            '   → http://192.168.0.100:8000');
      }

      print('API connection successful, proceeding with prediction...');

      var request = http.MultipartRequest('POST', Uri.parse(_apiUrl));

      request.headers.addAll({
        'Accept': 'application/json',
      });

      String fileName = path.basename(_selectedImage!.path);
      String fileExtension = path.extension(fileName).toLowerCase();

      String contentType;
      switch (fileExtension) {
        case '.jpg':
        case '.jpeg':
          contentType = 'image/jpeg';
          break;
        case '.png':
          contentType = 'image/png';
          break;
        case '.bmp':
          contentType = 'image/bmp';
          break;
        case '.webp':
          contentType = 'image/webp';
          break;
        default:
          contentType = 'image/jpeg';
      }

      print('File name: $fileName');
      print('Content type: $contentType');

      var multipartFile = http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: fileName,
        contentType: MediaType.parse(contentType),
      );

      request.files.add(multipartFile);

      print('Sending request to: $_apiUrl');
      print('File size: ${imageBytes.length} bytes');
      print('Content-Type: $contentType');

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Request timeout - API took too long to respond'),
      );

      var response = await http.Response.fromStream(streamedResponse);

      print('Response status: ${response.statusCode}');
      print('Response headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        setState(() {
          _apiResponse = jsonResponse;

          if (jsonResponse['success'] == true) {
            if (jsonResponse.containsKey('prediction')) {
              var prediction = jsonResponse['prediction'];
              _predictionResult = prediction['class_name'];
              _confidence = prediction['confidence'];
              _classId = prediction['class_id'].toString();
            }
            else if (jsonResponse.containsKey('detections')) {
              var detections = jsonResponse['detections'];
              if (detections.isNotEmpty) {
                var firstDetection = detections[0];
                _predictionResult = firstDetection['class_name'];
                _confidence = firstDetection['confidence'];
                _classId = firstDetection['class_id'].toString();
              } else {
                _predictionResult = 'No objects detected';
                _confidence = 0.0;
              }
            }
          } else {
            throw Exception('API returned success: false');
          }
        });

        await _saveToHistory(imageBytes);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image analyzed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

      } else {
        String errorMessage = 'API Error: ${response.statusCode}';
        try {
          var errorJson = json.decode(response.body);
          if (errorJson.containsKey('detail')) {
            errorMessage += '\n${errorJson['detail']}';
          }
        } catch (e) {
          errorMessage += '\n${response.body}';
        }
        _showErrorDialog(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Error: $e';

      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error: Cannot connect to server.\n'
            'Please check:\n'
            '• FastAPI server is running\n'
            '• Computer IP: 192.168.0.100\n'
            '• Both devices on same WiFi network';
      } else if (e.toString().contains('TimeoutException')) {
        errorMessage = 'Request timeout: Server took too long to respond.\n'
            'This might happen with large images or slow processing.';
      } else if (e.toString().contains('FormatException')) {
        errorMessage = 'Invalid response format from server.\n'
            'Please check FastAPI server logs.';
      }

      _showErrorDialog(errorMessage);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToHistory(List<int> imageBytes) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && _predictionResult != null) {
        // Convert image to base64 for storage
        String imageBase64 = base64Encode(imageBytes);

        // Prepare prediction data (matching your Firebase structure)
        Map<String, dynamic> predictionData = {
          'class_name': _predictionResult!,
          'confidence': _confidence ?? 0.0,
          'class_id': int.tryParse(_classId ?? '0') ?? 0,
        };

        await FirebaseFirestore.instance.collection('scan_history').add({
          'userId': user.uid,
          'userEmail': user.email,
          'prediction': predictionData, // Store as nested object
          'confidence': _confidence ?? 0.0, // Also store at root level for backward compatibility
          'classId': _classId ?? '0',
          'timestamp': FieldValue.serverTimestamp(),
          'imagePath': _selectedImage?.path, // Keep original path for reference
          'imageData': imageBase64, // Store base64 encoded image
          'apiResponse': _apiResponse, // Store full API response for debugging
        });

        print('History saved successfully with image data');
      }
    } catch (e) {
      print('Error saving to history: $e');
      // Show error to user but don't throw - prediction was successful
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Prediction successful but failed to save to history: $e'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: SingleChildScrollView(
          child: Text(message),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    if (_predictionResult == null) return const SizedBox.shrink();

    Color resultColor = _predictionResult!.toLowerCase().contains('positive') ||
        _predictionResult!.toLowerCase().contains('monkeypox') ||
        _predictionResult!.toLowerCase().contains('disease')
        ? Colors.red
        : Colors.green;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _predictionResult!.toLowerCase().contains('positive') ||
                      _predictionResult!.toLowerCase().contains('monkeypox') ||
                      _predictionResult!.toLowerCase().contains('disease')
                      ? Icons.warning
                      : Icons.check_circle,
                  color: resultColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Prediction Result',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: resultColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Result: $_predictionResult',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (_classId != null) ...[
              const SizedBox(height: 8),
              Text(
                'Class ID: $_classId',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (_confidence != null) ...[
              const SizedBox(height: 8),
              Text(
                'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: _confidence!,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(resultColor),
              ),
            ],
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This is an AI prediction. Please consult with healthcare professionals for accurate diagnosis.',
                      style: TextStyle(
                        color: Colors.orange[700],
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStatus() {
    return Card(
      margin: const EdgeInsets.all(16),
      color: Colors.blue.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.computer, color: Colors.blue[700]),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Local API Server',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'IP: 192.168.0.110:8000',
                    style: TextStyle(
                      color: Colors.blue[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Testing connection...')),
                );
                final isConnected = await _testApiConnection();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isConnected ? 'Connected!' : 'Connection failed'),
                    backgroundColor: isConnected ? Colors.green : Colors.red,
                  ),
                );
              },
              child: const Text('Test'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Image'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: _predictionResult != null
            ? [
          IconButton(
            onPressed: _resetScan,
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Scan',
          ),
        ]
            : null,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [

            _buildConnectionStatus(),

            Container(
              height: 300,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: _selectedImage != null
                  ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                ),
              )
                  : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No image selected',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showImageSourceDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Select Image'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _selectedImage != null && !_isLoading
                              ? _predictImage
                              : null,
                          icon: _isLoading
                              ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                              : const Icon(Icons.analytics),
                          label: Text(_isLoading ? 'Analyzing...' : 'Analyze'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_selectedImage != null || _predictionResult != null) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _resetScan,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reset Scan'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          foregroundColor: Colors.orange,
                          side: const BorderSide(color: Colors.orange),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            _buildResultCard(),

            Card(
              margin: const EdgeInsets.all(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for Better Results',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.blue[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('• Ensure good lighting when taking photos'),
                    const Text('• Keep the camera steady and focused'),
                    const Text('• Take clear, close-up images of affected areas'),
                    const Text('• Avoid blurry or dark images'),
                    const Text('• Make sure FastAPI server is running on computer'),
                    const Text('• Both devices must be on the same WiFi network'),
                    const SizedBox(height: 8),
                    const Text('• Use the Reset button to start a new scan',
                        style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}