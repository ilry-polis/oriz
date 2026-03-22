import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextEditingController? controller;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.controller,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.label, style: AppTypography.caption),
        const SizedBox(height: AppSpacing.xs),
        SizedBox(
          height: 48,
          child: TextField(
            controller: widget.controller,
            obscureText: _obscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            style: AppTypography.body,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.neutral100,
              contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.neutral200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.neutral200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: BorderSide(color: hasError ? AppColors.error : AppColors.primary),
              ),
              disabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.md),
                borderSide: const BorderSide(color: AppColors.neutral200),
              ),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.neutral400,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscured = !_obscured),
                    )
                  : null,
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(widget.errorText!, style: AppTypography.caption.copyWith(color: AppColors.error)),
        ],
      ],
    );
  }
}
