import 'package:ecopulse/data/models/profile_model.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/shared/widgets/app_text_field.dart';
import 'package:ecopulse/shared/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
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

  Future<void> _saveProfile(ProfileModel profile) async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

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
        const SnackBar(
          content: Text('Perfil actualizado correctamente.'),
        ),
      );
    } catch (exception) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No fue posible actualizar el perfil. Detalle: $exception',
          ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
      ),
      body: SafeArea(
        child: FutureBuilder<ProfileModel>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(22),
                child: Text(
                  'No fue posible cargar el perfil. Detalle: ${snapshot.error}',
                ),
              );
            }

            final profile = snapshot.data!;

            _loadControllers(profile);

            return ListView(
              padding: const EdgeInsets.all(22),
              children: [
                const Text(
                  'Actualiza tus datos básicos. Esta información se usará para personalizar tu experiencia dentro de EcoPulse.',
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text(
                      'Correo: ${profile.email ?? 'No disponible'}',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                        controller: _fullNameController,
                        label: 'Nombre completo',
                        validator: _validateName,
                      ),
                      const SizedBox(height: 16),
                      AppTextField(
                        controller: _phoneController,
                        label: 'Teléfono',
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 22),
                      PrimaryActionButton(
                        text: 'Guardar cambios',
                        icon: Icons.save_rounded,
                        isLoading: _isLoading,
                        onPressed: () {
                          _saveProfile(profile);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

