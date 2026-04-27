import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/presentation/home/widgets/home_action_card.dart';
import 'package:ecopulse/presentation/home/widgets/supabase_connection_card.dart';
import 'package:ecopulse/services/supabase/supabase_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthRepository().signOut();

    if (!context.mounted) {
      return;
    }

    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    final user = SupabaseService.client.auth.currentUser;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConstants.appName),
        actions: [
          IconButton(
            onPressed: () {
              _signOut(context);
            },
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Hola, ${user?.email ?? 'conductor'}',
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Gestiona tu vehículo, permisos, trayectos y mapas de EcoPulse.',
            ),
            const SizedBox(height: 20),
            const SupabaseConnectionCard(),
            const SizedBox(height: 16),
            HomeActionCard(
              title: 'Permisos',
              description: 'Revisa ubicación, GPS, notificaciones y sensores.',
              icon: Icons.verified_user_rounded,
              onTap: () {
                context.push(AppRoutes.permissions);
              },
            ),
            HomeActionCard(
              title: 'Trayecto en vivo',
              description: 'Inicia un trayecto manual o activa detección automática.',
              icon: Icons.route_rounded,
              onTap: () {
                context.push(AppRoutes.liveTrip);
              },
            ),
            HomeActionCard(
              title: 'Mapa en tiempo real',
              description: 'Visualiza tu ruta, ubicación actual y estaciones cercanas.',
              icon: Icons.map_rounded,
              onTap: () {
                context.push(AppRoutes.map);
              },
            ),
            HomeActionCard(
              title: 'Historial de trayectos',
              description: 'Consulta viajes finalizados, costos, consumo, eventos y rutas.',
              icon: Icons.history_rounded,
              onTap: () {
                context.push(AppRoutes.tripHistory);
              },
            ),
            HomeActionCard(
              title: 'Estaciones de gasolina',
              description: 'Consulta estaciones registradas en Pasto, Nariño.',
              icon: Icons.local_gas_station_rounded,
              onTap: () {
                context.push(AppRoutes.fuelStationsMap);
              },
            ),
            HomeActionCard(
              title: 'Precios de combustible',
              description: 'Consulta precios registrados para Pasto, Nariño.',
              icon: Icons.payments_rounded,
              onTap: () {
                context.push(AppRoutes.fuelPrices);
              },
            ),
            HomeActionCard(
              title: 'Mantenimiento preventivo',
              description: 'Gestiona revisiones recomendadas para tu vehículo.',
              icon: Icons.build_circle_rounded,
              onTap: () {
                context.push(AppRoutes.maintenance);
              },
            ),
            HomeActionCard(
              title: 'Asistente IA',
              description: 'Recibe consejos de conducción, consumo y mantenimiento.',
              icon: Icons.smart_toy_rounded,
              onTap: () {
                context.push(AppRoutes.aiAssistant);
              },
            ),
            HomeActionCard(
              title: 'Mi perfil',
              description: 'Actualiza tus datos personales básicos.',
              icon: Icons.person_rounded,
              onTap: () {
                context.push(AppRoutes.profile);
              },
            ),
            HomeActionCard(
              title: 'Vehículo',
              description: 'Selecciona un vehículo del catálogo o regístralo manualmente.',
              icon: Icons.directions_car_rounded,
              onTap: () {
                context.push(AppRoutes.vehicleSelection);
              },
            ),
            HomeActionCard(
              title: 'Configuración',
              description: 'Ajusta alertas, voz, eco-feedback y unidades de consumo.',
              icon: Icons.settings_rounded,
              onTap: () {
                context.push(AppRoutes.settings);
              },
            ),
            HomeActionCard(
              title: 'Política de datos',
              description: 'Consulta la política aceptada durante el registro.',
              icon: Icons.privacy_tip_rounded,
              onTap: () {
                context.push(AppRoutes.privacyPolicy);
              },
            ),
          ],
        ),
      ),
    );
  }
}