import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/budget_config.dart';
import '../services/ledger_state.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key});

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  late TextEditingController _incomeController;
  late TextEditingController _fixedController;
  late TextEditingController _apiKeyController;
  late TextEditingController _savingsGoalController;
  late TextEditingController _savingsCapController;
  late TextEditingController _alertThresholdController;
  late SurplusAllocationMode _selectedMode;
  DateTime? _alertDate;

  @override
  void initState() {
    super.initState();
    final state = context.read<LedgerState>();
    _incomeController = TextEditingController(text: state.budgetConfig.monthlyIncome.toStringAsFixed(0));
    _fixedController = TextEditingController(text: state.budgetConfig.fixedExpenses.toStringAsFixed(0));
    _apiKeyController = TextEditingController(text: state.geminiApiKey ?? '');
    _savingsGoalController = TextEditingController(text: state.budgetConfig.savingsGoalNote ?? '');
    _savingsCapController = TextEditingController(
        text: state.budgetConfig.savingsSpendingCap != null
            ? state.budgetConfig.savingsSpendingCap!.toStringAsFixed(0)
            : '');
    _alertThresholdController = TextEditingController(
        text: (state.budgetConfig.budgetAlertThreshold ?? 500.0).toStringAsFixed(0));
    _selectedMode = state.budgetConfig.surplusMode;
    _alertDate = state.budgetConfig.budgetAlertDate;
  }

  @override
  void dispose() {
    _incomeController.dispose();
    _fixedController.dispose();
    _apiKeyController.dispose();
    _savingsGoalController.dispose();
    _savingsCapController.dispose();
    _alertThresholdController.dispose();
    super.dispose();
  }

  void _saveBudget() {
    final income = double.tryParse(_incomeController.text.trim()) ?? 50000.0;
    final fixed = double.tryParse(_fixedController.text.trim()) ?? 20000.0;
    final apiKey = _apiKeyController.text.trim();
    final savingsGoal = _savingsGoalController.text.trim();
    final savingsCap = double.tryParse(_savingsCapController.text.trim());
    final alertThreshold = double.tryParse(_alertThresholdController.text.trim()) ?? 500.0;

    final state = context.read<LedgerState>();
    state.updateBudgetConfig(
      state.budgetConfig.copyWith(
        monthlyIncome: income,
        fixedExpenses: fixed,
        surplusMode: _selectedMode,
        savingsGoalNote: savingsGoal.isEmpty ? null : savingsGoal,
        savingsSpendingCap: savingsCap,
        clearSavingsNote: savingsGoal.isEmpty,
        clearSavingsCap: savingsCap == null,
        budgetAlertThreshold: alertThreshold,
        budgetAlertDate: _alertDate,
        clearAlertDate: _alertDate == null,
      ),
    );

    state.setGeminiApiKey(apiKey.isEmpty ? null : apiKey);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Budget & Savings Mode parameters updated successfully!'),
        backgroundColor: Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final income = double.tryParse(_incomeController.text.trim()) ?? 0.0;
    final fixed = double.tryParse(_fixedController.text.trim()) ?? 0.0;
    final discretionary = (income - fixed).clamp(0.0, double.infinity);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budget & AI Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Income Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Monthly Income & Fixed Outflows',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'Fixed outflows (Rent, Parent remittances, EMIs) are deducted upfront before daily quotas are calculated.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _incomeController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Monthly Income (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _fixedController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: const InputDecoration(
                        labelText: 'Fixed Outflows: Rent + Remittances (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Net Monthly Discretionary Fund:', style: TextStyle(fontWeight: FontWeight.w600)),
                          Text(
                            '₹${discretionary.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: Colors.green.shade900,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Surplus Allocation Mode
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Unspent Daily Quota Behavior',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(
                      'When you spend less than your daily quota, where should the leftover money go?',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    RadioListTile<SurplusAllocationMode>(
                      value: SurplusAllocationMode.weekendDhamaka,
                      groupValue: _selectedMode,
                      title: const Text('🎉 Weekend Dhamaka (Recommended)'),
                      subtitle: const Text(
                          'Store unspent daily funds into a weekend splurge pool for guilt-free outings.'),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMode = val);
                      },
                    ),
                    RadioListTile<SurplusAllocationMode>(
                      value: SurplusAllocationMode.rebalanceDaily,
                      groupValue: _selectedMode,
                      title: const Text('⚖️ Dynamic (Daily Rebalance)'),
                      subtitle: const Text(
                          'Spread unspent funds equally across all remaining days to boost future quotas.'),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMode = val);
                      },
                    ),
                    RadioListTile<SurplusAllocationMode>(
                      value: SurplusAllocationMode.savingsMode,
                      groupValue: _selectedMode,
                      title: const Text('🎯 Savings Mode'),
                      subtitle: const Text(
                          'Enforce a strict monthly spending cap and reserve surpluses toward custom savings goals.'),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedMode = val);
                      },
                    ),
                    if (_selectedMode == SurplusAllocationMode.savingsMode) ...[
                      const Divider(height: 24),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6751F5).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6751F5).withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.savings_rounded, color: Color(0xFF6751F5), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Savings Mode Configuration',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'These fields are optional and will never block saving your budget.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _savingsCapController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Monthly Spending Cap / Allocation (₹) - Optional',
                                hintText: 'e.g. 5000',
                                prefixText: '₹ ',
                                border: OutlineInputBorder(),
                                helperText: 'Caps your discretionary spending limit for this month (e.g. 5,000)',
                              ),
                            ),
                            const SizedBox(height: 14),
                            TextField(
                              controller: _savingsGoalController,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                labelText: 'Savings Notes / Goals - Optional',
                                hintText: 'e.g. Goa trip with friends or laptop upgrade fund',
                                border: OutlineInputBorder(),
                                helperText: 'Reminds you what you are saving for on your dashboard',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Budget Alerts & Date Picker (Requirement 5)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.notifications_active_rounded, color: Colors.amber, size: 22),
                        SizedBox(width: 8),
                        Text('Budget Alerts & Date Notifications',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Get notified automatically when remaining budget drops below a threshold or on a picked alert date.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _alertThresholdController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Remaining Budget Alert Threshold (₹)',
                        prefixText: '₹ ',
                        border: OutlineInputBorder(),
                        helperText: 'Shows a warning when remaining budget drops below this amount (e.g. ₹500)',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Alert Date (Optional):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              Text(
                                _alertDate != null
                                    ? '${_alertDate!.day}/${_alertDate!.month}/${_alertDate!.year}'
                                    : 'No alert date set',
                                style: TextStyle(color: _alertDate != null ? const Color(0xFF6751F5) : Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.event_rounded, size: 18),
                          label: Text(_alertDate == null ? 'Pick Alert Date' : 'Change Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _alertDate ?? DateTime.now().add(const Duration(days: 7)),
                              firstDate: DateTime.now().subtract(const Duration(days: 30)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (picked != null) {
                              setState(() => _alertDate = picked);
                            }
                          },
                        ),
                        if (_alertDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                            onPressed: () => setState(() => _alertDate = null),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Hackathon Configuration (Gemini API)
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.smart_toy, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text('PayPal AI Hackathon Settings',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Optional: Supply a Google Gemini API Key for live multimodal extraction. If blank, the app uses intelligent offline agent parsing.',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _apiKeyController,
                      decoration: const InputDecoration(
                        labelText: 'Gemini API Key (Optional)',
                        hintText: 'AIzaSy...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.check_circle_rounded),
              label: const Text('Save Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              onPressed: _saveBudget,
            ),
          ],
        ),
      ),
    );
  }
}
