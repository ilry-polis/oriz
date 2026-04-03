import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class TagChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final bool readOnly;

  const TagChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.readOnly = false,
  });

  Color get _backgroundColor {
    if (selected) return _tagColor.withAlpha(38);
    return AppColors.neutral100;
  }

  Color get _tagColor {
    switch (label.toLowerCase()) {
      case 'vip':
        return AppColors.accent;
      case 'novo':
        return AppColors.info;
      case 'inativo':
        return AppColors.neutral400;
      default:
        return AppColors.neutral600;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: readOnly ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: selected ? Border.all(color: _tagColor, width: 1) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: _tagColor,
          ),
        ),
      ),
    );
  }
}
