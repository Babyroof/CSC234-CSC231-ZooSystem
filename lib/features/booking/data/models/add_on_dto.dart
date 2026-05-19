import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/add_on_entity.dart';

class AddOnDto {
  const AddOnDto({
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

  factory AddOnDto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AddOnDto(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      order: (data['order'] as num?)?.toInt() ?? 0,
      priceType: data['priceType'] as String? ?? 'per_booking',
    );
  }

  AddOnEntity toEntity() => AddOnEntity(
    id: id,
    name: name,
    price: price,
    isActive: isActive,
    order: order,
    priceType: priceType,
  );
}
