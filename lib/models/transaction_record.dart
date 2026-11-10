import 'transaction_item.dart';

enum PaymentSource { upi, paypal, cash, other }

class TransactionRecord {
  final String id;
  final String payeeName;
  final String? payeeVpaOrEmail;
  final double amount;
  final DateTime timestamp;
  final PaymentSource source;
  final List<TransactionItem> items;
  final String category;
  final bool isItemized;
  final String? remark;
  final String currency;
  final String location;
  final bool isRecoverable;
  final DateTime? repaymentDueDate;
  final int reminderDaysBefore;
  final bool isRepaid;

  TransactionRecord({
    required this.id,
    required this.payeeName,
    this.payeeVpaOrEmail,
    required this.amount,
    required this.timestamp,
    this.source = PaymentSource.upi,
    this.items = const [],
    this.category = 'General',
    this.isItemized = false,
    this.remark,
    this.currency = 'INR',
    this.location = 'Hosur, Tamil Nadu',
    this.isRecoverable = false,
    this.repaymentDueDate,
    this.reminderDaysBefore = 0,
    this.isRepaid = false,
  });

  TransactionRecord copyWith({
    String? payeeName,
    String? payeeVpaOrEmail,
    double? amount,
    DateTime? timestamp,
    PaymentSource? source,
    List<TransactionItem>? items,
    String? category,
    bool? isItemized,
    String? remark,
    String? currency,
    String? location,
    bool? isRecoverable,
    DateTime? repaymentDueDate,
    int? reminderDaysBefore,
    bool? isRepaid,
  }) {
    return TransactionRecord(
      id: id,
      payeeName: payeeName ?? this.payeeName,
      payeeVpaOrEmail: payeeVpaOrEmail ?? this.payeeVpaOrEmail,
      amount: amount ?? this.amount,
      timestamp: timestamp ?? this.timestamp,
      source: source ?? this.source,
      items: items ?? this.items,
      category: category ?? this.category,
      isItemized: isItemized ?? this.isItemized,
      remark: remark ?? this.remark,
      currency: currency ?? this.currency,
      location: location ?? this.location,
      isRecoverable: isRecoverable ?? this.isRecoverable,
      repaymentDueDate: repaymentDueDate ?? this.repaymentDueDate,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      isRepaid: isRepaid ?? this.isRepaid,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'payeeName': payeeName,
        'payeeVpaOrEmail': payeeVpaOrEmail,
        'amount': amount,
        'timestamp': timestamp.toIso8601String(),
        'source': source.name,
        'items': items.map((e) => e.toJson()).toList(),
        'category': category,
        'isItemized': isItemized,
        'remark': remark,
        'currency': currency,
        'location': location,
        'isRecoverable': isRecoverable,
        'repaymentDueDate': repaymentDueDate?.toIso8601String(),
        'reminderDaysBefore': reminderDaysBefore,
        'isRepaid': isRepaid,
      };

  factory TransactionRecord.fromJson(Map<String, dynamic> json) => TransactionRecord(
        id: json['id'] as String,
        payeeName: json['payeeName'] as String,
        payeeVpaOrEmail: json['payeeVpaOrEmail'] as String?,
        amount: (json['amount'] as num).toDouble(),
        timestamp: DateTime.parse(json['timestamp'] as String),
        source: PaymentSource.values.firstWhere(
          (e) => e.name == json['source'],
          orElse: () => PaymentSource.upi,
        ),
        items: (json['items'] as List<dynamic>?)
                ?.map((e) => TransactionItem.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        category: json['category'] as String? ?? 'General',
        isItemized: json['isItemized'] as bool? ?? false,
        remark: json['remark'] as String?,
        currency: json['currency'] as String? ?? 'INR',
        location: json['location'] as String? ?? 'Hosur, Tamil Nadu',
        isRecoverable: json['isRecoverable'] as bool? ?? false,
        repaymentDueDate: json['repaymentDueDate'] != null
            ? DateTime.tryParse(json['repaymentDueDate'] as String)
            : null,
        reminderDaysBefore: (json['reminderDaysBefore'] as num?)?.toInt() ?? 0,
        isRepaid: json['isRepaid'] as bool? ?? false,
      );
}
