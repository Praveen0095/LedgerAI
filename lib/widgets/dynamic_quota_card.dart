import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/budget_config.dart';
import '../services/ledger_state.dart';

class DynamicQuotaCard extends StatelessWidget {
  const DynamicQuotaCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const emeraldGreen = Color(0xFF10B981);
    const warmAmber = Color(0xFFF59E0B);
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final todayBase = state.todayBaseQuota;
    final spentToday = state.spentToday;
    final remainingToday = state.todayRemainingQuota;
    final projectedTomorrow = state.projectedTomorrowQuota;

    final isOverspent = remainingToday < 0;
    final progress = todayBase > 0 ? (spentToday / todayBase).clamp(0.0, 1.0) : 0.0;

  
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isOverspent
            ? const Color(0xFFDC2626)
            : (theme.brightness == Brightness.dark
                ? const Color(0xFF1D1075)
                : theme.colorScheme.primary),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (isOverspent ? warmAmber : Colors.black).withOpacity(0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Day ${state.currentDayOfMonth} of ${state.daysInCurrentMonth}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${state.remainingDaysInMonth} days left',
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isOverspent ? Colors.white : emeraldGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isOverspent ? 'Auto-Adjusting' : 'On Track',
                  style: TextStyle(
                    color: isOverspent ? const Color(0xFFB45309) : Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            "TODAY'S DAILY QUOTA",
            style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 1.4, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                currencyFormat.format(isOverspent ? 0 : remainingToday),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '/ ${currencyFormat.format(todayBase)} limit',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white.withOpacity(0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                isOverspent ? Colors.white : emeraldGreen,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Spent Today', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(spentToday),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Discretionary Pool', style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(state.budgetConfig.discretionaryFund),
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              Container(width: 1, height: 26, color: Colors.white24),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Tomorrow's Quota", style: TextStyle(color: Colors.white70, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(
                    currencyFormat.format(projectedTomorrow),
                    style: TextStyle(
                      color: isOverspent ? Colors.white : emeraldGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (state.budgetConfig.surplusMode == SurplusAllocationMode.savingsMode) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.savings_rounded, color: Colors.amberAccent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.budgetConfig.savingsGoalNote != null &&
                              state.budgetConfig.savingsGoalNote!.isNotEmpty
                          ? 'Goal: ${state.budgetConfig.savingsGoalNote}'
                          : 'Savings Mode Active (Monthly Cap: ${currencyFormat.format(state.effectiveMonthlyBudget)})',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
