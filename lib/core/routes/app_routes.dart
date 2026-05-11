import 'package:flutter/material.dart';
import 'package:zoopernova_zoo_system/features/booking/screens/booking_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/screens/payment_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/screens/ticket_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/screens/event_info_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/screens/event_screen.dart';
import 'package:zoopernova_zoo_system/features/map/screens/map_screen.dart';
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
import '../../features/admin/profile/profileAdmin_screen.dart';
import '../../features/admin/profile/editProfileAdmin_screen.dart';
import '../../features/admin/profile/models/profile_admin_model.dart';

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
      ticket: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments
                as Map<String, dynamic>? ??
            const {};
        return TicketScreen(bookingArgs: args);
      },
      profile: (context) => const ProfileScreen(),
      adminAnimals: (context) => const AnimalAdminScreen(),
      adminAddAnimal: (context) => const AddAnimalAdminScreen(),
      adminBookings: (context) => const BookingAdminScreen(),
      adminEvents: (context) => const EventAdminScreen(),
      adminMap: (context) => const MapAdminScreen(),
      adminMapUploaded: (context) => const MapUploadedAdminScreen(),
      adminZones: (context) => const ZoneAdminScreen(),
      adminMapEdit: (context) {
        final args = ModalRoute.of(context)!.settings.arguments as MapEditArgs;
        return MapEditAdminScreen(args: args);
      },
      adminProfile: (context) => const ProfileAdminScreen(),
      adminEditProfile: (context) {
        final args =
            ModalRoute.of(context)?.settings.arguments as ProfileAdminModel?;
        return EditProfileAdminScreen(profile: args);
      },
    };
  }
}
