import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_item.dart';
import '../services/ai_receipt_service.dart';
import '../services/ledger_state.dart';

class AiBillScanScreen extends StatefulWidget {
  final String payeeName;
  final double totalAmount;

  const AiBillScanScreen({
    super.key,
    required this.payeeName,
    required this.totalAmount,
  });

  @override
  State<AiBillScanScreen> createState() => _AiBillScanScreenState();
}

class _AiBillScanScreenState extends State<AiBillScanScreen> {
  bool _isLoading = false;
  final _inputController = TextEditingController();
  List<TransactionItem> _extractedItems = [];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  Future<void> _processAiExtraction(String text) async {
    setState(() => _isLoading = true);
    final apiKey = context.read<LedgerState>().geminiApiKey;

    try {
      final items = await AiReceiptService.parseBillReceipt(
        rawReceiptText: text,
        geminiApiKey: apiKey,
      );
      setState(() {
        _extractedItems = items;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('AI Extraction error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadDemoReceipt(String sample) {
    _inputController.text = sample;
    _processAiExtraction(sample);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Bill & Receipt Scanner'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Vendor & Target Amount Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Merchant / Payee', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      Text(widget.payeeName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text('Target Bill', style: TextStyle(color: Colors.black54, fontSize: 12)),
                      Text('₹${widget.totalAmount.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blueAccent)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Demo Quick-Pill Presets for Hackathon
            const Text('Try Hackathon Demo Presets:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.emoji_food_beverage, size: 16),
                  label: const Text('Tea & Samosa ("1 tea 15 and 1 samosa 20")'),
                  onPressed: () => _loadDemoReceipt('1 tea 15 and 1 samosa 20'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.local_cafe, size: 16),
                  label: const Text('Cafe ("1 Cappuccino 120 and 1 Muffin 80")'),
                  onPressed: () => _loadDemoReceipt('1 Cappuccino 120 and 1 Muffin 80'),
                ),
                ActionChip(
                  avatar: const Icon(Icons.receipt_long, size: 16),
                  label: const Text('Tiffin ("1 Dosa 70 and 1 Filter Coffee 20")'),
                  onPressed: () => _loadDemoReceipt('1 Dosa 70 and 1 Filter Coffee 20'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bill Input / Camera simulation
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: _inputController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Type/Paste receipt text or transcribed voice (e.g. "1 Cold Coffee for 90 and 1 Brownie for 60")',
                      border: InputBorder.none,
                    ),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Scan Camera Bill'),
                        onPressed: () => _loadDemoReceipt('1 Masala Tea 15\n1 Samosa 20\n1 Bun Maska 25'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Extract with AI'),
                        onPressed: _isLoading || _inputController.text.trim().isEmpty
                            ? null
                            : () => _processAiExtraction(_inputController.text.trim()),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Extracted Items Preview
            if (_extractedItems.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('AI Extracted Line Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${_extractedItems.length} items found', style: const TextStyle(color: Colors.teal, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 10),
              ..._extractedItems.asMap().entries.map((entry) {
                final idx = entry.key;
                final item = entry.value;

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.teal.shade50,
                          child: Icon(Icons.fastfood, color: Colors.teal.shade800, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                              Text('Unit Price: ₹${item.price.toStringAsFixed(0)} | Qty: ${item.quantity}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                            ],
                          ),
                        ),
                        Text(
                          '₹${item.total.toStringAsFixed(0)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                          onPressed: () {
                            setState(() {
                              _extractedItems.removeAt(idx);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Confirm & Save to Personal Menu',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: () {
                  Navigator.of(context).pop(_extractedItems);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
