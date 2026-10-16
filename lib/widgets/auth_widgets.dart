import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Background gradient dengan pola lingkaran dekoratif di belakang konten.
class AuthBackground extends StatelessWidget {
  const AuthBackground({
    super.key,
    required this.child,
    this.gradient = AppColors.authGradient,
  });

  final Widget child;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: gradient),
      child: Stack(
        children: <Widget>[
          const Positioned(
            top: -60,
            right: -40,
            child: _Circle(size: 200, opacity: 0.10),
          ),
          const Positioned(
            bottom: -80,
            left: -50,
            child: _Circle(size: 240, opacity: 0.10),
          ),
          Positioned.fill(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.opacity});

  final double size;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: opacity),
      ),
    );
  }
}

/// Kartu putih tempat form login / register berada.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Field input dengan ikon di kiri dan tombol lihat password opsional.
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.hint,
    this.obscure = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? hint;
  final bool obscure;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onSubmitted;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _hidden = widget.obscure;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          widget.label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          obscureText: _hidden,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onFieldSubmitted: widget.onSubmitted,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: Icon(widget.icon, color: AppColors.textLight),
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _hidden ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textLight,
                    ),
                    onPressed: () => setState(() => _hidden = !_hidden),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}

/// Logo aplikasi yang tampil di atas kartu auth.
class AuthLogo extends StatelessWidget {
  const AuthLogo({
    super.key,
    required this.title,
    required this.subtitle,
    this.imageAsset,
  });

  final String title;
  final String subtitle;

  /// Aset gambar logo. Jika diisi, gambar ditampilkan di atas judul.
  final String? imageAsset;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        if (imageAsset != null)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Image.asset(
                imageAsset!,
                width: 220,
                fit: BoxFit.contain,
              ),
            ),
          )
        else
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.sports_esports_rounded,
              size: 46,
              color: AppColors.primary,
            ),
          ),
        const SizedBox(height: 18),
        Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
