import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../services/ai_recommendation_service.dart';
import '../services/ledger_state.dart';
import 'manual_entry_screen.dart';

class AiRecommendationsScreen extends StatefulWidget {
  final WeatherType initialWeather;
  final String? initialItemQuery;
  final double? initialPriceQuery;

  const AiRecommendationsScreen({
    super.key,
    this.initialWeather = WeatherType.rainy,
    this.initialItemQuery,
    this.initialPriceQuery,
  });

  @override
  State<AiRecommendationsScreen> createState() => _AiRecommendationsScreenState();
}

class _AiRecommendationsScreenState extends State<AiRecommendationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Weather Tab State
  late WeatherType _selectedWeather;

  // VFM Tab State
  late TextEditingController _itemController;
  late TextEditingController _priceController;
  bool _isAnalyzingVfm = false;
  VfmAnalysisResult? _vfmResult;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedWeather = widget.initialWeather;

    _itemController = TextEditingController(text: widget.initialItemQuery ?? 'Chicken Biryani');
    _priceController = TextEditingController(
      text: widget.initialPriceQuery != null
          ? widget.initialPriceQuery!.toStringAsFixed(0)
          : '250',
    );

    // If initial query provided, run analysis immediately
    if (widget.initialItemQuery != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _runVfmAnalysis();
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _itemController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _runVfmAnalysis() async {
    final itemName = _itemController.text.trim();
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (itemName.isEmpty || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid item name and price')),
      );
      return;
    }

    setState(() => _isAnalyzingVfm = true);

    final state = context.read<LedgerState>();
    final result = await AiRecommendationService.analyzeValueForMoney(
      itemName: itemName,
      proposedPrice: price,
      todayRemainingQuota: state.todayRemainingQuota,
      todayBaseQuota: state.todayBaseQuota,
      userMenu: state.personalMenuStats,
      geminiApiKey: state.geminiApiKey,
    );

    if (mounted) {
      setState(() {
        _vfmResult = result;
        _isAnalyzingVfm = false;
      });
    }
  }

  void _loadVfmPreset(String name, double price) {
    _itemController.text = name;
    _priceController.text = price.toStringAsFixed(0);
    _runVfmAnalysis();
  }

  @override
  Widget build(BuildContext context) {
    
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final theme = Theme.of(context);
    final state = context.watch<LedgerState>();
    final isDark = theme.brightness == Brightness.dark;

    const emeraldGreen = Color(0xFF10B981);
    const warmAmber = Color(0xFFF59E0B);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Spending & Craving Advisor'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: emeraldGreen,
          labelColor: isDark ? Colors.white : theme.colorScheme.primary,
          unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.wb_cloudy_rounded), text: 'Weather Bites'),
            Tab(icon: Icon(Icons.price_check_rounded), text: 'Is It Worth It? (VFM)'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Quota Context Header Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: isDark ? const Color(0xFF1D1075) : const Color(0xFFE2E8F0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt_rounded, size: 16, color: warmAmber),
                    const SizedBox(width: 6),
                    Text(
                      'Today\'s Quota Left: ${currencyFormat.format(state.todayRemainingQuota < 0 ? 0 : state.todayRemainingQuota)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  'Daily Limit: ${currencyFormat.format(state.todayBaseQuota)}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildWeatherTab(context, state, isDark, emeraldGreen, warmAmber),
                _buildVfmTab(context, state, isDark, emeraldGreen, warmAmber, currencyFormat),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------- TAB 1: WEATHER RECOMMENDATIONS -------------------
  Widget _buildWeatherTab(
    BuildContext context,
    LedgerState state,
    bool isDark,
    Color emeraldGreen,
    Color warmAmber,
  ) {
    final weatherRec = AiRecommendationService.getWeatherRecommendation(
      weather: _selectedWeather,
      userHistory: state.personalMenuStats,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Select Current Weather:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 10),

          // Weather Switcher Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _weatherChoiceChip('🌧️ Rainy / Monsoon', WeatherType.rainy),
              _weatherChoiceChip('☀️ Hot Summer', WeatherType.hotSummer),
              _weatherChoiceChip('❄️ Chilly Winter', WeatherType.chillyWinter),
              _weatherChoiceChip('⛅ Pleasant Breeze', WeatherType.pleasantBreezy),
            ],
          ),
          const SizedBox(height: 20),

                    // Hero Weather Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark 
                  ? Theme.of(context).colorScheme.surface 
                  : Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.grey.shade300,
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      weatherRec.title,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: emeraldGreen.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('AI Context', style: TextStyle(color: Color(0xFF34D399), fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  weatherRec.description,
                  style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recommended Items
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.restaurant_rounded, color: emeraldGreen, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Weather Craving Picks (Menu Matched)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  ...weatherRec.recommendedItems.map((item) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: emeraldGreen, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Frugal Smart Tip Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: warmAmber.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: warmAmber.withOpacity(0.3)),
            ),
            child: Text(
              weatherRec.frugalTip,
              style: TextStyle(
                color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action: Log this snack
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.edit_note_rounded),
            label: const Text('Log A Weather Snack in Ledger', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ManualEntryScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _weatherChoiceChip(String label, WeatherType type) {
    final isSelected = _selectedWeather == type;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (sel) {
        if (sel) setState(() => _selectedWeather = type);
      },
    );
  }

  // ------------------- TAB 2: VALUE FOR MONEY (VFM) -------------------
  Widget _buildVfmTab(
    BuildContext context,
    LedgerState state,
    bool isDark,
    Color emeraldGreen,
    Color warmAmber,
    NumberFormat currencyFormat,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header description
          Text(
            'Check Craving Before You Spend',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0D0B18)),
          ),
          const SizedBox(height: 4),
          Text(
            'Evaluating a ₹250 Biryani, ₹180 Coffee, or ₹400 Pizza? AI tests it against your remaining quota and suggests cheaper, tasty alternatives.',
            style: TextStyle(fontSize: 13, color: isDark ? Colors.white60 : Colors.black54),
          ),
          const SizedBox(height: 14),

          // Preset Chips
          const Text('Try Hackathon Demo Queries:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.rice_bowl_rounded, size: 16),
                label: const Text('Chicken Biryani ₹250'),
                onPressed: () => _loadVfmPreset('Chicken Biryani', 250),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_cafe_rounded, size: 16),
                label: const Text('Cafe Cold Coffee ₹180'),
                onPressed: () => _loadVfmPreset('Cold Coffee', 180),
              ),
              ActionChip(
                avatar: const Icon(Icons.local_pizza_rounded, size: 16),
                label: const Text('Large Pizza ₹380'),
                onPressed: () => _loadVfmPreset('Large Cheese Pizza', 380),
              ),
              ActionChip(
                avatar: const Icon(Icons.lunch_dining_rounded, size: 16),
                label: const Text('Burger Combo ₹190'),
                onPressed: () => _loadVfmPreset('Burger Combo Meal', 190),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Input Form
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  TextField(
                    controller: _itemController,
                    decoration: const InputDecoration(
                      labelText: 'Craving / Food Item',
                      hintText: 'e.g. Chicken Biryani, Butter Chicken, Ice Cream',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    decoration: const InputDecoration(
                      labelText: 'Proposed Price (₹)',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: _isAnalyzingVfm
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Analyze Value-for-Money', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: _isAnalyzingVfm ? null : _runVfmAnalysis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Analysis Output Card
          if (_vfmResult != null) ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1D1075) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _vfmResult!.verdict.contains('Heavy')
                      ? Colors.redAccent.withOpacity(0.5)
                      : (_vfmResult!.verdict.contains('Moderate')
                          ? warmAmber.withOpacity(0.5)
                          : emeraldGreen.withOpacity(0.5)),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          _vfmResult!.verdict,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: _vfmResult!.verdict.contains('Heavy')
                                ? Colors.redAccent
                                : (_vfmResult!.verdict.contains('Moderate') ? warmAmber : emeraldGreen),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: warmAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${_vfmResult!.quotaPercentage.toStringAsFixed(0)}% of today\'s limit',
                          style: TextStyle(color: warmAmber, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Text(
                    _vfmResult!.reasoning,
                    style: const TextStyle(fontSize: 14, height: 1.4),
                  ),
                  const SizedBox(height: 16),

                  // Cheaper / Tastier Alternatives Box
                  if (_vfmResult!.cheaperAlternatives.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: emeraldGreen.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: emeraldGreen.withOpacity(0.25)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.lightbulb_rounded, color: emeraldGreen, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Cheaper & Tasty Alternatives',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: emeraldGreen),
                                  ),
                                ],
                              ),
                              if (_vfmResult!.potentialSavings > 0)
                                Text(
                                  'Saves ₹${_vfmResult!.potentialSavings.toStringAsFixed(0)}',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: emeraldGreen, fontSize: 12),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._vfmResult!.cheaperAlternatives.map((alt) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('• ', style: TextStyle(color: emeraldGreen, fontWeight: FontWeight.bold)),
                                  Expanded(child: Text(alt, style: const TextStyle(fontSize: 13, height: 1.3))),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Impact on Tomorrow
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _vfmResult!.impactOnTomorrow,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                        ),
                      ),
                    ],
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
