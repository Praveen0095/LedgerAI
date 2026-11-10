import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_item.dart';
import '../models/transaction_record.dart';
import '../services/ai_receipt_service.dart';
import '../services/ledger_state.dart';
import 'ai_bill_scan_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _payeeController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  PaymentSource _selectedSource = PaymentSource.cash;
  String _selectedCategory = 'Food & Dining';
  String _selectedCurrency = 'INR';
  DateTime _selectedDate = DateTime.now();

  final List<TransactionItem> _lineItems = [];
  bool _isAiParsing = false;

  final List<String> _categories = [
    'Food & Dining',
    'Groceries',
    'Shopping',
    'Travel & Transit',
    'Entertainment',
    'Health & Medical',
    'General',
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'label': 'INR (₹)'},
    {'code': 'USD', 'symbol': '\$', 'label': 'USD (\$)'},
    {'code': 'EUR', 'symbol': '€', 'label': 'EUR (€)'},
    {'code': 'GBP', 'symbol': '£', 'label': 'GBP (£)'},
  ];

  @override
  void dispose() {
    _payeeController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
  }

  void _recalculateAmountFromItems() {
    if (_lineItems.isNotEmpty) {
      final total = _lineItems.fold(0.0, (sum, i) => sum + i.total);
      if (total > 0) {
        _amountController.text = total.truncateToDouble() == total
            ? total.toStringAsFixed(0)
            : total.toStringAsFixed(2);
      }
    }
  }

  Future<void> _openBillScanner() async {
    final payeeName = _payeeController.text.trim().isEmpty ? 'Merchant' : _payeeController.text.trim();
    final currentAmount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    final result = await Navigator.push<List<TransactionItem>>(
      context,
      MaterialPageRoute(
        builder: (_) => AiBillScanScreen(
          payeeName: payeeName,
          totalAmount: currentAmount,
        ),
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        _lineItems.clear();
        _lineItems.addAll(result);
        _recalculateAmountFromItems();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ AI extracted ${result.length} items from bill! Amount updated.'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _quickVoiceOrTextBillPrompt() async {
    final textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 8),
            Text('Quick Bill Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dictate or type what you bought, e.g.:\n"1 tea 15 and 1 samosa 20"',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. 1 tea 15, 1 samosa 20',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final text = textController.text.trim();
              if (text.isNotEmpty) {
                Navigator.pop(ctx);
                setState(() => _isAiParsing = true);
                final apiKey = context.read<LedgerState>().geminiApiKey;
                final items = await AiReceiptService.parseTextPrompt(prompt: text, geminiApiKey: apiKey);
                setState(() {
                  _isAiParsing = false;
                  _lineItems.addAll(items);
                  _recalculateAmountFromItems();
                });
              }
            },
            child: const Text('Extract'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _submitManualTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final payee = _payeeController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remark = _remarkController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount greater than 0')),
      );
      return;
    }

    final state = context.read<LedgerState>();
    await state.addTransaction(
      payeeName: payee.isEmpty ? 'Offline Merchant' : payee,
      amount: amount,
      source: _selectedSource,
      category: _selectedCategory,
      currency: _selectedCurrency,
      remark: remark.isEmpty ? null : remark,
      items: _lineItems,
      timestamp: _selectedDate,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Transaction of ₹${amount.toStringAsFixed(0)} logged to Ledger!'),
        backgroundColor: const Color(0xFF10B981),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const emeraldGreen = Color(0xFF10B981);
    const warmAmber = Color(0xFFF59E0B);

    final currMeta = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => {'symbol': '₹'},
    );
    final currSymbol = currMeta['symbol'] ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Transaction Entry'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1075) : const Color(0xFFF3F0FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: emeraldGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: emeraldGreen.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.edit_calendar_rounded, color: emeraldGreen, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offline / Un-scanned Payment',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Record cash, card, or manual payments. You can scan or dictate your bill below.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Payee / Merchant Name
              TextFormField(
                controller: _payeeController,
                decoration: InputDecoration(
                  labelText: 'Merchant / Payee Name *',
                  hintText: 'e.g. Ramesh Tea Stall, FreshMart, Cafe Mocha',
                  prefixIcon: const Icon(Icons.store_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter who you paid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount & Currency Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: TextFormField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: 'Total Amount *',
                        prefixText: '$currSymbol ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) return 'Enter amount';
                        final n = double.tryParse(val.trim());
                        if (n == null || n <= 0) return 'Enter a positive amount';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 4,
                    child: DropdownButtonFormField<String>(
                      value: _selectedCurrency,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: _currencies.map((c) {
                        return DropdownMenuItem<String>(
                          value: c['code'],
                          child: Text(c['label']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCurrency = val);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Payment Method Selector
              const Text('Payment Method:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.money_rounded, size: 16),
                    label: const Text('Cash'),
                    selected: _selectedSource == PaymentSource.cash,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedSource = PaymentSource.cash);
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.account_balance_wallet_rounded, size: 16),
                    label: const Text('UPI'),
                    selected: _selectedSource == PaymentSource.upi,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedSource = PaymentSource.upi);
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.payment_rounded, size: 16),
                    label: const Text('PayPal'),
                    selected: _selectedSource == PaymentSource.paypal,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedSource = PaymentSource.paypal);
                    },
                  ),
                  ChoiceChip(
                    avatar: const Icon(Icons.credit_card_rounded, size: 16),
                    label: const Text('Card / Other'),
                    selected: _selectedSource == PaymentSource.other,
                    onSelected: (sel) {
                      if (sel) setState(() => _selectedSource = PaymentSource.other);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Category & Date Pickers Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.calendar_today_rounded, size: 16),
                      label: Text(
                        DateFormat('MMM d').format(_selectedDate),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      onPressed: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description / Remark
              TextFormField(
                controller: _remarkController,
                decoration: InputDecoration(
                  labelText: 'Remarks / Notes (Optional)',
                  hintText: 'e.g. Chai break with team, paid offline',
                  prefixIcon: const Icon(Icons.notes_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 20),

              // ----------------- INTEGRATED BILL SCANNER SECTION -----------------
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1075) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: warmAmber.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: warmAmber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'AI Bill & Receipt Itemizer',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        if (_isAiParsing)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: warmAmber),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Scan a paper bill or dictate items to auto-calculate the total and add to your Personal Menu.',
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).colorScheme.primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.document_scanner_rounded, size: 18),
                            label: const Text('Scan Camera Bill', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: _openBillScanner,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: const BorderSide(color: warmAmber),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.mic_rounded, color: warmAmber, size: 18),
                            label: const Text('Dictate Items', style: TextStyle(color: warmAmber, fontSize: 13, fontWeight: FontWeight.bold)),
                            onPressed: _quickVoiceOrTextBillPrompt,
                          ),
                        ),
                      ],
                    ),

                    // Display Extracted Items List if any
                    if (_lineItems.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Itemized Bill (${_lineItems.length} items):',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          TextButton(
                            onPressed: () => setState(() {
                              _lineItems.clear();
                              _amountController.clear();
                            }),
                            child: const Text('Clear', style: TextStyle(color: Colors.redAccent, fontSize: 12)),
                          ),
                        ],
                      ),
                      ..._lineItems.asMap().entries.map((entry) {
                        final idx = entry.key;
                        final item = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: emeraldGreen.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.fastfood_rounded, size: 16, color: emeraldGreen),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '${item.quantity}x ${item.name}',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ),
                              Text(
                                '$currSymbol${item.total.toStringAsFixed(0)}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                                onPressed: () {
                                  setState(() {
                                    _lineItems.removeAt(idx);
                                    _recalculateAmountFromItems();
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Save Transaction to Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _submitManualTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
