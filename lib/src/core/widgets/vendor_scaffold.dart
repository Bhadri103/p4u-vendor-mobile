import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/data/auth_repository.dart';
import '../../features/vendor/domain/vendor_models.dart';
import '../theme/app_theme.dart';
import '../utils/text_formatters.dart';

/// Shared responsive rules for every authenticated vendor screen.
abstract final class VendorLayout {
  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1100
        ? 32.0
        : width >= 700
            ? 24.0
            : width <= 360
                ? 12.0
                : 16.0;
    return EdgeInsets.fromLTRB(horizontal, 16, horizontal, 24);
  }

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 600;
}

/// A compact metrics grid that moves from one/two phone columns to four
/// desktop columns without relying on fragile aspect ratios.
class ResponsiveMetricGrid extends StatelessWidget {
  const ResponsiveMetricGrid({
    required this.children,
    this.maxColumns = 4,
    this.minItemWidth = 132,
    this.itemHeight = 88,
    this.spacing = 12,
    super.key,
  });

  final List<Widget> children;
  final int maxColumns;
  final double minItemWidth;
  final double itemHeight;
  final double spacing;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final available = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final count = ((available + spacing) / (minItemWidth + spacing))
              .floor()
              .clamp(1, maxColumns);
          return GridView.count(
            crossAxisCount: count,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: itemHeight,
            children: children,
          );
        },
      );
}

class VendorScaffold extends ConsumerWidget {
  const VendorScaffold({
    required this.title,
    required this.child,
    this.actions = const [],
    super.key,
  });

  final String title;
  final Widget child;
  final List<Widget> actions;

  static List<_Destination> _bottomDestinationsFor(VendorUser? vendor) {
    if (vendor?.isServiceVendor == true) {
      return const [
        _Destination('Home', '/', Icons.dashboard_rounded),
        _Destination('Services', '/services', Icons.handyman_rounded),
        _Destination('Bookings', '/bookings', Icons.event_available_rounded),
        _Destination('Payments', '/settlements', Icons.currency_rupee_rounded),
        _Destination('Profile', '/profile', Icons.person_rounded),
      ];
    }
    return const [
      _Destination('Home', '/', Icons.dashboard_rounded),
      _Destination('Products', '/products', Icons.inventory_2_rounded),
      _Destination('Orders', '/orders', Icons.shopping_cart_rounded),
      _Destination('Payments', '/settlements', Icons.currency_rupee_rounded),
      _Destination('Profile', '/profile', Icons.person_rounded),
    ];
  }

  static bool isBlockedForVendor(String path, VendorUser? vendor) {
    if (vendor == null || vendor.isBothVendor) return false;
    const serviceOnly = {'/services', '/availability', '/bookings'};
    const productOnly = {'/products', '/orders', '/dropshipping'};
    if (vendor.isProductVendor && serviceOnly.contains(path)) return true;
    if (vendor.isServiceVendor && productOnly.contains(path)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).uri.path;
    final isDashboard = location == '/';
    final auth = ref.watch(authStateProvider);
    final vendor = auth.valueOrNull;
    if (!auth.isLoading && vendor == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/login');
      });
    } else if (isBlockedForVendor(location, vendor)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/');
      });
    }
    final destinations = _bottomDestinationsFor(vendor);
    final current = destinations.indexWhere((d) => d.path == '/'
        ? location == '/'
        : location == d.path || location.startsWith('${d.path}/'));
    return PopScope(
      // Routes reached with go (for example a restored/deep-linked module)
      // have no page beneath them. Intercept Back and return to Dashboard.
      canPop: isDashboard || context.canPop(),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !isDashboard) context.go('/');
      },
      child: Scaffold(
        extendBody: true,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.brandDark,
          leading: isDashboard
              ? null
              : IconButton(
                  tooltip: 'Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/');
                    }
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
          titleSpacing: 12,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Image.asset('assets/images/p4u-logo.png',
                    fit: BoxFit.contain),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.brandDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            if (!isDashboard)
              Builder(
                builder: (scaffoldContext) => IconButton(
                  tooltip: 'Menu',
                  onPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
                  icon: const Icon(Icons.menu_rounded),
                ),
              ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: location == '/notifications'
                  ? null
                  : () => context.push('/notifications'),
              icon: const Icon(Icons.notifications_none_rounded),
            ),
            ...actions,
          ],
        ),
        drawer: _VendorDrawer(activePath: location),
        body: DecoratedBox(
          decoration: const BoxDecoration(gradient: AppColors.pageGradient),
          child: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: ScrollConfiguration(
                  behavior: const _VendorScrollBehavior(),
                  child: child,
                ),
              ),
            ),
          ),
        ),
        bottomNavigationBar: _VendorBottomNav(
          destinations: destinations,
          selectedIndex: current < 0 ? 0 : current,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      ),
    );
  }
}

class _VendorScrollBehavior extends MaterialScrollBehavior {
  const _VendorScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      const BouncingScrollPhysics(parent: ClampingScrollPhysics());
}

class _VendorBottomNav extends StatelessWidget {
  const _VendorBottomNav({
    required this.destinations,
    required this.selectedIndex,
  });

  final List<_Destination> destinations;
  final int selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
        child: Container(
          height: 68,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: .97),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            for (var index = 0; index < destinations.length; index++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    if (index != selectedIndex) {
                      context.go(destinations[index].path);
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 38,
                        height: 30,
                        decoration: BoxDecoration(
                          color: index == selectedIndex
                              ? AppColors.accent
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(destinations[index].icon,
                            size: 21, color: AppColors.slate),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          destinations[index].label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: index == selectedIndex
                                ? FontWeight.w600
                                : FontWeight.w600,
                            color: index == selectedIndex
                                ? AppColors.brandDark
                                : AppColors.muted,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

class _VendorDrawer extends ConsumerWidget {
  const _VendorDrawer({required this.activePath});

  final String activePath;

  List<_Destination> _itemsFor(VendorUser? vendor) {
    final hasProduct = vendor?.hasProductFlow != false;
    final hasService = vendor?.hasServiceFlow == true;
    return [
      const _Destination('Dashboard', '/', Icons.dashboard_rounded),
      if (hasProduct)
        const _Destination('Products', '/products', Icons.inventory_2_rounded),
      if (hasService)
        const _Destination('Services', '/services', Icons.handyman_rounded),
      if (hasService)
        const _Destination(
            'Availability', '/availability', Icons.calendar_month_rounded),
      if (hasProduct)
        const _Destination('Orders', '/orders', Icons.shopping_cart_rounded),
      if (hasService)
        const _Destination(
            'Bookings', '/bookings', Icons.event_available_rounded),
      const _Destination(
          'Settlements', '/settlements', Icons.currency_rupee_rounded),
      const _Destination('Reports', '/reports', Icons.insights_rounded),
      const _Destination('Payment History', '/payments', Icons.history_rounded),
      // Hidden to match the vendor web (no Wallet module on web). Route/page
      // code is kept in the router — only the menu entry is hidden.
      // const _Destination(
      //     'Wallet', '/wallet', Icons.account_balance_wallet_rounded),
      const _Destination(
          'Bank Account', '/bank', Icons.account_balance_rounded),
      const _Destination('Media Library', '/media', Icons.perm_media_rounded),
      // Hidden to match the vendor web (no dedicated Analytics/Reviews modules).
      // Kept in the router; only hidden from the menu.
      // const _Destination('Analytics', '/analytics', Icons.bar_chart_rounded),
      // const _Destination('Reviews', '/reviews', Icons.star_rounded),
      const _Destination('Support', '/support', Icons.help_outline_rounded),
      const _Destination('Settings', '/settings', Icons.settings_rounded),
      const _Destination('Account Control', '/account-control',
          Icons.admin_panel_settings_rounded),
    ];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendor = ref.watch(authStateProvider).valueOrNull;
    final items = _itemsFor(vendor);
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: .72),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Icon(Icons.storefront_rounded,
                      color: AppColors.slate),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          vendor?.businessName.isNotEmpty == true
                              ? titleCaseWords(vendor!.businessName)
                              : 'Vendor Portal',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.brandDark,
                              fontWeight: FontWeight.w600)),
                      Text(vendor?.name ?? 'Seller Dashboard',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 12)),
                    ],
                  ),
                ),
              ]),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: items.map((item) {
                  final selected = activePath == item.path;
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    child: Stack(
                      children: [
                        ListTile(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          selected: selected,
                          selectedColor: AppColors.brandDark,
                          tileColor: Colors.transparent,
                          selectedTileColor: Colors.transparent,
                          leading:
                              Icon(item.icon, color: AppColors.slate, size: 20),
                          title: Text(
                            item.label,
                            style: TextStyle(
                              fontWeight:
                                  selected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            if (item.path != activePath) {
                              context.go(item.path);
                            }
                          },
                        ),
                        if (selected)
                          Positioned(
                            top: 9,
                            right: 0,
                            bottom: 9,
                            child: Container(
                              width: 4,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            ListTile(
              leading:
                  const Icon(Icons.logout_rounded, color: AppColors.danger),
              title: const Text('Logout',
                  style: TextStyle(color: AppColors.danger)),
              onTap: () async {
                await ref.read(authRepositoryProvider).signOut();
                if (context.mounted) context.go('/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Destination {
  const _Destination(this.label, this.path, this.icon);
  final String label;
  final String path;
  final IconData icon;
}
