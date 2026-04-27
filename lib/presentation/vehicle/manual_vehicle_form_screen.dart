import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/shared/widgets/app_text_field.dart';
import 'package:ecopulse/shared/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ManualVehicleFormScreen extends ConsumerStatefulWidget {
  const ManualVehicleFormScreen({super.key});

  @override
  ConsumerState<ManualVehicleFormScreen> createState() {
    return _ManualVehicleFormScreenState();
  }
}

class _ManualVehicleFormScreenState
    extends ConsumerState<ManualVehicleFormScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _brandController = TextEditingController();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _versionController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();
  final TextEditingController _engineController = TextEditingController();
  final TextEditingController _fuelTypeController = TextEditingController(
    text: 'Gasolina corriente',
  );
  final TextEditingController _powerHpController = TextEditingController();
  final TextEditingController _weightKgController = TextEditingController();
  final TextEditingController _transmissionController = TextEditingController();
  final TextEditingController _cityEfficiencyController =
      TextEditingController();
  final TextEditingController _highwayEfficiencyController =
      TextEditingController();

  bool _isSaving = false;

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _versionController.dispose();
    _yearController.dispose();
    _engineController.dispose();
    _fuelTypeController.dispose();
    _powerHpController.dispose();
    _weightKgController.dispose();
    _transmissionController.dispose();
    _cityEfficiencyController.dispose();
    _highwayEfficiencyController.dispose();
    super.dispose();
  }

  Future<void> _saveVehicle() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(vehicleRepositoryProvider).createManualVehicle(
            brand: _brandController.text,
            model: _modelController.text,
            version: _versionController.text,
            year: int.parse(_yearController.text),
            engine: _engineController.text,
            fuelType: _fuelTypeController.text,
            powerHp: _toDouble(_powerHpController.text),
            weightKg: _toDouble(_weightKgController.text),
            transmission: _transmissionController.text,
            estimatedCityKmPerGallon: _toDouble(
              _cityEfficiencyController.text,
            ),
            estimatedHighwayKmPerGallon: _toDouble(
              _highwayEfficiencyController.text,
            ),
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vehículo registrado y seleccionado correctamente.'),
        ),
      );

      context.pop();
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible guardar el vehículo. Detalle: $exception',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el año del vehículo.';
    }

    final year = int.tryParse(value);

    if (year == null) {
      return 'Ingresa un año válido.';
    }

    if (year < 2000) {
      return 'EcoPulse solo acepta vehículos desde el año 2000.';
    }

    if (year > DateTime.now().year + 1) {
      return 'El año ingresado no parece válido.';
    }

    return null;
  }

  String? _validateOptionalNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }

    final parsedValue = double.tryParse(value.replaceAll(',', '.'));

    if (parsedValue == null) {
      return 'Ingresa un número válido.';
    }

    if (parsedValue <= 0) {
      return 'El valor debe ser mayor que cero.';
    }

    return null;
  }

  double? _toDouble(String value) {
    if (value.trim().isEmpty) {
      return null;
    }

    return double.tryParse(value.replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrar vehículo'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Registra tu vehículo manualmente si no aparece en el catálogo. Usa datos reales siempre que sea posible.',
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _brandController,
                    label: 'Marca',
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _modelController,
                    label: 'Modelo',
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _versionController,
                    label: 'Versión',
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _yearController,
                    label: 'Año',
                    keyboardType: TextInputType.number,
                    validator: _validateYear,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _engineController,
                    label: 'Motor',
                    hint: 'Ejemplo: 1.6L',
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _fuelTypeController,
                    label: 'Tipo de combustible',
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _powerHpController,
                    label: 'Potencia aproximada HP',
                    keyboardType: TextInputType.number,
                    validator: _validateOptionalNumber,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _weightKgController,
                    label: 'Peso aproximado KG',
                    keyboardType: TextInputType.number,
                    validator: _validateOptionalNumber,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _transmissionController,
                    label: 'Transmisión',
                    hint: 'Manual o automática',
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _cityEfficiencyController,
                    label: 'Rendimiento ciudad km/galón',
                    keyboardType: TextInputType.number,
                    validator: _validateOptionalNumber,
                  ),
                  const SizedBox(height: 14),
                  AppTextField(
                    controller: _highwayEfficiencyController,
                    label: 'Rendimiento carretera km/galón',
                    keyboardType: TextInputType.number,
                    validator: _validateOptionalNumber,
                  ),
                  const SizedBox(height: 24),
                  PrimaryActionButton(
                    text: 'Guardar vehículo',
                    icon: Icons.save_rounded,
                    isLoading: _isSaving,
                    onPressed: _saveVehicle,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}