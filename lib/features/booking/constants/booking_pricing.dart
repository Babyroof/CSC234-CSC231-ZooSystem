// Ticket prices used as fallback when config/pricing document is unavailable.
// Add-on prices are fetched dynamically from the addOns Firestore collection.
class BookingPricing {
  const BookingPricing._();

  static const int adultPrice = 300;
  static const int kidPrice = 150;
  static const int elderPrice = 40;
}
