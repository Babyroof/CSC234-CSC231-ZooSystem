import '../entities/add_on_entity.dart';

abstract class AddOnRepository {
  Stream<List<AddOnEntity>> getActiveAddOns();
}
