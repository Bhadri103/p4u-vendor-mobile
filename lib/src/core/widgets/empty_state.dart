import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    super.key,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 34, horizontal: 18),
          child: Column(
            children: [
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border)),
                child: Icon(icon, size: 31, color: AppColors.slate),
              ),
              const SizedBox(height: 13),
              Text(title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: AppColors.brandDark,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12, height: 1.4)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
