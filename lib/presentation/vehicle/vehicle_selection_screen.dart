import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/data/models/user_vehicle_model.dart';
import 'package:ecopulse/data/models/vehicle_catalog_model.dart';
import 'package:ecopulse/data/repositories/vehicle_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  final FocusNode _searchFocusNode = FocusNode();

  late Future<List<VehicleCatalogModel>> _catalogFuture;
  late Future<List<UserVehicleModel>> _userVehiclesFuture;

  bool _isSelecting = false;
  bool _showSearchGlow = false;
  bool? _manualDark;
  String? _recentlyActivatedVehicleId;

  @override
  void initState() {
    super.initState();
    _catalogFuture = ref.read(vehicleRepositoryProvider).searchCatalog();
    _userVehiclesFuture = ref.read(vehicleRepositoryProvider).getUserVehicles();

    _searchController.addListener(_handleSearchState);
    _searchFocusNode.addListener(_handleSearchState);
  }

  @override
  void dispose() {
    _searchController.removeListener(_handleSearchState);
    _searchFocusNode.removeListener(_handleSearchState);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _handleSearchState() {
    final shouldGlow =
        _searchFocusNode.hasFocus || _searchController.text.trim().isNotEmpty;

    if (_showSearchGlow != shouldGlow && mounted) {
      setState(() {
        _showSearchGlow = shouldGlow;
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

  void _refreshCatalog() {
    setState(() {
      _catalogFuture = ref.read(vehicleRepositoryProvider).searchCatalog(
            query: _searchController.text.trim(),
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
      HapticFeedback.mediumImpact();

      await ref.read(vehicleRepositoryProvider).selectCatalogVehicle(
            vehicle: vehicle,
          );

      _refreshUserVehicles();

      if (!mounted) {
        return;
      }

      setState(() {
        _recentlyActivatedVehicleId = vehicle.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehículo seleccionado: ${vehicle.displayName}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _recentlyActivatedVehicleId = null;
        });
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible seleccionar el vehículo. Detalle: $exception',
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
      HapticFeedback.mediumImpact();

      await ref.read(vehicleRepositoryProvider).setSelectedVehicle(
            userVehicleId: vehicle.id,
          );

      _refreshUserVehicles();

      if (!mounted) {
        return;
      }

      setState(() {
        _recentlyActivatedVehicleId = vehicle.id;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vehículo activo: ${vehicle.displayName}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      Future.delayed(const Duration(milliseconds: 1400), () {
        if (!mounted) return;
        setState(() {
          _recentlyActivatedVehicleId = null;
        });
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible cambiar el vehículo activo. Detalle: $exception',
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
          _isSelecting = false;
        });
      }
    }
  }

  Future<void> _openManualVehicleForm() async {
    final created = await context.push(AppRoutes.manualVehicleForm);

    if (created == true) {
      _refreshUserVehicles();
      _refreshCatalog();
    }
  }

  Widget _buildUserVehicles(MapColors colors) {
    return FutureBuilder<List<UserVehicleModel>>(
      future: _userVehiclesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SectionStateCard(
            colors: colors,
            icon: Icons.directions_car_rounded,
            accent: colors.primary,
            title: 'Cargando tus vehículos',
            message: 'Estamos preparando tu garaje personal.',
          );
        }

        if (snapshot.hasError) {
          return _SectionStateCard(
            colors: colors,
            icon: Icons.error_outline_rounded,
            accent: colors.danger,
            title: 'No fue posible cargar tus vehículos',
            message: 'Detalle: ${snapshot.error}',
          );
        }

        final vehicles = snapshot.data ?? [];

        if (vehicles.isEmpty) {
          return _SectionStateCard(
            colors: colors,
            icon: Icons.garage_outlined,
            accent: colors.warning,
            title: 'Aún no tienes vehículos registrados',
            message:
                'Selecciona uno del catálogo o regístralo manualmente para empezar.',
          );
        }

        return Column(
          children: List.generate(vehicles.length, (index) {
            final vehicle = vehicles[index];

            return _AnimatedItem(
              index: index,
              child: _UserVehicleCard(
                colors: colors,
                vehicle: vehicle,
                isSelecting: _isSelecting,
                highlight:
                    _recentlyActivatedVehicleId != null &&
                    _recentlyActivatedVehicleId == vehicle.id,
                onUse: vehicle.isSelected
                    ? null
                    : () {
                        _setSelectedUserVehicle(vehicle);
                      },
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildCatalog(MapColors colors) {
    return FutureBuilder<List<VehicleCatalogModel>>(
      future: _catalogFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _SectionStateCard(
            colors: colors,
            icon: Icons.auto_awesome_motion_rounded,
            accent: colors.primary,
            title: 'Buscando en catálogo',
            message: 'Estamos cargando opciones para tu vehículo.',
          );
        }

        if (snapshot.hasError) {
          return _SectionStateCard(
            colors: colors,
            icon: Icons.error_outline_rounded,
            accent: colors.danger,
            title: 'No fue posible cargar el catálogo',
            message: 'Detalle: ${snapshot.error}',
          );
        }

        final vehicles = snapshot.data ?? [];

        if (vehicles.isEmpty) {
          return _SectionStateCard(
            colors: colors,
            icon: Icons.search_off_rounded,
            accent: colors.warning,
            title: 'No encontramos coincidencias',
            message:
                'Prueba otro criterio o registra el vehículo manualmente.',
          );
        }

        return Column(
          children: List.generate(vehicles.length, (index) {
            final vehicle = vehicles[index];

            return _AnimatedItem(
              index: index,
              child: _CatalogVehicleCard(
                colors: colors,
                vehicle: vehicle,
                isSelecting: _isSelecting,
                onSelect: () => _selectCatalogVehicle(vehicle),
              ),
            );
          }),
        );
      },
    );
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openManualVehicleForm,
        backgroundColor: colors.textPrimary.withOpacity(0.94),
        foregroundColor: colors.card,
        elevation: 0,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Manual'),
      ),
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
                child: _VehicleHeader(
                  colors: colors,
                  isDark: isDark,
                  isSelecting: _isSelecting,
                  onBack: () => Navigator.of(context).maybePop(),
                  onToggleTheme: _toggleTheme,
                  onAddManual: _openManualVehicleForm,
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
                child: _VehicleHeroCard(
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
                  12,
                ),
                child: _VehicleSectionHeader(
                  colors: colors,
                  title: 'Tus vehículos',
                  subtitle:
                      'Administra tu vehículo activo y cambia entre tus opciones registradas.',
                  accent: colors.primary,
                  icon: Icons.directions_car_filled_rounded,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  18,
                ),
                child: _buildUserVehicles(colors),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  12,
                ),
                child: _VehicleSectionHeader(
                  colors: colors,
                  title: 'Catálogo de vehículos',
                  subtitle:
                      'Busca por marca, modelo, año o versión y selecciona una opción compatible.',
                  accent: colors.accent,
                  icon: Icons.manage_search_rounded,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  12,
                ),
                child: _CatalogNoticeCard(colors: colors),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  16,
                ),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.card.withOpacity(0.98),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: _showSearchGlow
                          ? colors.primary.withOpacity(0.20)
                          : colors.border,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _showSearchGlow
                            ? colors.primary.withOpacity(0.10)
                            : colors.shadow.withOpacity(0.12),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: _CatalogSearchField(
                    colors: colors,
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onSearch: _refreshCatalog,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  0,
                  horizontalPadding,
                  90,
                ),
                child: _buildCatalog(colors),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VehicleHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isSelecting;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onAddManual;

  const _VehicleHeader({
    required this.colors,
    required this.isDark,
    required this.isSelecting,
    required this.onBack,
    required this.onToggleTheme,
    required this.onAddManual,
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
                    'Vehículo',
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
                'Gestiona tu garaje y registra nuevas opciones sin romper la coherencia visual.',
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
                    icon: isSelecting
                        ? Icons.hourglass_top_rounded
                        : Icons.add_rounded,
                    label: isSelecting ? 'Procesando' : 'Manual',
                    color: isSelecting ? colors.warning : colors.accent,
                    onTap: onAddManual,
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
                  'Vehículo',
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
                  'Gestiona tu garaje y registra nuevas opciones sin romper la coherencia visual.',
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
            icon: isSelecting
                ? Icons.hourglass_top_rounded
                : Icons.add_rounded,
            color: isSelecting ? colors.warning : colors.accent,
            bg: (isSelecting ? colors.warning : colors.accent).withOpacity(0.12),
            border:
                (isSelecting ? colors.warning : colors.accent).withOpacity(0.24),
            onTap: onAddManual,
          ),
        ],
      ),
    );
  }
}

class _VehicleHeroCard extends StatelessWidget {
  final MapColors colors;
  final bool isWide;

  const _VehicleHeroCard({
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
        borderRadius: BorderRadius.circular(30),
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
                _HeroGarageIcon(),
                SizedBox(width: 18),
                Expanded(child: _HeroGarageText()),
                SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: _HeroGaragePanel(),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HeroGarageIcon(),
                    SizedBox(width: 14),
                    Expanded(child: _HeroGarageText()),
                  ],
                ),
                SizedBox(height: 16),
                _HeroGaragePanel(),
              ],
            ),
    );
  }
}

class _HeroGarageIcon extends StatelessWidget {
  const _HeroGarageIcon();

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
        Icons.garage_rounded,
        size: 32,
        color: Colors.white,
      ),
    );
  }
}

class _HeroGarageText extends StatelessWidget {
  const _HeroGarageText();

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 430;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Garaje EcoPulse',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          compact ? 'Gestiona tu vehículo activo' : 'Elige tu vehículo activo',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            height: 1.08,
            color: Colors.white,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }
}

class _HeroGaragePanel extends StatelessWidget {
  const _HeroGaragePanel();

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
            icon: Icons.star_rounded,
            label: 'Clave',
            value: 'Vehículo activo',
          ),
          SizedBox(height: 10),
          _HeroMiniMetric(
            icon: Icons.tune_rounded,
            label: 'Beneficio',
            value: 'Más coherencia',
          ),
        ],
      ),
    );
  }
}

class _VehicleSectionHeader extends StatelessWidget {
  final MapColors colors;
  final String title;
  final String subtitle;
  final Color accent;
  final IconData icon;

  const _VehicleSectionHeader({
    required this.colors,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.10),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 20, color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14.4,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.8,
                    height: 1.42,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogNoticeCard extends StatelessWidget {
  final MapColors colors;

  const _CatalogNoticeCard({
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 14),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: colors.warning.withOpacity(0.18),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.14),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: colors.warning.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.warning.withOpacity(0.16),
              ),
            ),
            child: Icon(
              Icons.info_outline_rounded,
              size: 18,
              color: colors.warning,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Catálogo y datos demo',
                  style: TextStyle(
                    fontSize: 12.4,
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Los datos marcados como demo son vehiculos estandar creados para pruebas',
                  style: TextStyle(
                    fontSize: 11.9,
                    height: 1.5,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogSearchField extends StatelessWidget {
  final MapColors colors;
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;

  const _CatalogSearchField({
    required this.colors,
    required this.controller,
    required this.focusNode,
    required this.onSearch,
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

    return TextField(
      controller: controller,
      focusNode: focusNode,
      cursorColor: colors.primary,
      style: TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w600,
        color: colors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: 'Buscar por marca, modelo, año o versión',
        labelStyle: TextStyle(
          fontSize: 12.4,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
        ),
        hintText: 'Ejemplo: Mazda 3 2020',
        hintStyle: TextStyle(
          fontSize: 13.2,
          fontWeight: FontWeight.w500,
          color: colors.textSecondary.withOpacity(0.78),
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 20,
          color: colors.primary,
        ),
        suffixIcon: IconButton(
          onPressed: onSearch,
          icon: Icon(
            Icons.arrow_forward_rounded,
            color: colors.accent,
          ),
        ),
        filled: true,
        fillColor: colors.chip.withOpacity(0.72),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        enabledBorder: border(colors.border.withOpacity(0.90)),
        focusedBorder: border(colors.primary.withOpacity(0.95), 1.45),
      ),
      onSubmitted: (_) => onSearch(),
    );
  }
}

class _UserVehicleCard extends StatelessWidget {
  final MapColors colors;
  final UserVehicleModel vehicle;
  final bool isSelecting;
  final bool highlight;
  final VoidCallback? onUse;

  const _UserVehicleCard({
    required this.colors,
    required this.vehicle,
    required this.isSelecting,
    required this.highlight,
    required this.onUse,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = vehicle.isSelected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isActive
            ? LinearGradient(
                colors: [
                  colors.heroTop.withOpacity(0.98),
                  colors.heroBottom.withOpacity(0.98),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: isActive ? null : colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isActive
              ? colors.primary.withOpacity(0.18)
              : highlight
                  ? colors.success.withOpacity(0.22)
                  : colors.border,
        ),
        boxShadow: [
          BoxShadow(
            color: isActive
                ? colors.primary.withOpacity(0.16)
                : highlight
                    ? colors.success.withOpacity(0.10)
                    : colors.shadow.withOpacity(0.12),
            blurRadius: isActive ? 24 : 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: isActive
                          ? Colors.white.withOpacity(0.14)
                          : colors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: isActive
                            ? Colors.white.withOpacity(0.14)
                            : colors.primary.withOpacity(0.20),
                      ),
                    ),
                    child: Icon(
                      isActive
                          ? Icons.check_circle_rounded
                          : Icons.directions_car_rounded,
                      color: isActive ? Colors.white : colors.primary,
                      size: 24,
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
                            vehicle.displayName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              color: isActive ? Colors.white : colors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _VehicleMetaChip(
                                label: vehicle.fuelType,
                                color: isActive ? Colors.white : colors.primary,
                                filledOnDark: isActive,
                              ),
                              _VehicleMetaChip(
                                label: vehicle.isManual ? 'Manual' : 'Catálogo',
                                color: isActive ? Colors.white : colors.accent,
                                filledOnDark: isActive,
                              ),
                              if (isActive)
                                _VehicleMetaChip(
                                  label: 'Activo',
                                  color: Colors.white,
                                  filledOnDark: true,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (isActive)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.10),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          compact
                              ? 'Este vehículo está activo en EcoPulse.'
                              : 'Este es el vehículo que EcoPulse usa actualmente para métricas, recomendaciones y mantenimiento.',
                          style: TextStyle(
                            fontSize: 11.8,
                            height: 1.4,
                            color: Colors.white.withOpacity(0.86),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  width: compact ? double.infinity : null,
                  child: FilledButton.icon(
                    onPressed: isSelecting ? null : onUse,
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.textPrimary.withOpacity(0.94),
                      foregroundColor: colors.card,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    icon: isSelecting
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.card,
                            ),
                          )
                        : const Icon(Icons.flash_on_rounded, size: 18),
                    label: const Text('Usar este vehículo'),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CatalogVehicleCard extends StatelessWidget {
  final MapColors colors;
  final VehicleCatalogModel vehicle;
  final bool isSelecting;
  final VoidCallback onSelect;

  const _CatalogVehicleCard({
    required this.colors,
    required this.vehicle,
    required this.isSelecting,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final subtitleItems = [
      vehicle.engine,
      vehicle.fuelType,
      vehicle.transmission,
      vehicle.isExample ? 'Dato demo' : null,
    ].whereType<String>().toList();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: colors.shadow.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 420;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: colors.accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colors.accent.withOpacity(0.20)),
                    ),
                    child: Icon(
                      Icons.directions_car_filled_rounded,
                      size: 22,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        vehicle.displayName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14.8,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: subtitleItems.map((item) {
                  final isDemo = item == 'Dato demo';
                  final chipColor = isDemo ? colors.warning : colors.primary;

                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: chipColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: chipColor.withOpacity(0.16),
                      ),
                    ),
                    child: Text(
                      item,
                      style: TextStyle(
                        fontSize: 11.2,
                        fontWeight: FontWeight.w700,
                        color: chipColor,
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: compact ? double.infinity : null,
                child: FilledButton.icon(
                  onPressed: isSelecting ? null : onSelect,
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.textPrimary.withOpacity(0.94),
                    foregroundColor: colors.card,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  icon: isSelecting
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.card,
                          ),
                        )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Seleccionar'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VehicleMetaChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool filledOnDark;

  const _VehicleMetaChip({
    required this.label,
    required this.color,
    this.filledOnDark = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = filledOnDark ? Colors.white.withOpacity(0.10) : color.withOpacity(0.10);
    final border = filledOnDark ? Colors.white.withOpacity(0.14) : color.withOpacity(0.16);
    final textColor = filledOnDark ? Colors.white : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.1,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }
}

class _AnimatedItem extends StatelessWidget {
  final int index;
  final Widget child;

  const _AnimatedItem({
    required this.index,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 280 + (index * 45)),
      curve: Curves.easeOutCubic,
      builder: (context, value, animatedChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 18),
            child: animatedChild,
          ),
        );
      },
      child: child,
    );
  }
}

class _SectionStateCard extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;

  const _SectionStateCard({
    required this.colors,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: accent.withOpacity(0.20)),
            ),
            child: Icon(icon, size: 20, color: accent),
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
                      fontSize: 14.2,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: TextStyle(
                      fontSize: 11.9,
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