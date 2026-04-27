import 'package:ecopulse/services/permissions/app_permission_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PermissionsScreen extends ConsumerStatefulWidget {
  const PermissionsScreen({super.key});

  @override
  ConsumerState<PermissionsScreen> createState() {
    return _PermissionsScreenState();
  }
}

class _PermissionsScreenState extends ConsumerState<PermissionsScreen> {
  bool _isLoading = false;
  String _message = 'Revisa los permisos necesarios para usar EcoPulse.';

  Future<void> _requestPermissions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final status =
          await ref.read(appPermissionServiceProvider).requestRequiredPermissions();

      setState(() {
        _message = status.statusMessage;
      });
    } catch (exception) {
      setState(() {
        _message = 'No fue posible solicitar permisos. Detalle: $exception';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _openSettings() async {
    await ref.read(appPermissionServiceProvider).openDeviceSettings();
  }

  Future<void> _checkPermissions() async {
    setState(() {
      _isLoading = true;
    });

    final status = await ref.read(appPermissionServiceProvider).checkPermissions();

    setState(() {
      _message = status.statusMessage;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Permisos'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'Permisos requeridos',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const Text(
              'EcoPulse necesita ubicación mientras usas la app para registrar el recorrido, calcular velocidad, distancia y guardar puntos del trayecto.',
            ),
            const SizedBox(height: 16),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Ubicación precisa o aproximada.'),
                    Text('• GPS activo en el dispositivo.'),
                    Text('• Notificaciones para alertas futuras.'),
                    Text('• Sensores del teléfono cuando estén disponibles.'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(_message),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _isLoading ? null : _requestPermissions,
              icon: const Icon(Icons.verified_user_rounded),
              label: Text(
                _isLoading ? 'Solicitando...' : 'Solicitar permisos',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _openSettings,
              icon: const Icon(Icons.settings_rounded),
              label: const Text('Abrir configuración del dispositivo'),
            ),
          ],
        ),
      ),
    );
  }
}
