import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/core/services/api_client.dart';
import 'package:p4u_vendor_app/src/features/vendor/data/vendor_repository.dart';

class _VendorApi extends ApiClient {
  final paths = <String>[];

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, Object?> query = const {},
    bool auth = false,
  }) async {
    paths.add(path);
    if (path == '/api/v1/vendor/me/settlements') {
      return [
        {
          'id': 'settlement-1',
          'status': 'pending',
          'amount': '296.00',
          'metadata': {
            'orderRef': 'ORD-341',
            'gross': '341.00',
            'commissionTotal': '45.00',
          },
        }
      ];
    }
    if (path == '/api/v1/vendor/orders') {
      return [
        {
          'id': 'order-1',
          'orderRef': 'ORD-341',
          'totalAmount': '341.00',
          'metadata': {
            'lines': [
              {
                'productName': 'Repellent',
                'quantity': 2,
                'unitPrice': '150.00',
                'lineTotal': '300.00',
              }
            ]
          },
        }
      ];
    }
    return [];
  }
}

void main() {
  test('settlements use only persisted settlement API values', () async {
    final api = _VendorApi();
    final rows = await VendorRepository(api: api).settlements('vendor-1');

    expect(api.paths, ['/api/v1/vendor/me/settlements']);
    expect(rows.single['order_ref'], 'ORD-341');
    expect(rows.single['net_amount'], 296);
    expect(rows.single['gross_amount'], 341);
    expect(rows.single['commission'], 45);
  });

  test('orders preserve unit price, quantity, and line total for details',
      () async {
    final api = _VendorApi();
    final rows = await VendorRepository(api: api).orders('vendor-1');
    final item = Map<String, dynamic>.from(rows.single['items'].single as Map);

    expect(api.paths, ['/api/v1/vendor/orders']);
    expect(item['quantity'], 2);
    expect(item['unit_price'], 150);
    expect(item['line_total'], 300);
  });
}
