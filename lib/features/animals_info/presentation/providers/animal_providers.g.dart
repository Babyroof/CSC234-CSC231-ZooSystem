// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'animal_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$animalRemoteDataSourceHash() =>
    r'8ad86f1ef71b159801f5f3607c114983f0cf554d';

/// See also [animalRemoteDataSource].
@ProviderFor(animalRemoteDataSource)
final animalRemoteDataSourceProvider =
    Provider<AnimalRemoteDataSource>.internal(
      animalRemoteDataSource,
      name: r'animalRemoteDataSourceProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$animalRemoteDataSourceHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnimalRemoteDataSourceRef = ProviderRef<AnimalRemoteDataSource>;
String _$animalRepositoryHash() => r'82def8522d34aceaaef8ffc27b3b870a356296ad';

/// See also [animalRepository].
@ProviderFor(animalRepository)
final animalRepositoryProvider = Provider<AnimalRepository>.internal(
  animalRepository,
  name: r'animalRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$animalRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnimalRepositoryRef = ProviderRef<AnimalRepository>;
String _$getAnimalsUseCaseHash() => r'a520dca106ffa82e7aa87683de1400add375eb9a';

/// See also [getAnimalsUseCase].
@ProviderFor(getAnimalsUseCase)
final getAnimalsUseCaseProvider = Provider<GetAnimalsUseCase>.internal(
  getAnimalsUseCase,
  name: r'getAnimalsUseCaseProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$getAnimalsUseCaseHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetAnimalsUseCaseRef = ProviderRef<GetAnimalsUseCase>;
String _$getAnimalsWithZoneUseCaseHash() =>
    r'923792358e69909f861d3d09dd9e5ff2212cd906';

/// See also [getAnimalsWithZoneUseCase].
@ProviderFor(getAnimalsWithZoneUseCase)
final getAnimalsWithZoneUseCaseProvider =
    Provider<GetAnimalsWithZoneUseCase>.internal(
      getAnimalsWithZoneUseCase,
      name: r'getAnimalsWithZoneUseCaseProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$getAnimalsWithZoneUseCaseHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef GetAnimalsWithZoneUseCaseRef = ProviderRef<GetAnimalsWithZoneUseCase>;
String _$animalsWithZoneHash() => r'36a2a5c8c05262c0737f066d2b34c037191c5b01';

/// See also [animalsWithZone].
@ProviderFor(animalsWithZone)
final animalsWithZoneProvider =
    AutoDisposeFutureProvider<List<AnimalWithZoneEntity>>.internal(
      animalsWithZone,
      name: r'animalsWithZoneProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$animalsWithZoneHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AnimalsWithZoneRef =
    AutoDisposeFutureProviderRef<List<AnimalWithZoneEntity>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
