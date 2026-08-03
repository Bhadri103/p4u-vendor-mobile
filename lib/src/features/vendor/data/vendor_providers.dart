import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../domain/vendor_models.dart';
import 'vendor_repository.dart';

final vendorRepositoryProvider = Provider((ref) => VendorRepository());

final vendorIdProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateProvider);
  return auth.valueOrNull?.id;
});

final currentVendorProvider = Provider<VendorUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

final dashboardProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  if (vendorId == null) throw StateError('Not signed in');
  return ref.watch(vendorRepositoryProvider).dashboard(vendorId);
});

final vendorProductsProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  final vendor = ref.watch(currentVendorProvider);
  if (vendorId == null || vendor?.hasProductFlow == false) {
    return <Map<String, dynamic>>[];
  }
  return ref.watch(vendorRepositoryProvider).products(vendorId);
});

final vendorServicesProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  final vendor = ref.watch(currentVendorProvider);
  if (vendorId == null || vendor?.hasServiceFlow != true) {
    return <Map<String, dynamic>>[];
  }
  return ref.watch(vendorRepositoryProvider).services(vendorId);
});

final serviceCategoriesProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  final vendor = ref.watch(currentVendorProvider);
  if (vendorId == null || vendor?.hasServiceFlow != true) {
    return <Map<String, dynamic>>[];
  }
  return ref.watch(vendorRepositoryProvider).serviceCategories(vendorId);
});

final catalogServiceItemsProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  final vendor = ref.watch(currentVendorProvider);
  if (vendorId == null || vendor?.hasServiceFlow != true) {
    return <Map<String, dynamic>>[];
  }
  return ref.watch(vendorRepositoryProvider).catalogServiceItems(vendorId);
});

final vendorOrdersProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  final vendor = ref.watch(currentVendorProvider);
  if (vendorId == null || vendor?.hasProductFlow == false) {
    return <Map<String, dynamic>>[];
  }
  return ref.watch(vendorRepositoryProvider).orders(vendorId);
});

final vendorOrderProvider =
    FutureProvider.family<Map<String, dynamic>?, String>((ref, orderId) {
  return ref.watch(vendorRepositoryProvider).order(orderId);
});

final vendorBookingsProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  final vendor = ref.watch(currentVendorProvider);
  if (vendorId == null || vendor?.hasServiceFlow != true) {
    return <Map<String, dynamic>>[];
  }
  return ref.watch(vendorRepositoryProvider).bookings(vendorId);
});

final vendorSettlementsProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  if (vendorId == null) return <Map<String, dynamic>>[];
  return ref.watch(vendorRepositoryProvider).settlements(vendorId);
});
final settlementStatsProvider = FutureProvider((ref) async {
  final rows = await ref.watch(vendorSettlementsProvider.future);
  double sumWhere(bool Function(Map<String, dynamic>) test) =>
      rows.where(test).fold(0, (sum, row) => sum + moneyOf(row, 'net_amount'));
  return SettlementStats(
    totalEarned: sumWhere((r) => [
          'pending',
          'eligible',
          'created',
          'processing',
          'queued',
          'settled',
          'completed',
          'paid'
        ].contains(r['status']?.toString().toLowerCase())),
    pending: sumWhere((r) => [
          'pending',
          'eligible',
          'created',
          'processing',
          'queued'
        ].contains(r['status']?.toString().toLowerCase())),
    settled: sumWhere((r) => ['settled', 'completed', 'paid']
        .contains(r['status']?.toString().toLowerCase())),
    rejected: sumWhere((r) => ['rejected', 'failed', 'cancelled', 'on_hold']
        .contains(r['status']?.toString().toLowerCase())),
  );
});

final vendorProfileProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  if (vendorId == null) return <String, dynamic>{};
  return ref.watch(vendorRepositoryProvider).profile(vendorId);
});

final vendorBanksProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  if (vendorId == null) return <Map<String, dynamic>>[];
  return ref.watch(vendorRepositoryProvider).bankAccounts(vendorId);
});

final vendorNotificationsProvider = FutureProvider((ref) async {
  final vendorId = ref.watch(vendorIdProvider);
  if (vendorId == null) return <Map<String, dynamic>>[];
  return ref.watch(vendorRepositoryProvider).notifications(vendorId);
});
