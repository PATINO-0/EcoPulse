import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/shared/widgets/app_text_field.dart';
import 'package:ecopulse/shared/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() {
    return _RegisterScreenState();
  }
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _acceptedPolicy = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (!_acceptedPolicy) {
      _showMessage(
        'Debes aceptar la política de tratamiento de datos para crear tu cuenta.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authRepositoryProvider).signUp(
            fullName: _fullNameController.text,
            email: _emailController.text,
            password: _passwordController.text,
            acceptedPolicy: _acceptedPolicy,
          );

      if (!mounted) {
        return;
      }

      final session = ref.read(authRepositoryProvider).currentSession;

      if (session == null) {
        _showMessage(
          'Cuenta creada. Revisa tu correo si Supabase solicita confirmación.',
        );
        context.go(AppRoutes.login);
        return;
      }

      context.go(AppRoutes.home);
    } catch (exception) {
      _showMessage(exception.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo es obligatorio.';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingresa tu correo electrónico.';
    }

    if (!value.contains('@')) {
      return 'Ingresa un correo válido.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ingresa una contraseña.';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres.';
    }

    return null;
  }

  String? _validatePasswordConfirmation(String? value) {
    if (value != _passwordController.text) {
      return 'Las contraseñas no coinciden.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final canRegister = _acceptedPolicy && !_isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const Text(
              'Crea tu cuenta para guardar tus trayectos, vehículos, métricas y recomendaciones.',
            ),
            const SizedBox(height: 20),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  AppTextField(
                    controller: _fullNameController,
                    label: 'Nombre completo',
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _emailController,
                    label: 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    obscureText: _obscurePassword,
                    validator: _validatePassword,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar contraseña',
                    obscureText: _obscureConfirmPassword,
                    validator: _validatePasswordConfirmation,
                    suffixIcon: IconButton(
                      onPressed: () {
                        setState(() {
                          _obscureConfirmPassword =
                              !_obscureConfirmPassword;
                        });
                      },
                      icon: Icon(
                        _obscureConfirmPassword
                            ? Icons.visibility_rounded
                            : Icons.visibility_off_rounded,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: _acceptedPolicy,
                      onChanged: (value) {
                        setState(() {
                          _acceptedPolicy = value ?? false;
                        });
                      },
                      title: const Text(
                        'Acepto la política de tratamiento de datos personales.',
                      ),
                      subtitle: const Text(
                        'EcoPulse procesará ubicación, velocidad, sensores, trayectos, datos del vehículo y métricas de conducción.',
                      ),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          context.push(AppRoutes.privacyPolicy);
                        },
                        icon: const Icon(Icons.description_rounded),
                        label: const Text('Leer política completa'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            PrimaryActionButton(
              text: 'Crear cuenta',
              icon: Icons.person_add_alt_1_rounded,
              isLoading: _isLoading,
              onPressed: canRegister ? _register : null,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () {
                context.go(AppRoutes.login);
              },
              child: const Text('Ya tengo cuenta'),
            ),
          ],
        ),
      ),
    );
  }
}