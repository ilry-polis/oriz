import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/service_model.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(
        service.name,
        style: TextStyle(
          color: service.isActive ? AppColors.neutral900 : AppColors.neutral400,
        ),
      ),
      subtitle: Text(
        '${service.formattedDuration} • ${service.formattedPrice}',
        style: TextStyle(
          fontSize: 13,
          color: service.isActive ? AppColors.neutral600 : AppColors.neutral300,
        ),
      ),
      trailing: service.isActive
          ? const Icon(Icons.chevron_right, color: AppColors.neutral300)
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Inativo',
                style: TextStyle(fontSize: 11, color: AppColors.neutral400),
              ),
            ),
    );
  }
}
