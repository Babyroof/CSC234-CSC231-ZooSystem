import 'package:go_router/go_router.dart';
import 'package:zoopernova_zoo_system/core/widgets/admin_guard.dart';
import 'package:zoopernova_zoo_system/core/widgets/main_wrapper.dart';
import 'package:zoopernova_zoo_system/core/widgets/user_auth_guard.dart';
import 'package:zoopernova_zoo_system/features/admin/add_ons/presentation/screens/add_ons_admin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/animals/presentation/screens/addAnimalAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/animals/presentation/screens/animalAdmin.dart';
import 'package:zoopernova_zoo_system/features/admin/auth/presentation/screens/admin_login_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/auth/presentation/screens/admin_register_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/events/presentation/screens/eventAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/maps/presentation/screens/mapAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/maps/presentation/screens/mapEditAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/maps/presentation/screens/mapUploadedAdmin.dart';
import 'package:zoopernova_zoo_system/features/admin/pricing/presentation/screens/pricing_admin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/profile/models/profile_admin_model.dart';
import 'package:zoopernova_zoo_system/features/admin/profile/presentation/screens/editProfileAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/profile/presentation/screens/profileAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/tickets/presentation/screens/bookingAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/admin/zones/presentation/screens/zoneAdmin_screen.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/screens/animal_info_screen.dart';
import 'package:zoopernova_zoo_system/features/animals_info/presentation/screens/animal_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/screens/login_screen.dart';
import 'package:zoopernova_zoo_system/features/auth/presentation/screens/register_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/presentation/screens/booking_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/presentation/screens/payment_screen.dart';
import 'package:zoopernova_zoo_system/features/booking/presentation/screens/ticket_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/domain/entities/event_entity.dart';
import 'package:zoopernova_zoo_system/features/events_show/presentation/screens/event_info_screen.dart';
import 'package:zoopernova_zoo_system/features/events_show/presentation/screens/event_screen.dart';
import 'package:zoopernova_zoo_system/features/home/presentation/screens/home_screen.dart';
import 'package:zoopernova_zoo_system/features/map/presentation/screens/map_screen.dart';
import 'package:zoopernova_zoo_system/features/map/presentation/screens/qr_scan_screen.dart';
import 'package:zoopernova_zoo_system/features/profile/presentation/screens/profile_screen.dart';
import 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoute.root,
  routes: [
    GoRoute(
      path: AppRoute.root,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoute.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoute.register,
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: AppRoute.main,
      builder: (context, state) => const MainWrapperScreen(),
    ),
    GoRoute(
      path: AppRoute.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoute.events,
      builder: (context, state) => const EventScreen(),
    ),
    GoRoute(
      path: AppRoute.eventsInfo,
      builder: (context, state) =>
          EventInfoScreen(event: state.extra as EventEntity),
    ),
    GoRoute(
      path: AppRoute.animals,
      builder: (context, state) => const AnimalScreen(),
    ),
    GoRoute(
      path: AppRoute.animalInfo,
      builder: (context, state) => const AnimalInfoScreen(),
    ),
    GoRoute(path: AppRoute.map, builder: (context, state) => const MapScreen()),
    GoRoute(
      path: AppRoute.booking,
      builder: (context, state) => const UserAuthGuard(child: BookingScreen()),
    ),
    GoRoute(
      path: AppRoute.payment,
      builder: (context, state) => PaymentScreen(
        bookingArgs: (state.extra as Map<String, dynamic>?) ?? const {},
      ),
    ),
    GoRoute(
      path: AppRoute.ticket,
      builder: (context, state) => const TicketScreen(),
    ),
    GoRoute(
      path: AppRoute.profile,
      builder: (context, state) => const ProfileScreen(),
    ),
    GoRoute(
      path: AppRoute.qrScan,
      builder: (context, state) => const QrScanScreen(),
    ),
    GoRoute(
      path: AppRoute.adminAnimals,
      builder: (context, state) => const AdminGuard(child: AnimalAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminAddAnimal,
      builder: (context, state) =>
          const AdminGuard(child: AddAnimalAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminBookings,
      builder: (context, state) =>
          const AdminGuard(child: BookingAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminEvents,
      builder: (context, state) => const AdminGuard(child: EventAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminMap,
      builder: (context, state) => const AdminGuard(child: MapAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminMapUploaded,
      builder: (context, state) =>
          const AdminGuard(child: MapUploadedAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminMapEdit,
      builder: (context, state) => AdminGuard(
        child: MapEditAdminScreen(args: state.extra as MapEditArgs),
      ),
    ),
    GoRoute(
      path: AppRoute.adminZones,
      builder: (context, state) => const AdminGuard(child: ZoneAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminProfile,
      builder: (context, state) =>
          const AdminGuard(child: ProfileAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminEditProfile,
      builder: (context, state) => AdminGuard(
        child: EditProfileAdminScreen(
          profile: state.extra as ProfileAdminModel?,
        ),
      ),
    ),
    GoRoute(
      path: AppRoute.adminLogin,
      builder: (context, state) => const AdminLoginScreen(),
    ),
    GoRoute(
      path: AppRoute.adminRegister,
      builder: (context, state) => const AdminRegisterScreen(),
    ),
    GoRoute(
      path: AppRoute.adminHome,
      builder: (context, state) => const AdminGuard(child: AnimalAdminScreen()),
    ),
    GoRoute(
      path: AppRoute.adminAddOns,
      builder: (context, state) => const AddOnsAdminScreen(),
    ),
    GoRoute(
      path: AppRoute.adminPricing,
      builder: (context, state) => const PricingAdminScreen(),
    ),
  ],
);
