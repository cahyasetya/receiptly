import 'package:flutter/material.dart';
import 'dart:io';
import '../models/index.dart';
import '../services/index.dart';
import 'categorize_screen.dart';

class OCRScreen extends StatefulWidget {
  final String imagePath;
  final ExpenseRepository repository;

  const OCRScreen({
    Key? key,
    required this.imagePath,
    required this.repository,
  }) : super(key: key);

  @override
  State<OCRScreen> createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  late OCRService _ocrService;
  late TextEditingController _merchantController;
  late TextEditingController _amountController;
  late TextEditingController _ocrTextController;

  String? _merchantName;
  double? _amount;
  List<OCRItem> _items = [];
  String _fullOCRText = '';
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _ocrService = OCRService();
    _merchantController = TextEditingController();
    _amountController = TextEditingController();
    _ocrTextController = TextEditingController();
    _processImage();
  }

  Future<void> _processImage() async {
    try {
      setState(() {
        _isProcessing = true;
        _errorMessage = null;
      });

      final result = await _ocrService.recognizeTextFromImage(widget.imagePath);

      setState(() {
        _fullOCRText = result.fullText;
        _merchantName = result.merchantName;
        _amount = result.amount;
        _items = result.items;

        _merchantController.text = _merchantName ?? '';
        _amountController.text = _amount?.toStringAsFixed(2) ?? '';
        _ocrTextController.text = _fullOCRText;

        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to process image: $e';
        _isProcessing = false;
      });
    }
  }

  Future<void> _proceedToCategory() async {
    // Validate inputs
    if (_merchantController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter merchant name')),
      );
      return;
    }

    double? amount;
    try {
      amount = double.parse(_amountController.text);
      if (amount <= 0) throw FormatException('Amount must be greater than 0');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    // Navigate to categorize screen
    if (amount == null) return;

    final result = await Navigator.push<Expense>(
      context,
      MaterialPageRoute(
        builder: (context) => CategorizeScreen(
          imagePath: widget.imagePath,
          merchantName: _merchantController.text,
          amount: amount!,
          ocrText: _fullOCRText,
          items: _items,
          repository: widget.repository,
        ),
      ),
    );

    if (result != null && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Receipt'),
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
                  Text('Processing receipt...'),
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

                    // Merchant name field
                    const SizedBox(height: 16),
                    const Text(
                      'Merchant Name',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _merchantController,
                      decoration: InputDecoration(
                        hintText: 'Enter merchant name',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // Amount field
                    const SizedBox(height: 16),
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),

                    // OCR Text preview (collapsible)
                    const SizedBox(height: 24),
                    ExpansionTile(
                      title: const Text('OCR Text Preview'),
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _fullOCRText.isEmpty
                                ? 'No text detected'
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
                        child: const Text('Continue to Category'),
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
    _merchantController.dispose();
    _amountController.dispose();
    _ocrTextController.dispose();
    _ocrService.dispose();
    super.dispose();
  }
}
