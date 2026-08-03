import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/features/auth/presentation/register_page.dart';
import 'package:p4u_vendor_app/src/features/vendor/data/vendor_providers.dart';
import 'package:p4u_vendor_app/src/features/vendor/data/vendor_repository.dart';

class _RegistrationRepository extends VendorRepository {
  @override
  Future<List<Map<String, dynamic>>> registrationProductCategories() async =>
      const [
        {'id': 'grocery-id', 'name': 'Groceries', 'slug': 'groceries'},
        {'id': 'electronics-id', 'name': 'Electronics', 'slug': 'electronics'},
      ];

  @override
  Future<List<Map<String, dynamic>>> registrationServiceCategories() async =>
      const [
        {'id': 'plumbing-id', 'name': 'Plumbing', 'slug': 'plumbing'},
        {'id': 'salon-id', 'name': 'Salon', 'slug': 'salon'},
      ];

  @override
  Future<String?> checkVendorPhoneUnique(String phone) async => null;

  @override
  Future<String?> checkVendorEmailUnique(String email) async => null;
}

Finder _textField(String key) =>
    find.byKey(ValueKey('vendor-registration-field-$key'));

String _fieldText(WidgetTester tester, String key) {
  final editable = find.descendant(
    of: _textField(key),
    matching: find.byType(EditableText),
  );
  return tester.widget<EditableText>(editable).controller.text;
}

Future<void> _tapNext(WidgetTester tester) async {
  final next = find.text('Next');
  await tester.dragUntilVisible(
    next,
    find.byType(ListView),
    const Offset(0, -300),
  );
  await tester.tap(next);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('registration steps do not copy values into unrelated fields',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_RegistrationRepository()),
        ],
        child: const MaterialApp(home: VendorRegisterPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(_textField('name'), 'Selva Kumar');
    await tester.enterText(_textField('email'), 'selva@example.com');
    await _tapNext(tester);

    expect(find.text('Business Details'), findsOneWidget);
    expect(_fieldText(tester, 'business_name'), isEmpty);
    expect(_fieldText(tester, 'state'), isEmpty);
    expect(_fieldText(tester, 'district'), isEmpty);
    expect(_fieldText(tester, 'shop_address'), isEmpty);
    await _tapNext(tester);

    expect(find.text('KYC & Documents'), findsOneWidget);
    await _tapNext(tester);

    expect(find.text('Bank Details'), findsOneWidget);
    expect(_fieldText(tester, 'bank_name'), isEmpty);
    expect(_fieldText(tester, 'bank_holder_name'), isEmpty);
    expect(_fieldText(tester, 'bank_account_number'), isEmpty);
  });

  testWidgets('product category uses catalog options and supports add new',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_RegistrationRepository()),
        ],
        child: const MaterialApp(home: VendorRegisterPage()),
      ),
    );
    await tester.pumpAndSettle();
    await _tapNext(tester);

    final vendorType =
        find.byKey(const ValueKey('vendor-registration-dropdown-category'));
    await tester.ensureVisible(vendorType);
    await tester.tap(vendorType);
    await tester.pumpAndSettle();
    await tester.tap(find.text('product').last);
    await tester.pumpAndSettle();

    final dropdownFinder = find.byKey(
      const ValueKey('vendor-registration-product-category-2'),
    );
    expect(dropdownFinder, findsOneWidget);

    await tester.ensureVisible(dropdownFinder);
    await tester.pumpAndSettle();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Groceries').last, findsOneWidget);
    expect(find.text('+ Add new category').last, findsOneWidget);
    await tester.tap(find.text('+ Add new category').last);
    await tester.pumpAndSettle();

    expect(_textField('product_category'), findsOneWidget);
  });

  testWidgets('service selector uses admin options and supports add new',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_RegistrationRepository()),
        ],
        child: const MaterialApp(home: VendorRegisterPage()),
      ),
    );
    await tester.pumpAndSettle();
    await _tapNext(tester);

    final vendorType = find.byKey(
      const ValueKey('vendor-registration-dropdown-category'),
    );
    await tester.ensureVisible(vendorType);
    await tester.tap(vendorType);
    await tester.pumpAndSettle();
    await tester.tap(find.text('service').last);
    await tester.pumpAndSettle();

    final service = find.byKey(
      const ValueKey('vendor-registration-service-category-2'),
    );
    await tester.ensureVisible(service);
    await tester.tap(service);
    await tester.pumpAndSettle();
    expect(find.text('Plumbing').last, findsOneWidget);
    expect(find.text('+ Add new service').last, findsOneWidget);
    await tester.tap(find.text('+ Add new service').last);
    await tester.pumpAndSettle();
    expect(_textField('service_name'), findsOneWidget);
  });
  testWidgets('all registration steps can be skipped when fields are empty',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          vendorRepositoryProvider.overrideWithValue(_RegistrationRepository()),
        ],
        child: const MaterialApp(home: VendorRegisterPage()),
      ),
    );
    await tester.pumpAndSettle();

    for (var step = 1; step < 5; step++) {
      await _tapNext(tester);
    }

    expect(find.text('Review & Submit'), findsOneWidget);
  });
}
