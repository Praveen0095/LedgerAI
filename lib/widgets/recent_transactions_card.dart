import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_record.dart';
import '../screens/all_transactions_screen.dart';
import '../screens/post_payment_dialog.dart';
import '../services/ledger_state.dart';

class RecentTransactionsCard extends StatelessWidget {
  const RecentTransactionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final lastFive = state.lastFiveTransactions;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with navigation arrow
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 20, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    const Text(
                      'Recent Transactions',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '(${lastFive.length})',
                      style: const TextStyle(fontSize: 13, color: Colors.grey, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
                IconButton(
                  tooltip: 'View All Transactions',
                  icon: const Icon(Icons.arrow_forward_rounded, size: 22),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllTransactionsScreen()),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 16),

            if (lastFive.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No transactions logged yet.\nTap "Scan QR & Pay" to make your first payment!',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: lastFive.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final txn = lastFive[index];
                  final dateFormat = DateFormat('MMM d • h:mm a');

                  return ListTile(
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: txn.source == PaymentSource.paypal
                          ? const Color(0xFF0079C1).withOpacity(0.12)
                          : const Color(0xFF10B981).withOpacity(0.12),
                      child: Icon(
                        txn.source == PaymentSource.paypal ? Icons.payment_rounded : Icons.account_balance_wallet_rounded,
                        color: txn.source == PaymentSource.paypal ? const Color(0xFF0079C1) : const Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            txn.payeeName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '-${currencyFormat.format(txn.amount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 2),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dateFormat.format(txn.timestamp),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    txn.category,
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (txn.isItemized)
                              Text(
                                '${txn.items.length} items logged',
                                style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.w600),
                              )
                            else
                              InkWell(
                                onTap: () => PostPaymentDialog.show(context, txn),
                                child: const Text(
                                  '+ Itemize',
                                  style: TextStyle(color: Color(0xFFF59E0B), fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => PostPaymentDialog.show(context, txn),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
