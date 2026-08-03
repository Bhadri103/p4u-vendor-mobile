import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      'active' ||
      'verified' ||
      'settled' ||
      'completed' ||
      'delivered' =>
        AppColors.success,
      'pending' ||
      'pending_approval' ||
      'eligible' ||
      'in_progress' ||
      'offline_pending' =>
        AppColors.warning,
      'paid' || 'accepted' || 'confirmed' || 'shipped' => AppColors.info,
      'cancelled' ||
      'rejected' ||
      'inactive' ||
      'on_hold' ||
      'deleted' =>
        AppColors.danger,
      _ => AppColors.muted,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: .18)),
      ),
      child: Text(
        status.replaceAll('_', ' '),
        style: TextStyle(
            color: color, fontSize: 10, height: 1, fontWeight: FontWeight.w600),
      ),
    );
  }
}
