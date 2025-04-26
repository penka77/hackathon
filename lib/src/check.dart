import 'dart:async';
import 'dart:io';


import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class CheckScreen extends StatefulWidget {
  const CheckScreen({super.key});

  @override
  State<CheckScreen> createState() => _CheckScreenState();
}

class _CheckScreenState extends State<CheckScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) return;

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      _controller = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );

      _initializeControllerFuture = _controller.initialize().then((_) {
        if (!mounted) return;
        setState(() => _isCameraInitialized = true);
      });
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  Future<void> _takePicture() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Камера недоступна в веб-версии')),
      );
      return;
    }

    if (!_isCameraInitialized) return;

    try {
      final image = await _controller.takePicture();
      setState(() => _capturedImage = image);
      await _uploadImage(image);
    } catch (e) {
      debugPrint('Error taking picture: $e');
    }
  }

  Future<void> _pickImages() async {
    try {
      final images = await _picker.pickMultiImage(imageQuality: 80);
      if (images == null || images.isEmpty) return;

      setState(() => _isUploading = true);

      for (final image in images) {
        await _uploadImage(image);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Загружено ${images.length} изображений')),
      );
    } catch (e) {
      debugPrint('Ошибка загрузки изображений: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _uploadImage(XFile image) async {
    try {
      setState(() => _isUploading = true);

      // Configure server URL based on platform
      final serverUrl = kIsWeb
          ? 'http://localhost:8000/upload'
          : 'http://10.0.2.2:8000/upload';

      final uri = Uri.parse(serverUrl);
      final request = http.MultipartRequest('POST', uri);

      // Read file bytes
      final bytes = await image.readAsBytes();

      // Add file to request
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: image.name,
      ));

      debugPrint('Uploading to $serverUrl...');
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Изображение успешно загружено')),
        );
      } else {
        throw Exception('Server error: $responseBody');
      }
    } catch (e) {
      debugPrint('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Приемная камера'),
      ),
      body: _buildCameraPreview(),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildCameraPreview() {
    if (_capturedImage != null) {
      return Center(
        child: kIsWeb
            ? Image.network(_capturedImage!.path)
            : Image.file(File(_capturedImage!.path)),
      );
    }

    if (!kIsWeb && !_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    if (kIsWeb) {
      return const Center(
        child: Text('Предварительный просмотр камеры недоступен в веб-версии'),
      );
    }

    return CameraPreview(_controller);
  }

  Widget _buildBottomButtons() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Gallery button
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDE3E1B),
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _isUploading ? null : _pickImages,
                child: const Icon(Icons.photo_library, color: Colors.white, size: 32),
              ),
            ),
          ),
          // Кнопка для съемки фото
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: const Color(0xFFDE3E1B), width: 2),
                  ),
                ),
                onPressed: _takePicture,
                child: Icon(Icons.camera_alt, color: const Color(0xFFDE3E1B), size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}