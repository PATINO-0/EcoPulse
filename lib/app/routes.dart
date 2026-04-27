import 'package:ecopulse/presentation/ai/ai_assistant_screen.dart';
import 'package:ecopulse/presentation/auth/login_screen.dart';
import 'package:ecopulse/presentation/auth/privacy_policy_screen.dart';
import 'package:ecopulse/presentation/auth/register_screen.dart';
import 'package:ecopulse/presentation/fuel_prices/fuel_prices_screen.dart';
import 'package:ecopulse/presentation/history/trip_detail_screen.dart';
import 'package:ecopulse/presentation/history/trip_history_screen.dart';
import 'package:ecopulse/presentation/history/trip_summary_screen.dart';
import 'package:ecopulse/presentation/home/home_screen.dart';
import 'package:ecopulse/presentation/maintenance/maintenance_screen.dart';
import 'package:ecopulse/presentation/map/fuel_stations_map_screen.dart';
import 'package:ecopulse/presentation/map/map_screen.dart';
import 'package:ecopulse/presentation/permissions/permissions_screen.dart';
import 'package:ecopulse/presentation/profile/profile_screen.dart';
import 'package:ecopulse/presentation/settings/settings_screen.dart';
import 'package:ecopulse/presentation/splash/splash_screen.dart';
import 'package:ecopulse/presentation/trip/live_trip_screen.dart';
import 'package:ecopulse/presentation/vehicle/manual_vehicle_form_screen.dart';
import 'package:ecopulse/presentation/vehicle/vehicle_selection_screen.dart';
import 'package:go_router/go_router.dart';

class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String privacyPolicy = '/privacy-policy';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String vehicleSelection = '/vehicles';
  static const String manualVehicleForm = '/vehicles/manual';
  static const String permissions = '/permissions';
  static const String liveTrip = '/trip/live';
  static const String map = '/map';
  static const String fuelStationsMap = '/fuel-stations-map';
  static const String tripHistory = '/trips';
  static const String fuelPrices = '/fuel-prices';
  static const String maintenance = '/maintenance';
  static const String aiAssistant = '/ai-assistant';
  static const String settings = '/settings';

  static String tripDetailPath(String tripId) {
    return '/trips/$tripId';
  }

  static String tripSummaryPath(String tripId) {
    return '/trips/$tripId/summary';
  }
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splash,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) {
          return const SplashScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) {
          return const LoginScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.register,
        builder: (context, state) {
          return const RegisterScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.privacyPolicy,
        builder: (context, state) {
          return const PrivacyPolicyScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) {
          return const HomeScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) {
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.vehicleSelection,
        builder: (context, state) {
          return const VehicleSelectionScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.manualVehicleForm,
        builder: (context, state) {
          return const ManualVehicleFormScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.permissions,
        builder: (context, state) {
          return const PermissionsScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.liveTrip,
        builder: (context, state) {
          return const LiveTripScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.map,
        builder: (context, state) {
          return const MapScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.fuelStationsMap,
        builder: (context, state) {
          return const FuelStationsMapScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.tripHistory,
        builder: (context, state) {
          return const TripHistoryScreen();
        },
      ),
      GoRoute(
        path: '/trips/:tripId',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;

          return TripDetailScreen(
            tripId: tripId,
          );
        },
      ),
      GoRoute(
        path: '/trips/:tripId/summary',
        builder: (context, state) {
          final tripId = state.pathParameters['tripId']!;

          return TripSummaryScreen(
            tripId: tripId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.fuelPrices,
        builder: (context, state) {
          return const FuelPricesScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.maintenance,
        builder: (context, state) {
          return const MaintenanceScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.aiAssistant,
        builder: (context, state) {
          return const AiAssistantScreen();
        },
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) {
          return const SettingsScreen();
        },
      ),
    ],
  );
}