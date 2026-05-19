import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/index.dart';
import 'crop_screen.dart';
import 'ocr_screen.dart';

class CameraScreen extends StatefulWidget {
  final ExpenseRepository repository;

  const CameraScreen({
    super.key,
    required this.repository,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isProcessing = false;

  Future<void> _pickAndCrop(ImageSource source) async {
    try {
      setState(() => _isProcessing = true);

      final pickedFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );

      if (pickedFile == null || !mounted) {
        if (mounted) setState(() => _isProcessing = false);
        return;
      }

      if (mounted) setState(() => _isProcessing = false);

      final imagePath = await _showCropChoice(pickedFile.path);
      if (imagePath == null) return;

      if (mounted) {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => OCRScreen(
              imagePath: imagePath,
              repository: widget.repository,
            ),
          ),
        );
        if (result == true && mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memproses gambar: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<String?> _showCropChoice(String imagePath) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nota yang dipilih',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(imagePath),
                  height: 150,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context, 'crop'),
                  icon: const Icon(Icons.crop),
                  label: const Text('Potong Nota'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pop(context, 'skip'),
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('Langsung OCR'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (!mounted) return null;
    if (action == 'crop') {
      return Navigator.push<String>(
        context,
        MaterialPageRoute(
          builder: (context) => CropScreen(imagePath: imagePath),
        ),
      );
    } else if (action == 'skip') {
      return imagePath;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ambil Nota'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses gambar...'),
                ],
              ),
            )
          : Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long,
                    size: 80,
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Ambil Foto Nota',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Foto atau pilih dari galeri, lalu potong jika perlu',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => _pickAndCrop(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Ambil Foto'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickAndCrop(ImageSource.gallery),
                            icon: const Icon(Icons.image),
                            label: const Text('Pilih dari Galeri'),
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
}
