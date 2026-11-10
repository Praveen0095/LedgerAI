import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/ledger_state.dart';

class WeekendDhamakaScreen extends StatefulWidget {
  const WeekendDhamakaScreen({super.key});

  @override
  State<WeekendDhamakaScreen> createState() => _WeekendDhamakaScreenState();
}

class _WeekendDhamakaScreenState extends State<WeekendDhamakaScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh countdown every minute
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Calculates the weekend countdown according to rules:
  /// - Wednesday -> "2 days left"
  /// - Thursday -> "1 day left"
  /// - Friday within 12 hours of Saturday 00:00 (e.g. 10 PM) -> "2 hrs left"
  /// - Saturday/Sunday -> "Weekend is Live!"
  String _getCountdownText(DateTime now) {
    if (now.weekday == DateTime.saturday || now.weekday == DateTime.sunday) {
      return "🎉 Weekend Dhamaka is LIVE!";
    }

    // Next Saturday at 00:00:00
    final daysUntilSaturday = DateTime.saturday - now.weekday;
    final nextSaturday = DateTime(now.year, now.month, now.day).add(Duration(days: daysUntilSaturday));
    final difference = nextSaturday.difference(now);

    final totalHoursLeft = difference.inHours;

    // Show hours left ONLY within 12 hours of the weekend
    if (totalHoursLeft < 12) {
      final hours = totalHoursLeft <= 0 ? 1 : totalHoursLeft;
      return "$hours hrs left";
    }

    // Days calculation (e.g. Wednesday -> 2 days left, Thursday -> 1 day left)
    final daysLeft = (daysUntilSaturday - 1).clamp(0, 6);
    if (daysLeft == 0) {
      return "Starts tonight!";
    }
    return "$daysLeft day${daysLeft > 1 ? 's' : ''} left";
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final now = DateTime.now();

    final isWeekend = state.isWeekend;
    final countdownText = _getCountdownText(now);
    final pool = state.budgetConfig.weekendDhamakaPool;

    const warmAmber = Color(0xFFF59E0B);
    const emeraldGrowth = Color(0xFF10B981);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Weekend Dhamaka'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Countdown Hero Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWeekend
                      ? [const Color(0xFFD97706), warmAmber]
                      : (isDark
                          ? [const Color(0xFF1D1075), const Color(0xFF0D0B18)]
                          : [const Color(0xFF0D0B18), const Color(0xFF1D1075)]),
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isWeekend ? warmAmber : Colors.black).withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isWeekend ? Icons.celebration_rounded : Icons.hourglass_top_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    isWeekend ? 'WEEKEND IS HERE!' : 'COUNTDOWN TO WEEKEND',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    countdownText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isWeekend
                        ? 'Your savings are unlocked! Claim funds to boost your daily spend.'
                        : 'Unlocks on Saturday 12:00 AM for guilt-free weekend fun.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pool Balance Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Available Dhamaka Stash',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isWeekend ? emeraldGrowth.withOpacity(0.15) : warmAmber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            isWeekend ? 'Unlocked' : 'Locked',
                            style: TextStyle(
                              color: isWeekend ? emeraldGrowth : warmAmber,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      currencyFormat.format(pool),
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0D0B18),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Accumulated automatically whenever you spend less than your daily quota.',
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black45),
                    ),
                    if (state.todayClaimedDhamaka > 0) ...[
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Claimed to today\'s quota:', style: TextStyle(fontWeight: FontWeight.w500)),
                          Text(
                            '+${currencyFormat.format(state.todayClaimedDhamaka)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, color: emeraldGrowth),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Claim Action Button
            SizedBox(
              height: 54,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isWeekend ? emeraldGrowth : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  disabledForegroundColor: isDark ? Colors.grey.shade600 : Colors.grey.shade500,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                icon: Icon(isWeekend ? Icons.lock_open_rounded : Icons.lock_rounded),
                label: Text(
                  isWeekend ? 'Claim to Today\'s Limit' : 'Locked Until Weekend',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                onPressed: (isWeekend && pool > 0)
                    ? () => _showClaimDialog(context, state, pool)
                    : null,
              ),
            ),
            const SizedBox(height: 12),

            Center(
              child: Text(
                isWeekend
                    ? 'Claimed funds will be added directly to your today\'s daily spending limit.'
                    : 'The Claim button becomes active on Saturday & Sunday.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClaimDialog(BuildContext context, LedgerState state, double currentPool) {
    final controller = TextEditingController(text: currentPool.toStringAsFixed(0));
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Claim Weekend Dhamaka'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Available in stash: ₹${currentPool.toStringAsFixed(0)}\nThis amount will be added to today\'s daily quota.',
                style: const TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                keyboardType: TextInputType.number,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Amount to Add (₹)',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                validator: (val) {
                  final amt = double.tryParse(val ?? '') ?? 0.0;
                  if (amt <= 0) return 'Enter an amount greater than 0';
                  if (amt > currentPool) return 'Cannot exceed current stash (₹${currentPool.toStringAsFixed(0)})';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                final amt = double.tryParse(controller.text) ?? 0.0;
                state.claimWeekendDhamaka(amt);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('🎉 Added ₹${amt.toStringAsFixed(0)} to today\'s daily spending limit!'),
                    backgroundColor: const Color(0xFF10B981),
                  ),
                );
              }
            },
            child: const Text('Claim to Today\'s Limit'),
          ),
        ],
      ),
    );
  }
}
