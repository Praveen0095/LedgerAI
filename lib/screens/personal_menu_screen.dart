import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/personal_menu_stat.dart';
import '../services/ledger_state.dart';
import '../theme/app_theme.dart';

class PersonalMenuScreen extends StatefulWidget {
  const PersonalMenuScreen({super.key});

  @override
  State<PersonalMenuScreen> createState() => _PersonalMenuScreenState();
}

class _PersonalMenuScreenState extends State<PersonalMenuScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedLocationFilter = 'All Locations';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LedgerState>();
    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    // Group menu by location
    final Map<String, List<PersonalMenuStat>> groupedMenu = state.menuGroupedByLocation;

    // Filter by selected location and search query
    final Map<String, List<PersonalMenuStat>> displayGroups = {};

    groupedMenu.forEach((loc, stats) {
      if (_selectedLocationFilter != 'All Locations' &&
          loc.toLowerCase() != _selectedLocationFilter.toLowerCase()) {
        return;
      }
      final filtered = _searchQuery.isEmpty
          ? stats
          : stats
              .where((s) => s.itemName.toLowerCase().contains(_searchQuery.toLowerCase()))
              .toList();
      if (filtered.isNotEmpty) {
        displayGroups[loc] = filtered;
      }
    });

    final allLocations = ['All Locations', ...groupedMenu.keys.toList()];

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Personal Menu'),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Header description & Search bar
          Container(
            color: isDark ? const Color(0xFF1D1075) : const Color(0xFFF3F0FA),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Craving something? Compare historical prices across vendors & areas!',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Search field
                TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: TextStyle(color: isDark ? Colors.white : Colors.black87),
                  decoration: InputDecoration(
                    hintText: 'Search cravings (e.g. Tea, Samosa, Coffee)...',
                    hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600),
                    prefixIcon: Icon(Icons.search, color: isDark ? Colors.white70 : Colors.grey.shade600),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: isDark ? Colors.white70 : Colors.grey.shade600),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? const Color(0xFF0D0B18) : Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: isDark ? Colors.white12 : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Location Filter Chips (User Location Setting)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: allLocations.map((loc) {
                      final isSelected = _selectedLocationFilter == loc;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          avatar: Icon(
                            loc == 'All Locations' ? Icons.public : Icons.location_on,
                            size: 14,
                            color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                          ),
                          label: Text(
                            loc,
                            style: TextStyle(
                              color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          backgroundColor: isDark ? const Color(0xFF0D0B18) : Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : (isDark ? Colors.white12 : Colors.grey.shade300),
                            ),
                          ),
                          onSelected: (selected) {
                            setState(() {
                              _selectedLocationFilter = selected ? loc : 'All Locations';
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Content List Grouped By Location
          Expanded(
            child: displayGroups.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.restaurant_menu, size: 64, color: isDark ? Colors.white30 : Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No items in this location yet.\nScan bills or record payments to start tracking!'
                                : 'No matching cravings found for "$_searchQuery"',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.grey.shade600, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: displayGroups.length,
                    itemBuilder: (context, groupIndex) {
                      final loc = displayGroups.keys.elementAt(groupIndex);
                      final items = displayGroups[loc]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location Group Header (Requirement 3: Grouped by location)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 12, left: 4),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(Icons.location_on, size: 16, color: Theme.of(context).colorScheme.primary),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  loc,
                                  style: TextStyle(
                                    fontFamily: AppTheme.fontTitle,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '${items.length} ${items.length == 1 ? "item" : "items"}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...items.map((stat) => _buildCravingCard(context, stat, currencyFormat, isDark)),
                          const SizedBox(height: 12),
                        ],
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCravingCard(BuildContext context, PersonalMenuStat stat, NumberFormat currency, bool isDark) {
    const emeraldGreen = Color(0xFF10B981);
    const warmAmber = Color(0xFFF59E0B);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showHistoryBottomSheet(context, stat, currency, isDark),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: warmAmber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.fastfood_rounded, color: warmAmber, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.itemName,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Consumed ${stat.totalCount} times (${currency.format(stat.totalSpent)} total)',
                            style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Avg Price', style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 11)),
                      Text(
                        currency.format(stat.averagePrice),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: emeraldGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  // Lowest price chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: emeraldGreen.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: emeraldGreen.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward_rounded, color: emeraldGreen, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Cheapest',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF065F46),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${currency.format(stat.lowestPrice)} at ${stat.lowestPriceVendor}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Highest price chip
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: warmAmber.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: warmAmber.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward_rounded, color: warmAmber, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Priciest',
                                style: TextStyle(
                                  color: isDark ? const Color(0xFFFBBF24) : const Color(0xFF92400E),
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${currency.format(stat.highestPrice)} at ${stat.highestPriceVendor}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistoryBottomSheet(BuildContext context, PersonalMenuStat stat, NumberFormat currency, bool isDark) {
    const emeraldGreen = Color(0xFF10B981);
    final surfaceColor = isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
    final textColor = isDark ? AppTheme.darkText : AppTheme.lightText;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: isDark ? AppTheme.darkSecondary.withValues(alpha: 0.6) : AppTheme.lightSecondary.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                '${stat.itemName} History',
                style: TextStyle(
                  fontFamily: AppTheme.fontTitle,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Compare all ${stat.history.length} times you purchased this item',
                style: TextStyle(
                  fontFamily: AppTheme.fontBody,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                  fontSize: 13,
                ),
              ),
              const Divider(height: 26),
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  itemCount: stat.history.length,
                  separatorBuilder: (_, __) => Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                  itemBuilder: (_, i) {
                    final h = stat.history[i];
                    final dateFormat = DateFormat('MMM d, yyyy • h:mm a');
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: emeraldGreen.withOpacity(0.15),
                        child: Text(
                          currency.format(h.price).replaceAll('₹', ''),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: emeraldGreen,
                          ),
                        ),
                      ),
                      title: Text(
                        h.vendor,
                        style: TextStyle(
                          fontFamily: AppTheme.fontTitle,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      subtitle: Text(
                        dateFormat.format(h.date),
                        style: TextStyle(
                          fontFamily: AppTheme.fontBody,
                          color: isDark ? Colors.white60 : Colors.grey.shade600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: Text(
                        '${h.quantity}x @ ${currency.format(h.price)}',
                        style: TextStyle(
                          fontFamily: AppTheme.fontTitle,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
