enum SurplusAllocationMode {
  weekendDhamaka, // Save daily unspent quota to splurge on weekends
  rebalanceDaily, // Spread unspent quota equally across all remaining days
  savingsMode,    // Dedicated savings mode with optional cap and goal notes
}

class BudgetConfig {
  final double monthlyIncome;
  final double fixedExpenses;
  final SurplusAllocationMode surplusMode;
  final double weekendDhamakaPool;
  final String? savingsGoalNote;
  final double? savingsSpendingCap;
  final double? budgetAlertThreshold;
  final DateTime? budgetAlertDate;

  BudgetConfig({
    this.monthlyIncome = 50000.0,
    this.fixedExpenses = 20000.0,
    this.surplusMode = SurplusAllocationMode.weekendDhamaka,
    this.weekendDhamakaPool = 0.0,
    this.savingsGoalNote,
    this.savingsSpendingCap,
    this.budgetAlertThreshold = 500.0,
    this.budgetAlertDate,
  });

  /// Monthly discretionary fund or monthly spending cap if savings mode is active
  double get discretionaryFund {
    if (surplusMode == SurplusAllocationMode.savingsMode &&
        savingsSpendingCap != null &&
        savingsSpendingCap! > 0) {
      return savingsSpendingCap!;
    }
    return (monthlyIncome - fixedExpenses).clamp(0, double.infinity);
  }

  BudgetConfig copyWith({
    double? monthlyIncome,
    double? fixedExpenses,
    SurplusAllocationMode? surplusMode,
    double? weekendDhamakaPool,
    String? savingsGoalNote,
    double? savingsSpendingCap,
    double? budgetAlertThreshold,
    DateTime? budgetAlertDate,
    bool clearSavingsNote = false,
    bool clearSavingsCap = false,
    bool clearAlertDate = false,
  }) {
    return BudgetConfig(
      monthlyIncome: monthlyIncome ?? this.monthlyIncome,
      fixedExpenses: fixedExpenses ?? this.fixedExpenses,
      surplusMode: surplusMode ?? this.surplusMode,
      weekendDhamakaPool: weekendDhamakaPool ?? this.weekendDhamakaPool,
      savingsGoalNote: clearSavingsNote ? null : (savingsGoalNote ?? this.savingsGoalNote),
      savingsSpendingCap: clearSavingsCap ? null : (savingsSpendingCap ?? this.savingsSpendingCap),
      budgetAlertThreshold: budgetAlertThreshold ?? this.budgetAlertThreshold,
      budgetAlertDate: clearAlertDate ? null : (budgetAlertDate ?? this.budgetAlertDate),
    );
  }

  Map<String, dynamic> toJson() => {
        'monthlyIncome': monthlyIncome,
        'fixedExpenses': fixedExpenses,
        'surplusMode': surplusMode.name,
        'weekendDhamakaPool': weekendDhamakaPool,
        'savingsGoalNote': savingsGoalNote,
        'savingsSpendingCap': savingsSpendingCap,
        'budgetAlertThreshold': budgetAlertThreshold,
        'budgetAlertDate': budgetAlertDate?.toIso8601String(),
      };

  factory BudgetConfig.fromJson(Map<String, dynamic> json) => BudgetConfig(
        monthlyIncome: (json['monthlyIncome'] as num?)?.toDouble() ?? 50000.0,
        fixedExpenses: (json['fixedExpenses'] as num?)?.toDouble() ?? 20000.0,
        surplusMode: SurplusAllocationMode.values.firstWhere(
          (e) => e.name == json['surplusMode'],
          orElse: () => SurplusAllocationMode.weekendDhamaka,
        ),
        weekendDhamakaPool: (json['weekendDhamakaPool'] as num?)?.toDouble() ?? 0.0,
        savingsGoalNote: json['savingsGoalNote'] as String?,
        savingsSpendingCap: (json['savingsSpendingCap'] as num?)?.toDouble(),
        budgetAlertThreshold: (json['budgetAlertThreshold'] as num?)?.toDouble() ?? 500.0,
        budgetAlertDate: json['budgetAlertDate'] != null ? DateTime.tryParse(json['budgetAlertDate'] as String) : null,
      );
}
