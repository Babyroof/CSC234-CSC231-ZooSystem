class AddOnEntity {
  const AddOnEntity({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
    required this.order,
    this.priceType = 'per_booking',
  });

  final String id;
  final String name;
  final int price;
  final bool isActive;
  final int order;
  final String priceType;

  int calculatePrice(int totalPeople) {
    if (priceType == 'per_person') return price * totalPeople;
    return price;
  }
}
