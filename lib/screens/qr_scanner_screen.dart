import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_record.dart';
import '../services/ledger_state.dart';
import '../services/payment_service.dart';
import 'post_payment_dialog.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  final _qrInputController = TextEditingController();
  final _amountController = TextEditingController();
  final _payeeController = TextEditingController();
  PaymentSource _selectedSource = PaymentSource.upi;
  String _selectedCurrency = 'INR';
  String _selectedCategory = 'Food & Dining';
  String? _selectedLocation;
  bool _isPayeeIdentified = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Dining', 'icon': Icons.restaurant_rounded},
    {'name': 'Utilities', 'icon': Icons.bolt_rounded},
    {'name': 'Recharge', 'icon': Icons.phone_android_rounded},
    {'name': 'Groceries', 'icon': Icons.shopping_basket_rounded},
    {'name': 'Transport', 'icon': Icons.directions_bus_rounded},
    {'name': 'Entertainment', 'icon': Icons.movie_filter_rounded},
    {'name': 'Others', 'icon': Icons.receipt_rounded},
  ];

  final List<Map<String, String>> _currencies = [
    {'code': 'INR', 'symbol': '₹', 'label': 'INR (₹)'},
    {'code': 'USD', 'symbol': '\$', 'label': 'USD (\$)'},
    {'code': 'EUR', 'symbol': '€', 'label': 'EUR (€)'},
    {'code': 'GBP', 'symbol': '£', 'label': 'GBP (£)'},
  ];

  @override
  void dispose() {
    _qrInputController.dispose();
    _amountController.dispose();
    _payeeController.dispose();
    super.dispose();
  }

  void _onQrScannedOrEntered(String raw) {
    if (raw.trim().isEmpty) return;

    final parsed = PaymentService.parseQr(raw);
    setState(() {
      _payeeController.text = parsed.payeeName;
      _selectedSource = parsed.source;
      if (parsed.amount != null && parsed.amount! > 0) {
        _amountController.text = parsed.amount!.toStringAsFixed(0);
      }
      _isPayeeIdentified = true;
    });
  }

  void _loadPreset(String qrString) {
    _qrInputController.text = qrString;
    _onQrScannedOrEntered(qrString);
  }

  Future<void> _proceedPayment() async {
    final payee = _payeeController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    if (payee.isEmpty || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid payee and amount')),
      );
      return;
    }

    final raw = _qrInputController.text.trim();
    String launchTarget = raw;

    if (_selectedSource == PaymentSource.paypal) {
      final cleanPayee = payee.replaceAll(' ', '');
      final formattedAmt = amount.truncateToDouble() == amount ? amount.toStringAsFixed(0) : amount.toStringAsFixed(2);
      // Explicitly append currency code (e.g. 420INR, 25USD, 20EUR) so PayPal defaults to the selected currency instead of EUR
      launchTarget = 'https://paypal.me/$cleanPayee/$formattedAmt$_selectedCurrency';
    } else if (_selectedSource == PaymentSource.upi && raw.startsWith('upi://pay')) {
      final uri = Uri.tryParse(raw);
      if (uri != null) {
        final queryParams = Map<String, String>.from(uri.queryParameters);
        queryParams['am'] = amount.toStringAsFixed(2);
        launchTarget = uri.replace(queryParameters: queryParams).toString();
      }
    }

    // 1. Launch external app if link exists
    if (launchTarget.isNotEmpty) {
      await PaymentService.launchPaymentApp(launchTarget);
    }

    // 2. Add transaction to Ledger
    if (!mounted) return;
    final state = context.read<LedgerState>();
    
    
    // Extract location from homepage search selection:
    final extractedHomeLoc = state.currentLocation;
    final effectiveLoc = _selectedLocation ??
        (extractedHomeLoc != 'All Locations' ? extractedHomeLoc : 'Hosur, Tamil Nadu');

    await state.addTransaction(
      payeeName: payee,
      payeeVpaOrEmail: raw,
      amount: amount,
      source: _selectedSource,
      category: _selectedCategory,
      currency: _selectedCurrency,
      location: effectiveLoc,
    );
    final newTxn = state.transactions.first;

    // Check for budget alert notification
    if (state.hasBudgetAlert && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFFDC2626),
          content: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Expanded(child: Text('⚠️ Budget Alert: ${state.budgetAlertMessage}')),
            ],
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }

    // 3. Return to home and show Post-Payment Itemization Dialog!
    Navigator.of(context).pop();
    PostPaymentDialog.show(context, newTxn);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan & Pay (UPI / PayPal)'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Viewfinder Camera Mockup
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyanAccent, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, color: Colors.cyanAccent, size: 50),
                      SizedBox(height: 8),
                      Text(
                        'Align QR within frame',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Demo QR shortcuts for Hackathon
            const Text('Demo QR Presets (Instant Test):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('PayPal (paypal.me/randomname/420)'),
                  onPressed: () => _loadPreset('paypal.me/randomname/420'),
                ),
                ActionChip(
                  label: const Text('Chai Tapri (UPI)'),
                  onPressed: () => _loadPreset('upi://pay?pa=tea.stall@okaxis&pn=Chai+Point&am=35'),
                ),
                ActionChip(
                  label: const Text('Supermarket (UPI)'),
                  onPressed: () => _loadPreset('upi://pay?pa=freshmart@icici&pn=FreshMart+Groceries&am=450'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Manual QR String or Paste
            TextField(
              controller: _qrInputController,
              decoration: InputDecoration(
                labelText: 'Paste QR Data / Payment Link',
                hintText: 'upi://pay?pa=... or paypal.me/...',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => _onQrScannedOrEntered(_qrInputController.text),
                ),
              ),
              onSubmitted: _onQrScannedOrEntered,
            ),
            const SizedBox(height: 18),

            if (_isPayeeIdentified) ...[
              Builder(builder: (context) {
              final theme = Theme.of(context);
              final isDarkMode = theme.brightness == Brightness.dark;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDarkMode
                      ? theme.colorScheme.surface
                      : Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDarkMode
                        ? theme.colorScheme.primary.withOpacity(0.35)
                        : Colors.teal.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _payeeController,
                      decoration: const InputDecoration(
                        labelText: 'Payee Name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 5,
                          child: TextField(
                            controller: _amountController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              labelText: 'Amount to Pay',
                              prefixText: '${_currencies.firstWhere((c) => c['code'] == _selectedCurrency, orElse: () => {'symbol': '₹'})['symbol']} ',
                              border: const OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 4,
                          child: DropdownButtonFormField<String>(
                            value: _selectedCurrency,
                            decoration: const InputDecoration(
                              labelText: 'Currency',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _currencies.map((c) {
                              return DropdownMenuItem<String>(
                                value: c['code'],
                                child: Text(c['label']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                              );
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => _selectedCurrency = val);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Expense Category Selector (Required by User: Utilities, Recharge, Others, etc.)
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Expense Category',
                        prefixIcon: Icon(Icons.category_rounded, size: 20),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['name'] as String,
                          child: Row(
                            children: [
                              Icon(cat['icon'] as IconData, size: 18, color: Theme.of(context).colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(cat['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                    const SizedBox(height: 12),
                    // Location Selector (Hospital, Area, City)
                    Builder(
                      builder: (ctx) {
                        final ledgerState = ctx.watch<LedgerState>();
                        final locations = ledgerState.availableLocations
                            .where((loc) => loc != 'All Locations')
                            .toList();
                        final activeLoc = _selectedLocation ??
                            (ledgerState.currentLocation != 'All Locations'
                                ? ledgerState.currentLocation
                                : 'Hosur, Tamil Nadu');

                        return DropdownButtonFormField<String>(
                          value: locations.contains(activeLoc) ? activeLoc : locations.first,
                          decoration: const InputDecoration(
                            labelText: 'Expense Location / Area',
                            prefixIcon: Icon(Icons.location_on_rounded, size: 20, color: Colors.redAccent),
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: locations.map((loc) {
                            return DropdownMenuItem<String>(
                              value: loc,
                              child: Text(loc, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _selectedLocation = val);
                          },
                        );
                      },
                    ),
                    if (_selectedSource == PaymentSource.paypal) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.info_outline_rounded, size: 14, color: Color(0xFF0079C1)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'PayPal link will explicitly charge in $_selectedCurrency (prevents default EUR).',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF0079C1), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.payment),
                label: Text(
                  _selectedSource == PaymentSource.paypal ? 'Pay via PayPal' : 'Pay via UPI App',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: _proceedPayment,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
