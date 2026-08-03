import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_card.dart';

class MetricCard extends StatelessWidget {
  const MetricCard({
    required this.icon,
    required this.label,
    required this.value,
    this.caption,
    this.color = AppColors.primary,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? caption;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: .22)),
            ),
            child: Icon(icon, size: 19, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.brandDark,
                        fontWeight: FontWeight.w600)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600)),
                if (caption != null)
                  Text(caption!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 9,
                          color: AppColors.muted,
                          fontWeight: FontWeight.w400)),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.arrow_outward_rounded,
                size: 16, color: AppColors.muted),
        ],
      ),
    );
  }
}
