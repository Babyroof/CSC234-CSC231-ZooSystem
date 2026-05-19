class SelectedAddOnEntity {
  const SelectedAddOnEntity({
    required this.addOnId,
    required this.name,
    required this.price,
    required this.priceType,
  });

  factory SelectedAddOnEntity.fromMap(Map<String, dynamic> map) =>
      SelectedAddOnEntity(
        addOnId: map['addOnId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        priceType: map['priceType'] as String? ?? 'per_booking',
      );

  final String addOnId;
  final String name;
  final int price;
  final String priceType;

  int calculatePrice(int totalPeople) {
    if (priceType == 'per_person') return price * totalPeople;
    return price;
  }

  Map<String, dynamic> toMap() => {
    'addOnId': addOnId,
    'name': name,
    'price': price,
    'priceType': priceType,
  };
}
