import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/transaction_item.dart';

/// PayPal Integration Service for PayPal AI Hackathon
/// Connects PayPal Checkout / Orders API with the Multimodal AI Itemizer
class PayPalService {
  // Sandbox API configuration
  static const String sandboxBaseUrl = 'https://api-m.sandbox.paypal.com';

  /// 1. Create a PayPal Order with metadata (Orders v2 API)
  static Future<Map<String, dynamic>> createOrder({
    required double amount,
    required String currency,
    required String payeeName,
    String? accessToken,
  }) async {
    // If no access token provided in demo mode, return mock order response
    if (accessToken == null || accessToken.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'id': 'PAYPAL-ORD-${DateTime.now().millisecondsSinceEpoch}',
        'status': 'CREATED',
        'amount': amount,
        'currency': currency,
        'payee': payeeName,
      };
    }

    final url = Uri.parse('$sandboxBaseUrl/v2/checkout/orders');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        "intent": "CAPTURE",
        "purchase_units": [
          {
            "amount": {
              "currency_code": currency,
              "value": amount.toStringAsFixed(2),
            },
            "description": "Daily ledger spend at $payeeName"
          }
        ]
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('PayPal Orders API error: ${response.statusCode}');
    }
  }

  /// 2. Capture payment from PayPal
  static Future<Map<String, dynamic>> captureOrder({
    required String orderId,
    String? accessToken,
  }) async {
    if (accessToken == null || accessToken.isEmpty) {
      await Future.delayed(const Duration(milliseconds: 600));
      return {
        'id': orderId,
        'status': 'COMPLETED',
        'capture_id': 'CAPTURE-${DateTime.now().millisecondsSinceEpoch}',
      };
    }

    final url = Uri.parse('$sandboxBaseUrl/v2/checkout/orders/$orderId/capture');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      throw Exception('PayPal Capture API error: ${response.statusCode}');
    }
  }

  /// 3. AI + PayPal Synergy: Attach AI-extracted line items to PayPal Invoicing / Transaction record
  static Map<String, dynamic> buildPayPalItemizedPayload({
    required String paypalOrderId,
    required String merchantName,
    required List<TransactionItem> aiExtractedItems,
    required double totalAmount,
  }) {
    return {
      'paypal_transaction_id': paypalOrderId,
      'merchant': merchantName,
      'total_amount': totalAmount,
      'source': 'PayPal_AI_Ledger',
      'items': aiExtractedItems.map((item) => {
        'name': item.name,
        'unit_amount': item.price,
        'quantity': item.quantity,
        'total': item.total,
      }).toList(),
      'ai_parsed_at': DateTime.now().toIso8601String(),
    };
  }
}
