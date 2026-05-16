import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/core/widgets/admin_guard.dart';
import 'package:zoopernova_zoo_system/features/admin/auth/screens/admin_login_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/auth/screens/admin_register_screen.dart';
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
import '../../features/admin/animals/screens/animalAdmin.dart';
import '../../features/admin/animals/screens/addAnimalAdmin_screen.dart';
import '../../features/admin/tickets/screens/bookingAdmin_screen.dart';
import '../../features/admin/events/screens/eventAdmin_screen.dart';
import '../../features/admin/maps/screens/mapAdmin_screen.dart';
import '../../features/admin/maps/screens/mapUploadedAdmin.dart';
import '../../features/admin/maps/screens/mapEditAdmin_screen.dart';
import '../../features/admin/zones/screens/zoneAdmin_screen.dart';
import '../../features/admin/profile/screens/profileAdmin_screen.dart';
import '../../features/admin/profile/screens/editProfileAdmin_screen.dart';
import '../../features/admin/profile/models/profile_admin_model.dart';
import '../../features/admin/add_ons/screens/add_ons_admin_screen.dart';
import '../../features/admin/pricing/screens/pricing_admin_screen.dart';

class AppRoute {
  static const String root = '/';
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
  static const String adminAnimals = '/admin/animals';
  static const String adminAddAnimal = '/admin/animals/add';
  static const String adminBookings = '/admin/bookings';
  static const String adminEvents = '/admin/events';
  static const String adminAddEvent = '/admin/events/add';
  static const String adminMap = '/admin/map';
  static const String adminMapUploaded = '/admin/map/uploaded';
  static const String adminMapEdit = '/admin/map/edit';
  static const String adminZones = '/admin/zones';
  static const String adminProfile = '/admin/profile';
  static const String adminEditProfile = '/admin/profile/edit';
  static const String adminLogin = '/admin/login';
  static const String adminRegister = '/admin/register';
  static const String adminHome = '/admin/home';
  static const String adminAddOns = '/admin/add_ons';
  static const String adminPricing = '/admin/pricing';
  static const String qrScan = '/qr_scan';

  static Map<String, WidgetBuilder> getRoutes() {
    return {
      root: (context) => const HomeScreen(),
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
      ticket: (context) => const TicketScreen(),
      profile: (context) => const ProfileScreen(),
      adminAnimals: (context) => const AdminGuard(child: AnimalAdminScreen()),
      adminAddAnimal: (context) =>
          const AdminGuard(child: AddAnimalAdminScreen()),
      adminBookings: (context) => const AdminGuard(child: BookingAdminScreen()),
      adminEvents: (context) => const AdminGuard(child: EventAdminScreen()),
      adminMap: (context) => const AdminGuard(child: MapAdminScreen()),
      adminMapUploaded: (context) =>
          const AdminGuard(child: MapUploadedAdminScreen()),
      adminZones: (context) => const AdminGuard(child: ZoneAdminScreen()),
      adminMapEdit: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as MapEditArgs;
        return AdminGuard(child: MapEditAdminScreen(args: args));
      },
      adminProfile: (context) => const AdminGuard(child: ProfileAdminScreen()),
      adminEditProfile: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as ProfileAdminModel?;
        return AdminGuard(child: EditProfileAdminScreen(profile: args));
      },
      adminLogin: (context) => const AdminLoginScreen(),
      adminRegister: (context) => const AdminRegisterScreen(),
      adminHome: (context) => const AdminHomeScreen(),
      adminAddOns: (context) => const AddOnsAdminScreen(),
      adminPricing: (context) => const PricingAdminScreen(),
      qrScan: (context) => const QrScanScreen(),
    };
  }
}
