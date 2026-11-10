import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_record.dart';
import '../services/ledger_state.dart';
import 'post_payment_dialog.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final allTxns = state.transactions;
    final filteredTxns = _searchQuery.isEmpty
        ? allTxns
        : allTxns.where((t) {
            final matchPayee = t.payeeName.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchItem = t.items.any((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()));
            return matchPayee || matchItem;
          }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search by payee or item (e.g. Tea, Samosa)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Total count & Summary bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${filteredTxns.length} Transactions',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                Text(
                  'Total Spent: ${currencyFormat.format(filteredTxns.fold(0.0, (sum, t) => sum + t.amount))}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Transaction list
          Expanded(
            child: filteredTxns.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty ? 'No transactions logged yet.' : 'No matching transactions found.',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    itemCount: filteredTxns.length,
                    itemBuilder: (context, index) {
                      final txn = filteredTxns[index];
                      return _buildTxnCard(context, txn, currencyFormat, state);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTxnCard(
    BuildContext context,
    TransactionRecord txn,
    NumberFormat currency,
    LedgerState state,
  ) {
    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: txn.source == PaymentSource.paypal
              ? const Color(0xFF0079C1).withOpacity(0.12)
              : const Color(0xFF10B981).withOpacity(0.12),
          child: Icon(
            txn.source == PaymentSource.paypal ? Icons.payment_rounded : Icons.account_balance_wallet_rounded,
            color: txn.source == PaymentSource.paypal ? const Color(0xFF0079C1) : const Color(0xFF10B981),
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                txn.payeeName,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '-${currency.format(txn.amount)}',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateFormat.format(txn.timestamp), style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                if (txn.isItemized)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${txn.items.length} items logged',
                      style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  )
                else
                  InkWell(
                    onTap: () => PostPaymentDialog.show(context, txn),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add_rounded, size: 12, color: Color(0xFFF59E0B)),
                          SizedBox(width: 2),
                          Text(
                            'Itemize',
                            style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            if (txn.isItemized && txn.items.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                txn.items.map((i) => '${i.quantity}x ${i.name} (₹${i.price.toStringAsFixed(0)})').join(' • '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF10B981), fontSize: 12),
              ),
            ],
            if (txn.isRecoverable) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: txn.isRepaid
                          ? const Color(0xFF10B981).withOpacity(0.15)
                          : const Color(0xFFF59E0B).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      txn.isRepaid ? '✅ Repaid / Received' : '⏳ Loan Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: txn.isRepaid ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  if (!txn.isRepaid) ...[
                    const Spacer(),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => state.markAsRepaid(txn.id),
                      child: const Text(
                        'Mark Received',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
        onTap: () => PostPaymentDialog.show(context, txn),
        onLongPress: () {
          // Delete option
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Delete Transaction?'),
              content: Text('Remove this ₹${txn.amount.toStringAsFixed(0)} transaction from ${txn.payeeName}?'),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    state.deleteTransaction(txn.id);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Delete'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
