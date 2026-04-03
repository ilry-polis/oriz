import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/client_model.dart';
import 'tag_chip.dart';

class ClientListItem extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onTap;

  const ClientListItem({super.key, required this.client, this.onTap});

  String get _lastVisitText {
    if (client.lastAppointmentAt == null) return '';
    try {
      final date = DateTime.parse(client.lastAppointmentAt!);
      final months = [
        'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
        'jul', 'ago', 'set', 'out', 'nov', 'dez'
      ];
      return 'Última visita: ${date.day} ${months[date.month - 1]}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: AppColors.neutral200,
        child: Text(
          client.initials,
          style: const TextStyle(
              color: AppColors.neutral600, fontWeight: FontWeight.w600),
        ),
      ),
      title: Text(client.name),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_lastVisitText.isNotEmpty)
            Text(_lastVisitText,
                style:
                    const TextStyle(fontSize: 12, color: AppColors.neutral400)),
          if (client.allTags.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Wrap(
                spacing: 4,
                children: client.allTags
                    .map((t) => TagChip(label: t, readOnly: true))
                    .toList(),
              ),
            ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.neutral300),
    );
  }
}
