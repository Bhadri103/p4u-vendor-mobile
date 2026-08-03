import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/core/navigation/vendor_deep_links.dart';

void main() {
  test('maps backend and web vendor deep links to mobile routes', () {
    expect(vendorRouteForDeepLink('/dashboard/product/orders'), '/orders');
    expect(vendorRouteForDeepLink('/dashboard/service/bookings'), '/bookings');
    expect(
        vendorRouteForDeepLink('https://example.test/vendor/settlements?id=1'),
        '/settlements');
    expect(vendorRouteForDeepLink('/unknown'), '/');
  });
}
