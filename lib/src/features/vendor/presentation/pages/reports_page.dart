import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_value_ui.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/vendor_page_intro.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../data/vendor_providers.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});
  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends ConsumerState<ReportsPage> {
  bool ordersReport = true;
  String period = 'Monthly', query = '', status = 'All', sort = 'Newest';
  DateTime? from, to;
  int visible = 10;

  DateTime? _date(Map<String, dynamic> row) =>
      DateTime.tryParse((row['createdAt'] ??
              row['created_at'] ??
              row['updatedAt'] ??
              row['updated_at'] ??
              '')
          .toString());
  double _amount(Map<String, dynamic> row) =>
      double.tryParse((ordersReport
              ? row['total_amount'] ?? row['totalAmount'] ?? row['total']
              : row['amount'] ?? row['net_amount'] ?? row['netAmount'])
          .toString()) ??
      0;
  String _state(Map<String, dynamic> row) =>
      (row['status'] ?? 'unknown').toString().toLowerCase();
  String _ref(Map<String, dynamic> row) => (row['order_ref'] ??
          row['orderRef'] ??
          row['settlement_ref'] ??
          row['settlementRef'] ??
          row['id'] ??
          '—')
      .toString();
  bool _inRange(Map<String, dynamic> row) {
    final date = _date(row);
    if (date == null) return false;
    final now = DateTime.now();
    DateTime start;
    switch (period) {
      case 'Daily':
        start = DateTime(now.year, now.month, now.day);
        break;
      case 'Weekly':
        start = DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6));
        break;
      case 'Yearly':
        start = DateTime(now.year);
        break;
      case 'Custom':
        start = from ?? DateTime(2000);
        break;
      default:
        start = DateTime(now.year, now.month);
    }
    final end = period == 'Custom' && to != null
        ? DateTime(to!.year, to!.month, to!.day, 23, 59, 59)
        : now;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  Future<void> _pick(bool start) async {
    final selected = await showDatePicker(
        context: context,
        initialDate: (start ? from : to) ?? DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime.now());
    if (selected != null) {
      setState(() {
        if (start) {
          from = selected;
        } else {
          to = selected;
        }
        visible = 10;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = ordersReport
        ? ref.watch(vendorOrdersProvider)
        : ref.watch(vendorSettlementsProvider);
    return VendorScaffold(
        title: 'Reports',
        child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vendorOrdersProvider);
              ref.invalidate(vendorSettlementsProvider);
            },
            child: data.whenUi(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, _) => ListView(children: [
                const SizedBox(height: 160),
                Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.muted),
                const SizedBox(height: 12),
                Text(error.toString(), textAlign: TextAlign.center),
                TextButton(
                    onPressed: () => ref.invalidate(ordersReport
                        ? vendorOrdersProvider
                        : vendorSettlementsProvider),
                    child: const Text('Try again'))
              ]),
              data: (allRows) {
                var rows = allRows.where(_inRange).toList();
                final statuses = rows.map(_state).toSet().toList()..sort();
                rows = rows
                    .where((r) =>
                        (status == 'All' || _state(r) == status) &&
                        '${_ref(r)} ${_state(r)}'
                            .toLowerCase()
                            .contains(query.toLowerCase()))
                    .toList();
                rows.sort((a, b) {
                  if (sort == 'Amount') return _amount(b).compareTo(_amount(a));
                  final delta = (_date(a) ?? DateTime(2000))
                      .compareTo(_date(b) ?? DateTime(2000));
                  return sort == 'Newest' ? -delta : delta;
                });
                return ListView(
                    padding:
                        VendorLayout.pagePadding(context).copyWith(bottom: 100),
                    children: [
                      const VendorPageIntro(
                        icon: Icons.query_stats_rounded,
                        title: 'Business reports',
                        subtitle:
                            'See performance clearly, filter the details and make the next decision faster.',
                      ),
                      const SizedBox(height: 16),
                      Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFF9FCFE), Color(0xFFE9F5FD)]),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.insights_rounded,
                                    color: AppColors.slate),
                                SizedBox(height: 18),
                                Text('Reports & insights',
                                    style: TextStyle(
                                        color: AppColors.brandDark,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 24)),
                                SizedBox(height: 4),
                                Text(
                                    'Live orders, sales and settlement performance',
                                    style: TextStyle(color: AppColors.muted))
                              ])),
                      const SizedBox(height: 16),
                      SegmentedButton<bool>(
                          segments: const [
                            ButtonSegment(
                                value: true,
                                label: Text('Orders'),
                                icon: Icon(Icons.shopping_bag_outlined)),
                            ButtonSegment(
                                value: false,
                                label: Text('Settlements'),
                                icon: Icon(Icons.payments_outlined))
                          ],
                          selected: {
                            ordersReport
                          },
                          onSelectionChanged: (v) => setState(() {
                                ordersReport = v.first;
                                status = 'All';
                                visible = 10;
                              })),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                              children: [
                            'Daily',
                            'Weekly',
                            'Monthly',
                            'Yearly',
                            'Custom'
                          ]
                                  .map((p) => Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: ChoiceChip(
                                          label: Text(p),
                                          selected: period == p,
                                          onSelected: (_) => setState(() {
                                                period = p;
                                                visible = 10;
                                              }))))
                                  .toList())),
                      if (period == 'Custom')
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: LayoutBuilder(builder: (context, box) {
                              final fromButton = OutlinedButton.icon(
                                  onPressed: () => _pick(true),
                                  icon: const Icon(Icons.calendar_today_rounded,
                                      size: 18),
                                  label: Text(from == null
                                      ? 'From date'
                                      : DateFormat('dd MMM yyyy')
                                          .format(from!)));
                              final toButton = OutlinedButton.icon(
                                  onPressed: () => _pick(false),
                                  icon:
                                      const Icon(Icons.event_rounded, size: 18),
                                  label: Text(to == null
                                      ? 'To date'
                                      : DateFormat('dd MMM yyyy').format(to!)));
                              if (box.maxWidth < 390) {
                                return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      fromButton,
                                      const SizedBox(height: 8),
                                      toButton,
                                    ]);
                              }
                              return Row(children: [
                                Expanded(child: fromButton),
                                const SizedBox(width: 8),
                                Expanded(child: toButton),
                              ]);
                            })),
                      const SizedBox(height: 16),
                      _SummaryGrid(
                          rows: allRows.where(_inRange).toList(),
                          orders: ordersReport,
                          amount: _amount,
                          state: _state),
                      const SizedBox(height: 16),
                      Card(
                          child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        '${ordersReport ? 'Order' : 'Settlement'} trends',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 18),
                                    SizedBox(
                                        height: 150,
                                        width: double.infinity,
                                        child: _TrendChart(
                                            rows: allRows
                                                .where(_inRange)
                                                .toList(),
                                            amount: _amount,
                                            date: _date))
                                  ]))),
                      const SizedBox(height: 16),
                      TextField(
                          onChanged: (v) => setState(() {
                                query = v;
                                visible = 10;
                              }),
                          decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.search_rounded),
                              hintText: 'Search reference or status')),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                initialValue:
                                    statuses.contains(status) ? status : 'All',
                                decoration:
                                    const InputDecoration(labelText: 'Status'),
                                items: ['All', ...statuses]
                                    .map((s) => DropdownMenuItem(
                                        value: s,
                                        child: Text(s.replaceAll('_', ' '))))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => status = v ?? 'All'))),
                        const SizedBox(width: 8),
                        Expanded(
                            child: DropdownButtonFormField<String>(
                                initialValue: sort,
                                decoration:
                                    const InputDecoration(labelText: 'Sort'),
                                items: ['Newest', 'Oldest', 'Amount']
                                    .map((s) => DropdownMenuItem(
                                        value: s, child: Text(s)))
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => sort = v ?? 'Newest')))
                      ]),
                      const SizedBox(height: 12),
                      if (rows.isEmpty)
                        const Card(
                            child: Padding(
                                padding: EdgeInsets.all(36),
                                child: Column(children: [
                                  Icon(Icons.query_stats_rounded,
                                      size: 42, color: AppColors.slate),
                                  SizedBox(height: 10),
                                  Text('No report data found',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  Text('Try another date range or filter.',
                                      style: TextStyle(color: AppColors.muted))
                                ])))
                      else
                        ...rows.take(visible).map((r) => Card(
                            child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                leading: Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: Icon(ordersReport ? Icons.inventory_2_outlined : Icons.account_balance_wallet_outlined,
                                        color: AppColors.slate)),
                                title: Text(_ref(r),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w600)),
                                subtitle: Text(
                                    '${_date(r) == null ? '—' : DateFormat('dd MMM yyyy').format(_date(r)!)}  •  ${_state(r).replaceAll('_', ' ')}'),
                                trailing: Text(NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(_amount(r)),
                                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.brandDark))))),
                      if (rows.length > visible)
                        Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: OutlinedButton(
                                onPressed: () => setState(() => visible += 10),
                                child: Text(
                                    'Load more (${rows.length - visible})'))),
                    ]);
              },
            )));
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid(
      {required this.rows,
      required this.orders,
      required this.amount,
      required this.state});
  final List<Map<String, dynamic>> rows;
  final bool orders;
  final double Function(Map<String, dynamic>) amount;
  final String Function(Map<String, dynamic>) state;
  @override
  Widget build(BuildContext context) {
    final done = {'completed', 'delivered'},
        pending = {
          'pending',
          'placed',
          'created',
          'new',
          'processing',
          'accepted',
          'packed',
          'shipped'
        },
        cancelled = {'cancelled', 'refunded', 'failed'},
        paid = {'paid', 'settled', 'completed'};
    final total = rows.fold<double>(0, (n, r) => n + amount(r));
    final values = orders
        ? <(String, String, IconData)>[
            ('Total orders', '${rows.length}', Icons.receipt_long_outlined),
            (
              'Completed',
              '${rows.where((r) => done.contains(state(r))).length}',
              Icons.check_circle_outline
            ),
            (
              'Pending',
              '${rows.where((r) => pending.contains(state(r))).length}',
              Icons.schedule_rounded
            ),
            (
              'Cancelled',
              '${rows.where((r) => cancelled.contains(state(r))).length}',
              Icons.cancel_outlined
            ),
            (
              'Total sales',
              NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(
                  rows
                      .where((r) => done.contains(state(r)))
                      .fold<double>(0, (n, r) => n + amount(r))),
              Icons.currency_rupee_rounded
            ),
            (
              'Average',
              NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹')
                  .format(rows.isEmpty ? 0 : total / rows.length),
              Icons.analytics_outlined
            )
          ]
        : <(String, String, IconData)>[
            (
              'Total amount',
              NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹')
                  .format(total),
              Icons.currency_rupee
            ),
            (
              'Paid',
              NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(
                  rows
                      .where((r) => paid.contains(state(r)))
                      .fold<double>(0, (n, r) => n + amount(r))),
              Icons.check_circle_outline
            ),
            (
              'Pending',
              NumberFormat.compactCurrency(locale: 'en_IN', symbol: '₹').format(
                  rows
                      .where((r) => !paid.contains(state(r)))
                      .fold<double>(0, (n, r) => n + amount(r))),
              Icons.schedule
            ),
            ('Entries', '${rows.length}', Icons.list_alt_rounded)
          ];
    return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.55,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10),
        itemCount: values.length,
        itemBuilder: (_, i) {
          final v = values[i];
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(v.$3, color: AppColors.slate, size: 21),
                        const Spacer(),
                        Text(v.$1,
                            style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.muted,
                                fontWeight: FontWeight.w600)),
                        Text(v.$2,
                            maxLines: 1,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w600))
                      ])));
        });
  }
}

class _TrendChart extends StatelessWidget {
  const _TrendChart(
      {required this.rows, required this.amount, required this.date});
  final List<Map<String, dynamic>> rows;
  final double Function(Map<String, dynamic>) amount;
  final DateTime? Function(Map<String, dynamic>) date;
  @override
  Widget build(BuildContext context) {
    final sorted = [...rows]..sort((a, b) =>
        (date(a) ?? DateTime(2000)).compareTo(date(b) ?? DateTime(2000)));
    final points = sorted.map(amount).toList();
    if (points.isEmpty) {
      return const Center(
          child: Text('No trend data for this period',
              style: TextStyle(color: AppColors.muted)));
    }
    return CustomPaint(
        painter: _TrendPainter(points), child: const SizedBox.expand());
  }
}

class _TrendPainter extends CustomPainter {
  _TrendPainter(this.values);
  final List<double> values;
  @override
  void paint(Canvas canvas, Size size) {
    final maxValue = values.fold<double>(
        1, (maximum, value) => math.max(maximum, value).toDouble());
    final fill = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.fill;
    final line = Paint()
      ..color = AppColors.primary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = values.length == 1
          ? size.width / 2
          : i * size.width / (values.length - 1);
      final y = size.height - (values[i] / maxValue) * (size.height - 12) - 6;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final area = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(area, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _TrendPainter old) => old.values != values;
}
