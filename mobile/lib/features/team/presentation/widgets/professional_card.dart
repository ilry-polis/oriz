import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/professional_model.dart';

class ProfessionalCard extends StatelessWidget {
  final ProfessionalModel professional;
  final VoidCallback? onTap;

  const ProfessionalCard({super.key, required this.professional, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.neutral200,
        child: Text(
          professional.name.isNotEmpty ? professional.name[0].toUpperCase() : '?',
          style: const TextStyle(color: AppColors.neutral600, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(
        professional.name,
        style: TextStyle(
          color: professional.isActive ? AppColors.neutral900 : AppColors.neutral400,
        ),
      ),
      subtitle: Text(
        'Comissão: ${professional.formattedCommission}',
        style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
      ),
      trailing: professional.isActive
          ? const Icon(Icons.chevron_right, color: AppColors.neutral300)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text('Inativa', style: TextStyle(fontSize: 11, color: AppColors.neutral400)),
            ),
    );
  }
}
