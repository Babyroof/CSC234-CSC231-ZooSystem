import '../repositories/pricing_repository.dart';

class GetPricingUseCase {
  const GetPricingUseCase(this._repository);
  final PricingRepository _repository;
  Future<Map<String, int>> call() => _repository.getPricing();
}
