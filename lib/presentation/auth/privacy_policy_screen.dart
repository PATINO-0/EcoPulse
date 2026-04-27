import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Política de datos'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'Política de tratamiento de datos personales',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            const Text(
              'EcoPulse es una aplicación diseñada para estimar el consumo de combustible y mejorar los hábitos de conducción usando datos del teléfono móvil y datos del vehículo registrados por el usuario.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Datos que se podrán procesar',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('• Ubicación aproximada y precisa durante el trayecto.'),
            const Text('• Velocidad, distancia, altitud, rumbo y precisión GPS.'),
            const Text('• Lecturas de acelerómetro, giroscopio, magnetómetro y barómetro si están disponibles.'),
            const Text('• Datos del vehículo, como marca, modelo, año, combustible, peso y rendimiento estimado.'),
            const Text('• Historial de viajes, eventos de conducción y estimaciones de consumo.'),
            const Text('• Métricas de conducción, costos estimados y recomendaciones generadas.'),
            const SizedBox(height: 16),
            const Text(
              'Finalidad del tratamiento',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los datos se usarán para registrar trayectos, estimar consumo de combustible, detectar aceleraciones bruscas, frenadas fuertes, ralentí prolongado y otros eventos que puedan afectar el rendimiento del vehículo.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Limitaciones técnicas',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'EcoPulse no reemplaza mediciones oficiales del computador del vehículo ni datos OBD-II. El consumo calculado es una estimación basada en sensores móviles, GPS, datos del vehículo y modelos físico-matemáticos aproximados.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Control del usuario',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'El usuario podrá cerrar sesión, editar su perfil, cambiar su vehículo seleccionado y modificar preferencias de alertas en fases posteriores de la aplicación.',
            ),
            const SizedBox(height: 16),
            const Text(
              'Aceptación',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Para crear una cuenta en EcoPulse es obligatorio aceptar esta política. La aceptación se guardará en Supabase con el identificador del usuario, fecha de aceptación y versión de la política.',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                  return;
                }

                Navigator.of(context).maybePop();
              },
              icon: const Icon(Icons.check_rounded),
              label: const Text('Entendido'),
            ),
          ],
        ),
      ),
    );
  }
}