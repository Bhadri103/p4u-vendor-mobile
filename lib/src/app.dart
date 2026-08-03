import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/navigation/vendor_deep_links.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/login_page.dart';
import 'features/auth/presentation/register_page.dart';
import 'features/auth/presentation/splash_gate.dart';
import 'features/vendor/presentation/pages/availability_page.dart';
import 'features/vendor/presentation/pages/bank_accounts_page.dart';
import 'features/vendor/presentation/pages/bookings_page.dart';
import 'features/vendor/presentation/pages/dashboard_page.dart';
import 'features/vendor/presentation/pages/dropshipping_page.dart';
import 'features/vendor/presentation/pages/media_library_page.dart';
import 'features/vendor/presentation/pages/order_details_page.dart';
import 'features/vendor/presentation/pages/orders_page.dart';
import 'features/vendor/presentation/pages/payments_page.dart';
import 'features/vendor/presentation/pages/products_page.dart';
import 'features/vendor/presentation/pages/reports_page.dart';
import 'features/vendor/presentation/pages/profile_page.dart';
import 'features/vendor/presentation/pages/services_page.dart';
import 'features/vendor/presentation/pages/settlements_page.dart';
import 'features/vendor/presentation/pages/vendor_kyc_page.dart';
import 'features/vendor/presentation/pages/vendor_plans_page.dart';
import 'features/vendor/presentation/pages/simple_vendor_page.dart';

GoRouter? _vendorRouter;
void openVendorDeepLink(String raw) {
  _vendorRouter?.go(vendorRouteForDeepLink(raw));
}

Page<void> _modulePage(Widget child, GoRouterState state) {
  return NoTransitionPage<void>(key: state.pageKey, child: child);
}

final routerProvider = Provider<GoRouter>((ref) {
  return _vendorRouter = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const VendorSplashGate()),
      GoRoute(path: '/login', builder: (_, __) => const VendorLoginPage()),
      GoRoute(
          path: '/register', builder: (_, __) => const VendorRegisterPage()),
      GoRoute(
        path: '/',
        pageBuilder: (context, state) =>
            _modulePage(const DashboardPage(), state),
      ),
      GoRoute(
        path: '/products',
        pageBuilder: (context, state) =>
            _modulePage(const ProductsPage(), state),
      ),
      GoRoute(
        path: '/services',
        pageBuilder: (context, state) =>
            _modulePage(const ServicesPage(), state),
      ),
      GoRoute(
        path: '/availability',
        pageBuilder: (context, state) =>
            _modulePage(const AvailabilityPage(), state),
      ),
      GoRoute(
        path: '/orders',
        pageBuilder: (context, state) =>
            _modulePage(const OrdersPage(), state),
      ),
      GoRoute(
        path: '/orders/:orderId',
        builder: (_, state) => OrderDetailsPage(
          orderId: state.pathParameters['orderId']!,
        ),
      ),
      GoRoute(
        path: '/bookings',
        pageBuilder: (context, state) =>
            _modulePage(const BookingsPage(), state),
      ),
      GoRoute(
        path: '/settlements',
        pageBuilder: (context, state) =>
            _modulePage(const SettlementsPage(), state),
      ),
      GoRoute(
        path: '/payments',
        pageBuilder: (context, state) =>
            _modulePage(const PaymentsPage(), state),
      ),
      GoRoute(
        path: '/reports',
        pageBuilder: (context, state) =>
            _modulePage(const ReportsPage(), state),
      ),
      GoRoute(
        path: '/wallet',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.wallet), state),
      ),
      GoRoute(
        path: '/bank',
        pageBuilder: (context, state) =>
            _modulePage(const BankAccountsPage(), state),
      ),
      GoRoute(
        path: '/media',
        pageBuilder: (context, state) =>
            _modulePage(const MediaLibraryPage(), state),
      ),
      GoRoute(
        path: '/profile',
        pageBuilder: (context, state) =>
            _modulePage(const ProfilePage(), state),
      ),
      GoRoute(
        path: '/kyc',
        pageBuilder: (context, state) =>
            _modulePage(const VendorKycPage(), state),
      ),
      GoRoute(
        path: '/plans',
        pageBuilder: (context, state) =>
            _modulePage(const VendorPlansPage(), state),
      ),
      GoRoute(
        path: '/dropshipping',
        pageBuilder: (context, state) =>
            _modulePage(const DropshippingPage(), state),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.settings), state),
      ),
      GoRoute(
        path: '/account-control',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.accountControl),
            state),
      ),
      GoRoute(
        path: '/analytics',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.analytics), state),
      ),
      GoRoute(
        path: '/reviews',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.reviews), state),
      ),
      GoRoute(
        path: '/support',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.support), state),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => _modulePage(
            const SimpleVendorPage(kind: SimpleVendorKind.notifications),
            state),
      ),
    ],
  );
});

class VendorApp extends ConsumerWidget {
  const VendorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Planext4u Vendor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1);
        final supportedScale = systemScale.clamp(1.0, 1.2).toDouble();
        return MediaQuery(
          data: media.copyWith(textScaler: TextScaler.linear(supportedScale)),
          child: child ?? const SizedBox.shrink(),
        );
      },
      routerConfig: ref.watch(routerProvider),
    );
  }
}
