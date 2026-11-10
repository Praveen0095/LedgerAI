import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/ledger_state.dart';
import '../theme/app_theme.dart';

enum ComparisonPeriod { past7Days, pastWeek, pastMonth }

class SpendComparisonCard extends StatefulWidget {
  const SpendComparisonCard({super.key});

  @override
  State<SpendComparisonCard> createState() => _SpendComparisonCardState();
}

class _SpendComparisonCardState extends State<SpendComparisonCard> {
  ComparisonPeriod _selectedPeriod = ComparisonPeriod.past7Days;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    const emeraldGreen = Color(0xFF10B981);
    const warmAmber = Color(0xFFF59E0B);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    final now = DateTime.now();

    double currentSpend = 0.0;
    double previousSpend = 0.0;
    String currentLabel = 'CURRENT';
    String previousLabel = 'PREVIOUS';

    switch (_selectedPeriod) {
      case ComparisonPeriod.past7Days:
        currentLabel = 'PAST 7 DAYS';
        previousLabel = 'PREV 7 DAYS';
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        final fourteenDaysAgo = now.subtract(const Duration(days: 14));

        for (final t in state.transactions) {
          if (t.timestamp.isAfter(sevenDaysAgo) && !t.timestamp.isAfter(now)) {
            currentSpend += t.amount;
          } else if (t.timestamp.isAfter(fourteenDaysAgo) && !t.timestamp.isAfter(sevenDaysAgo)) {
            previousSpend += t.amount;
          }
        }
        break;

      case ComparisonPeriod.pastWeek:
        currentLabel = 'THIS WEEK';
        previousLabel = 'LAST WEEK';
        // Monday of current week
        final daysFromMonday = now.weekday - 1;
        final thisWeekMonday = DateTime(now.year, now.month, now.day).subtract(Duration(days: daysFromMonday));
        final lastWeekMonday = thisWeekMonday.subtract(const Duration(days: 7));

        for (final t in state.transactions) {
          if (!t.timestamp.isBefore(thisWeekMonday) && !t.timestamp.isAfter(now)) {
            currentSpend += t.amount;
          } else if (!t.timestamp.isBefore(lastWeekMonday) && t.timestamp.isBefore(thisWeekMonday)) {
            previousSpend += t.amount;
          }
        }
        break;

      case ComparisonPeriod.pastMonth:
        currentLabel = 'THIS MONTH';
        previousLabel = 'LAST MONTH';
        final firstDayThisMonth = DateTime(now.year, now.month, 1);
        final firstDayLastMonth = DateTime(now.year, now.month - 1, 1);

        for (final t in state.transactions) {
          if (!t.timestamp.isBefore(firstDayThisMonth)) {
            currentSpend += t.amount;
          } else if (!t.timestamp.isBefore(firstDayLastMonth) && t.timestamp.isBefore(firstDayThisMonth)) {
            previousSpend += t.amount;
          }
        }
        break;
    }

    final double diff = (currentSpend - previousSpend).abs();
    final bool spentLess = currentSpend < previousSpend;
    final bool spentMore = currentSpend > previousSpend;

    String percentageText = '';
    if (previousSpend > 0) {
      final pct = ((diff / previousSpend) * 100).clamp(0, 999).round();
      percentageText = '$pct%';
    }

    final periodName = _selectedPeriod == ComparisonPeriod.past7Days
        ? 'previous 7 days'
        : (_selectedPeriod == ComparisonPeriod.pastWeek ? 'last week' : 'last month');

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Row: Title on Left, 3 Tabs on Top Right Corner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: emeraldGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.compare_arrows_rounded, color: emeraldGreen, size: 20),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Spend Comparison',
                      style: TextStyle(
                        fontFamily: AppTheme.fontTitle,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
                // 3 Tabs in Top Right Corner (Requirement 6)
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTabChip('7 Days', ComparisonPeriod.past7Days, isDark),
                      _buildTabChip('Week', ComparisonPeriod.pastWeek, isDark),
                      _buildTabChip('Month', ComparisonPeriod.pastMonth, isDark),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Two Period Stat Blocks
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D0B18) : const Color(0xFFF3F0FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTitle,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(currentSpend),
                          style: TextStyle(
                            fontFamily: AppTheme.fontTitle,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0D0B18) : const Color(0xFFF3F0FA),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          previousLabel,
                          style: TextStyle(
                            fontFamily: AppTheme.fontTitle,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          currencyFormat.format(previousSpend),
                          style: TextStyle(
                            fontFamily: AppTheme.fontTitle,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Comparison Trend Insight Pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: spentLess
                    ? emeraldGreen.withOpacity(0.12)
                    : (spentMore ? warmAmber.withOpacity(0.12) : Colors.grey.withOpacity(0.1)),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: spentLess
                      ? emeraldGreen.withOpacity(0.3)
                      : (spentMore ? warmAmber.withOpacity(0.3) : Colors.grey.withOpacity(0.2)),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    spentLess
                        ? Icons.trending_down_rounded
                        : (spentMore ? Icons.trending_up_rounded : Icons.horizontal_rule_rounded),
                    color: spentLess ? emeraldGreen : (spentMore ? warmAmber : Colors.grey),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      spentLess
                          ? 'Spent ${currencyFormat.format(diff)} less than $periodName${percentageText.isNotEmpty ? " ($percentageText down)" : ""} 🎉'
                          : (spentMore
                              ? 'Spent ${currencyFormat.format(diff)} more than $periodName${percentageText.isNotEmpty ? " (+$percentageText)" : ""}'
                              : 'Exact same spend as $periodName'),
                      style: TextStyle(
                        fontFamily: AppTheme.fontBody,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: spentLess
                            ? (isDark ? const Color(0xFF34D399) : const Color(0xFF065F46))
                            : (spentMore
                                ? (isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E))
                                : (isDark ? Colors.white70 : Colors.black87)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabChip(String label, ComparisonPeriod period, bool isDark) {
    final isSelected = _selectedPeriod == period;
    return GestureDetector(
      onTap: () => setState(() => _selectedPeriod = period),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.white70 : Colors.black87),
          ),
        ),
      ),
    );
  }
}
