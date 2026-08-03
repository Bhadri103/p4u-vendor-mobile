import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../../../core/widgets/vendor_page_intro.dart';
import '../../data/vendor_providers.dart';
import 'settlements_page.dart';

final _paymentsSearchProvider = StateProvider<String>((_) => '');

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settlements = ref.watch(vendorSettlementsProvider);
    final query = ref.watch(_paymentsSearchProvider).trim().toLowerCase();
    return VendorScaffold(
      title: 'Payment History',
      child: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(vendorSettlementsProvider);
          ref.invalidate(settlementStatsProvider);
          await ref.read(vendorSettlementsProvider.future);
        },
        child: settlements.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (items) {
            final filtered = query.isEmpty
                ? items
                : items.where((row) {
                    final id = '${row['id'] ?? ''}'.toLowerCase();
                    final orderId = '${row['order_id'] ?? row['orderId'] ?? ''}'
                        .toLowerCase();
                    final refId = '${row['reference'] ?? row['txn_id'] ?? ''}'
                        .toLowerCase();
                    return id.contains(query) ||
                        orderId.contains(query) ||
                        refId.contains(query);
                  }).toList();
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: VendorLayout.pagePadding(context),
              children: [
                const VendorPageIntro(
                  icon: Icons.receipt_long_rounded,
                  title: 'Payment timeline',
                  subtitle:
                      'Search, review and reconcile every transaction from one reliable history.',
                ),
                const SizedBox(height: 16),
                TextField(
                  decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Search by ID or order ID...'),
                  onChanged: (v) =>
                      ref.read(_paymentsSearchProvider.notifier).state = v,
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 24),
                    child: Center(
                        child: Text('No matching payments',
                            style: TextStyle(color: AppColors.muted))),
                  )
                else
                  ...filtered.map((row) => SettlementTile(row)),
              ],
            );
          },
        ),
      ),
    );
  }
}
