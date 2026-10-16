import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Field dengan label kecil di atasnya, dipakai pada form master.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

/// Input teks biasa untuk form master.
class MasterTextField extends StatelessWidget {
  const MasterTextField({
    super.key,
    required this.controller,
    this.hint,
    this.icon,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.maxLines = 1,
    this.readOnly = false,
    this.textInputAction,
    this.onChanged,
    this.validator,
  });

  final TextEditingController controller;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int maxLines;
  final bool readOnly;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      maxLines: maxLines,
      textInputAction: textInputAction,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: icon == null ? null : Icon(icon, color: AppColors.textLight),
        counterText: '',
      ),
    );
  }
}

/// Kartu daftar master (item/customer/penjualan) dengan aksi Edit & Hapus.
class MasterListCard extends StatelessWidget {
  const MasterListCard({
    super.key,
    required this.badge,
    required this.title,
    required this.lines,
    required this.onEdit,
    required this.onDelete,
  });

  final String badge;
  final String title;
  final List<String> lines;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  for (final line in lines) ...<Widget>[
                    const SizedBox(height: 4),
                    Text(
                      line,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textLight,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppColors.danger),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

/// Tampilan saat daftar master masih kosong.
class EmptyList extends StatelessWidget {
  const EmptyList({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textLight),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textLight),
          ),
        ],
      ),
    );
  }
}
