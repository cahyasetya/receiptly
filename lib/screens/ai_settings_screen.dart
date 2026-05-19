import 'package:flutter/material.dart';
import '../models/index.dart';
import '../services/index.dart';
import '../rules/ai_models.dart';

class AISettingsScreen extends StatefulWidget {
  final ExpenseRepository repository;

  const AISettingsScreen({super.key, required this.repository});

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  late TextEditingController _customModelController;
  String _currentModel = '';
  String _selectedPreset = '';
  bool _isLoading = true;
  bool _isCustom = false;
  CreditInfo? _creditInfo;

  @override
  void initState() {
    super.initState();
    _customModelController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    final saved = await widget.repository.getSetting('ai_model');
    if (!mounted) return;
    setState(() {
      _currentModel = saved ?? '';
      _isLoading = false;
      _isCustom = true;
      for (final preset in presetAiModels) {
        if (preset.$1.startsWith('---')) continue;
        if (preset.$1 == _currentModel) {
          _selectedPreset = preset.$1;
          _isCustom = false;
          break;
        }
      }
      if (_isCustom) {
        _customModelController.text = _currentModel;
      }
    });
    _loadCreditInfo();
  }

  Future<void> _loadCreditInfo() async {
    final info = await AIOCRService().fetchCreditInfo();
    if (mounted) setState(() => _creditInfo = info);
  }

  Future<void> _selectPreset(String modelId) async {
    AIOCRService().updateModel(modelId);
    await widget.repository.setSetting('ai_model', modelId);
    setState(() {
      _currentModel = modelId;
      _selectedPreset = modelId;
      _isCustom = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model diubah ke $modelId')),
      );
    }
  }

  Future<void> _saveCustomModel() async {
    final modelId = _customModelController.text.trim();
    if (modelId.isEmpty) return;
    AIOCRService().updateModel(modelId);
    await widget.repository.setSetting('ai_model', modelId);
    setState(() {
      _currentModel = modelId;
      _selectedPreset = '';
      _isCustom = true;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model diubah ke $modelId')),
      );
    }
  }

  @override
  void dispose() {
    _customModelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan AI')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Current model
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Model Saat Ini', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text(
                          _currentModel.isNotEmpty ? _currentModel : 'Default (.env)',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Credit info
                if (_creditInfo != null)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('Kredit API', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              SizedBox(
                                width: 32, height: 32,
                                child: IconButton(
                                  padding: EdgeInsets.zero,
                                  icon: const Icon(Icons.refresh, size: 18),
                                  onPressed: _loadCreditInfo,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Text('Sisa Kredit', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              const Spacer(),
                              Text(
                                _creditInfo!.formattedRemaining,
                                style: TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w700,
                                  color: _creditInfo!.limitRemaining > 0 ? Colors.green[600] : Theme.of(context).colorScheme.error,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _creditInfo!.remainingPercentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _creditInfo!.limitRemaining > 0 ? Colors.green[400]! : Colors.red[400]!,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _row('Plan', _creditInfo!.planLabel),
                          _row('Total Limit', _creditInfo!.formattedLimit),
                          _row('Terpakai', _creditInfo!.formattedUsed),
                          if (_creditInfo!.usageDaily > 0) _row('Hari Ini', _creditInfo!.formattedDaily),
                          if (_creditInfo!.usageMonthly > 0) _row('Bulan Ini', _creditInfo!.formattedMonthly),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Free models
                const Text('Model Gratis', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...presetAiModels.where((p) => p.$3 && !p.$1.startsWith('---')).map((p) => _modelTile(p.$1, p.$2)),
                const SizedBox(height: 16),

                // Paid models
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('Model Berbayar', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 8),
                ...presetAiModels.where((p) => !p.$3 && !p.$1.startsWith('---')).map((p) => _modelTile(p.$1, p.$2)),
                const SizedBox(height: 16),

                // Custom model
                const Text('Model Kustom', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customModelController,
                        decoration: const InputDecoration(
                          hintText: 'provider/model:free',
                          labelText: 'ID Model',
                          border: OutlineInputBorder(),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _saveCustomModel(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(onPressed: _saveCustomModel, child: const Text('Gunakan')),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Contoh: nvidia/nemotron-nano-12b-v2-vl:free',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ),
    );
  }

  Widget _modelTile(String modelId, String label) {
    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: RadioListTile<String>(
        title: Text(label, style: const TextStyle(fontSize: 14)),
        subtitle: Text(modelId, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        value: modelId,
        groupValue: _selectedPreset,
        onChanged: (v) => v != null ? _selectPreset(v) : null,
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant))),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13), textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}
