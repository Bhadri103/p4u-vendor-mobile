import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/core/theme/app_theme.dart';
import 'package:p4u_vendor_app/src/core/utils/text_formatters.dart';
import 'package:p4u_vendor_app/src/core/widgets/metric_card.dart';
import 'package:p4u_vendor_app/src/core/widgets/vendor_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shop names capitalize the first letter of every word', () {
    expect(titleCaseWords('mobile shop'), 'Mobile Shop');
    expect(titleCaseWords('  new   Planext4U store  '), 'New Planext4U Store');
  });

  test('vendor dashboard uses light surfaces and colorful module artwork',
      () async {
    final theme = AppTheme.light();

    expect(theme.scaffoldBackgroundColor, AppColors.background);
    expect(theme.appBarTheme.backgroundColor, AppColors.background);
    expect(theme.appBarTheme.foregroundColor, AppColors.brandDark);
    expect(theme.cardTheme.elevation, 0);
    expect(theme.iconTheme.color, AppColors.slate);
    expect(theme.inputDecorationTheme.prefixIconColor, AppColors.slate);
    expect(theme.textTheme.bodyMedium?.fontFamily, AppTheme.fontFamily);
    expect(theme.textTheme.titleLarge?.fontWeight, FontWeight.w600);
    expect(theme.filledButtonTheme.style?.minimumSize?.resolve({}),
        const Size(40, 44));
    expect(theme.outlinedButtonTheme.style?.minimumSize?.resolve({}),
        const Size(40, 42));

    final hero = await rootBundle
        .load('assets/images/vendor/dashboard-light-overview.png');
    expect(hero.lengthInBytes, greaterThan(0));
    const actionAssets = [
      'products.png',
      'orders.png',
      'settlements.png',
      'reports.png',
      'bank.png',
      'dropship.png',
      'kyc.png',
      'plans.png',
    ];
    for (final asset in actionAssets) {
      final bytes =
          await rootBundle.load('assets/images/vendor/quick-actions/$asset');
      expect(bytes.lengthInBytes, greaterThan(0));
    }
  });

  testWidgets('metric cards fit compact page grids without overflow',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const Scaffold(
          body: Center(
            child: SizedBox(
              width: 180,
              height: 86,
              child: MetricCard(
                icon: Icons.shopping_bag_rounded,
                color: AppColors.coral,
                value: '30.30K',
                label: 'Revenue',
                caption: '2 orders',
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.text('30.30K'), findsOneWidget);
    final cardDecorations = tester
        .widgetList<Container>(find.byType(Container))
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>();
    expect(
        cardDecorations.every((decoration) =>
            decoration.boxShadow == null || decoration.boxShadow!.isEmpty),
        isTrue);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.shopping_bag_rounded)).color,
      AppColors.coral,
    );
  });

  testWidgets('responsive metric grid adapts across phone and tablet widths',
      (tester) async {
    Future<void> renderAt(double width) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: width,
              child: const ResponsiveMetricGrid(
                children: [
                  MetricCard(
                      icon: Icons.inventory_2_rounded,
                      label: 'Products',
                      value: '12'),
                  MetricCard(
                      icon: Icons.shopping_cart_rounded,
                      label: 'Orders',
                      value: '8'),
                  MetricCard(
                      icon: Icons.currency_rupee_rounded,
                      label: 'Revenue',
                      value: 'Rs.30K'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    await renderAt(300);
    await renderAt(900);
  });
}
