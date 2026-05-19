import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:path_provider/path_provider.dart';

class CropScreen extends StatefulWidget {
  final String imagePath;

  const CropScreen({super.key, required this.imagePath});

  @override
  State<CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<CropScreen> {
  final CropController _controller = CropController();
  bool _isCropping = false;

  void _onCropped(Uint8List result) async {
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(path).writeAsBytes(result);
    if (mounted) Navigator.pop(context, path);
  }

  void _crop() {
    setState(() => _isCropping = true);
    _controller.crop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Potong Nota'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, widget.imagePath),
            child: const Text('Lewati'),
          ),
        ],
      ),
      body: FutureBuilder<Uint8List>(
        future: File(widget.imagePath).readAsBytes(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Crop(
            image: snapshot.data!,
            controller: _controller,
            onCropped: _onCropped,
            radius: 8,
            maskColor: Colors.black54,
            progressIndicator: const CircularProgressIndicator(),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isCropping ? null : _crop,
        icon: const Icon(Icons.crop),
        label: const Text('Potong'),
      ),
    );
  }
}
