import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/ledger_state.dart';
import '../widgets/ai_advisor_card.dart';
import '../widgets/dynamic_quota_card.dart';
import '../widgets/recent_transactions_card.dart';
import '../widgets/spend_comparison_card.dart';
import '../widgets/weekend_dhamaka_card.dart';
import 'ai_recommendations_screen.dart';
import 'budget_setup_screen.dart';
import 'expense_entry_screen.dart';
import 'manual_entry_screen.dart';
import 'personal_menu_screen.dart';
import 'qr_scanner_screen.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final TextEditingController _locationSearchController = TextEditingController();
  List<String> _locationSuggestions = [];
  bool _showLocationSuggestions = false;
  final FocusNode _locationFocusNode = FocusNode();

  // Comprehensive Indian cities list for search
  static const List<String> _allCities = [
    'All Locations',
    'Mumbai, Maharashtra', 'Delhi, NCT', 'Bengaluru, Karnataka',
    'Hyderabad, Telangana', 'Chennai, Tamil Nadu', 'Kolkata, West Bengal',
    'Pune, Maharashtra', 'Ahmedabad, Gujarat', 'Jaipur, Rajasthan',
    'Surat, Gujarat', 'Lucknow, Uttar Pradesh', 'Kanpur, Uttar Pradesh',
    'Nagpur, Maharashtra', 'Indore, Madhya Pradesh', 'Thane, Maharashtra',
    'Bhopal, Madhya Pradesh', 'Visakhapatnam, Andhra Pradesh',
    'Vadodara, Gujarat', 'Ludhiana, Punjab', 'Patna, Bihar',
    'Agra, Uttar Pradesh', 'Nashik, Maharashtra', 'Faridabad, Haryana',
    'Meerut, Uttar Pradesh', 'Rajkot, Gujarat', 'Kalyan, Maharashtra',
    'Vasai, Maharashtra', 'Varanasi, Uttar Pradesh',
    'Srinagar, Jammu & Kashmir', 'Aurangabad, Maharashtra',
    'Dhanbad, Jharkhand', 'Amritsar, Punjab', 'Navi Mumbai, Maharashtra',
    'Allahabad, Uttar Pradesh', 'Howrah, West Bengal',
    'Coimbatore, Tamil Nadu', 'Jabalpur, Madhya Pradesh',
    'Gwalior, Madhya Pradesh', 'Vijayawada, Andhra Pradesh',
    'Jodhpur, Rajasthan', 'Madurai, Tamil Nadu', 'Raipur, Chhattisgarh',
    'Kota, Rajasthan', 'Guwahati, Assam', 'Chandigarh, Punjab',
    'Solapur, Maharashtra', 'Hubli, Karnataka', 'Tiruchirappalli, Tamil Nadu',
    'Bareilly, Uttar Pradesh', 'Mysuru, Karnataka',
    'Thiruvananthapuram, Kerala', 'Tiruppur, Tamil Nadu', 'Kochi, Kerala',
    'Aligarh, Uttar Pradesh', 'Bhubaneswar, Odisha', 'Salem, Tamil Nadu',
    'Moradabad, Uttar Pradesh', 'Warangal, Telangana',
    'Guntur, Andhra Pradesh', 'Noida, Uttar Pradesh', 'Gurugram, Haryana',
    'Mangaluru, Karnataka', 'Koramangala, Karnataka',
    'Indiranagar, Karnataka', 'HSR Layout, Karnataka',
    'Whitefield, Karnataka', 'Electronic City, Karnataka',
    'Hosur, Tamil Nadu', 'Ambattur, Tamil Nadu', 'Velachery, Tamil Nadu',
    'Porur, Tamil Nadu', 'Adyar, Tamil Nadu', 'Andheri, Maharashtra',
    'Bandra, Maharashtra', 'Worli, Maharashtra', 'Powai, Maharashtra',
    'Malad, Maharashtra', 'Borivali, Maharashtra', 'Dwarka, Delhi',
    'Rohini, Delhi', 'Lajpat Nagar, Delhi', 'Connaught Place, Delhi',
    'Saket, Delhi', 'Vasant Kunj, Delhi', 'Sector 17, Chandigarh',
    'Salt Lake, West Bengal', 'New Town, West Bengal',
    'Park Street, West Bengal', 'Yelahanka, Karnataka',
    'Jayanagar, Karnataka', 'Banashankari, Karnataka',
    'JP Nagar, Karnataka', 'Sarjapur, Karnataka', 'Marathahalli, Karnataka',
  ];

  @override
  void initState() {
    super.initState();
    _locationFocusNode.addListener(() {
      if (!_locationFocusNode.hasFocus) {
        // Delay so tap on suggestion registers before hiding
        Future.delayed(const Duration(milliseconds: 150), () {
          if (mounted) setState(() => _showLocationSuggestions = false);
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = context.read<LedgerState>().currentLocation;
    if (_locationSearchController.text.isEmpty ||
        _locationSearchController.text != loc) {
      _locationSearchController.text = loc == 'All Locations' ? '' : loc;
    }
  }

  @override
  void dispose() {
    _locationSearchController.dispose();
    _locationFocusNode.dispose();
    super.dispose();
  }

  void _filterLocations(String query) {
    final state = context.read<LedgerState>();
    // Merge app-stored locations with the static list (deduplicated)
    final merged = {
      ...state.availableLocations,
      ..._allCities,
    }.toList();

    if (query.trim().isEmpty) {
      // Show stored/recent locations when empty
      setState(() {
        _locationSuggestions = merged.take(6).toList();
        _showLocationSuggestions = true;
      });
    } else {
      final lower = query.toLowerCase();
      final matches = merged
          .where((c) => c.toLowerCase().contains(lower))
          .take(7)
          .toList();
      // If nothing matched but user typed something, offer "Add '<query>'"
      setState(() {
        _locationSuggestions = matches;
        _showLocationSuggestions = true;
      });
    }
  }

  void _selectLocation(String loc, LedgerState state) {
    state.addLocation(loc);
    state.setCurrentLocation(loc);
    _locationSearchController.text = loc == 'All Locations' ? '' : loc;
    setState(() => _showLocationSuggestions = false);
    _locationFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();

    const emeraldGreen = Color(0xFF10B981);
    const warmAmber = Color(0xFFF59E0B);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icons/Icon-192.png',
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 22,
                  color: emeraldGreen,
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Text('LedgerAI', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.auto_awesome,
              color: Color(0xFFFBBF24),
            ),
            tooltip: 'AI Spending Advisor',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AiRecommendationsScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(
              state.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            tooltip: state.isDarkMode
                ? 'Switch to Light Mode'
                : 'Switch to Dark Mode',
            onPressed: () => state.toggleTheme(!state.isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            tooltip: 'Budget Setup',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BudgetSetupScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => state.refresh(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Location Search Bar (replaces fixed dropdown) ──────────────
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0D0B18) : const Color(0xFFF3F0FA),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 18, color: Colors.redAccent),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _locationSearchController,
                              focusNode: _locationFocusNode,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search city or area...',
                                hintStyle: TextStyle(
                                  fontSize: 13,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                  fontWeight: FontWeight.normal,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                suffixIcon: _locationSearchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close_rounded,
                                            size: 16,
                                            color: isDark ? Colors.white54 : Colors.black45),
                                        padding: EdgeInsets.zero,
                                        onPressed: () {
                                          _locationSearchController.clear();
                                          _selectLocation('All Locations', state);
                                        },
                                      )
                                    : Icon(Icons.search_rounded,
                                        size: 18,
                                        color: theme.colorScheme.primary),
                              ),
                              onChanged: _filterLocations,
                              onTap: () => _filterLocations(_locationSearchController.text),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Suggestion dropdown list
                    if (_showLocationSuggestions && _locationSuggestions.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1A1730)
                              : Colors.white,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(16),
                            bottomRight: Radius.circular(16),
                          ),
                          border: Border(
                            top: BorderSide(
                              color: isDark ? Colors.white12 : Colors.grey.shade200,
                            ),
                          ),
                        ),
                        constraints: const BoxConstraints(maxHeight: 240),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: _locationSuggestions.length,
                          itemBuilder: (ctx, i) {
                            final city = _locationSuggestions[i];
                            final isSelected = city == state.currentLocation;
                            return InkWell(
                              onTap: () => _selectLocation(city, state),
                              borderRadius: i == _locationSuggestions.length - 1
                                  ? const BorderRadius.only(
                                      bottomLeft: Radius.circular(16),
                                      bottomRight: Radius.circular(16),
                                    )
                                  : BorderRadius.zero,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      isSelected
                                          ? Icons.location_on_rounded
                                          : Icons.location_city_rounded,
                                      size: 16,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : (isDark ? Colors.white38 : Colors.black38),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        city,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Icon(Icons.check_rounded,
                                          size: 16, color: theme.colorScheme.primary),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),

              // Active Repayment Due Reminders
              if (state.activeRepaymentReminders.isNotEmpty) ...[
                ...state.activeRepaymentReminders.map((loan) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1D1075) : const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: warmAmber, width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: warmAmber.withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: warmAmber.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.notification_important_rounded, color: warmAmber, size: 20),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Repayment Due${loan.repaymentDueDate != null ? ' — ${_formatDate(loan.repaymentDueDate!)}' : ''}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: isDark ? Colors.amber.shade200 : const Color(0xFF92400E),
                                    ),
                                  ),
                                  Text(
                                    '₹${loan.amount.toStringAsFixed(0)} from ${loan.payeeName}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () => state.markAsRepaid(loan.id),
                              style: TextButton.styleFrom(
                                backgroundColor: warmAmber.withOpacity(0.15),
                                foregroundColor: warmAmber,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              ),
                              child: const Text('Mark\nReceived', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        if (loan.remark != null && loan.remark!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            loan.remark!,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),
              ],

              // Budget Alert Banner
              if (state.hasBudgetAlert) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3F0B0B) : const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '⚠️ ${state.budgetAlertMessage}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // 1. Dynamic Quota Card
              const DynamicQuotaCard(),
              const SizedBox(height: 18),

              // 2. Weekend Dhamaka / Mode Card
              const WeekendDhamakaCard(),
              const SizedBox(height: 18),

              // 3. Primary Actions Grid
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                      label: const Text('Scan & Pay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const QrScannerScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: emeraldGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.document_scanner_rounded, size: 20),
                      label: const Text('Manual Bill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualEntryScreen()));
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Row 2: Expense (Lend / Recharge) + Craving Index
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: warmAmber,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: const Icon(Icons.handshake_rounded, size: 20),
                      label: const Text('Expense (Lend)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseEntryScreen()));
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: isDark ? Colors.white30 : theme.colorScheme.primary.withOpacity(0.4)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(Icons.restaurant_menu_rounded, color: isDark ? Colors.white : theme.colorScheme.primary, size: 20),
                      label: Text(
                        'Craving Index',
                        style: TextStyle(
                          color: isDark ? Colors.white : theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalMenuScreen()));
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // 4. AI Spending & Craving Advisor Card
              const AiAdvisorCard(),

              const SizedBox(height: 16),

              // 5. Recent Transactions Panel
              const RecentTransactionsCard(),

              const SizedBox(height: 16),

              // 6. Spend Comparison Panel
              const SpendComparisonCard(),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year}';
}
