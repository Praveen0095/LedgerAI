import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/budget_config.dart';
import '../models/personal_menu_stat.dart';
import '../models/transaction_item.dart';
import '../models/transaction_record.dart';

class LedgerState extends ChangeNotifier {
  static const _uuid = Uuid();
  static const _prefKeyBudget = 'ledger_budget_config';
  static const _prefKeyTxns = 'ledger_transactions';
  static const _prefKeyApiKey = 'ledger_gemini_api_key';
  static const _prefKeyTheme = 'ledger_theme_mode';
  static const _prefKeyClaimed = 'ledger_claimed_dhamaka_today';
  static const _prefKeyLocation = 'ledger_selected_location';

  BudgetConfig _budgetConfig = BudgetConfig();
  List<TransactionRecord> _transactions = [];
  String? _geminiApiKey;
  bool _isInitialized = false;
  bool _isDarkMode = false;
  double _todayClaimedDhamaka = 0.0;
  String _currentLocation = 'All Locations';
  final List<String> _customLocations = [
    'All Locations',
    'Hosur, Tamil Nadu',
    'Koramangala, Karnataka',
    'Indiranagar, Karnataka',
    'HSR Layout, Karnataka',
  ];

  LedgerState() {
    _loadFromPrefs();
  }

  // Getters
  BudgetConfig get budgetConfig => _budgetConfig;
  List<TransactionRecord> get transactions => List.unmodifiable(_transactions);
  List<TransactionRecord> get lastFiveTransactions => _transactions.take(5).toList();
  String? get geminiApiKey => _geminiApiKey;
  bool get isInitialized => _isInitialized;
  bool get isDarkMode => _isDarkMode;
  double get todayClaimedDhamaka => _todayClaimedDhamaka;
  String get currentLocation => _currentLocation;
  List<String> get availableLocations => List.unmodifiable(_customLocations);

  void setCurrentLocation(String loc) {
    _currentLocation = loc;
    _saveToPrefs();
    notifyListeners();
  }

  void addLocation(String loc) {
    if (loc.trim().isNotEmpty && !_customLocations.contains(loc.trim())) {
      _customLocations.add(loc.trim());
      _currentLocation = loc.trim();
      _saveToPrefs();
      notifyListeners();
    }
  }

  // --- Budget Alerts & Monthly Metrics ---

  double get effectiveMonthlyBudget => _budgetConfig.discretionaryFund;

  double get remainingMonthlyBudget => effectiveMonthlyBudget - spentThisMonth;

  bool get hasBudgetAlert {
    final threshold = _budgetConfig.budgetAlertThreshold ?? 500.0;
    final isBelowThreshold = remainingMonthlyBudget <= threshold;
    final isAlertDateHit = _budgetConfig.budgetAlertDate != null &&
        DateTime.now().isAfter(_budgetConfig.budgetAlertDate!);
    return isBelowThreshold || isAlertDateHit;
  }

  String get budgetAlertMessage {
    final remaining = remainingMonthlyBudget < 0 ? 0 : remainingMonthlyBudget;
    return 'Remaining budget is only ₹${remaining.toStringAsFixed(0)} of your ₹${effectiveMonthlyBudget.toStringAsFixed(0)} limit!';
  }

  // --- Recoverable Loans & Reminders ---

  List<TransactionRecord> get pendingRecoverables =>
      _transactions.where((t) => t.isRecoverable && !t.isRepaid).toList();

  List<TransactionRecord> get activeRepaymentReminders {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return _transactions.where((t) {
      if (!t.isRecoverable || t.isRepaid || t.repaymentDueDate == null) return false;
      final due = t.repaymentDueDate!;
      final dueDateOnly = DateTime(due.year, due.month, due.day);
      final reminderTriggerDate = dueDateOnly.subtract(Duration(days: t.reminderDaysBefore));

      // Active if today is on or past the reminder trigger date
      return !today.isBefore(reminderTriggerDate);
    }).toList();
  }

  Future<void> markAsRepaid(String transactionId) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(isRepaid: true);
      await _saveToPrefs();
      notifyListeners();
    }
  }

  void toggleTheme(bool isDark) {
    _isDarkMode = isDark;
    _saveToPrefs();
    notifyListeners();
  }

  void refresh() {
    notifyListeners();
  }

  // --- Dynamic Quota Calculations ---

  /// Total days in current month
  int get daysInCurrentMonth {
    final now = DateTime.now();
    final firstDayNextMonth = DateTime(now.year, now.month + 1, 1);
    final lastDayThisMonth = firstDayNextMonth.subtract(const Duration(days: 1));
    return lastDayThisMonth.day;
  }

  /// Current day number in the month (e.g. 15 of 30)
  int get currentDayOfMonth => DateTime.now().day;

  /// Remaining days in month including today
  int get remainingDaysInMonth => (daysInCurrentMonth - currentDayOfMonth + 1).clamp(1, 31);

  /// Total amount spent today
  double get spentToday {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month &&
            t.timestamp.day == now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total amount spent yesterday
  double get spentYesterday {
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    return _transactions
        .where((t) =>
            t.timestamp.year == yesterday.year &&
            t.timestamp.month == yesterday.month &&
            t.timestamp.day == yesterday.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total amount spent this month (all days)
  double get spentThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) => t.timestamp.year == now.year && t.timestamp.month == now.month)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Total spent in current month prior to today
  double get spentPriorDaysThisMonth {
    final now = DateTime.now();
    return _transactions
        .where((t) =>
            t.timestamp.year == now.year &&
            t.timestamp.month == now.month &&
            t.timestamp.day < now.day)
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  /// Base dynamic daily quota calculated for today (including any Weekend Dhamaka claimed today)
  double get todayBaseQuota {
    final netDiscretionary = _budgetConfig.discretionaryFund;
    final priorSpent = spentPriorDaysThisMonth;
    final reservedDhamaka = _budgetConfig.weekendDhamakaPool;

    // Remaining funds to distribute across remaining days
    final remainingFund = (netDiscretionary - priorSpent - reservedDhamaka).clamp(0.0, double.infinity);
    final daysLeft = remainingDaysInMonth;

    return (remainingFund / daysLeft) + _todayClaimedDhamaka;
  }

  /// Remaining quota left for today
  double get todayRemainingQuota {
    return todayBaseQuota - spentToday;
  }

  /// Is today a weekend?
  bool get isWeekend {
    final weekday = DateTime.now().weekday;
    return weekday == DateTime.saturday || weekday == DateTime.sunday;
  }

  /// Tomorrow's projected quota if user finishes today with current spend
  double get projectedTomorrowQuota {
    final netDiscretionary = _budgetConfig.discretionaryFund;
    final totalSpentWithToday = spentPriorDaysThisMonth + spentToday;
    final reservedDhamaka = _budgetConfig.weekendDhamakaPool;

    final remainingFund = (netDiscretionary - totalSpentWithToday - reservedDhamaka).clamp(0.0, double.infinity);
    final daysAfterToday = (remainingDaysInMonth - 1).clamp(1, 31);

    return remainingFund / daysAfterToday;
  }

  // --- Transactions & Budget Operations ---

  Future<void> addTransaction({
    required String payeeName,
    String? payeeVpaOrEmail,
    required double amount,
    PaymentSource source = PaymentSource.upi,
    List<TransactionItem> items = const [],
    String category = 'General',
    String? remark,
    String currency = 'INR',
    String? location,
    bool isRecoverable = false,
    DateTime? repaymentDueDate,
    int reminderDaysBefore = 0,
    bool isRepaid = false,
    DateTime? timestamp,
  }) async {
    final effectiveLocation = (location != null && location.isNotEmpty)
        ? location
        : (_currentLocation != 'All Locations' ? _currentLocation : 'Hosur, Tamil Nadu');

    final record = TransactionRecord(
      id: _uuid.v4(),
      payeeName: payeeName,
      payeeVpaOrEmail: payeeVpaOrEmail,
      amount: amount,
      timestamp: timestamp ?? DateTime.now(),
      source: source,
      items: items,
      category: category,
      isItemized: items.isNotEmpty,
      remark: remark,
      currency: currency,
      location: effectiveLocation,
      isRecoverable: isRecoverable,
      repaymentDueDate: repaymentDueDate,
      reminderDaysBefore: reminderDaysBefore,
      isRepaid: isRepaid,
    );

    _transactions.insert(0, record);
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateTransactionItems(String transactionId, List<TransactionItem> items) async {
    final index = _transactions.indexWhere((t) => t.id == transactionId);
    if (index != -1) {
      _transactions[index] = _transactions[index].copyWith(
        items: items,
        isItemized: items.isNotEmpty,
      );
      _saveToPrefs();
      notifyListeners();
    }
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> updateBudgetConfig(BudgetConfig config) async {
    _budgetConfig = config;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> addToWeekendDhamaka(double amount) async {
    _budgetConfig = _budgetConfig.copyWith(
      weekendDhamakaPool: (_budgetConfig.weekendDhamakaPool + amount).clamp(0.0, double.infinity),
    );
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> claimWeekendDhamaka(double amount) async {
    final validAmt = amount.clamp(0.0, _budgetConfig.weekendDhamakaPool);
    _budgetConfig = _budgetConfig.copyWith(
      weekendDhamakaPool: (_budgetConfig.weekendDhamakaPool - validAmt).clamp(0.0, double.infinity),
    );
    _todayClaimedDhamaka += validAmt;
    _saveToPrefs();
    notifyListeners();
  }

  Future<void> setGeminiApiKey(String? key) async {
    _geminiApiKey = key;
    final prefs = await SharedPreferences.getInstance();
    if (key == null || key.isEmpty) {
      await prefs.remove(_prefKeyApiKey);
    } else {
      await prefs.setString(_prefKeyApiKey, key);
    }
    notifyListeners();
  }

  // --- Personal Menu Engine ---

  List<PersonalMenuStat> get personalMenuStats => getPersonalMenuForLocation(_currentLocation);

  List<PersonalMenuStat> getPersonalMenuForLocation(String targetLocation) {
    final Map<String, List<Map<String, dynamic>>> itemGroups = {};

    final sourceTxns = (targetLocation == 'All Locations')
        ? _transactions
        : _transactions.where((t) => t.location.toLowerCase() == targetLocation.toLowerCase()).toList();

    for (final txn in sourceTxns) {
      for (final item in txn.items) {
        final key = _normalizeItemName(item.name);
        itemGroups.putIfAbsent(key, () => []);
        itemGroups[key]!.add({
          'price': item.price,
          'quantity': item.quantity,
          'vendor': txn.payeeName,
          'date': txn.timestamp,
          'location': txn.location,
        });
      }
    }

    final stats = <PersonalMenuStat>[];

    itemGroups.forEach((name, purchases) {
      int totalCount = 0;
      double totalSpent = 0.0;
      double lowestPrice = double.infinity;
      String lowestVendor = 'Unknown';
      double highestPrice = 0.0;
      String highestVendor = 'Unknown';
      final history = <ItemPurchaseRecord>[];
      final String groupLocation = purchases.isNotEmpty
          ? (purchases.first['location'] as String? ?? 'Hosur, Tamil Nadu')
          : 'Hosur, Tamil Nadu';

      for (final p in purchases) {
        final price = p['price'] as double;
        final qty = p['quantity'] as int;
        final vendor = p['vendor'] as String;
        final date = p['date'] as DateTime;
        final loc = p['location'] as String? ?? 'Hosur, Tamil Nadu';

        totalCount += qty;
        totalSpent += (price * qty);

        if (price < lowestPrice) {
          lowestPrice = price;
          lowestVendor = vendor;
        }
        if (price > highestPrice) {
          highestPrice = price;
          highestVendor = vendor;
        }

        history.add(ItemPurchaseRecord(
          price: price,
          quantity: qty,
          vendor: vendor,
          date: date,
          location: loc,
        ));
      }

      stats.add(PersonalMenuStat(
        itemName: name,
        totalCount: totalCount,
        totalSpent: totalSpent,
        averagePrice: totalCount > 0 ? (totalSpent / totalCount) : 0.0,
        lowestPrice: lowestPrice == double.infinity ? 0.0 : lowestPrice,
        lowestPriceVendor: lowestVendor,
        highestPrice: highestPrice,
        highestPriceVendor: highestVendor,
        history: history,
        location: groupLocation,
      ));
    });

    // Sort by most frequently purchased
    stats.sort((a, b) => b.totalCount.compareTo(a.totalCount));
    return stats;
  }

  /// Groups the menu items by location (e.g. "Hosur, Tamil Nadu", "Koramangala, Karnataka")
  Map<String, List<PersonalMenuStat>> get menuGroupedByLocation {
    final Map<String, List<PersonalMenuStat>> grouped = {};

    // Discover all distinct locations in transactions
    final distinctLocations = _transactions
        .map((t) => t.location.trim())
        .where((loc) => loc.isNotEmpty)
        .toSet()
        .toList();

    if (distinctLocations.isEmpty) {
      distinctLocations.addAll(['Hosur, Tamil Nadu', 'Koramangala, Karnataka']);
    }

    for (final loc in distinctLocations) {
      final itemsForLoc = getPersonalMenuForLocation(loc);
      if (itemsForLoc.isNotEmpty) {
        grouped[loc] = itemsForLoc;
      }
    }

    return grouped;
  }

  String _normalizeItemName(String raw) {
    var clean = raw.trim().toLowerCase();
    // Common aliases normalization
    if (clean.contains('chai') || clean.contains('tea')) return 'Tea (Chai)';
    if (clean.contains('samosa')) return 'Samosa';
    if (clean.contains('coffee')) return 'Coffee';
    if (clean.contains('dosa')) return 'Dosa';
    if (clean.contains('biryani')) return 'Biryani';

    // Capitalize first letters
    return raw.trim().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  // --- Persistence & Initial Seed ---

  Future<void> _loadFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _geminiApiKey = prefs.getString(_prefKeyApiKey);
      _isDarkMode = prefs.getBool(_prefKeyTheme) ?? false;
      _todayClaimedDhamaka = prefs.getDouble(_prefKeyClaimed) ?? 0.0;
      _currentLocation = prefs.getString(_prefKeyLocation) ?? 'All Locations';

      final budgetJson = prefs.getString(_prefKeyBudget);
      if (budgetJson != null) {
        _budgetConfig = BudgetConfig.fromJson(jsonDecode(budgetJson));
      } else {
        _budgetConfig = BudgetConfig(
          monthlyIncome: 50000.0,
          fixedExpenses: 20000.0,
          surplusMode: SurplusAllocationMode.weekendDhamaka,
          weekendDhamakaPool: 650.0, // Seed weekend pool
        );
      }

      final txnsJson = prefs.getString(_prefKeyTxns);
      if (txnsJson != null) {
        final List<dynamic> list = jsonDecode(txnsJson);
        _transactions = list.map((e) => TransactionRecord.fromJson(e)).toList();
      } else {
        _seedInitialDemoData();
      }
    } catch (_) {
      _seedInitialDemoData();
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> _saveToPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKeyTheme, _isDarkMode);
    await prefs.setDouble(_prefKeyClaimed, _todayClaimedDhamaka);
    await prefs.setString(_prefKeyLocation, _currentLocation);
    await prefs.setString(_prefKeyBudget, jsonEncode(_budgetConfig.toJson()));
    await prefs.setString(
        _prefKeyTxns, jsonEncode(_transactions.map((e) => e.toJson()).toList()));
  }

  void _seedInitialDemoData() {
    final now = DateTime.now();

    _transactions = [
      // 1. Recoverable Loan to Ravi Kumar (Due today - triggers reminder!)
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Ravi Kumar',
        payeeVpaOrEmail: 'ravi@upi',
        amount: 500.0,
        timestamp: now.subtract(const Duration(days: 3)),
        source: PaymentSource.upi,
        category: 'Loan to Friend (Recoverable)',
        remark: 'Lent for lunch & metro pass',
        location: 'Hosur, Tamil Nadu',
        isRecoverable: true,
        repaymentDueDate: now, // Due Today!
        reminderDaysBefore: 0,
        isRepaid: false,
      ),
      // 2. Hosur Chai Point
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Sharma Chai Point',
        payeeVpaOrEmail: 'sharma.tea@upi',
        amount: 35.0,
        timestamp: now.subtract(const Duration(hours: 2)),
        source: PaymentSource.upi,
        category: 'Food & Dining',
        location: 'Hosur, Tamil Nadu',
        items: [
          TransactionItem(id: _uuid.v4(), name: 'Tea (Chai)', price: 15.0, quantity: 1),
          TransactionItem(id: _uuid.v4(), name: 'Samosa', price: 20.0, quantity: 1),
        ],
        isItemized: true,
      ),
      // 3. Koramangala Udupi
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Udupi Upahar',
        payeeVpaOrEmail: 'udupi@upi',
        amount: 90.0,
        timestamp: now.subtract(const Duration(hours: 5)),
        source: PaymentSource.upi,
        category: 'Food & Dining',
        location: 'Koramangala, Karnataka',
        items: [
          TransactionItem(id: _uuid.v4(), name: 'Masala Dosa', price: 70.0, quantity: 1),
          TransactionItem(id: _uuid.v4(), name: 'Filter Coffee', price: 20.0, quantity: 1),
        ],
        isItemized: true,
      ),
      // 4. Hosur Campus Tapri
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Campus Tea Stall',
        payeeVpaOrEmail: 'campus.tapri@upi',
        amount: 24.0,
        timestamp: now.subtract(const Duration(days: 1, hours: 3)),
        source: PaymentSource.upi,
        category: 'Food & Dining',
        location: 'Hosur, Tamil Nadu',
        items: [
          TransactionItem(id: _uuid.v4(), name: 'Tea (Chai)', price: 12.0, quantity: 2),
        ],
        isItemized: true,
      ),
      // 5. Koramangala Coffee House
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Corner Coffee House',
        payeeVpaOrEmail: 'paypal@cornercoffee.com',
        amount: 140.0,
        timestamp: now.subtract(const Duration(days: 3)),
        source: PaymentSource.paypal,
        category: 'Food & Dining',
        location: 'Koramangala, Karnataka',
        items: [
          TransactionItem(id: _uuid.v4(), name: 'Cappuccino', price: 110.0, quantity: 1),
          TransactionItem(id: _uuid.v4(), name: 'Butter Cookie', price: 30.0, quantity: 1),
        ],
        isItemized: true,
      ),
      // 6. Utility Bill
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Electricity Board',
        payeeVpaOrEmail: 'bescom@upi',
        amount: 850.0,
        timestamp: now.subtract(const Duration(days: 4)),
        source: PaymentSource.upi,
        category: 'Utilities',
        location: 'Hosur, Tamil Nadu',
        remark: 'Electricity bill payment',
      ),
      // 7. Mobile Recharge
      TransactionRecord(
        id: _uuid.v4(),
        payeeName: 'Jio Prepaid',
        payeeVpaOrEmail: 'jio@upi',
        amount: 299.0,
        timestamp: now.subtract(const Duration(days: 6)),
        source: PaymentSource.upi,
        category: 'Recharge',
        location: 'Koramangala, Karnataka',
        remark: 'Monthly 5G data plan',
      ),
    ];
  }
}
