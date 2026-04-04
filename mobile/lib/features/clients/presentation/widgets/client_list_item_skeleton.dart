import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ClientListItemSkeleton extends StatelessWidget {
  const ClientListItemSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(backgroundColor: AppColors.neutral200),
      title: Container(
        height: 14,
        width: 120,
        decoration: BoxDecoration(
          color: AppColors.neutral200,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 10,
        width: 80,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: AppColors.neutral100,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
