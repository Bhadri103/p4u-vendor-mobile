import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// A visual page identity shared across the vendor app. When an explicit image
/// is not supplied, the most relevant illustration is selected from the title.
class VendorPageIntro extends StatelessWidget {
  const VendorPageIntro({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.accent = AppColors.primary,
    this.trailing,
    this.imageAsset,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Widget? trailing;
  final String? imageAsset;

  String get _resolvedAsset {
    if (imageAsset != null) return imageAsset!;
    final value = title.toLowerCase();
    if (value.contains('service') ||
        value.contains('booking') ||
        value.contains('availability') ||
        value.contains('schedule')) {
      return 'assets/images/vendor/service-schedule.png';
    }
    if (value.contains('payment') ||
        value.contains('settlement') ||
        value.contains('bank') ||
        value.contains('wallet') ||
        value.contains('money') ||
        value.contains('payout') ||
        value.contains('report') ||
        value.contains('analytics') ||
        value.contains('earning')) {
      return 'assets/images/vendor/finance-growth.png';
    }
    if (value.contains('profile') ||
        value.contains('identity') ||
        value.contains('trust') ||
        value.contains('verification') ||
        value.contains('kyc') ||
        value.contains('plan') ||
        value.contains('support') ||
        value.contains('setting') ||
        value.contains('notification') ||
        value.contains('review') ||
        value.contains('account')) {
      return 'assets/images/vendor/business-trust.png';
    }
    return 'assets/images/vendor/catalog-operations.png';
  }

  Color get _resolvedAccent {
    if (accent != AppColors.primary) return accent;
    final value = title.toLowerCase();
    if (value.contains('service') ||
        value.contains('booking') ||
        value.contains('availability') ||
        value.contains('schedule')) {
      return AppColors.mint;
    }
    if (value.contains('payment') ||
        value.contains('settlement') ||
        value.contains('bank') ||
        value.contains('wallet') ||
        value.contains('report') ||
        value.contains('earning')) {
      return AppColors.amber;
    }
    if (value.contains('profile') ||
        value.contains('kyc') ||
        value.contains('plan') ||
        value.contains('support') ||
        value.contains('setting') ||
        value.contains('account')) {
      return AppColors.violet;
    }
    return AppColors.coral;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= 700;
    final imageWidth = (width * .42).clamp(180.0, 360.0);
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, 8 * (1 - value)),
          child: child,
        ),
      ),
      child: RepaintBoundary(
        child: Container(
          height: wide ? 172 : 154,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF9FCFE), Color(0xFFE9F5FD)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                width: imageWidth,
                child: Opacity(
                  opacity: .72,
                  child: Image.asset(_resolvedAsset,
                      fit: BoxFit.cover, alignment: Alignment.centerRight),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      const Color(0xFFF9FCFE),
                      const Color(0xFFF9FCFE).withValues(alpha: .96),
                      const Color(0xFFF9FCFE).withValues(alpha: .18),
                    ],
                    stops: const [0, .56, .86],
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(width <= 360 ? 14 : 18),
                child: Row(
                  children: [
                    Expanded(
                      flex: wide ? 7 : 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 39,
                            height: 39,
                            decoration: BoxDecoration(
                              color: _resolvedAccent.withValues(alpha: .12),
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(
                                  color:
                                      _resolvedAccent.withValues(alpha: .24)),
                            ),
                            child: Icon(icon, color: _resolvedAccent, size: 21),
                          ),
                          const SizedBox(height: 9),
                          Text(title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                      color: AppColors.brandDark,
                                      fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.muted,
                                  fontSize: 10.5,
                                  height: 1.35)),
                        ],
                      ),
                    ),
                    Spacer(flex: wide ? 3 : 4),
                    if (trailing != null) trailing!,
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
