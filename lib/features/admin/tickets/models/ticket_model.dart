import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:zoopernova_zoo_system/features/booking/models/selected_add_on_model.dart';

class TicketModel {
  final String id;
  final List<SelectedAddOnModel> selectedAddOns;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final String status;
  final DocumentReference userId;

  const TicketModel({
    required this.id,
    required this.selectedAddOns,
    required this.adultTotal,
    required this.childTotal,
    required this.elderTotal,
    required this.date,
    required this.status,
    required this.userId,
  });

  factory TicketModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime resolvedDate = DateTime.fromMillisecondsSinceEpoch(0);
    final rawDate = data['date'];
    if (rawDate is Timestamp) {
      resolvedDate = rawDate.toDate();
    }

    final rawAddOns = data['selectedAddOns'];
    final addOns = <SelectedAddOnModel>[];
    if (rawAddOns is List) {
      for (final item in rawAddOns) {
        if (item is Map<String, dynamic>) {
          addOns.add(SelectedAddOnModel.fromMap(item));
        }
      }
    }

    return TicketModel(
      id: doc.id,
      selectedAddOns: addOns,
      adultTotal: (data['adultTotal'] as num? ?? 0).toInt(),
      childTotal: (data['childTotal'] as num? ?? 0).toInt(),
      elderTotal: (data['elderTotal'] as num? ?? 0).toInt(),
      date: resolvedDate,
      status: data['status'] as String? ?? 'pending',
      userId: data['userId'] as DocumentReference,
    );
  }

  Map<String, dynamic> toMap() => {
    'selectedAddOns': selectedAddOns.map((a) => a.toMap()).toList(),
    'adultTotal': adultTotal,
    'childTotal': childTotal,
    'elderTotal': elderTotal,
    'date': Timestamp.fromDate(date),
    'status': status,
    'userId': userId,
  };

  TicketModel copyWith({
    String? id,
    List<SelectedAddOnModel>? selectedAddOns,
    int? adultTotal,
    int? childTotal,
    int? elderTotal,
    DateTime? date,
    String? status,
    DocumentReference? userId,
  }) => TicketModel(
    id: id ?? this.id,
    selectedAddOns: selectedAddOns ?? this.selectedAddOns,
    adultTotal: adultTotal ?? this.adultTotal,
    childTotal: childTotal ?? this.childTotal,
    elderTotal: elderTotal ?? this.elderTotal,
    date: date ?? this.date,
    status: status ?? this.status,
    userId: userId ?? this.userId,
  );
}
