import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    FocusScope.of(context).unfocus();
    setState(() => _loading = true);

    final error = await AuthService.resetPassword(
      email: _emailController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error != null) {
      _showMessage(error, isError: true);
      return;
    }

    _showMessage('Password berhasil direset. Silakan login kembali.');
    Navigator.of(context).pop();
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
                    title: 'Lupa Password?',
                    subtitle: 'Buat password baru untuk akunmu',
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
                            'Reset Password',
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
                            label: 'Email terdaftar',
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
                            controller: _newPasswordController,
                            label: 'Password baru',
                            hint: 'Minimal 8 karakter',
                            icon: Icons.lock_outline,
                            obscure: true,
                            textInputAction: TextInputAction.next,
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
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _confirmController,
                            label: 'Konfirmasi password baru',
                            hint: 'Ulangi password baru',
                            icon: Icons.lock_reset_outlined,
                            obscure: true,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Konfirmasi password wajib diisi';
                              }
                              if (value != _newPasswordController.text) {
                                return 'Password tidak sama';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
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
                                : const Text('Reset Password'),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              const Text(
                                'Ingat password? ',
                                style: TextStyle(color: AppColors.textLight),
                              ),
                              GestureDetector(
                                onTap: _loading
                                    ? null
                                    : () => Navigator.of(context).pop(),
                                child: const Text(
                                  'Kembali Login',
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
