class ItemPurchaseRecord {
  final double price;
  final int quantity;
  final String vendor;
  final DateTime date;
  final String location;

  ItemPurchaseRecord({
    required this.price,
    required this.quantity,
    required this.vendor,
    required this.date,
    this.location = 'Hosur, Tamil Nadu',
  });
}

class PersonalMenuStat {
  final String itemName;
  final int totalCount;
  final double totalSpent;
  final double averagePrice;
  final double lowestPrice;
  final String lowestPriceVendor;
  final double highestPrice;
  final String highestPriceVendor;
  final List<ItemPurchaseRecord> history;
  final String location;

  PersonalMenuStat({
    required this.itemName,
    required this.totalCount,
    required this.totalSpent,
    required this.averagePrice,
    required this.lowestPrice,
    required this.lowestPriceVendor,
    required this.highestPrice,
    required this.highestPriceVendor,
    required this.history,
    this.location = 'Hosur, Tamil Nadu',
  });
}
