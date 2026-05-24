import 'package:ecopulse/data/models/profile_model.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/presentation/map/map_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() {
    return _ProfileScreenState();
  }
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  late Future<ProfileModel> _profileFuture;

  bool _isLoading = false;
  bool _controllersLoaded = false;
  bool? _manualDark;

  @override
  void initState() {
    super.initState();
    _profileFuture = ref.read(authRepositoryProvider).getCurrentProfile();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool _isDark(BuildContext context) =>
      _manualDark ??
      (MediaQuery.of(context).platformBrightness == Brightness.dark);

  void _toggleTheme() {
    HapticFeedback.lightImpact();
    setState(() => _manualDark = !_isDark(context));
  }

  Future<void> _reloadProfile() async {
    HapticFeedback.lightImpact();
    setState(() {
      _controllersLoaded = false;
      _profileFuture = ref.read(authRepositoryProvider).getCurrentProfile();
    });
    await _profileFuture;
  }

  Future<void> _saveProfile(ProfileModel profile) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedProfile = profile.copyWith(
        fullName: _fullNameController.text.trim(),
        phone: _phoneController.text.trim(),
      );

      await ref.read(authRepositoryProvider).updateProfile(
            profile: updatedProfile,
          );

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Perfil actualizado correctamente.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        ),
      );

      setState(() {
        _profileFuture = Future.value(updatedProfile);
      });
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible actualizar el perfil. Detalle: $exception',
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
          _isLoading = false;
        });
      }
    }
  }

  void _loadControllers(ProfileModel profile) {
    if (_controllersLoaded) {
      return;
    }

    _fullNameController.text = profile.fullName ?? '';
    _phoneController.text = profile.phone ?? '';
    _controllersLoaded = true;
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu nombre.';
    }
    return null;
  }

  String _initialsFrom(ProfileModel profile) {
    final source = (profile.fullName ?? profile.email ?? 'Eco Pulse').trim();
    if (source.isEmpty) return 'EP';

    final parts = source
        .split(' ')
        .where((e) => e.trim().isNotEmpty)
        .map((e) => e.trim())
        .toList();

    if (parts.isEmpty) return 'EP';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();

    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = _isDark(context);
    final colors = MapColors(isDark);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ProfileModel>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _ProfileLoadingView(colors: colors);
            }

            if (snapshot.hasError) {
              return _ProfileStatusView(
                colors: colors,
                icon: Icons.person_off_rounded,
                accent: colors.danger,
                title: 'No fue posible cargar tu perfil',
                message: 'Detalle: ${snapshot.error}',
                actionLabel: 'Reintentar',
                onPressed: _reloadProfile,
              );
            }

            final profile = snapshot.data!;
            _loadControllers(profile);

            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isTablet = width >= 760;
                final isDesktop = width >= 1140;
                final horizontalPadding = isDesktop
                    ? 30.0
                    : isTablet
                        ? 24.0
                        : 18.0;

                return CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          14,
                          horizontalPadding,
                          14,
                        ),
                        child: _ProfileHeader(
                          colors: colors,
                          isDark: isDark,
                          isLoading: _isLoading,
                          onBack: () => Navigator.of(context).maybePop(),
                          onToggleTheme: _toggleTheme,
                          onRefresh: _reloadProfile,
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
                        child: _ProfileHeroCard(
                          colors: colors,
                          profile: profile,
                          initials: _initialsFrom(profile),
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
                        child: isTablet
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 5,
                                    child: _ProfileInfoPanel(
                                      colors: colors,
                                      profile: profile,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    flex: 7,
                                    child: _ProfileFormCard(
                                      colors: colors,
                                      formKey: _formKey,
                                      fullNameController: _fullNameController,
                                      phoneController: _phoneController,
                                      isLoading: _isLoading,
                                      onSave: () => _saveProfile(profile),
                                      validateName: _validateName,
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  _ProfileInfoPanel(
                                    colors: colors,
                                    profile: profile,
                                  ),
                                  const SizedBox(height: 16),
                                  _ProfileFormCard(
                                    colors: colors,
                                    formKey: _formKey,
                                    fullNameController: _fullNameController,
                                    phoneController: _phoneController,
                                    isLoading: _isLoading,
                                    onSave: () => _saveProfile(profile),
                                    validateName: _validateName,
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final MapColors colors;
  final bool isDark;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onToggleTheme;
  final VoidCallback onRefresh;

  const _ProfileHeader({
    required this.colors,
    required this.isDark,
    required this.isLoading,
    required this.onBack,
    required this.onToggleTheme,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;

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
                        'Mi perfil',
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
                    'Gestiona tus datos y mantén tu experiencia de EcoPulse siempre actualizada.',
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
                        icon: isLoading
                            ? Icons.hourglass_top_rounded
                            : Icons.refresh_rounded,
                        label: isLoading ? 'Guardando' : 'Recargar',
                        color: isLoading ? colors.warning : colors.accent,
                        onTap: onRefresh,
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
                      'Mi perfil',
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
                      'Gestiona tus datos y mantén tu experiencia de EcoPulse siempre actualizada.',
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
                icon: isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.refresh_rounded,
                color: isLoading ? colors.warning : colors.accent,
                bg:
                    (isLoading ? colors.warning : colors.accent).withOpacity(
                  0.12,
                ),
                border:
                    (isLoading ? colors.warning : colors.accent).withOpacity(
                  0.24,
                ),
                onTap: onRefresh,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  final MapColors colors;
  final ProfileModel profile;
  final String initials;
  final bool isWide;

  const _ProfileHeroCard({
    required this.colors,
    required this.profile,
    required this.initials,
    required this.isWide,
  });

  @override
  Widget build(BuildContext context) {
    final displayName =
        (profile.fullName?.trim().isNotEmpty ?? false)
            ? profile.fullName!.trim()
            : 'Usuario EcoPulse';

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
              children: [
                _ProfileAvatar(initials: initials),
                const SizedBox(width: 18),
                Expanded(
                  child: _HeroIdentityBlock(
                    displayName: displayName,
                    email: profile.email ?? 'No disponible',
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  width: 240,
                  child: _HeroStatusPanel(colors: colors, profile: profile),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _ProfileAvatar(initials: initials),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _HeroIdentityBlock(
                        displayName: displayName,
                        email: profile.email ?? 'No disponible',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _HeroStatusPanel(colors: colors, profile: profile),
              ],
            ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final String initials;

  const _ProfileAvatar({required this.initials});

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
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.6,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _HeroIdentityBlock extends StatelessWidget {
  final String displayName;
  final String email;

  const _HeroIdentityBlock({
    required this.displayName,
    required this.email,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Perfil personal',
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.72),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          displayName,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          email,
          maxLines: 2,
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

class _HeroStatusPanel extends StatelessWidget {
  final MapColors colors;
  final ProfileModel profile;

  const _HeroStatusPanel({
    required this.colors,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = (profile.phone?.trim().isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          _HeroMiniMetric(
            icon: Icons.verified_user_rounded,
            label: 'Estado del perfil',
            value: hasPhone ? 'Completo' : 'Incompleto',
          ),
          const SizedBox(height: 10),
          _HeroMiniMetric(
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: hasPhone ? 'Registrado' : 'Pendiente',
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

class _ProfileInfoPanel extends StatelessWidget {
  final MapColors colors;
  final ProfileModel profile;

  const _ProfileInfoPanel({
    required this.colors,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhone = (profile.phone?.trim().isNotEmpty ?? false);
    final hasName = (profile.fullName?.trim().isNotEmpty ?? false);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Resumen de cuenta',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Consulta tu información principal y el estado actual de tu perfil.',
            style: TextStyle(
              fontSize: 12.4,
              height: 1.45,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          _ProfileInfoTile(
            colors: colors,
            icon: Icons.email_rounded,
            label: 'Correo',
            value: profile.email ?? 'No disponible',
            accent: colors.primary,
          ),
          const SizedBox(height: 12),
          _ProfileInfoTile(
            colors: colors,
            icon: Icons.badge_rounded,
            label: 'Nombre registrado',
            value: hasName ? profile.fullName!.trim() : 'Pendiente de completar',
            accent: colors.accent,
          ),
          const SizedBox(height: 12),
          _ProfileInfoTile(
            colors: colors,
            icon: Icons.phone_rounded,
            label: 'Teléfono',
            value: hasPhone ? profile.phone!.trim() : 'Pendiente de registrar',
            accent: colors.warning,
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _ProfileInfoTile({
    required this.colors,
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.chip,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.chipBorder),
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
                    label,
                    style: TextStyle(
                      fontSize: 11.2,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.0,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
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

class _ProfileFormCard extends StatelessWidget {
  final MapColors colors;
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController phoneController;
  final bool isLoading;
  final VoidCallback onSave;
  final String? Function(String?) validateName;

  const _ProfileFormCard({
    required this.colors,
    required this.formKey,
    required this.fullNameController,
    required this.phoneController,
    required this.isLoading,
    required this.onSave,
    required this.validateName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.card.withOpacity(0.98),
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
      child: Form(
        key: formKey,
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
                    color: colors.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: colors.primary.withOpacity(0.20)),
                  ),
                  child: Icon(
                    Icons.edit_note_rounded,
                    size: 22,
                    color: colors.primary,
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
                          'Editar información',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Actualiza tus datos básicos y mantén tu perfil alineado con la experiencia de EcoPulse.',
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
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.chip,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.chipBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Datos editables',
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Estos datos se usan para personalizar tu cuenta y futuras funciones dentro de la app.',
                    style: TextStyle(
                      fontSize: 11.6,
                      height: 1.45,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileStyledField(
                    controller: fullNameController,
                    label: 'Nombre completo',
                    hint: 'Escribe tu nombre completo',
                    icon: Icons.person_rounded,
                    colors: colors,
                    validator: validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 14),
                  _ProfileStyledField(
                    controller: phoneController,
                    label: 'Teléfono',
                    hint: 'Ingresa tu número de contacto',
                    icon: Icons.phone_rounded,
                    colors: colors,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: colors.primary.withOpacity(0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acción principal',
                    style: TextStyle(
                      fontSize: 11.4,
                      fontWeight: FontWeight.w700,
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Guarda los cambios para actualizar tu información de perfil.',
                    style: TextStyle(
                      fontSize: 12.2,
                      height: 1.4,
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _ProfileSaveButton(
                    colors: colors,
                    text: 'Guardar cambios',
                    icon: Icons.save_rounded,
                    isLoading: isLoading,
                    onPressed: onSave,
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

class _ProfileStyledField extends StatelessWidget {
  final MapColors colors;
  final TextEditingController controller;
  final String label;
  final String hint;
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
            fillColor: colors.card.withOpacity(0.92),
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

class _ProfileSaveButton extends StatelessWidget {
  final MapColors colors;
  final String text;
  final IconData icon;
  final bool isLoading;
  final VoidCallback onPressed;

  const _ProfileSaveButton({
    required this.colors,
    required this.text,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final buttonColor = colors.textPrimary;
    final softSurface = colors.textPrimary.withOpacity(0.06);
    final borderColor = colors.textPrimary.withOpacity(0.10);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading
            ? null
            : () {
                HapticFeedback.lightImpact();
                onPressed();
              },
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isLoading ? softSurface.withOpacity(0.75) : softSurface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withOpacity(0.35),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.1,
                    color: buttonColor,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Guardando...',
                  style: TextStyle(
                    fontSize: 13.8,
                    fontWeight: FontWeight.w800,
                    color: buttonColor,
                    letterSpacing: -0.1,
                  ),
                ),
              ] else ...[
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.12),
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 16,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    text,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.8,
                      fontWeight: FontWeight.w800,
                      color: buttonColor,
                      letterSpacing: -0.1,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileLoadingView extends StatelessWidget {
  final MapColors colors;

  const _ProfileLoadingView({required this.colors});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: colors.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Cargando perfil',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Estamos preparando tu información personal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.5,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileStatusView extends StatelessWidget {
  final MapColors colors;
  final IconData icon;
  final Color accent;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _ProfileStatusView({
    required this.colors,
    required this.icon,
    required this.accent,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(22),
      children: [
        Container(
          width: double.infinity,
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: colors.border),
            boxShadow: [
              BoxShadow(
                color: colors.shadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: accent.withOpacity(0.22)),
                ),
                child: Icon(icon, color: accent, size: 26),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.8,
                  height: 1.55,
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: onPressed,
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded),
                label: Text(actionLabel),
              ),
            ],
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