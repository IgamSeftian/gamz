import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';
import 'forgot_password_screen.dart';
import 'main_menu_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _loading = false;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final error = await AuthService.login(
      email: _emailController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    _showMessage('Login berhasil. Selamat datang!');
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainMenuScreen()),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? AppColors.danger : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  Future<void> _goToRegister() async {
    final registered = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (_) => const RegisterScreen()),
    );

    if (registered == true && mounted) {
      _showMessage('Registrasi berhasil. Silakan login.');
    }
  }

  Future<void> _goToForgotPassword() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ForgotPasswordScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                children: <Widget>[
                  const AuthLogo(
                    title: 'Dapoer Iboe',
                    subtitle: 'Masuk untuk melanjutkan',
                    imageAsset: 'assets/images/DapoerIboe.png',
                  ),
                  const SizedBox(height: 28),
                  AuthCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          const Text(
                            'Login',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 24),
                          AppTextField(
                            controller: _emailController,
                            label: 'Email',
                            hint: 'nama@email.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              final email = value.trim();
                              final valid = RegExp(
                                r'^[\w\.\-]+@[\w\-]+\.[\w\.\-]+$',
                              ).hasMatch(email);
                              if (!valid) return 'Format email tidak valid';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _passwordController,
                            label: 'Password',
                            hint: 'Minimal 8 karakter',
                            icon: Icons.lock_outline,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Password wajib diisi';
                              }
                              if (value.length < 8) {
                                return 'Password minimal 8 karakter';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _loading ? null : _goToForgotPassword,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text(
                                'Lupa Password?',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: <Widget>[
                              SizedBox(
                                height: 24,
                                width: 24,
                                child: Checkbox(
                                  value: _rememberMe,
                                  activeColor: AppColors.primary,
                                  onChanged: (v) =>
                                      setState(() => _rememberMe = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                'Ingat saya',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          FilledButton(
                            onPressed: _loading ? null : _submit,
                            child: _loading
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Login'),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text(
                                'Belum punya akun? ',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                              GestureDetector(
                                onTap: _loading ? null : _goToRegister,
                                child: const Text(
                                  'Daftar sekarang',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
