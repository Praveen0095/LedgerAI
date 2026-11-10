class TransactionItem {
  final String id;
  final String name;
  final double price;
  final int quantity;
  final String? notes;

  TransactionItem({
    required this.id,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes,
  });

  double get total => price * quantity;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'quantity': quantity,
        'notes': notes,
      };

  factory TransactionItem.fromJson(Map<String, dynamic> json) => TransactionItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: (json['price'] as num).toDouble(),
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        notes: json['notes'] as String?,
      );
}
