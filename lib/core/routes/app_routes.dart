import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/features/booking/screens/booking_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/screens/payment_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/screens/ticket_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/screens/event_info_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/screens/event_screen.dart';
import 'package:zoopernova_zoo_system/features/map/screens/map_screen.dart';
import 'package:zoopernova_zoo_system/features/map/screens/qr_scan_screen.dart';
import 'package:zoopernova_zoo_system/features/profile/screens/profile_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/screens/login_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/screens/register_screen.dart';
import '../../core/widgets/main_wrapper.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/animals_info/screens/animal_screen.dart';
import '../../features/animals_info/screens/animal_info_screen.dart';
import '../../features/events_show/models/event_model.dart';

class AppRoute {
  static const String login = '/login';
  static const String register = '/register';
  static const String main = '/main';
  static const String home = '/home';
  static const String events = '/events';
  static const String eventsInfo = '/events_info';
  static const String animals = '/animals';
  static const String animalInfo = '/animal_info';
  static const String map = '/map';
  static const String booking = '/booking';
  static const String payment = '/payment';
  static const String ticket = '/ticket';
  static const String profile = '/profile';
  static const String qrScan = '/qr_scan';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      login: (context) => const LoginScreen(),
      register: (context) => const RegisterScreen(),
      main: (context) => const MainWrapperScreen(),
      home: (context) => const HomeScreen(),
      events: (context) => const EventScreen(),
      eventsInfo: (context) {
        final args = ModalRoute.of(context)!.settings.arguments;

        if (args is EventModel) {
          return EventInfoScreen(event: args);
        }
        return const Scaffold(body: Center(child: Text('No Event Data')));
      },
      animals: (context) => const AnimalScreen(),
      animalInfo: (context) => const AnimalInfoScreen(),
      map: (context) => const MapScreen(),
      booking: (context) => const BookingScreen(),
      payment: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>? ??
            const {};
        return PaymentScreen(bookingArgs: args);
      },
      ticket: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>? ??
            const {};
        return TicketScreen(bookingArgs: args);
      },
      profile: (context) => const ProfileScreen(),
      qrScan: (context) => const QrScanScreen(),
    };
  }
}
