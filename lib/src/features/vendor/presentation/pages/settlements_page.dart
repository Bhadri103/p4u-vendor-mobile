import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_value_ui.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../../../core/widgets/vendor_page_intro.dart';
import '../../data/vendor_providers.dart';

class SettlementsPage extends ConsumerWidget {
  const SettlementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(vendorSettlementsProvider);
    final stats = ref.watch(settlementStatsProvider);
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.', decimalDigits: 0);
    return VendorScaffold(
      title: 'Settlements',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vendorSettlementsProvider);
          ref.invalidate(settlementStatsProvider);
          await ref.read(vendorSettlementsProvider.future);
        },
        child: ListView(
          padding: VendorLayout.pagePadding(context),
          children: [
            const VendorPageIntro(
              icon: Icons.account_balance_wallet_rounded,
              title: 'Money center',
              subtitle:
                  'A clear view of earnings, pending payouts and settled funds.',
              accent: AppColors.success,
            ),
            const SizedBox(height: 14),
            stats.maybeWhen(
              data: (s) => ResponsiveMetricGrid(
                children: [
                  MetricCard(
                      icon: Icons.currency_rupee_rounded,
                      color: AppColors.mint,
                      label: 'Total Earned',
                      value: currency.format(s.totalEarned)),
                  MetricCard(
                      icon: Icons.schedule_rounded,
                      color: AppColors.amber,
                      label: 'Pending',
                      value: currency.format(s.pending)),
                  MetricCard(
                      icon: Icons.check_circle_rounded,
                      color: AppColors.primary,
                      label: 'Settled',
                      value: currency.format(s.settled)),
                  MetricCard(
                      icon: Icons.cancel_rounded,
                      color: AppColors.danger,
                      label: 'Rejected',
                      value: currency.format(s.rejected)),
                ],
              ),
              orElse: () => const SizedBox(
                  height: 96,
                  child: Center(child: CircularProgressIndicator())),
            ),
            const SizedBox(height: 16),
            settlements.whenUi(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('$e'),
              data: (items) => items.isEmpty
                  ? const EmptyState(
                      icon: Icons.currency_rupee_rounded,
                      title: 'No settlements found')
                  : Column(
                      children: items.map((s) => SettlementTile(s)).toList()),
            ),
          ],
        ),
      ),
    );
  }
}

class SettlementTile extends StatelessWidget {
  const SettlementTile(this.row, {super.key});
  final Map<String, dynamic> row;

  @override
  Widget build(BuildContext context) {
    final currency =
        NumberFormat.currency(locale: 'en_IN', symbol: 'Rs.', decimalDigits: 0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(_settlementTitle(row),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                StatusBadge(row['status']?.toString() ?? 'pending'),
                const SizedBox(width: 8),
                Text(currency.format(_amount(row['net_amount'])),
                    style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandDark)),
              ],
            ),
            if (_orderLabel(row).isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Order: ${_orderLabel(row)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.muted)),
            ],
            const SizedBox(height: 4),
            Text(
                'Gross: ${currency.format(_amount(row['gross_amount'] ?? row['amount']))} - Commission: ${currency.format(_amount(row['platform_fee'] ?? row['commission']))}',
                style: const TextStyle(fontSize: 12, color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}

double _amount(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

String _settlementTitle(Map<String, dynamic> row) {
  final normalized =
      _firstSettlementText(row, const ['settlement_title', 'title']);
  if (normalized.isNotEmpty) return normalized;
  final explicit = _firstSettlementText(row, const [
    'settlementNumber',
    'settlement_number',
    'reference',
    'referenceNumber',
    'orderNumber',
    'order_number',
    'orderCode',
    'order_code',
    'customer_name',
    'customerName',
    'vendor_name',
    'vendorName'
  ]);
  if (explicit.isNotEmpty) {
    return explicit.contains('Settlement') ? explicit : '$explicit settlement';
  }
  final order = row['order'];
  if (order is Map) {
    final orderText =
        _firstSettlementText(Map<String, dynamic>.from(order), const [
      'orderNumber',
      'order_number',
      'orderCode',
      'order_code',
      'customer_name',
      'customerName'
    ]);
    if (orderText.isNotEmpty) return '$orderText settlement';
  }
  return 'Order settlement';
}

String _orderLabel(Map<String, dynamic> row) {
  final normalized =
      _firstSettlementText(row, const ['order_label', 'order_ref']);
  if (normalized.isNotEmpty) return normalized;
  final direct = _firstSettlementText(row, const [
    'orderNumber',
    'order_number',
    'orderCode',
    'order_code',
    'order_ref',
    'orderReference'
  ]);
  if (direct.isNotEmpty) return direct;
  final order = row['order'];
  if (order is Map) {
    return _firstSettlementText(Map<String, dynamic>.from(order), const [
      'orderNumber',
      'order_number',
      'orderCode',
      'order_code',
      'customer_name',
      'customerName'
    ]);
  }
  return '';
}

String _firstSettlementText(Map<String, dynamic> row, List<String> keys) {
  for (final key in keys) {
    final value = row[key]?.toString().trim() ?? '';
    if (value.isNotEmpty && !_looksLikeUuid(value)) return value;
  }
  return '';
}

bool _looksLikeUuid(String value) => RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value.trim());
