import 'package:flutter/material.dart';
import '../../app/theme/app_colors.dart';
import '../../core/service/api_client.dart';

class AdminDeliveryScreen extends StatefulWidget {
  const AdminDeliveryScreen({super.key});

  @override
  State<AdminDeliveryScreen> createState() => _AdminDeliveryScreenState();
}

class _AdminDeliveryScreenState extends State<AdminDeliveryScreen> {
  bool _isLoading = true;

  // Settings
  bool _isFreeDeliveryActive = false;
  final _freeDeliveryThresholdController = TextEditingController();
  final _defaultChargeController = TextEditingController();

  // Rules
  List<Map<String, dynamic>> _rules = [];

  // Quote Simulator
  final _testSubtotalController = TextEditingController(text: '750');
  Map<String, dynamic>? _testQuoteResult;
  bool _isCalculatingQuote = false;

  @override
  void initState() {
    super.initState();
    _loadAllDeliveryData();
  }

  @override
  void dispose() {
    _freeDeliveryThresholdController.dispose();
    _defaultChargeController.dispose();
    _testSubtotalController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDeliveryData() async {
    setState(() => _isLoading = true);
    try {
      final settings = await ApiClient.get('/admin/delivery/settings');
      final rules = await ApiClient.get('/admin/delivery/rules');

      if (mounted) {
        setState(() {
          _isFreeDeliveryActive = settings['is_free_delivery_active'] ?? false;
          _freeDeliveryThresholdController.text =
              settings['free_delivery_threshold']?.toString() ?? '1500';
          _defaultChargeController.text =
              settings['default_delivery_charge']?.toString() ?? '50';
          _rules = List<Map<String, dynamic>>.from(rules as List);
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading delivery settings: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final payload = {
        'is_free_delivery_active': _isFreeDeliveryActive,
        'free_delivery_threshold':
            double.tryParse(_freeDeliveryThresholdController.text.trim()),
        'default_delivery_charge':
            double.tryParse(_defaultChargeController.text.trim()) ?? 50.0,
      };

      await ApiClient.put('/admin/delivery/settings', body: payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Delivery settings updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _showRuleDialog({Map<String, dynamic>? rule}) async {
    final isEditing = rule != null;
    final nameCtrl = TextEditingController(text: rule?['name'] ?? '');
    final minCtrl = TextEditingController(
        text: rule?['min_order_amount']?.toString() ?? '0');
    final maxCtrl = TextEditingController(
        text: rule?['max_order_amount']?.toString() ?? '');
    final chargeCtrl =
        TextEditingController(text: rule?['charge']?.toString() ?? '40');
    final priorityCtrl =
        TextEditingController(text: rule?['priority']?.toString() ?? '1');
    bool isActive = rule?['is_active'] ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: Text(isEditing ? 'Edit Delivery Rule' : 'Add Delivery Rule'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Rule Name *', hintText: 'e.g. Standard Tier'),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: minCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Min Order (₹)'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: maxCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Max Order (₹)', hintText: 'None'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: chargeCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Delivery Charge (₹) *'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: priorityCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Priority (e.g. 5)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  title: const Text('Rule Active', style: TextStyle(fontSize: 13)),
                  value: isActive,
                  onChanged: (v) => setDlgState(() => isActive = v),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () async {
                final payload = {
                  'name': nameCtrl.text.trim(),
                  'min_order_amount': double.tryParse(minCtrl.text.trim()) ?? 0.0,
                  'max_order_amount': maxCtrl.text.trim().isNotEmpty
                      ? double.tryParse(maxCtrl.text.trim())
                      : null,
                  'charge': double.tryParse(chargeCtrl.text.trim()) ?? 0.0,
                  'priority': int.tryParse(priorityCtrl.text.trim()) ?? 0,
                  'is_active': isActive,
                };

                final nav = Navigator.of(ctx);
                final messenger = ScaffoldMessenger.of(context);
                try {
                  if (isEditing) {
                    await ApiClient.put('/admin/delivery/rules/${rule['id']}', body: payload);
                  } else {
                    await ApiClient.post('/admin/delivery/rules', body: payload);
                  }
                  nav.pop(true);
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('SAVE'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      _loadAllDeliveryData();
    }
  }

  Future<void> _deleteRule(String ruleId) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiClient.delete('/admin/delivery/rules/$ruleId');
      _loadAllDeliveryData();
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _simulateQuote() async {
    final sub = double.tryParse(_testSubtotalController.text.trim());
    if (sub == null) return;

    setState(() => _isCalculatingQuote = true);
    try {
      final res = await ApiClient.post('/delivery/quote', body: {'subtotal': sub});
      if (mounted) {
        setState(() {
          _testQuoteResult = res as Map<String, dynamic>;
          _isCalculatingQuote = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isCalculatingQuote = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Delivery Management'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Global Settings Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Global Delivery Settings',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                          ),
                          const SizedBox(height: 12),

                          SwitchListTile(
                            title: const Text('Free Delivery Promotion', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text('Waives delivery fee for orders exceeding threshold', style: TextStyle(fontSize: 11)),
                            value: _isFreeDeliveryActive,
                            activeThumbColor: AppColors.primary,
                            onChanged: (v) => setState(() => _isFreeDeliveryActive = v),
                            contentPadding: EdgeInsets.zero,
                          ),
                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _freeDeliveryThresholdController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Free Delivery Over (₹)',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _defaultChargeController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Default Fee (₹)',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _saveSettings,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                              child: const Text('SAVE SETTINGS'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tiered Delivery Rules Card
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Tiered Delivery Rules',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _showRuleDialog(),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('ADD RULE'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_rules.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              child: Center(
                                child: Text('No custom rules defined. Default fee applies.', style: TextStyle(color: AppColors.textSecondary)),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _rules.length,
                              separatorBuilder: (_, _) => const Divider(height: 1),
                              itemBuilder: (context, idx) {
                                final r = _rules[idx];
                                final maxTxt = r['max_order_amount'] != null ? '₹${r['max_order_amount']}' : '∞';
                                return ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                  subtitle: Text(
                                    'Order: ₹${r['min_order_amount']} to $maxTxt  •  Priority: ${r['priority']}',
                                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '₹${r['charge']}',
                                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.primary, fontSize: 14),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, size: 18, color: AppColors.grey),
                                        onPressed: () => _showRuleDialog(rule: r),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                                        onPressed: () => _deleteRule(r['id']),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Interactive Quote Preview / Test Simulator
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Live Delivery Quote Simulator',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.text),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Test your active delivery rules against test cart amounts:',
                            style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 12),

                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _testSubtotalController,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Order Subtotal (₹)',
                                    prefixText: '₹ ',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton(
                                onPressed: _isCalculatingQuote ? null : _simulateQuote,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                ),
                                child: _isCalculatingQuote
                                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('CALCULATE'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          if (_testQuoteResult != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.softLavender,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Applied: ${_testQuoteResult!['applied_rule'] ?? 'Default'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primary),
                                      ),
                                      Text(
                                        _testQuoteResult!['is_free_delivery'] == true ? 'Free Delivery Qualified' : 'Standard Charge',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        'Fee: ₹${_testQuoteResult!['delivery_charge']}',
                                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.primary),
                                      ),
                                      Text(
                                        'Total: ₹${_testQuoteResult!['total']}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
