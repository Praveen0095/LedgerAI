import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/personal_menu_stat.dart';

enum WeatherType {
  rainy,
  hotSummer,
  chillyWinter,
  pleasantBreezy,
}

class VfmAnalysisResult {
  final String itemName;
  final double proposedPrice;
  final double quotaPercentage;
  final String verdict; // e.g. "Great Value", "Moderate Splurge", "Heavy Splurge"
  final String reasoning;
  final List<String> cheaperAlternatives;
  final double potentialSavings;
  final String impactOnTomorrow;

  VfmAnalysisResult({
    required this.itemName,
    required this.proposedPrice,
    required this.quotaPercentage,
    required this.verdict,
    required this.reasoning,
    required this.cheaperAlternatives,
    required this.potentialSavings,
    required this.impactOnTomorrow,
  });
}

class WeatherRecommendation {
  final WeatherType weather;
  final String title;
  final String description;
  final List<String> recommendedItems;
  final String frugalTip;

  WeatherRecommendation({
    required this.weather,
    required this.title,
    required this.description,
    required this.recommendedItems,
    required this.frugalTip,
  });
}

class AiRecommendationService {
  /// 1. Weather-Based Contextual Food & Spending Recommendations
  static WeatherRecommendation getWeatherRecommendation({
    required WeatherType weather,
    List<PersonalMenuStat> userHistory = const [],
  }) {
    switch (weather) {
      case WeatherType.rainy:
        final hasTea = userHistory.any((s) => s.itemName.toLowerCase().contains('tea'));
        final teaPrice = hasTea
            ? userHistory.firstWhere((s) => s.itemName.toLowerCase().contains('tea')).averagePrice
            : 15.0;

        return WeatherRecommendation(
          weather: weather,
          title: '🌧️ Monsoon / Rainy Weather Comfort',
          description:
              'Rainy weather triggers cravings for hot, deep-fried, and spicy snacks. Food delivery apps often add ₹40-₹80 surge pricing in the rain!',
          recommendedItems: [
            'Hot Masala Chai (avg ₹${teaPrice.toStringAsFixed(0)} in your menu)',
            'Crispy Samosa or Onion Pakoda (₹20-₹35)',
            'Hot Roasted Sweet Corn / Bhutta (₹25-₹30)',
            'Steaming Veg/Chicken Momos with spicy dip (₹60-₹90)',
          ],
          frugalTip:
              '💡 Frugal Tip: Avoid Swiggy/Zomato rain surge fees. Walk to your nearby tea stall or brew chai at home to save over ₹100!',
        );

      case WeatherType.hotSummer:
        return WeatherRecommendation(
          weather: weather,
          title: '☀️ Hot & Humid Weather Hydration',
          description:
              'High heat drains energy and increases thirst. Heavy gravies or oily food will cause fatigue. Prioritize natural cooling fluids.',
          recommendedItems: [
            'Fresh Tender Coconut Water (₹40-₹50)',
            'Chilled Butter Milk / Spiced Chaas (₹15-₹20)',
            'Iced Lemon Mint Soda / Shikanji (₹20-₹30)',
            'Watermelon / Sweet Lime Juice (₹40-₹60)',
            'Cold Coffee (₹70-₹110)',
          ],
          frugalTip:
              '💡 Frugal Tip: Roadside coconut water or local chaas is 3x cheaper and healthier than packaged carbonated drinks or fancy cafe iced lattes.',
        );

      case WeatherType.chillyWinter:
        return WeatherRecommendation(
          weather: weather,
          title: '❄️ Chilly Winter / Cold Evening Warmers',
          description:
              'Cold temperatures increase metabolic appetite. Hot broths, toasted bread, and warm beverages provide lasting comfort.',
          recommendedItems: [
            'South Indian Filter Coffee (₹20-₹30)',
            'Hot Sweet Corn Soup or Tomato Broth (₹50-₹80)',
            'Bun Maska with Kadak Chai (₹35-₹50)',
            'Hot Gulab Jamun or Gajar Ka Halwa (₹40-₹60)',
          ],
          frugalTip:
              '💡 Frugal Tip: A hot ₹25 filter coffee at an Udupi Darshini gives the same warmth as a ₹240 coffee chain beverage!',
        );

      case WeatherType.pleasantBreezy:
        return WeatherRecommendation(
          weather: weather,
          title: '⛅ Pleasant Breeze & Evening Walk',
          description:
              'Great weather for light, casual street bites while enjoying the evening breeze.',
          recommendedItems: [
            'Pani Puri / Sev Puri street chaat (₹30-₹50)',
            'Masala Dosa with Chutney (₹60-₹80)',
            'Grilled Sandwich (₹50-₹70)',
            'Fresh Sugarcane Juice with ginger & lemon (₹25-₹30)',
          ],
          frugalTip:
              '💡 Frugal Tip: Good weather is ideal for a stroll—skip short auto/cab rides to nearby snacks and pocket the savings for your Weekend Dhamaka stash!',
        );
    }
  }

  /// 2. Value-for-Money (VFM) Analyzer
  /// Evaluates whether an expense like ₹250 Biryani is worth it based on current quota,
  /// and provides cheaper/tastier alternatives.
  static Future<VfmAnalysisResult> analyzeValueForMoney({
    required String itemName,
    required double proposedPrice,
    required double todayRemainingQuota,
    required double todayBaseQuota,
    List<PersonalMenuStat> userMenu = const [],
    String? geminiApiKey,
  }) async {
    // If Gemini API is available, try live generative reasoning
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      try {
        final apiResult = await _callGeminiVfm(
          itemName: itemName,
          proposedPrice: proposedPrice,
          todayRemainingQuota: todayRemainingQuota,
          apiKey: geminiApiKey,
        );
        if (apiResult != null) return apiResult;
      } catch (_) {
        // Fall back to rule-based engine
      }
    }

    return _ruleBasedVfmAnalysis(
      itemName: itemName,
      proposedPrice: proposedPrice,
      todayRemainingQuota: todayRemainingQuota,
      todayBaseQuota: todayBaseQuota,
      userMenu: userMenu,
    );
  }

  static VfmAnalysisResult _ruleBasedVfmAnalysis({
    required String itemName,
    required double proposedPrice,
    required double todayRemainingQuota,
    required double todayBaseQuota,
    List<PersonalMenuStat> userMenu = const [],
  }) {
    final cleanName = itemName.trim().toLowerCase();
    final quotaPct = todayRemainingQuota > 0
        ? ((proposedPrice / todayRemainingQuota) * 100).clamp(0, 999).toDouble()
        : 100.0;

    String verdict;
    String reasoning;
    List<String> alternatives = [];
    double savings = 0.0;
    String tomorrowImpact;

    if (quotaPct > 80) {
      verdict = '🚨 Heavy Splurge (Quota Alert)';
      reasoning =
          'At ₹${proposedPrice.toStringAsFixed(0)}, this single purchase consumes ${quotaPct.toStringAsFixed(0)}% of your remaining daily budget (₹${todayRemainingQuota.toStringAsFixed(0)}). It will drag down your daily quota for the rest of the month.';
      tomorrowImpact = 'Tomorrow\'s daily limit will drop by approx ₹${(proposedPrice / 15).toStringAsFixed(0)}/day.';
    } else if (quotaPct > 40) {
      verdict = '⚠️ Moderate Splurge';
      reasoning =
          '₹${proposedPrice.toStringAsFixed(0)} takes a noticeable ${quotaPct.toStringAsFixed(0)}% bite out of your remaining ₹${todayRemainingQuota.toStringAsFixed(0)} limit for today. You will need to keep other meals very light.';
      tomorrowImpact = 'Manageable if dinner is kept frugal, or consider funding from Weekend Dhamaka.';
    } else {
      verdict = '✅ Safe & Budget-Friendly';
      reasoning =
          'Spending ₹${proposedPrice.toStringAsFixed(0)} is only ${quotaPct.toStringAsFixed(0)}% of today\'s remaining quota (₹${todayRemainingQuota.toStringAsFixed(0)}). You are comfortably within your financial buffer.';
      tomorrowImpact = 'Zero negative impact on upcoming daily quotas.';
    }

    // Specific Alternatives Mapping
    if (cleanName.contains('biryani')) {
      if (proposedPrice >= 200) {
        alternatives = [
          'Egg Biryani or Half-Chicken Biryani from local military/handi mess (₹110-₹130)',
          'Chicken Shawarma / Kathi Roll meal (₹100-₹120)',
          'South Indian Unlimited Meals / Thali (₹80-₹100)',
          'Wait for Weekend Dhamaka: Save this ₹${proposedPrice.toStringAsFixed(0)} to splurge guilt-free on Saturday!',
        ];
        savings = proposedPrice - 120.0;
      } else {
        alternatives = [
          'Chicken Biryani at ₹${proposedPrice.toStringAsFixed(0)} is already well-priced compared to high-end restaurant averages (₹280-₹350).',
          'Pair with a ₹15 local lime soda instead of a ₹60 soft drink to save extra.',
        ];
        savings = 45.0;
      }
    } else if (cleanName.contains('coffee') || cleanName.contains('cappuccino') || cleanName.contains('latte')) {
      if (proposedPrice >= 120) {
        alternatives = [
          'Authentic South Indian Filter Coffee at local Darshini (₹20-₹30)',
          'Cold Coffee with Ice Cream from local juice bar (₹60-₹70)',
          'Brewed Americano / Pour-over at home (₹15)',
        ];
        savings = proposedPrice - 30.0;
      } else {
        alternatives = [
          '₹${proposedPrice.toStringAsFixed(0)} is reasonable for crafted coffee.',
        ];
        savings = 0.0;
      }
    } else if (cleanName.contains('pizza') || cleanName.contains('burger')) {
      if (proposedPrice >= 200) {
        alternatives = [
          'Grilled Cheese Corn Sandwich from street stall (₹60-₹80)',
          'Desi Paneer/Chicken Burger from local bakery/cafe (₹80-₹110)',
          'Medium Pizza weekday combo deal instead of solo large (saves ₹120)',
        ];
        savings = proposedPrice - 80.0;
      } else {
        alternatives = [
          'Within budget snack range. Avoid ordering add-on sugary sides.',
        ];
        savings = 0.0;
      }
    } else if (cleanName.contains('tea') || cleanName.contains('chai')) {
      if (proposedPrice >= 50) {
        alternatives = [
          'Authentic Cutting Chai from local tea stall (₹12-₹15)',
          'Kulhad Masala Tea with biscuits (₹20-₹25)',
        ];
        savings = proposedPrice - 15.0;
      } else {
        alternatives = [
          'Tea is one of your best value daily beverages! Enjoy it.',
        ];
        savings = 0.0;
      }
    } else {
      // Generic item alternatives
      if (proposedPrice > 150) {
        alternatives = [
          'Look for daily thali / combo plate at local dining hall (₹80-₹100)',
          'Order half-portion if dining alone (saves 40%)',
          'Put the difference of ₹${(proposedPrice * 0.4).toStringAsFixed(0)} into your Weekend Dhamaka fund!',
        ];
        savings = proposedPrice * 0.4;
      } else {
        alternatives = [
          'This item fits comfortably within typical Indian daily snacking/dining micro-budgets.',
        ];
        savings = 0.0;
      }
    }

    return VfmAnalysisResult(
      itemName: itemName,
      proposedPrice: proposedPrice,
      quotaPercentage: quotaPct,
      verdict: verdict,
      reasoning: reasoning,
      cheaperAlternatives: alternatives,
      potentialSavings: savings > 0 ? savings : 0.0,
      impactOnTomorrow: tomorrowImpact,
    );
  }

  static Future<VfmAnalysisResult?> _callGeminiVfm({
    required String itemName,
    required double proposedPrice,
    required double todayRemainingQuota,
    required String apiKey,
  }) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final prompt = '''
Analyze this spending decision for an Indian consumer using a dynamic daily budget app:
Item: "$itemName"
Price: ₹$proposedPrice
Today's Remaining Daily Quota: ₹$todayRemainingQuota

Output JSON with keys:
- "verdict": Short verdict (e.g. "Safe Pick", "Moderate Splurge", "Heavy Splurge")
- "reasoning": 2-3 sentence honest advice evaluating if it is worth it and its budget impact
- "cheaper_alternatives": array of 2-3 specific cheaper/tastier Indian food/drink alternatives with realistic INR prices
- "potential_savings": number in INR saved if taking the cheaper alternative
- "tomorrow_impact": 1 sentence describing impact on tomorrow's quota
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final raw = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final clean = raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final map = jsonDecode(clean);

      final quotaPct = todayRemainingQuota > 0
          ? ((proposedPrice / todayRemainingQuota) * 100).clamp(0, 999).toDouble()
          : 100.0;

      return VfmAnalysisResult(
        itemName: itemName,
        proposedPrice: proposedPrice,
        quotaPercentage: quotaPct,
        verdict: map['verdict'] ?? 'VFM Analysis',
        reasoning: map['reasoning'] ?? '',
        cheaperAlternatives: (map['cheaper_alternatives'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
        potentialSavings: (map['potential_savings'] as num?)?.toDouble() ?? 0.0,
        impactOnTomorrow: map['tomorrow_impact'] ?? '',
      );
    }
    return null;
  }
}
