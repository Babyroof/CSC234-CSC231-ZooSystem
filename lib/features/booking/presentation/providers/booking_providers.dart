import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../constants/booking_pricing.dart';
import '../../data/datasources/add_on_remote_datasource.dart';
import '../../data/datasources/booking_remote_datasource.dart';
import '../../data/datasources/payment_remote_datasource.dart';
import '../../data/datasources/pricing_remote_datasource.dart';
import '../../data/repositories/add_on_repository_impl.dart';
import '../../data/repositories/booking_repository_impl.dart';
import '../../data/repositories/payment_repository_impl.dart';
import '../../data/repositories/pricing_repository_impl.dart';
import '../../domain/entities/add_on_entity.dart';
import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/add_on_repository.dart';
import '../../domain/repositories/booking_repository.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/repositories/pricing_repository.dart';
import '../../domain/usecases/create_booking_usecase.dart';
import '../../domain/usecases/create_payment_charge_usecase.dart';
import '../../domain/usecases/delete_booking_usecase.dart';
import '../../domain/usecases/get_active_add_ons_usecase.dart';
import '../../domain/usecases/get_past_bookings_usecase.dart';
import '../../domain/usecases/get_pricing_usecase.dart';
import '../../domain/usecases/get_upcoming_bookings_usecase.dart';
import '../../domain/usecases/update_booking_status_usecase.dart';
import '../../domain/usecases/update_charge_id_usecase.dart';
import '../../domain/usecases/watch_booking_usecase.dart';

part 'booking_providers.g.dart';

// ── Datasources ───────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
BookingRemoteDataSource bookingRemoteDataSource(Ref ref) =>
    BookingRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
AddOnRemoteDataSource addOnRemoteDataSource(Ref ref) =>
    AddOnRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
PaymentRemoteDataSource paymentRemoteDataSource(Ref ref) =>
    PaymentRemoteDataSourceImpl();

@Riverpod(keepAlive: true)
PricingRemoteDataSource pricingRemoteDataSource(Ref ref) =>
    PricingRemoteDataSourceImpl();

// ── Repositories ──────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
BookingRepository bookingRepository(Ref ref) =>
    BookingRepositoryImpl(ref.watch(bookingRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
AddOnRepository addOnRepository(Ref ref) =>
    AddOnRepositoryImpl(ref.watch(addOnRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
PaymentRepository paymentRepository(Ref ref) =>
    PaymentRepositoryImpl(ref.watch(paymentRemoteDataSourceProvider));

@Riverpod(keepAlive: true)
PricingRepository pricingRepository(Ref ref) =>
    PricingRepositoryImpl(ref.watch(pricingRemoteDataSourceProvider));

// ── Use Cases ─────────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
CreateBookingUseCase createBookingUseCase(Ref ref) =>
    CreateBookingUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
UpdateBookingStatusUseCase updateBookingStatusUseCase(Ref ref) =>
    UpdateBookingStatusUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
UpdateChargeIdUseCase updateChargeIdUseCase(Ref ref) =>
    UpdateChargeIdUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
WatchBookingUseCase watchBookingUseCase(Ref ref) =>
    WatchBookingUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
GetUpcomingBookingsUseCase getUpcomingBookingsUseCase(Ref ref) =>
    GetUpcomingBookingsUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
GetPastBookingsUseCase getPastBookingsUseCase(Ref ref) =>
    GetPastBookingsUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
DeleteBookingUseCase deleteBookingUseCase(Ref ref) =>
    DeleteBookingUseCase(ref.watch(bookingRepositoryProvider));

@Riverpod(keepAlive: true)
GetActiveAddOnsUseCase getActiveAddOnsUseCase(Ref ref) =>
    GetActiveAddOnsUseCase(ref.watch(addOnRepositoryProvider));

@Riverpod(keepAlive: true)
CreatePaymentChargeUseCase createPaymentChargeUseCase(Ref ref) =>
    CreatePaymentChargeUseCase(ref.watch(paymentRepositoryProvider));

@Riverpod(keepAlive: true)
GetPricingUseCase getPricingUseCase(Ref ref) =>
    GetPricingUseCase(ref.watch(pricingRepositoryProvider));

// ── Stream Providers ──────────────────────────────────────────────────────────

@riverpod
Stream<List<AddOnEntity>> activeAddOns(Ref ref) =>
    ref.watch(getActiveAddOnsUseCaseProvider).call();

@riverpod
Stream<List<BookingEntity>> upcomingBookings(Ref ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(getUpcomingBookingsUseCaseProvider).call(uid);
}

@riverpod
Stream<List<BookingEntity>> pastBookings(Ref ref) {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return Stream.value([]);
  return ref.read(getPastBookingsUseCaseProvider).call(uid);
}

// ── Booking Form State ────────────────────────────────────────────────────────

class BookingFormState {
  const BookingFormState({
    this.selectedDate,
    this.adultCount = 0,
    this.kidCount = 0,
    this.elderCount = 0,
    this.selectedAddOnIds = const {},
    this.loadedAddOns = const [],
    this.adultPrice = BookingPricing.adultPrice,
    this.kidPrice = BookingPricing.kidPrice,
    this.elderPrice = BookingPricing.elderPrice,
  });

  final DateTime? selectedDate;
  final int adultCount;
  final int kidCount;
  final int elderCount;
  final Set<String> selectedAddOnIds;
  final List<AddOnEntity> loadedAddOns;
  final int adultPrice;
  final int kidPrice;
  final int elderPrice;

  int get totalPeople => adultCount + kidCount + elderCount;

  int get ticketTotal =>
      adultCount * adultPrice + kidCount * kidPrice + elderCount * elderPrice;

  int get addOnTotal => loadedAddOns
      .where((a) => selectedAddOnIds.contains(a.id))
      .fold(0, (acc, a) => acc + a.calculatePrice(totalPeople));

  BookingFormState copyWith({
    DateTime? selectedDate,
    int? adultCount,
    int? kidCount,
    int? elderCount,
    Set<String>? selectedAddOnIds,
    List<AddOnEntity>? loadedAddOns,
    int? adultPrice,
    int? kidPrice,
    int? elderPrice,
  }) => BookingFormState(
    selectedDate: selectedDate ?? this.selectedDate,
    adultCount: adultCount ?? this.adultCount,
    kidCount: kidCount ?? this.kidCount,
    elderCount: elderCount ?? this.elderCount,
    selectedAddOnIds: selectedAddOnIds ?? this.selectedAddOnIds,
    loadedAddOns: loadedAddOns ?? this.loadedAddOns,
    adultPrice: adultPrice ?? this.adultPrice,
    kidPrice: kidPrice ?? this.kidPrice,
    elderPrice: elderPrice ?? this.elderPrice,
  );
}

@riverpod
class BookingFormNotifier extends _$BookingFormNotifier {
  @override
  BookingFormState build() {
    _loadPricing();
    return const BookingFormState();
  }

  Future<void> _loadPricing() async {
    final pricing = await ref.read(getPricingUseCaseProvider).call();
    try {
      state = state.copyWith(
        adultPrice: pricing['adultPrice'] ?? BookingPricing.adultPrice,
        kidPrice: pricing['childPrice'] ?? BookingPricing.kidPrice,
        elderPrice: pricing['elderPrice'] ?? BookingPricing.elderPrice,
      );
    } catch (_) {}
  }

  void setDate(DateTime d) => state = state.copyWith(selectedDate: d);

  void incrementAdult() =>
      state = state.copyWith(adultCount: state.adultCount + 1);
  void decrementAdult() {
    if (state.adultCount > 0)
      state = state.copyWith(adultCount: state.adultCount - 1);
  }

  void incrementKid() => state = state.copyWith(kidCount: state.kidCount + 1);
  void decrementKid() {
    if (state.kidCount > 0)
      state = state.copyWith(kidCount: state.kidCount - 1);
  }

  void incrementElder() =>
      state = state.copyWith(elderCount: state.elderCount + 1);
  void decrementElder() {
    if (state.elderCount > 0)
      state = state.copyWith(elderCount: state.elderCount - 1);
  }

  void toggleAddOn(String addOnId) {
    final current = Set<String>.from(state.selectedAddOnIds);
    if (current.contains(addOnId)) {
      current.remove(addOnId);
    } else {
      current.add(addOnId);
    }
    state = state.copyWith(selectedAddOnIds: current);
  }

  void setLoadedAddOns(List<AddOnEntity> addOns) =>
      state = state.copyWith(loadedAddOns: addOns);
}
