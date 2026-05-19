import '../../domain/entities/selected_add_on_entity.dart';

class SelectedAddOnDto {
  const SelectedAddOnDto({
    required this.addOnId,
    required this.name,
    required this.price,
    required this.priceType,
  });

  final String addOnId;
  final String name;
  final int price;
  final String priceType;

  factory SelectedAddOnDto.fromMap(Map<String, dynamic> map) =>
      SelectedAddOnDto(
        addOnId: map['addOnId'] as String? ?? '',
        name: map['name'] as String? ?? '',
        price: (map['price'] as num?)?.toInt() ?? 0,
        priceType: map['priceType'] as String? ?? 'per_booking',
      );

  SelectedAddOnEntity toEntity() => SelectedAddOnEntity(
    addOnId: addOnId,
    name: name,
    price: price,
    priceType: priceType,
  );
}
