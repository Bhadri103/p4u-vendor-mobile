import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/vendor_page_intro.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../data/vendor_providers.dart';

class OrderDetailsPage extends ConsumerWidget {
  const OrderDetailsPage({required this.orderId, super.key});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(vendorOrderProvider(orderId));
    return VendorScaffold(
      title: 'Order Details',
      child: order.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: error.toString(),
          onRetry: () => ref.invalidate(vendorOrderProvider(orderId)),
        ),
        data: (value) {
          if (value == null) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'Order not found',
                subtitle: 'This order is unavailable for your vendor account.',
              ),
            );
          }
          return _OrderDetails(
            order: value,
            onRefresh: () async {
              ref.invalidate(vendorOrderProvider(orderId));
              await ref.read(vendorOrderProvider(orderId).future);
            },
          );
        },
      ),
    );
  }
}

class _OrderDetails extends StatelessWidget {
  const _OrderDetails({required this.order, required this.onRefresh});

  final Map<String, dynamic> order;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final metadata = _map(order['metadata']);
    final totals = _map(metadata['totals']);
    final items = (order['items'] is List ? order['items'] as List : const [])
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
    final status = _first([order['status'], 'placed']);
    final orderRef = _first([
      order['order_ref'],
      order['orderRef'],
      metadata['displayId'],
      order['id'],
    ]);
    final finalTotal = _number(order['total'],
        _number(order['totalAmount'], _number(totals['grandTotal'])));
    final subtotal = _number(
      totals['itemSubtotal'],
      items.fold<num>(0, (sum, item) => sum + _lineTotal(item)),
    );
    final customerName = _first([
      order['customer_name'],
      order['customerName'],
      metadata['customerName'],
      'Customer',
    ]);
    final phone = _first([
      order['customer_phone'],
      order['customerPhone'],
      metadata['customerPhone'],
      _map(metadata['shippingAddress'])['phone'],
    ]);
    final email = _first([order['customerEmail'], metadata['customerEmail']]);
    final address = _address(metadata);
    final paymentMode = _first([
      order['payment_mode'],
      order['paymentMode'],
      metadata['paymentMode'],
    ]);
    final paymentStatus = _first([
      order['payment_status'],
      order['paymentStatus'],
      metadata['paymentStatus'],
    ]);
    final deliverySchedule = _deliverySchedule(metadata['deliverySchedule']);
    final returnRequest = _map(metadata['returnRequest']);

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: VendorLayout.pagePadding(context),
        children: [
          VendorPageIntro(
            icon: Icons.local_shipping_rounded,
            title: 'Order $orderRef',
            subtitle:
                'Track fulfilment, payment, customer details and every line item.',
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderRef,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _dateTime(
                                order['created_at'] ?? order['createdAt']),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(status),
                  ],
                ),
                const Divider(height: 28),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Order total',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      _money(finalTotal),
                      style: const TextStyle(
                        color: AppColors.brandDark,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.inventory_2_outlined,
            title: 'Items (${items.length})',
            child: items.isEmpty
                ? const Text('No line-item data available.')
                : Column(
                    children: [
                      for (var index = 0; index < items.length; index++) ...[
                        _ItemRow(item: items[index]),
                        if (index != items.length - 1)
                          const Divider(height: 24),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.receipt_long_outlined,
            title: 'Price details',
            child: Column(
              children: [
                _AmountRow('Item subtotal', subtotal),
                _AmountRow('Product tax', _number(totals['productTax'])),
                _AmountRow('Platform fee', _number(totals['platformFee'])),
                _AmountRow(
                    'GST on platform fee', _number(totals['gstOnPlatformFee'])),
                _AmountRow('Delivery fee', _number(totals['deliveryFee'])),
                _AmountRow('Surge fee', _number(totals['surgeCost'])),
                _AmountRow('Discount', -_number(totals['discount'])),
                _AmountRow(
                    'Points discount', -_number(totals['pointsRedeemedValue'])),
                const Divider(height: 22),
                _AmountRow('Final total', finalTotal, total: true),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.person_outline_rounded,
            title: 'Customer & delivery',
            child: Column(
              children: [
                _InfoRow('Customer', customerName),
                _InfoRow('Phone', phone),
                _InfoRow('Email', email),
                _InfoRow('Address', address, multiline: true),
                _InfoRow('Delivery slot', deliverySchedule),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _SectionCard(
            icon: Icons.payments_outlined,
            title: 'Payment',
            child: Column(
              children: [
                _InfoRow('Method', _label(paymentMode)),
                _InfoRow('Status', _label(paymentStatus)),
                _InfoRow(
                  'Transaction ID',
                  _first([
                    metadata['transactionId'],
                    metadata['paymentId'],
                    metadata['paymentReference'],
                  ]),
                ),
              ],
            ),
          ),
          if (_hasShipping(metadata, order)) ...[
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.local_shipping_outlined,
              title: 'Shipping',
              child: Column(
                children: [
                  _InfoRow(
                      'Type',
                      _label(_first([
                        order['shipping_type'],
                        metadata['shipping_type'],
                        metadata['shippingType'],
                      ]))),
                  _InfoRow(
                      'Courier',
                      _first([
                        order['courier_name'],
                        metadata['courier_name'],
                        metadata['courierName'],
                      ])),
                  _InfoRow(
                      'Tracking number',
                      _first([
                        order['tracking_number'],
                        metadata['tracking_number'],
                        metadata['trackingNumber'],
                      ])),
                  _InfoRow(
                      'Notes',
                      _first([
                        order['shipping_notes'],
                        metadata['shipping_notes'],
                        metadata['shippingNotes'],
                      ]),
                      multiline: true),
                ],
              ),
            ),
          ],
          if (returnRequest.isNotEmpty) ...[
            const SizedBox(height: 12),
            _SectionCard(
              icon: Icons.assignment_return_outlined,
              title: 'Return details',
              child: Column(
                children: [
                  _InfoRow('Status', _label(_first([returnRequest['status']]))),
                  _InfoRow('Reason', _first([returnRequest['reason']]),
                      multiline: true),
                  _InfoRow('Vendor note', _first([returnRequest['vendorNote']]),
                      multiline: true),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final Map<String, dynamic> item;

  @override
  Widget build(BuildContext context) {
    final title = _first([
      item['title'],
      item['name'],
      item['productName'],
      'Item',
    ]);
    final image = _first([
      item['image'],
      item['imageUrl'],
      item['thumbnailUrl'],
      item['productImage'],
    ]);
    final quantity = _number(item['quantity'], _number(item['qty'], 1));
    final total = _lineTotal(item);
    final unitPrice = _number(
      item['unit_price'],
      _number(item['unitPrice'], quantity > 0 ? total / quantity : total),
    );
    final variation = _first([
      item['variantName'],
      item['variationName'],
      item['variant'],
    ]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(
            width: 58,
            height: 58,
            child: image.isEmpty
                ? _imageFallback()
                : Image.network(
                    image,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _imageFallback(),
                  ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (variation.isNotEmpty)
                Text(variation,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12)),
              const SizedBox(height: 5),
              Text(
                '${_money(unitPrice)} × ${_quantity(quantity)}',
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(_money(total),
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _imageFallback() => Container(
        color: AppColors.productSurface,
        alignment: Alignment.center,
        child: const Icon(Icons.inventory_2_outlined,
            color: AppColors.muted, size: 22),
      );
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.icon, required this.title, required this.child});

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.slate, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow(this.label, this.amount, {this.total = false});

  final String label;
  final num amount;
  final bool total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: TextStyle(
                  color: total ? AppColors.brandDark : AppColors.muted,
                  fontWeight: total ? FontWeight.w600 : FontWeight.w600,
                )),
          ),
          Text(
            _money(amount),
            style: TextStyle(
              fontSize: total ? 17 : 14,
              fontWeight: total ? FontWeight.w600 : FontWeight.w600,
              color: AppColors.brandDark,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value, {this.multiline = false});

  final String label;
  final String value;
  final bool multiline;

  @override
  Widget build(BuildContext context) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: MediaQuery.sizeOf(context).width <= 360 ? 88 : 112,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.muted, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                color: AppColors.danger, size: 40),
            const SizedBox(height: 10),
            const Text('Could not load order details',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.muted, fontSize: 12)),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

String _first(List<Object?> values) {
  for (final value in values) {
    final text = value?.toString().trim() ?? '';
    if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
  }
  return '';
}

num _number(Object? value, [num fallback = 0]) {
  if (value is num) return value;
  return num.tryParse(value?.toString() ?? '') ?? fallback;
}

num _lineTotal(Map<String, dynamic> item) {
  final quantity = _number(item['quantity'], _number(item['qty'], 1));
  final unit = _number(item['unit_price'], _number(item['unitPrice']));
  return _number(item['line_total'],
      _number(item['lineTotal'], _number(item['total'], unit * quantity)));
}

String _money(num value) => NumberFormat.currency(
      locale: 'en_IN',
      symbol: 'Rs.',
      decimalDigits: value == value.roundToDouble() ? 0 : 2,
    ).format(value);

String _quantity(num value) => value == value.roundToDouble()
    ? value.toInt().toString()
    : value.toString();

String _dateTime(Object? value) {
  final date = DateTime.tryParse(value?.toString() ?? '')?.toLocal();
  return date == null ? '' : DateFormat('dd MMM yyyy, hh:mm a').format(date);
}

String _label(String value) {
  if (value.isEmpty) return '';
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String _address(Map<String, dynamic> metadata) {
  final raw = metadata['shippingAddress'] ?? metadata['shipping_address'];
  if (raw is String) return raw.trim();
  final address = _map(raw);
  final values = <String>[];
  for (final key in const [
    'addressLine1',
    'addressLine2',
    'address',
    'areaLocality',
    'landmark',
    'city',
    'district',
    'state',
    'pincode',
    'postalCode',
  ]) {
    final value = _first([address[key]]);
    if (value.isNotEmpty && !values.contains(value)) values.add(value);
  }
  return values.join(', ');
}

String _deliverySchedule(Object? raw) {
  if (raw is String) return raw.trim();
  final schedule = _map(raw);
  return [
    _first([schedule['date'], schedule['deliveryDate']]),
    _first([schedule['timeSlot'], schedule['slot'], schedule['time']]),
  ].where((value) => value.isNotEmpty).join(' · ');
}

bool _hasShipping(Map<String, dynamic> metadata, Map<String, dynamic> order) {
  return [
    order['shipping_type'],
    order['tracking_number'],
    metadata['shipping_type'],
    metadata['shippingType'],
    metadata['tracking_number'],
    metadata['trackingNumber'],
    metadata['courier_name'],
    metadata['courierName'],
  ].any((value) => _first([value]).isNotEmpty);
}
