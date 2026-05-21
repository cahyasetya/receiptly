import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import '../models/index.dart';
import '../services/index.dart';
import 'categorize_screen.dart';

class OCRScreen extends StatefulWidget {
  final String imagePath;
  final ExpenseRepository repository;

  const OCRScreen({
    super.key,
    required this.imagePath,
    required this.repository,
  });

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  late TextEditingController _ocrTextController;

  List<OCRItem> _items = [];
  double _totalAmount = 0;
  String _fullOCRText = '';
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ocrTextController = TextEditingController();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final aiService = AIOCRService();
      await aiService.init(repository: widget.repository);
      final result = await aiService.recognizeTextFromImage(widget.imagePath);

      setState(() {
        _fullOCRText = result.fullText;
        _items = result.items;
        _totalAmount = result.amount ?? 0;
        _ocrTextController.text = _fullOCRText;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Gagal memproses gambar: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _proceedToCategory() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada item yang terdeteksi')),
      );
      return;
    }

    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorizeScreen(
          imagePath: widget.imagePath,
          ocrText: _fullOCRText,
          items: _items,
          totalAmount: _totalAmount,
          repository: widget.repository,
          source: InputMode.ai,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayTotal = _totalAmount > 0 ? _totalAmount : _items.fold<double>(0, (sum, i) => sum + i.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tinjau Nota'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Memproses nota...'),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Receipt image preview
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(widget.imagePath),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Error message if any
                    if (_errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red[300]!),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),

                    // Detected items summary
                    if (_items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 20, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            '${_items.length} item terdeteksi',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            NumberFormat.currency(
                              locale: 'id',
                              symbol: 'Rp',
                              decimalDigits: 0,
                            ).format(displayTotal),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ..._items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(child: Text(item.name, style: const TextStyle(fontSize: 13))),
                            Text(
                              NumberFormat.currency(
                                locale: 'id',
                                symbol: 'Rp',
                                decimalDigits: 0,
                              ).format(item.price),
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )),
                    ],

                    // OCR Text preview (collapsible)
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text('Teks OCR'),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _fullOCRText.isEmpty
                                ? 'Tidak ada teks terdeteksi'
                                : _fullOCRText,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),

                    // Continue button
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _proceedToCategory,
                        child: const Text('Lanjut ke Kategori'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _ocrTextController.dispose();
    super.dispose();
  }
}
