import '../../domain/entities/add_on_entity.dart';
import '../../domain/repositories/add_on_repository.dart';
import '../datasources/add_on_remote_datasource.dart';

class AddOnRepositoryImpl implements AddOnRepository {
  const AddOnRepositoryImpl(this._dataSource);
  final AddOnRemoteDataSource _dataSource;

  @override
  Stream<List<AddOnEntity>> getActiveAddOns() => _dataSource
      .getActiveAddOns()
      .map((dtos) => dtos.map((d) => d.toEntity()).toList());
}
