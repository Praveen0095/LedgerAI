import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_record.dart';
import '../services/ledger_state.dart';

class ExpenseEntryScreen extends StatefulWidget {
  const ExpenseEntryScreen({super.key});

  @override
  State<ExpenseEntryScreen> createState() => _ExpenseEntryScreenState();
}

class _ExpenseEntryScreenState extends State<ExpenseEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _amountController = TextEditingController();
  final _remarkController = TextEditingController();

  String _expenseType = 'Lending to Friend';
  PaymentSource _selectedSource = PaymentSource.upi;
  String _selectedCurrency = 'INR';
  DateTime _selectedDate = DateTime.now();
  bool _isRecoverableLoan = true;
  DateTime _repaymentDueDate = DateTime.now().add(const Duration(days: 7));
  int _reminderDaysBefore = 0; // 0 = on due date, 1 = 1 day before
  String? _selectedLocation;

  final List<Map<String, dynamic>> _expenseTypes = [
    {
      'label': 'Lending to Friend',
      'icon': Icons.handshake_rounded,
      'color': Color(0xFFF59E0B),
      'hint': 'Friend\'s Name (e.g. Rahul, Priya)',
      'remarkHint': 'e.g. Lent for lunch; promised to return by Friday',
    },
    {
      'label': 'Mobile / WiFi Recharge',
      'icon': Icons.phone_android_rounded,
      'color': Color(0xFF10B981),
      'hint': 'Provider / Number (e.g. Jio 5G, Airtel WiFi)',
      'remarkHint': 'e.g. Monthly 84-day unlimited recharge plan',
    },
    {
      'label': 'Utility & Bills',
      'icon': Icons.bolt_rounded,
      'color': Color(0xFF0284C7),
      'hint': 'Biller Name (e.g. BESCOM Electricity, Gas cylinder)',
      'remarkHint': 'e.g. Electricity bill for October',
    },
    {
      'label': 'Emergency & Medical',
      'icon': Icons.medical_services_rounded,
      'color': Color(0xFFEF4444),
      'hint': 'Clinic / Pharmacy / Emergency',
      'remarkHint': 'e.g. Prescription medicines and health test',
    },
    {
      'label': 'Other Expense',
      'icon': Icons.receipt_rounded,
      'color': Color(0xFF6366F1),
      'hint': 'Beneficiary / Expense Name',
      'remarkHint': 'e.g. Miscellaneous personal outflow',
    },
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'label': 'INR (₹)'},
    {'code': 'USD', 'symbol': '\$', 'label': 'USD (\$)'},
    {'code': 'EUR', 'symbol': '€', 'label': 'EUR (€)'},
    {'code': 'GBP', 'symbol': '£', 'label': 'GBP (£)'},
  ];

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _remarkController.dispose();
    super.dispose();
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

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final recipient = _recipientController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final remark = _remarkController.text.trim();

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an amount greater than 0')),
      );
      return;
    }

    final categoryLabel = _expenseType == 'Lending to Friend'
        ? (_isRecoverableLoan ? 'Loan to Friend (Recoverable)' : 'Friend Gift / Help')
        : _expenseType;

    final state = context.read<LedgerState>();
    final effectiveLoc = _selectedLocation ??
        (state.currentLocation != 'All Locations' ? state.currentLocation : 'Hosur, Tamil Nadu');

    await state.addTransaction(
      payeeName: recipient.isEmpty ? _expenseType : recipient,
      amount: amount,
      source: _selectedSource,
      category: categoryLabel,
      currency: _selectedCurrency,
      remark: remark,
      timestamp: _selectedDate,
      location: effectiveLoc,
      isRecoverable: _isRecoverableLoan && _expenseType == 'Lending to Friend',
      repaymentDueDate: (_isRecoverableLoan && _expenseType == 'Lending to Friend') ? _repaymentDueDate : null,
      reminderDaysBefore: _reminderDaysBefore,
      isRepaid: false,
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💸 Recorded expense of ₹${amount.toStringAsFixed(0)} ($categoryLabel)!'),
        backgroundColor: const Color(0xFFF59E0B),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const warmAmber = Color(0xFFF59E0B);

    final activeMeta = _expenseTypes.firstWhere(
      (e) => e['label'] == _expenseType,
      orElse: () => _expenseTypes.first,
    );

    final currMeta = _currencies.firstWhere(
      (c) => c['code'] == _selectedCurrency,
      orElse: () => {'symbol': '₹'},
    );
    final currSymbol = currMeta['symbol'] ?? '₹';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Personal Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: warmAmber.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: warmAmber.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: warmAmber.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.outbox_rounded, color: warmAmber, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Personal Outflows & Transfers',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Use this for friend loans, phone recharges, and bill dues. Add a description to remember details.',
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

              // Purpose / Category selector pills
              const Text('Expense Type:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _expenseTypes.map((type) {
                  final isSelected = _expenseType == type['label'];
                  final Color typeColor = type['color'] as Color;
                  return ChoiceChip(
                    avatar: Icon(
                      type['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : typeColor,
                    ),
                    label: Text(type['label'] as String),
                    selected: isSelected,
                    selectedColor: typeColor,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (sel) {
                      if (sel) setState(() => _expenseType = type['label'] as String);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Beneficiary / Recipient Name
              TextFormField(
                controller: _recipientController,
                decoration: InputDecoration(
                  labelText: 'Recipient / Purpose *',
                  hintText: activeMeta['hint'] as String,
                  prefixIcon: Icon(activeMeta['icon'] as IconData, color: activeMeta['color'] as Color),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter who or what this expense was for';
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
                        labelText: 'Amount *',
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

              // Payment Method & Date Row
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<PaymentSource>(
                      value: _selectedSource,
                      decoration: InputDecoration(
                        labelText: 'Payment Mode',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(value: PaymentSource.upi, child: Text('UPI / GPay / PhonePe')),
                        DropdownMenuItem(value: PaymentSource.cash, child: Text('Cash')),
                        DropdownMenuItem(value: PaymentSource.paypal, child: Text('PayPal')),
                        DropdownMenuItem(value: PaymentSource.other, child: Text('Bank Transfer / NetBanking')),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedSource = val);
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

              // If Lending to Friend, show recoverable loan controls & reminder options
              if (_expenseType == 'Lending to Friend') ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1D1075) : Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: warmAmber.withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        activeColor: warmAmber,
                        title: const Text(
                          'Mark as Recoverable Loan (Expect return)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text(
                          'Tracks this as money owed to you rather than spent on personal lifestyle.',
                          style: TextStyle(fontSize: 11),
                        ),
                        value: _isRecoverableLoan,
                        onChanged: (val) => setState(() => _isRecoverableLoan = val ?? true),
                      ),
                      if (_isRecoverableLoan) ...[
                        const Divider(),
                        const SizedBox(height: 6),
                        // Expected Repayment Date
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Expected Repayment Date *',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('EEE, MMM d, yyyy').format(_repaymentDueDate),
                                    style: const TextStyle(
                                      color: warmAmber,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: warmAmber),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              icon: const Icon(Icons.event_available_rounded, size: 16, color: warmAmber),
                              label: const Text('Pick Due Date', style: TextStyle(color: warmAmber, fontSize: 12)),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _repaymentDueDate,
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _repaymentDueDate = picked);
                                }
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Reminder timing selection (Requirement 7)
                        const Text(
                          'Reminder Notification:',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            ChoiceChip(
                              label: const Text('On due date'),
                              selected: _reminderDaysBefore == 0,
                              selectedColor: warmAmber,
                              labelStyle: TextStyle(
                                color: _reminderDaysBefore == 0 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontSize: 12,
                                fontWeight: _reminderDaysBefore == 0 ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _reminderDaysBefore = 0);
                              },
                            ),
                            const SizedBox(width: 8),
                            ChoiceChip(
                              label: const Text('1 day before'),
                              selected: _reminderDaysBefore == 1,
                              selectedColor: warmAmber,
                              labelStyle: TextStyle(
                                color: _reminderDaysBefore == 1 ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                                fontSize: 12,
                                fontWeight: _reminderDaysBefore == 1 ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (val) {
                                if (val) setState(() => _reminderDaysBefore = 1);
                              },
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Mandatory / Highlighted Remark & Description Box
              TextFormField(
                controller: _remarkController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Remark / Description *',
                  hintText: activeMeta['remarkHint'] as String,
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.description_rounded),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a brief remark or reason for this outflow';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Submit Button
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: warmAmber,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Record Expense in Ledger', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _submitExpense,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
