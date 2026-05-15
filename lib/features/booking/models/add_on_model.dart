import 'package:cloud_firestore/cloud_firestore.dart';

class AddOnModel {
  final String id;
  final String name;
  final int price;
  final bool isActive;
  final int order;
  final String priceType; // "per_booking" or "per_person"

  const AddOnModel({
    required this.id,
    required this.name,
    required this.price,
    required this.isActive,
    required this.order,
    this.priceType = 'per_booking',
  });

  factory AddOnModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AddOnModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? false,
      order: (data['order'] as num?)?.toInt() ?? 0,
      priceType: data['priceType'] as String? ?? 'per_booking',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'price': price,
    'isActive': isActive,
    'order': order,
    'priceType': priceType,
  };

  AddOnModel copyWith({
    String? id,
    String? name,
    int? price,
    bool? isActive,
    int? order,
    String? priceType,
  }) => AddOnModel(
    id: id ?? this.id,
    name: name ?? this.name,
    price: price ?? this.price,
    isActive: isActive ?? this.isActive,
    order: order ?? this.order,
    priceType: priceType ?? this.priceType,
  );

  int calculatePrice(int totalPeople) {
    if (priceType == 'per_person') return price * totalPeople;
    return price;
  }
}
