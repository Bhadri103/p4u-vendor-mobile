import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/features/vendor/domain/vendor_models.dart';

void main() {
  test('dashboard revenue includes only completed or delivered work', () {
    const dashboard = VendorDashboard(
      vendor: {'vendorType': 'BOTH'},
      products: [],
      services: [],
      settlements: [],
      orders: [
        {'status': 'pending', 'total': 100},
        {'status': 'cancelled', 'total': 200},
        {'status': 'delivered', 'total': 300},
        {'status': 'completed', 'total_amount': '400.50'},
      ],
    );

    expect(dashboard.revenue, 700.5);
    expect(dashboard.hasProductFlow, isTrue);
    expect(dashboard.hasServiceFlow, isTrue);
  });
}
