import '../../domain/entities/booking_entity.dart';
import '../../domain/repositories/booking_repository.dart';
import '../datasources/booking_remote_datasource.dart';

class BookingRepositoryImpl implements BookingRepository {
  const BookingRepositoryImpl(this._dataSource);
  final BookingRemoteDataSource _dataSource;

  @override
  Future<String> createBooking(BookingEntity booking) =>
      _dataSource.createBooking(booking);

  @override
  Future<void> updateStatus({
    required String bookingId,
    required String status,
  }) => _dataSource.updateStatus(bookingId: bookingId, status: status);

  @override
  Future<void> updateChargeId({
    required String bookingId,
    required String chargeId,
  }) => _dataSource.updateChargeId(bookingId: bookingId, chargeId: chargeId);

  @override
  Future<BookingEntity?> getBookingById(String bookingId) async {
    final dto = await _dataSource.getBookingById(bookingId);
    return dto?.toEntity();
  }

  @override
  Stream<BookingEntity?> watchBooking(String bookingId) =>
      _dataSource.watchBooking(bookingId).map((dto) => dto?.toEntity());

  @override
  Stream<List<BookingEntity>> getUpcomingBookings(String userId) => _dataSource
      .getUpcomingBookings(userId)
      .map((dtos) => dtos.map((d) => d.toEntity()).toList());

  @override
  Stream<List<BookingEntity>> getPastBookings(String userId) => _dataSource
      .getPastBookings(userId)
      .map((dtos) => dtos.map((d) => d.toEntity()).toList());

  @override
  Future<void> deleteBooking(String bookingId) =>
      _dataSource.deleteBooking(bookingId);
}
