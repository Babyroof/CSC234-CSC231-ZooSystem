import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/services/remote_config_service.dart';
import '../../../animals_info/domain/entities/animal_with_zone_entity.dart';
import '../../../animals_info/presentation/providers/animal_providers.dart';

part 'home_providers.g.dart';

@riverpod
Future<List<AnimalWithZoneEntity>> homePopularAnimals(Ref ref) async {
  final animals = await ref.watch(animalsWithZoneProvider.future);
  final shuffled = List<AnimalWithZoneEntity>.from(animals)..shuffle();
  return shuffled.take(4).toList();
}

@riverpod
bool featurePopularAnimals(Ref ref) =>
    RemoteConfigService.featurePopularAnimals;
