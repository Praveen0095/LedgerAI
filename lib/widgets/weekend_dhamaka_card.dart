import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/budget_config.dart';
import '../screens/weekend_dhamaka_screen.dart';
import '../services/ledger_state.dart';

class WeekendDhamakaCard extends StatelessWidget {
  const WeekendDhamakaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    if (state.budgetConfig.surplusMode != SurplusAllocationMode.weekendDhamaka) {
      return const SizedBox.shrink();
    }

    final pool = state.budgetConfig.weekendDhamakaPool;
    final isWeekend = state.isWeekend;

    const warmAmber = Color(0xFFF59E0B);
    const darkAmber = Color(0xFFD97706);

    return Container(
      margin: const EdgeInsets.only(top: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isWeekend
              ? [darkAmber, warmAmber]
              : [const Color(0xFF1D1075), const Color(0xFF3F2CBA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isWeekend ? warmAmber : Colors.black).withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const WeekendDhamakaScreen()),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isWeekend ? Icons.celebration_rounded : Icons.savings_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            isWeekend ? '🎉 WEEKEND DHAMAKA LIVE!' : '✨ WEEKEND DHAMAKA STASH',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isWeekend
                            ? '${currencyFormat.format(pool)} ready to claim & spend!'
                            : '${currencyFormat.format(pool)} saved • Tap for Countdown',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.95),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
