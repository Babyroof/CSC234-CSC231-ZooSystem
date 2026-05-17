import 'package:zoopernova_zoo_system/features/booking/models/selected_add_on_model.dart';

class BookingAdminModel {
  final String id;
  final String userId;
  final String userName;
  final int adultTotal;
  final int childTotal;
  final int elderTotal;
  final DateTime date;
  final List<SelectedAddOnModel> selectedAddOns;
  final String status;

  const BookingAdminModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.adultTotal,
    required this.childTotal,
    required this.elderTotal,
    required this.date,
    required this.selectedAddOns,
    required this.status,
  });

  int get totalTickets => adultTotal + childTotal + elderTotal;

  // TODO (backend): service layer must convert Firestore Timestamp → DateTime before calling fromMap
  factory BookingAdminModel.fromMap(
    String id,
    Map<String, dynamic> map,
    String userName,
  ) {
    final rawAddOns = map['selectedAddOns'];
    final addOns = <SelectedAddOnModel>[];
    if (rawAddOns is List) {
      for (final item in rawAddOns) {
        if (item is Map<String, dynamic>) {
          addOns.add(SelectedAddOnModel.fromMap(item));
        }
      }
    }

    return BookingAdminModel(
      id: id,
      userId: map['userId'] ?? '',
      userName: userName,
      adultTotal: (map['adultTotal'] as num?)?.toInt() ?? 0,
      childTotal: (map['childTotal'] as num?)?.toInt() ?? 0,
      elderTotal: (map['elderTotal'] as num?)?.toInt() ?? 0,
      date: (map['date'] as DateTime?) ?? DateTime.now(),
      selectedAddOns: addOns,
      status: map['status'] ?? 'pending',
    );
  }
}
