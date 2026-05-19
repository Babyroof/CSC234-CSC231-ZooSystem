import '../entities/booking_entity.dart';

abstract class BookingRepository {
  Future<String> createBooking(BookingEntity booking);
  Future<void> updateStatus({
    required String bookingId,
    required String status,
  });
  Future<void> updateChargeId({
    required String bookingId,
    required String chargeId,
  });
  Future<BookingEntity?> getBookingById(String bookingId);
  Stream<BookingEntity?> watchBooking(String bookingId);
  Stream<List<BookingEntity>> getUpcomingBookings(String userId);
  Stream<List<BookingEntity>> getPastBookings(String userId);
  Future<void> deleteBooking(String bookingId);
}
