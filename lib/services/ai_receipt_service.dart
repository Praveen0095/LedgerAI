import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../models/transaction_item.dart';

class AiReceiptService {
  static const _uuid = Uuid();

  /// Parse natural language voice/text input into structured line items using Gemini or local heuristic
  static Future<List<TransactionItem>> parseTextPrompt({
    required String prompt,
    String? geminiApiKey,
  }) async {
    if (geminiApiKey != null && geminiApiKey.isNotEmpty) {
      try {
        return await _callGeminiText(prompt, geminiApiKey);
      } catch (_) {
        // Fallback to local heuristic parser if API fails or is offline
      }
    }
    return _localTextHeuristic(prompt);
  }

  /// Parse simulated or uploaded bill receipt
  static Future<List<TransactionItem>> parseBillReceipt({
    String? imageBase64,
    String? rawReceiptText,
    String? geminiApiKey,
  }) async {
    if (rawReceiptText != null && rawReceiptText.isNotEmpty) {
      return parseTextPrompt(prompt: rawReceiptText, geminiApiKey: geminiApiKey);
    }

    // Default simulated smart receipt parser for demo/hackathon presentations
    await Future.delayed(const Duration(milliseconds: 800));
    return [
      TransactionItem(
        id: _uuid.v4(),
        name: 'Special Masala Tea',
        price: 15.0,
        quantity: 1,
        notes: 'Chai tapri',
      ),
      TransactionItem(
        id: _uuid.v4(),
        name: 'Aloo Samosa',
        price: 20.0,
        quantity: 1,
        notes: 'Crispy snack',
      ),
    ];
  }

  static Future<List<TransactionItem>> _callGeminiText(String text, String apiKey) async {
    final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

    final systemInstruction = '''
You are an AI financial receipt parser. Extract line items from the user's spending text or receipt.
Format rules:
- Format "1 tea 15" means 1 quantity of "Tea" with unit price 15.0.
- Format "2 tea for 30" means 2 quantity of "Tea" with unit price 15.0.
Return ONLY a valid JSON array of objects with keys:
- "name": string (clean item name, capitalized)
- "price": number (unit price per single item)
- "quantity": integer (number of units)
Example: [{"name": "Tea", "price": 15.0, "quantity": 1}, {"name": "Samosa", "price": 20.0, "quantity": 1}]
''';

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": "$systemInstruction\nInput text to parse: $text"}
            ]
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final rawResponse = data['candidates'][0]['content']['parts'][0]['text'] as String;
      final cleanJson = rawResponse.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> parsedList = jsonDecode(cleanJson);

      return parsedList.map((item) {
        return TransactionItem(
          id: _uuid.v4(),
          name: _capitalizeWords((item['name'] as String).trim()),
          price: (item['price'] as num).toDouble(),
          quantity: (item['quantity'] as num?)?.toInt() ?? 1,
        );
      }).toList();
    } else {
      throw Exception('Gemini API Error: ${response.statusCode}');
    }
  }

  /// High-accuracy rule-based parser that properly distinguishes Quantity, Name, and Price
  static List<TransactionItem> _localTextHeuristic(String text) {
    final items = <TransactionItem>[];

    // Split compound sentences (e.g. "1 tea 15 and 1 samosa 20" or multiline receipts)
    final lines = text
        .split(RegExp(r'[\n,;]|(?:\s+and\s+)', caseSensitive: false))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);

    // Pattern 1: Starts with quantity, e.g. "1 tea 15", "2 tea for 30", "1 samosa 20", "2 coffee @ 40"
    final qtyFirstRegex = RegExp(
      r'^(\d+)\s+([a-zA-Z\s]+?)\s+(?:for\s+|at\s+|@\s*|rs\.?|₹|\$)?\s*(\d+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    );

    // Pattern 2: Name with explicit multiplier, e.g. "tea x 2 30" or "tea * 2 for 30"
    final nameMultiplierRegex = RegExp(
      r'^([a-zA-Z\s]+?)\s+(?:x|\*)\s*(\d+)\s+(?:for\s+|at\s+|@\s*|rs\.?|₹|\$)?\s*(\d+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    );

    // Pattern 3: Name followed by price, e.g. "tea 15", "samosa 20", "coffee for 60"
    final namePriceRegex = RegExp(
      r'^([a-zA-Z\s]+?)\s+(?:for\s+|at\s+|@\s*|rs\.?|₹|\$)?\s*(\d+(?:\.\d{1,2})?)$',
      caseSensitive: false,
    );

    for (final line in lines) {
      // Check Pattern 1: "1 tea 15"
      final match1 = qtyFirstRegex.firstMatch(line);
      if (match1 != null) {
        final qty = int.tryParse(match1.group(1) ?? '1') ?? 1;
        final rawName = match1.group(2) ?? 'Item';
        final totalOrUnit = double.tryParse(match1.group(3) ?? '0') ?? 0.0;

        // If line specifies "for" or total amount (e.g. "2 tea for 30"), unit price is 15
        final bool isTotalStated = line.toLowerCase().contains('for');
        final double unitPrice = (qty > 1 && isTotalStated) ? (totalOrUnit / qty) : totalOrUnit;

        items.add(TransactionItem(
          id: _uuid.v4(),
          name: _capitalizeWords(rawName.trim()),
          price: unitPrice,
          quantity: qty,
        ));
        continue;
      }

      // Check Pattern 2: "tea x 2 30"
      final match2 = nameMultiplierRegex.firstMatch(line);
      if (match2 != null) {
        final rawName = match2.group(1) ?? 'Item';
        final qty = int.tryParse(match2.group(2) ?? '1') ?? 1;
        final totalOrUnit = double.tryParse(match2.group(3) ?? '0') ?? 0.0;
        final double unitPrice = qty > 1 ? (totalOrUnit / qty) : totalOrUnit;

        items.add(TransactionItem(
          id: _uuid.v4(),
          name: _capitalizeWords(rawName.trim()),
          price: unitPrice,
          quantity: qty,
        ));
        continue;
      }

      // Check Pattern 3: "tea 15"
      final match3 = namePriceRegex.firstMatch(line);
      if (match3 != null) {
        final rawName = match3.group(1) ?? 'Item';
        final price = double.tryParse(match3.group(2) ?? '0') ?? 0.0;

        items.add(TransactionItem(
          id: _uuid.v4(),
          name: _capitalizeWords(rawName.trim()),
          price: price,
          quantity: 1,
        ));
        continue;
      }

      // Fallback: extract last number as price and remainder as name
      final allNumbers = RegExp(r'(\d+(?:\.\d{1,2})?)').allMatches(line).toList();
      if (allNumbers.isNotEmpty) {
        final lastNumberMatch = allNumbers.last;
        final price = double.tryParse(lastNumberMatch.group(1) ?? '0') ?? 0.0;
        final namePart = line.substring(0, lastNumberMatch.start).replaceAll(RegExp(r'for|at|rs|₹|@'), '').trim();

        items.add(TransactionItem(
          id: _uuid.v4(),
          name: _capitalizeWords(namePart.isEmpty ? 'Item' : namePart),
          price: price,
          quantity: 1,
        ));
      } else {
        items.add(TransactionItem(
          id: _uuid.v4(),
          name: _capitalizeWords(line),
          price: 0.0,
          quantity: 1,
        ));
      }
    }

    return items;
  }

  static String _capitalizeWords(String input) {
    if (input.isEmpty) return input;
    return input.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }
}
