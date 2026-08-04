import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_value_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../data/vendor_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(dashboardProvider);
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.', decimalDigits: 0);
    return VendorScaffold(
      title: 'Business Hub',
      child: data.whenUi(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorCard(message: '$error'),
        data: (dashboard) {
          final recentActivity = dashboard.orders.take(5).toList();
          final isServiceOnly = dashboard.isServiceVendor;
          final itemLabel = isServiceOnly ? 'Services' : 'Products';
          final activityLabel = isServiceOnly ? 'Bookings' : 'Orders';
          final activityPath = isServiceOnly ? '/bookings' : '/orders';
          final itemCount = isServiceOnly
              ? dashboard.services.length
              : dashboard.products.length;
          final vendorName = titleCaseWords(dashboard.vendor['businessName'] ??
              dashboard.vendor['business_name'] ??
              dashboard.vendor['name'] ??
              'Your business');
          final pending = dashboard.orders
              .where((item) => const {
                    'placed',
                    'created',
                    'pending',
                    'paid',
                    'new'
                  }.contains(item['status']?.toString().toLowerCase()))
              .length;
          return RefreshIndicator(
            onRefresh: () => ref.refresh(dashboardProvider.future),
            child: LayoutBuilder(builder: (context, constraints) {
              final wide = constraints.maxWidth >= 780;
              return ListView(
                padding:
                    VendorLayout.pagePadding(context).copyWith(bottom: 104),
                children: [
                  _DashboardHero(
                    vendorName: vendorName,
                    activityLabel: activityLabel,
                    pending: pending,
                    activityPath: activityPath,
                    isServiceOnly: isServiceOnly,
                  ),
                  const SizedBox(height: 20),
                  const _SectionHeading(
                      eyebrow: 'LIVE OVERVIEW',
                      title: 'Today at a glance',
                      subtitle: 'The numbers that need your attention now'),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: wide ? 4 : 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: wide ? 1.45 : 1.12,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _DashboardMetric(
                        icon: Icons.currency_rupee_rounded,
                        label: 'Total revenue',
                        value: currency.format(dashboard.revenue),
                        caption:
                            '${dashboard.orders.length} ${activityLabel.toLowerCase()}',
                        surface: AppColors.softGreen,
                        iconColor: AppColors.mint,
                        onTap: () => context.push('/settlements'),
                      ),
                      _DashboardMetric(
                        icon: isServiceOnly
                            ? Icons.event_available_rounded
                            : Icons.shopping_bag_rounded,
                        label: 'Active $activityLabel',
                        value: '${dashboard.activeOrders}',
                        caption: '$pending awaiting action',
                        surface: AppColors.accent,
                        iconColor: AppColors.amber,
                        onTap: () => context.push(activityPath),
                      ),
                      _DashboardMetric(
                        icon: isServiceOnly
                            ? Icons.handyman_rounded
                            : Icons.inventory_2_rounded,
                        label: itemLabel,
                        value: '$itemCount',
                        caption: 'Manage your catalog',
                        surface: AppColors.navySoft,
                        iconColor: AppColors.coral,
                        onTap: () => context
                            .push(isServiceOnly ? '/services' : '/products'),
                      ),
                      _DashboardMetric(
                        icon: Icons.star_rounded,
                        label: 'Store rating',
                        value: '${dashboard.vendor['rating'] ?? 0}',
                        caption:
                            '${dashboard.vendor['total_orders'] ?? 0} lifetime',
                        surface: const Color(0xFFF5F2F4),
                        iconColor: AppColors.violet,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  if (wide)
                    Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                              flex: 6,
                              child: _RevenuePanel(orders: dashboard.orders)),
                          const SizedBox(width: 14),
                          Expanded(
                            flex: 5,
                            child: _RecentPanel(
                              activityLabel: activityLabel,
                              activityPath: activityPath,
                              rows: recentActivity,
                              currency: currency,
                            ),
                          ),
                        ])
                  else ...[
                    _RevenuePanel(orders: dashboard.orders),
                    const SizedBox(height: 14),
                    _RecentPanel(
                      activityLabel: activityLabel,
                      activityPath: activityPath,
                      rows: recentActivity,
                      currency: currency,
                    ),
                  ],
                  const SizedBox(height: 22),
                  const _SectionHeading(
                    eyebrow: 'TOOLS',
                    title: 'Run your business',
                    subtitle: 'Everything you need, one tap away',
                  ),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: wide ? 5 : 3,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: wide ? 1.18 : .92,
                    children: [
                      if (!isServiceOnly)
                        const _QuickLink(
                            'Products', '/products', _QuickArt.products),
                      if (isServiceOnly || dashboard.isBothVendor)
                        const _QuickLink(
                            'Services', '/services', _QuickArt.products),
                      if (isServiceOnly || dashboard.isBothVendor)
                        const _QuickLink(
                            'Bookings', '/bookings', _QuickArt.orders),
                      if (!isServiceOnly)
                        const _QuickLink('Orders', '/orders', _QuickArt.orders),
                      const _QuickLink(
                          'Settlements', '/settlements', _QuickArt.settlements),
                      const _QuickLink(
                          'Reports', '/reports', _QuickArt.reports),
                      const _QuickLink('Bank A/C', '/bank', _QuickArt.bank),
                      const _QuickLink('KYC', '/kyc', _QuickArt.kyc),
                      const _QuickLink('Plans', '/plans', _QuickArt.plans),
                    ],
                  ),
                ],
              );
            }),
          );
        },
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink(this.label, this.path, this.art);
  final String label;
  final String path;
  final _QuickArt art;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push(path),
      padding: const EdgeInsets.all(12),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        _QuickActionImage(art),
        const SizedBox(height: 8),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

enum _QuickArt {
  products,
  orders,
  settlements,
  reports,
  bank,
  dropship,
  kyc,
  plans,
}

class _QuickActionImage extends StatelessWidget {
  const _QuickActionImage(this.art);

  final _QuickArt art;

  String get _asset => switch (art) {
        _QuickArt.products => 'assets/images/vendor/quick-actions/products.png',
        _QuickArt.orders => 'assets/images/vendor/quick-actions/orders.png',
        _QuickArt.settlements =>
          'assets/images/vendor/quick-actions/settlements.png',
        _QuickArt.reports => 'assets/images/vendor/quick-actions/reports.png',
        _QuickArt.bank => 'assets/images/vendor/quick-actions/bank.png',
        _QuickArt.dropship => 'assets/images/vendor/quick-actions/dropship.png',
        _QuickArt.kyc => 'assets/images/vendor/quick-actions/kyc.png',
        _QuickArt.plans => 'assets/images/vendor/quick-actions/plans.png',
      };

  @override
  Widget build(BuildContext context) => Container(
        width: 54,
        height: 54,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Image.asset(_asset, fit: BoxFit.cover),
      );
}

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.surface,
    required this.iconColor,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String caption;
  final Color surface;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: iconColor.withValues(alpha: .22)),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const Spacer(),
                if (onTap != null)
                  const Icon(Icons.arrow_outward_rounded,
                      color: AppColors.slate, size: 17),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 3),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(caption,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 9.5)),
          ],
        ),
      );
}

class _DashboardHero extends StatelessWidget {
  const _DashboardHero({
    required this.vendorName,
    required this.activityLabel,
    required this.pending,
    required this.activityPath,
    required this.isServiceOnly,
  });

  final String vendorName;
  final String activityLabel;
  final int pending;
  final String activityPath;
  final bool isServiceOnly;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 700;
          return Container(
            height: wide ? 270 : 238,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFF8FCFE), Color(0xFFE4F4FC)],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  top: wide ? 12 : 42,
                  right: wide ? 8 : -70,
                  bottom: wide ? 8 : -4,
                  width: wide
                      ? constraints.maxWidth * .56
                      : constraints.maxWidth * .72,
                  child: Image.asset(
                    'assets/images/vendor/dashboard-light-overview.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.centerRight,
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        const Color(0xFFF8FCFE),
                        const Color(0xFFF8FCFE).withValues(alpha: .96),
                        const Color(0xFFF8FCFE).withValues(alpha: .18),
                      ],
                      stops: wide ? const [0, .43, .68] : const [0, .55, .86],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(wide ? 26 : 20),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: wide ? 390 : 238),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: .88),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.success,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 7),
                                const Text('BUSINESS OVERVIEW',
                                    style: TextStyle(
                                        color: AppColors.slate,
                                        fontSize: 9,
                                        letterSpacing: .9,
                                        fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Good day,\n$vendorName',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                      color: AppColors.brandDark,
                                      height: 1.13,
                                      fontSize: wide ? 28 : 24,
                                      fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            pending > 0
                                ? '$pending ${activityLabel.toLowerCase()} need your attention.'
                                : 'Everything is moving smoothly today.',
                            style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                                height: 1.4),
                          ),
                          const SizedBox(height: 15),
                          FilledButton(
                            onPressed: () => context.push(pending > 0
                                ? activityPath
                                : (isServiceOnly ? '/services' : '/products')),
                            style: FilledButton.styleFrom(
                                minimumSize: const Size(0, 42)),
                            child: Text(pending > 0
                                ? 'Review now'
                                : (isServiceOnly
                                    ? 'Manage services'
                                    : 'Manage catalog')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading(
      {required this.eyebrow, required this.title, required this.subtitle});
  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow,
              style: const TextStyle(
                  color: AppColors.slate,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(color: AppColors.muted, fontSize: 12)),
        ],
      );
}

class _RevenuePanel extends StatelessWidget {
  const _RevenuePanel({required this.orders});
  final List<Map<String, dynamic>> orders;

  @override
  Widget build(BuildContext context) => AppCard(
        elevated: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                  color: AppColors.softGreen,
                  borderRadius: BorderRadius.circular(12)),
              child:
                  const Icon(Icons.show_chart_rounded, color: AppColors.slate),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Revenue pulse',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    Text('Last 7 calendar days',
                        style: TextStyle(color: AppColors.muted, fontSize: 11)),
                  ]),
            ),
          ]),
          const SizedBox(height: 18),
          SizedBox(
            height: 220,
            child: LineChart(LineChartData(
              minX: 0,
              maxX: 6,
              gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      const FlLine(color: AppColors.border, strokeWidth: 1)),
              titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(),
                  topTitles: AxisTitles(),
                  rightTitles: AxisTitles()),
              borderData: FlBorderData(show: false),
              lineTouchData: const LineTouchData(enabled: true),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  color: AppColors.secondary,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: false),
                  spots: _weekRevenueSpots(orders),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.secondary.withValues(alpha: .22),
                        AppColors.secondary.withValues(alpha: .01),
                      ],
                    ),
                  ),
                ),
              ],
            )),
          ),
        ]),
      );
}

class _RecentPanel extends StatelessWidget {
  const _RecentPanel({
    required this.activityLabel,
    required this.activityPath,
    required this.rows,
    required this.currency,
  });
  final String activityLabel;
  final String activityPath;
  final List<Map<String, dynamic>> rows;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) => AppCard(
        elevated: true,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text('Recent $activityLabel',
                    style: const TextStyle(fontWeight: FontWeight.w600))),
            TextButton(
                onPressed: () => context.push(activityPath),
                child: const Text('View all')),
          ]),
          if (rows.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 42),
              child: Center(
                child: Column(children: [
                  const Icon(Icons.inbox_outlined,
                      color: AppColors.muted, size: 34),
                  const SizedBox(height: 8),
                  Text('No ${activityLabel.toLowerCase()} yet',
                      style: const TextStyle(color: AppColors.muted)),
                ]),
              ),
            )
          else
            for (var i = 0; i < rows.length; i++) ...[
              _ActivityRow(
                  row: rows[i],
                  activityLabel: activityLabel,
                  currency: currency),
              if (i < rows.length - 1) const Divider(height: 1),
            ],
        ]),
      );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow(
      {required this.row, required this.activityLabel, required this.currency});
  final Map<String, dynamic> row;
  final String activityLabel;
  final NumberFormat currency;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 11),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(
                activityLabel == 'Bookings'
                    ? Icons.event_available_rounded
                    : Icons.shopping_bag_rounded,
                color: AppColors.slate,
                size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_activityTitle(row, activityLabel),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
              Text(
                  row['customer_name']?.toString() ??
                      row['customerName']?.toString() ??
                      'Customer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.muted, fontSize: 10)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(currency.format(row['total'] ?? row['total_amount'] ?? 0),
                style:
                    const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 3),
            StatusBadge(row['status']?.toString() ?? 'placed'),
          ]),
        ]),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
      child: Padding(padding: const EdgeInsets.all(24), child: Text(message)));
}

String _activityTitle(Map<String, dynamic> row, String activityLabel) {
  final explicit = _firstText(row, const [
    'orderNumber',
    'order_number',
    'orderCode',
    'order_code',
    'bookingNumber',
    'booking_number',
    'bookingCode',
    'booking_code',
    'service_name',
    'serviceName',
    'product_name',
    'productName',
    'title',
    'name'
  ]);
  if (explicit.isNotEmpty) {
    return explicit;
  }
  final items = row['items'];
  if (items is List && items.isNotEmpty) {
    final first = items.first;
    if (first is Map) {
      final itemTitle = _firstText(Map<String, dynamic>.from(first),
          const ['title', 'name', 'productName', 'product_name']);
      if (itemTitle.isNotEmpty) return itemTitle;
    }
  }
  final customer = _firstText(row, const ['customer_name', 'customerName']);
  if (customer.isNotEmpty && customer != 'Customer') {
    return '$customer $activityLabel';
  }
  return activityLabel == 'Bookings' ? 'Service booking' : 'Customer order';
}

/// Last 7 calendar days of non-cancelled order totals (x = 0..6 oldest→newest).
List<FlSpot> _weekRevenueSpots(List<Map<String, dynamic>> orders) {
  final now = DateTime.now();
  final start =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final totals = List<double>.filled(7, 0);
  for (final o in orders) {
    if (o['status']?.toString() == 'cancelled') continue;
    final created =
        DateTime.tryParse('${o['created_at'] ?? o['createdAt'] ?? ''}');
    if (created == null) continue;
    final day = DateTime(created.year, created.month, created.day);
    final idx = day.difference(start).inDays;
    if (idx < 0 || idx > 6) continue;
    final amount = o['total'] ?? o['total_amount'] ?? 0;
    totals[idx] += amount is num
        ? amount.toDouble()
        : double.tryParse(amount.toString()) ?? 0;
  }
  return [
    for (var i = 0; i < 7; i++) FlSpot(i.toDouble(), totals[i]),
  ];
}

String _firstText(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && !_looksLikeUuid(value)) return value;
  }
  return '';
}

bool _looksLikeUuid(String value) => RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
