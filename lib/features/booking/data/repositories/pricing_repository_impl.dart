import '../../domain/repositories/pricing_repository.dart';
import '../datasources/pricing_remote_datasource.dart';

class PricingRepositoryImpl implements PricingRepository {
  const PricingRepositoryImpl(this._dataSource);
  final PricingRemoteDataSource _dataSource;

  @override
  Future<Map<String, int>> getPricing() => _dataSource.getPricing();
}
