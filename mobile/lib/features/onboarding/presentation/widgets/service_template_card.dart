import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

const _durationOptions = [15, 30, 45, 60, 75, 90, 105, 120, 150, 180, 210, 240];

String _formatPrice(int cents) {
  final reais = cents ~/ 100;
  final centavos = cents % 100;
  return 'R\$ $reais,${centavos.toString().padLeft(2, '0')}';
}

int _parsePrice(String text) {
  final cleaned = text.replaceAll(RegExp(r'[^0-9]'), '');
  return int.tryParse(cleaned) ?? 0;
}

class ServiceTemplateCard extends StatefulWidget {
  final String name;
  final int durationMinutes;
  final int price;
  final VoidCallback onRemove;
  final void Function(String name, int durationMinutes, int price) onChanged;

  const ServiceTemplateCard({
    super.key,
    required this.name,
    required this.durationMinutes,
    required this.price,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<ServiceTemplateCard> createState() => _ServiceTemplateCardState();
}

class _ServiceTemplateCardState extends State<ServiceTemplateCard> {
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late int _duration;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.name);
    _priceController = TextEditingController(text: _formatPrice(widget.price));
    _duration = widget.durationMinutes;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyChanged() {
    widget.onChanged(
      _nameController.text,
      _duration,
      _parsePrice(_priceController.text),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  style: AppTypography.bodySemibold,
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    border: InputBorder.none,
                  ),
                  onChanged: (_) => _notifyChanged(),
                ),
              ),
              SizedBox(
                width: 44,
                height: 44,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 18, color: AppColors.neutral400),
                  onPressed: widget.onRemove,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _durationOptions.contains(_duration) ? _duration : 30,
                  isExpanded: true,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  items: _durationOptions
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text('$d min', style: AppTypography.caption),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _duration = value);
                      _notifyChanged();
                    }
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  style: AppTypography.caption,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      borderSide: const BorderSide(color: AppColors.neutral200),
                    ),
                  ),
                  onChanged: (_) => _notifyChanged(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
