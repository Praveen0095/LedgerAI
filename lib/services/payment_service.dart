import 'package:url_launcher/url_launcher.dart';
import '../models/transaction_record.dart';

class ParsedPaymentInfo {
  final String payeeName;
  final String? payeeVpaOrEmail;
  final double? amount;
  final PaymentSource source;
  final String rawData;

  ParsedPaymentInfo({
    required this.payeeName,
    this.payeeVpaOrEmail,
    this.amount,
    required this.source,
    required this.rawData,
  });
}

class PaymentService {
  /// Parses a UPI QR string (e.g. upi://pay?pa=vendor@upi&pn=VendorName&am=50)
  /// or a PayPal QR / Link (e.g. paypal.me/randomname/420 or https://paypal.me/randomname/420)
  static ParsedPaymentInfo parseQr(String rawData) {
    final trimmed = rawData.trim();

    // 1. UPI QR parser
    if (trimmed.startsWith('upi://pay')) {
      final uri = Uri.tryParse(trimmed);
      if (uri != null) {
        final pa = uri.queryParameters['pa'] ?? '';
        final pn = uri.queryParameters['pn'] ?? (pa.isNotEmpty ? pa.split('@').first : 'Merchant');
        final amStr = uri.queryParameters['am'];
        final am = amStr != null ? double.tryParse(amStr) : null;

        return ParsedPaymentInfo(
          payeeName: Uri.decodeComponent(pn),
          payeeVpaOrEmail: pa,
          amount: am,
          source: PaymentSource.upi,
          rawData: rawData,
        );
      }
    }

    // 2. PayPal Link / QR parser (e.g. paypal.me/randomname/420)
    if (trimmed.toLowerCase().contains('paypal.me') ||
        trimmed.toLowerCase().contains('paypal.com')) {
      // Ensure scheme for reliable Uri parsing
      final sanitizedUrl = trimmed.startsWith('http://') || trimmed.startsWith('https://')
          ? trimmed
          : 'https://$trimmed';
      final uri = Uri.tryParse(sanitizedUrl);

      String payee = 'PayPal Merchant';
      double? amount;

      if (uri != null && uri.pathSegments.isNotEmpty) {
        // e.g. pathSegments: ["randomname", "420"]
        // The first segment is ALWAYS the username / payee
        payee = uri.pathSegments[0];

        // If there is a second segment, check if it's the payment amount
        if (uri.pathSegments.length > 1) {
          final possibleAmt = double.tryParse(uri.pathSegments[1]);
          if (possibleAmt != null && possibleAmt > 0) {
            amount = possibleAmt;
          }
        }
      } else {
        // Regex fallback for raw paypal.me/randomname/420
        final paypalRegex = RegExp(r'paypal\.me\/([^\/\s\?]+)(?:\/(\d+(?:\.\d{1,2})?))?', caseSensitive: false);
        final match = paypalRegex.firstMatch(trimmed);
        if (match != null) {
          payee = match.group(1) ?? 'PayPal Merchant';
          if (match.group(2) != null) {
            amount = double.tryParse(match.group(2)!);
          }
        }
      }

      return ParsedPaymentInfo(
        payeeName: payee,
        payeeVpaOrEmail: trimmed,
        amount: amount,
        source: PaymentSource.paypal,
        rawData: rawData,
      );
    }

    // Fallback: Generic Payee
    return ParsedPaymentInfo(
      payeeName: trimmed.length > 20 ? '${trimmed.substring(0, 18)}...' : trimmed,
      payeeVpaOrEmail: trimmed,
      source: PaymentSource.other,
      rawData: rawData,
    );
  }

  /// Launch external payment application via intent or URL
  static Future<bool> launchPaymentApp(String urlString) async {
    String sanitized = urlString.trim();
    if (sanitized.toLowerCase().startsWith('paypal.me')) {
      sanitized = 'https://$sanitized';
    }

    final uri = Uri.tryParse(sanitized);
    if (uri == null) return false;

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Fallback
    }
    return false;
  }
}
