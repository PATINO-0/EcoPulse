import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showComposerGlow = false;
  bool? _manualDark;

  static const List<String> _acceptedFuelTypes = [
    'Gasolina corriente',
    'Gasolina extra',
  ];

  @override
  void initState() {
    super.initState();

    for (final controller in [
      _brandController,
      _modelController,
      _versionController,
      _yearController,
      _engineController,
      _fuelTypeController,
      _powerHpController,
      _weightKgController,
      _transmissionController,
      _cityEfficiencyController,
      _highwayEfficiencyController,
    ]) {
      controller.addListener(_handleComposerState);
    }
  }

  @override
  void dispose() {
    for (final controller in [
      _brandController,
      _modelController,
      _versionController,
      _yearController,
      _engineController,
      _fuelTypeController,
      _powerHpController,
      _weightKgController,
      _transmissionController,
      _cityEfficiencyController,
      _highwayEfficiencyController,
    ]) {
      controller.removeListener(_handleComposerState);
    }

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

  void _handleComposerState() {
    final shouldGlow = [
      _brandController,
      _modelController,
      _versionController,
      _yearController,
      _engineController,
      _fuelTypeController,
      _powerHpController,
      _weightKgController,
      _transmissionController,
      _cityEfficiencyController,
      _highwayEfficiencyController,
    ].any((controller) => controller.text.trim().isNotEmpty);

    if (_showComposerGlow != shouldGlow && mounted) {
      setState(() {
        _showComposerGlow = shouldGlow;
      });
    }
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  String _normalizeFuelType(String value) {
    final trimmed = value.trim().toLowerCase();

    if (trimmed == 'gasolina corriente') {
      return 'Gasolina corriente';
    }

    if (trimmed == 'gasolina extra') {
      return 'Gasolina extra';
    }

    return value.trim();
  }

  String? _validateFuelType(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa el tipo de combustible.';
    }

    final normalized = _normalizeFuelType(value);

    if (!_acceptedFuelTypes.contains(normalized)) {
      return 'Los tipos de combustible aceptados son Gasolina corriente o Gasolina extra.';
    }

    return null;
  }

  Future<void> _saveVehicle() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Corrige el tipo de combustible. Solo se permite Gasolina corriente o Gasolina extra.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    final normalizedFuelType = _normalizeFuelType(_fuelTypeController.text);

    if (!_acceptedFuelTypes.contains(normalizedFuelType)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Los tipos de combustible aceptados son Gasolina corriente o Gasolina extra.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isSaving = true;
    });

    try {
      await ref.read(vehicleRepositoryProvider).createManualVehicle(
            brand: _brandController.text.trim(),
            model: _modelController.text.trim(),
            version: _versionController.text.trim(),
            year: int.parse(_yearController.text.trim()),
            engine: _engineController.text.trim(),
            fuelType: normalizedFuelType,
            powerHp: _toDouble(_powerHpController.text),
            weightKg: _toDouble(_weightKgController.text),
            transmission: _transmissionController.text.trim(),
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
        SnackBar(
          content: const Text(
            'Vehículo registrado y seleccionado correctamente.',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      context.pop(true);
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible guardar el vehículo. Detalle: $exception',
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
    final isDark = _isDark(context);
    final colors = MapColors(isDark);
    final width = MediaQuery.of(context).size.width;
    final isTablet = width >= 760;
    final isDesktop = width >= 1140;
    final horizontalPadding = isDesktop
        ? 30.0
        : isTablet
            ? 24.0
            : 18.0;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  14,
                  horizontalPadding,
                  14,
                ),
                child: _VehicleFormHeader(
                  colors: colors,
                  isDark: isDark,
                  isSaving: _isSaving,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleTheme: _toggleTheme,
                  onSave: _saveVehicle,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  14,
                ),
                child: _VehicleFormHeroCard(
                  colors: colors,
                  isWide: isTablet,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  22,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _AnimatedFormSection(
                        colors: colors,
                        delay: 0,
                        title: 'Identidad del vehículo',
                        subtitle:
                            'Define la base del vehículo para que EcoPulse lo reconozca correctamente.',
                        icon: Icons.badge_rounded,
                        accent: colors.primary,
                        child: Column(
                          children: [
                            _ProfileStyledField(
                              controller: _brandController,
                              label: 'Marca',
                              hint: 'Ejemplo: Mazda',
                              icon: Icons.business_rounded,
                              colors: colors,
                              validator: _validateRequired,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _modelController,
                              label: 'Modelo',
                              hint: 'Ejemplo: 3 Touring',
                              icon: Icons.directions_car_filled_rounded,
                              colors: colors,
                              validator: _validateRequired,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _versionController,
                              label: 'Versión',
                              hint: 'Ejemplo: Grand Touring LX',
                              icon: Icons.layers_rounded,
                              colors: colors,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _yearController,
                              label: 'Año',
                              hint: 'Ejemplo: 2020',
                              icon: Icons.calendar_today_rounded,
                              colors: colors,
                              keyboardType: TextInputType.number,
                              validator: _validateYear,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnimatedFormSection(
                        colors: colors,
                        delay: 80,
                        title: 'Motorización y consumo',
                        subtitle:
                            'Añade datos técnicos para lograr recomendaciones más precisas.',
                        icon: Icons.local_gas_station_rounded,
                        accent: colors.warning,
                        child: Column(
                          children: [
                            _ProfileStyledField(
                              controller: _engineController,
                              label: 'Motor',
                              hint: 'Ejemplo: 1.6L',
                              icon: Icons.settings_input_component_rounded,
                              colors: colors,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _fuelTypeController,
                              label: 'Tipo de combustible',
                              hint: 'Gasolina corriente o Gasolina extra',
                              helperText:
                                  'Tipos aceptados: Gasolina corriente o Gasolina extra.',
                              icon: Icons.local_gas_station_rounded,
                              colors: colors,
                              validator: _validateFuelType,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _powerHpController,
                              label: 'Potencia aproximada HP',
                              hint: 'Ejemplo: 130',
                              icon: Icons.bolt_rounded,
                              colors: colors,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateOptionalNumber,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _weightKgController,
                              label: 'Peso aproximado KG',
                              hint: 'Ejemplo: 1240',
                              icon: Icons.fitness_center_rounded,
                              colors: colors,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateOptionalNumber,
                              textInputAction: TextInputAction.next,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      _AnimatedFormSection(
                        colors: colors,
                        delay: 140,
                        title: 'Transmisión y eficiencia',
                        subtitle:
                            'Completa esta sección para enriquecer análisis de uso y consumo.',
                        icon: Icons.speed_rounded,
                        accent: colors.accent,
                        child: Column(
                          children: [
                            _ProfileStyledField(
                              controller: _transmissionController,
                              label: 'Transmisión',
                              hint: 'Manual o automática',
                              icon: Icons.sync_alt_rounded,
                              colors: colors,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _cityEfficiencyController,
                              label: 'Rendimiento ciudad km/galón',
                              hint: 'Ejemplo: 42.5',
                              icon: Icons.location_city_rounded,
                              colors: colors,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateOptionalNumber,
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 14),
                            _ProfileStyledField(
                              controller: _highwayEfficiencyController,
                              label: 'Rendimiento carretera km/galón',
                              hint: 'Ejemplo: 58.2',
                              icon: Icons.route_rounded,
                              colors: colors,
                              keyboardType: const TextInputType.numberWithOptions(
                                decimal: true,
                              ),
                              validator: _validateOptionalNumber,
                              textInputAction: TextInputAction.done,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        decoration: BoxDecoration(
                          color: _showComposerGlow
                              ? colors.textPrimary.withOpacity(0.05)
                              : colors.card.withOpacity(0.98),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: _showComposerGlow
                                ? colors.textPrimary.withOpacity(0.12)
                                : colors.border,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: _showComposerGlow
                                  ? colors.textPrimary.withOpacity(0.08)
                                  : colors.shadow.withOpacity(0.12),
                              blurRadius: 18,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Acción principal',
                              style: TextStyle(
                                fontSize: 11.4,
                                fontWeight: FontWeight.w700,
                                color: colors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Guarda el vehículo para dejarlo registrado y convertirlo en el activo actual del usuario.',
                              style: TextStyle(
                                fontSize: 12.2,
                                height: 1.4,
                                color: colors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton.icon(
                                onPressed: _isSaving ? null : _saveVehicle,
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      colors.textPrimary.withOpacity(0.94),
                                  foregroundColor: colors.card,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 15,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                icon: _isSaving
                                    ? SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: colors.card,
                                        ),
                                      )
                                    : const Icon(Icons.save_rounded, size: 18),
                                label: Text(
                                  _isSaving
                                      ? 'Guardando vehículo'
                                      : 'Guardar vehículo',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleFormHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isSaving;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onSave;

  const _VehicleFormHeader({
    required this.colors,
    required this.isDark,
    required this.isSaving,
    required this.onBack,
    required this.onToggleTheme,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 560;

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.card.withOpacity(0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                _CircleAction(
                  icon: Icons.arrow_back_rounded,
                  color: colors.primary,
                  bg: colors.chip,
                  border: colors.chipBorder,
                  onTap: onBack,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Registro manual',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                      color: colors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Crea un vehículo manual cuando no aparezca en el catálogo y mantén la misma calidad visual en toda la app.',
                style: TextStyle(
                  fontSize: 12.2,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _HeaderActionButton(
                    colors: colors,
                    icon: isDark
                        ? Icons.light_mode_rounded
                        : Icons.dark_mode_rounded,
                    label: isDark ? 'Modo claro' : 'Modo oscuro',
                    color: isDark ? colors.warning : colors.primary,
                    onTap: onToggleTheme,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _HeaderActionButton(
                    colors: colors,
                    icon: isSaving
                        ? Icons.hourglass_top_rounded
                        : Icons.save_rounded,
                    label: isSaving ? 'Guardando' : 'Guardar',
                    color: isSaving ? colors.warning : colors.textPrimary,
                    onTap: onSave,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow,
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _CircleAction(
            icon: Icons.arrow_back_rounded,
            color: colors.primary,
            bg: colors.chip,
            border: colors.chipBorder,
            onTap: onBack,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registro manual',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Crea un vehículo manual cuando no aparezca en el catálogo y mantén la misma calidad visual en toda la app.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.2,
                    height: 1.4,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _CircleAction(
            icon: isDark
                ? Icons.light_mode_rounded
                : Icons.dark_mode_rounded,
            color: isDark ? colors.warning : colors.primary,
            bg: colors.chip,
            border: colors.chipBorder,
            onTap: onToggleTheme,
          ),
          const SizedBox(width: 8),
          _CircleAction(
            icon: isSaving
                ? Icons.hourglass_top_rounded
                : Icons.save_rounded,
            color: isSaving ? colors.warning : colors.textPrimary,
            bg: (isSaving ? colors.warning : colors.textPrimary).withOpacity(0.12),
            border:
                (isSaving ? colors.warning : colors.textPrimary).withOpacity(0.24),
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}

class _VehicleFormHeroCard extends StatelessWidget {
  final MapColors colors;
  final bool isWide;

  const _VehicleFormHeroCard({
    required this.colors,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(isWide ? 20 : 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colors.heroTop, colors.heroBottom],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.16),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: isWide
          ? Row(
              children: const [
                _HeroVehicleIcon(),
                SizedBox(width: 18),
                Expanded(
                  child: _HeroVehicleText(),
                ),
                SizedBox(width: 16),
                SizedBox(
                  width: 230,
                  child: _HeroVehiclePanel(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  children: [
                    _HeroVehicleIcon(),
                    SizedBox(width: 14),
                    Expanded(child: _HeroVehicleText()),
                  ],
                ),
                SizedBox(height: 16),
                _HeroVehiclePanel(),
              ],
            ),
    );
  }
}

class _HeroVehicleIcon extends StatelessWidget {
  const _HeroVehicleIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.directions_car_filled_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}

class _HeroVehicleText extends StatelessWidget {
  const _HeroVehicleText();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vehículo manual',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Registra un auto con datos reales',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Esto permite personalizar recomendaciones, mantenimiento y análisis',
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12.8,
            height: 1.4,
            color: Colors.white.withOpacity(0.86),
          ),
        ),
      ],
    );
  }
}

class _HeroVehiclePanel extends StatelessWidget {
  const _HeroVehiclePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: const Column(
        children: [
          _HeroMiniMetric(
            icon: Icons.fact_check_rounded,
            label: 'Objetivo',
            value: 'Más precisión',
          ),
          SizedBox(height: 10),
          _HeroMiniMetric(
            icon: Icons.auto_graph_rounded,
            label: 'Resultado',
            value: 'Perfil completo',
          ),
        ],
      ),
    );
  }
}

class _HeroMiniMetric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HeroMiniMetric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.2,
                  color: Colors.white.withOpacity(0.70),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13.6,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AnimatedFormSection extends StatelessWidget {
  final MapColors colors;
  final int delay;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _AnimatedFormSection({
    required this.colors,
    required this.delay,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 360 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, sectionChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: sectionChild,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: colors.card.withOpacity(0.98),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.14),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: accent.withOpacity(0.20)),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12.4,
                            height: 1.45,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            child,
          ],
        ),
      ),
    );
  }
}

class _ProfileStyledField extends StatelessWidget {
  final MapColors colors;
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? helperText;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;

  const _ProfileStyledField({
    required this.colors,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.helperText,
    this.validator,
    this.keyboardType,
    this.textInputAction,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(18);

    OutlineInputBorder border(Color color, [double width = 1.15]) {
      return OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: BorderSide(
          color: color,
          width: width,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.6,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          cursorColor: colors.primary,
          style: TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            helperText: helperText,
            helperStyle: TextStyle(
              fontSize: 11.0,
              height: 1.35,
              color: colors.textSecondary,
            ),
            hintStyle: TextStyle(
              fontSize: 13.2,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary.withOpacity(0.78),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 10, right: 4),
              child: Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: 18,
                  color: colors.primary.withOpacity(0.92),
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 44,
              minHeight: 44,
            ),
            filled: true,
            fillColor: colors.chip.withOpacity(0.72),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            enabledBorder: border(colors.border.withOpacity(0.90)),
            focusedBorder: border(colors.primary.withOpacity(0.95), 1.45),
            errorBorder: border(colors.danger.withOpacity(0.90), 1.25),
            focusedErrorBorder: border(colors.danger, 1.45),
            disabledBorder: border(colors.border.withOpacity(0.55)),
            errorStyle: TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w600,
              color: colors.danger,
            ),
          ),
        ),
      ],
    );
  }
}

class _HeaderActionButton extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _HeaderActionButton({
    required this.colors,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.10),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  const _CircleAction({
    required this.icon,
    required this.color,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border),
          ),
          child: Icon(icon, color: color, size: 21),
        ),
      ),
    );
  }
}