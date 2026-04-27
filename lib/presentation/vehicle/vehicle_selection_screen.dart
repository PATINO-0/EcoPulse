import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:ecopulse/data/models/vehicle_catalog_model.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VehicleSelectionScreen extends ConsumerStatefulWidget {
  const VehicleSelectionScreen({super.key});

  @override
  ConsumerState<VehicleSelectionScreen> createState() {
    return _VehicleSelectionScreenState();
  }
}

class _VehicleSelectionScreenState
    extends ConsumerState<VehicleSelectionScreen> {
  final TextEditingController _searchController = TextEditingController();

  late Future<List<VehicleCatalogModel>> _catalogFuture;
  late Future<List<UserVehicleModel>> _userVehiclesFuture;

  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _catalogFuture = ref.read(vehicleRepositoryProvider).searchCatalog();
    _userVehiclesFuture = ref.read(vehicleRepositoryProvider).getUserVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _refreshCatalog() {
    setState(() {
      _catalogFuture = ref.read(vehicleRepositoryProvider).searchCatalog(
            query: _searchController.text,
          );
    });
  }

  void _refreshUserVehicles() {
    setState(() {
      _userVehiclesFuture = ref.read(vehicleRepositoryProvider).getUserVehicles();
    });
  }

  Future<void> _selectCatalogVehicle(VehicleCatalogModel vehicle) async {
    setState(() {
      _isSelecting = true;
    });

    try {
      await ref.read(vehicleRepositoryProvider).selectCatalogVehicle(
            vehicle: vehicle,
          );

      _refreshUserVehicles();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehículo seleccionado: ${vehicle.displayName}'),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible seleccionar el vehículo. Detalle: $exception',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
      }
    }
  }

  Future<void> _setSelectedUserVehicle(UserVehicleModel vehicle) async {
    setState(() {
      _isSelecting = true;
    });

    try {
      await ref.read(vehicleRepositoryProvider).setSelectedVehicle(
            userVehicleId: vehicle.id,
          );

      _refreshUserVehicles();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehículo activo: ${vehicle.displayName}'),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible cambiar el vehículo activo. Detalle: $exception',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSelecting = false;
        });
      }
    }
  }

  Widget _buildUserVehicles() {
    return FutureBuilder<List<UserVehicleModel>>(
      future: _userVehiclesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text('Cargando tus vehículos...'),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No fue posible cargar tus vehículos. Detalle: ${snapshot.error}',
              ),
            ),
          );
        }

        final vehicles = snapshot.data ?? [];

        if (vehicles.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Aún no tienes un vehículo seleccionado. Elige uno del catálogo o regístralo manualmente.',
              ),
            ),
          );
        }

        return Column(
          children: vehicles.map((vehicle) {
            return Card(
              child: ListTile(
                leading: Icon(
                  vehicle.isSelected
                      ? Icons.check_circle_rounded
                      : Icons.directions_car_rounded,
                  color: vehicle.isSelected ? Colors.green : null,
                ),
                title: Text(vehicle.displayName),
                subtitle: Text(
                  '${vehicle.fuelType} • ${vehicle.isManual ? 'Manual' : 'Catálogo'}',
                ),
                trailing: vehicle.isSelected
                    ? const Text('Activo')
                    : TextButton(
                        onPressed: _isSelecting
                            ? null
                            : () {
                                _setSelectedUserVehicle(vehicle);
                              },
                        child: const Text('Usar'),
                      ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCatalog() {
    return FutureBuilder<List<VehicleCatalogModel>>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(22),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Text(
                'No fue posible cargar el catálogo. Detalle: ${snapshot.error}',
              ),
            ),
          );
        }

        final vehicles = snapshot.data ?? [];

        if (vehicles.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'No encontramos vehículos con ese criterio. Puedes registrarlo manualmente.',
              ),
            ),
          );
        }

        return Column(
          children: vehicles.map((vehicle) {
            return Card(
              child: ListTile(
                leading: const Icon(Icons.directions_car_filled_rounded),
                title: Text(vehicle.displayName),
                subtitle: Text(
                  [
                    vehicle.engine,
                    vehicle.fuelType,
                    vehicle.transmission,
                    vehicle.isExample ? 'Dato demo' : null,
                  ].whereType<String>().join(' • '),
                ),
                trailing: TextButton(
                  onPressed: _isSelecting
                      ? null
                      : () {
                          _selectCatalogVehicle(vehicle);
                        },
                  child: const Text('Seleccionar'),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehículo'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.manualVehicleForm);
          _refreshUserVehicles();
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('Manual'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Tus vehículos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),
            _buildUserVehicles(),
            const SizedBox(height: 24),
            Text(
              'Catálogo de vehículos',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Los datos marcados como demo deben reemplazarse por una fuente real antes de producción.',
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Buscar por marca, modelo, año o versión',
                suffixIcon: IconButton(
                  onPressed: _refreshCatalog,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              onSubmitted: (_) {
                _refreshCatalog();
              },
            ),
            const SizedBox(height: 16),
            _buildCatalog(),
          ],
        ),
      ),
    );
  }
}