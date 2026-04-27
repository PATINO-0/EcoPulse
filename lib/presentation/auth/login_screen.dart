import 'package:ecopulse/app/routes.dart';
import 'package:ecopulse/core/constants/app_constants.dart';
import 'package:ecopulse/data/repositories/auth_repository.dart';
import 'package:ecopulse/shared/widgets/app_text_field.dart';
import 'package:ecopulse/shared/widgets/primary_action_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() {
    return _LoginScreenState();
  }
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await ref.read(authRepositoryProvider).signIn(
            email: _emailController.text,
            password: _passwordController.text,
          );

      if (!mounted) {
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

  Future<void> _showResetPasswordDialog() async {
    final TextEditingController resetEmailController = TextEditingController(
      text: _emailController.text,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        bool isSending = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Recuperar contraseña'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Escribe tu correo y te enviaremos instrucciones para recuperar tu cuenta.',
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: resetEmailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isSending
                      ? null
                      : () {
                          Navigator.of(dialogContext).pop();
                        },
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: isSending
                      ? null
                      : () async {
                          setDialogState(() {
                            isSending = true;
                          });

                          try {
                            await ref
                                .read(authRepositoryProvider)
                                .sendPasswordResetEmail(
                                  email: resetEmailController.text,
                                );

                            if (!mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop();

                            _showMessage(
                              'Correo de recuperación enviado. Revisa tu bandeja de entrada.',
                            );
                          } catch (exception) {
                            if (!mounted) {
                              return;
                            }

                            Navigator.of(dialogContext).pop();

                            _showMessage(
                              exception
                                  .toString()
                                  .replaceFirst('Exception: ', ''),
                            );
                          }
                        },
                  child: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );

    resetEmailController.dispose();
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
      return 'Ingresa tu contraseña.';
    }

    if (value.length < 6) {
      return 'La contraseña debe tener mínimo 6 caracteres.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.all(24),
            children: [
              const Icon(
                Icons.eco_rounded,
                size: 72,
                color: Color(0xFF1F8A4C),
              ),
              const SizedBox(height: 20),
              Text(
                AppConstants.appName,
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Inicia sesión para registrar tus trayectos y consultar tus métricas de conducción.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
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
                    const SizedBox(height: 20),
                    PrimaryActionButton(
                      text: 'Iniciar sesión',
                      icon: Icons.login_rounded,
                      isLoading: _isLoading,
                      onPressed: _signIn,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: _showResetPasswordDialog,
                child: const Text('Olvidé mi contraseña'),
              ),
              TextButton(
                onPressed: () {
                  context.go(AppRoutes.register);
                },
                child: const Text('Crear cuenta nueva'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}