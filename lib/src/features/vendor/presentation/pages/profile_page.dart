import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_value_ui.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/text_formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/metric_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../data/vendor_providers.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(vendorProfileProvider);
    final dashboard = ref.watch(dashboardProvider);
    return VendorScaffold(
      title: 'Business Profile',
      child: profile.whenUi(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (vendor) => ListView(
          padding: VendorLayout.pagePadding(context),
          children: [
            _ProfileHero(
              vendor: vendor,
              onChangeCover: () => _uploadCover(context, ref),
            ),
            const SizedBox(height: 18),
            LayoutBuilder(builder: (context, constraints) {
              final details = _BusinessDetailsCard(
                vendor: vendor,
                onEdit: () => _editProfile(context, ref, vendor),
              );
              final plan = _PlanCard(vendor: vendor);
              if (constraints.maxWidth >= 760) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 6, child: details),
                    const SizedBox(width: 14),
                    Expanded(flex: 4, child: plan),
                  ],
                );
              }
              return Column(
                  children: [details, const SizedBox(height: 14), plan]);
            }),
            const SizedBox(height: 20),
            Text('Business overview',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 10),
            dashboard.maybeWhen(
              data: (d) => ResponsiveMetricGrid(
                maxColumns: 3,
                children: [
                  MetricCard(
                      icon: Icons.inventory_2_rounded,
                      color: AppColors.coral,
                      label: 'Products',
                      value: '${d.products.length}'),
                  MetricCard(
                      icon: Icons.shopping_cart_rounded,
                      color: AppColors.amber,
                      label: 'Orders',
                      value: '${d.orders.length}'),
                  MetricCard(
                      icon: Icons.currency_rupee_rounded,
                      color: AppColors.mint,
                      label: 'Revenue',
                      value: NumberFormat.compactCurrency(
                              locale: 'en_IN', symbol: 'Rs.')
                          .format(d.revenue)),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(
      BuildContext context, WidgetRef ref, Map<String, dynamic> vendor) async {
    final vendorId = ref.read(vendorIdProvider);
    if (vendorId == null) return;
    final email =
        TextEditingController(text: vendor['email']?.toString() ?? '');
    final mobile =
        TextEditingController(text: vendor['mobile']?.toString() ?? '');
    final address =
        TextEditingController(text: vendor['shop_address']?.toString() ?? '');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
            16, 8, 16, MediaQuery.viewInsetsOf(sheetContext).bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 10),
            TextField(
                controller: mobile,
                decoration: const InputDecoration(labelText: 'Phone')),
            const SizedBox(height: 10),
            TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Shop Address')),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                await ref
                    .read(vendorRepositoryProvider)
                    .updateProfile(vendorId, {
                  'email': email.text.trim(),
                  'mobile': mobile.text.trim(),
                  'shop_address': address.text.trim()
                });
                ref.invalidate(vendorProfileProvider);
                if (sheetContext.mounted) Navigator.pop(sheetContext);
              },
              child: const Text('Save Profile'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadCover(BuildContext context, WidgetRef ref) async {
    final vendorId = ref.read(vendorIdProvider);
    if (vendorId == null) return;
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 82);
    if (picked == null) return;
    final url = await ref.read(vendorRepositoryProvider).uploadVendorAsset(
          vendorId,
          File(picked.path),
          'vendor-backgrounds',
          picked.name,
          picked.mimeType ?? 'image/jpeg',
        );
    await ref
        .read(vendorRepositoryProvider)
        .updateProfile(vendorId, {'background_image': url});
    ref.invalidate(vendorProfileProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Cover image updated')));
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({required this.vendor, required this.onChangeCover});

  final Map<String, dynamic> vendor;
  final VoidCallback onChangeCover;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 440;
          final background = vendor['background_image']?.toString();
          return Container(
            height: compact ? 220 : 250,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: AppColors.border),
              image: background != null && background.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(background), fit: BoxFit.cover)
                  : const DecorationImage(
                      image:
                          AssetImage('assets/images/vendor/business-trust.png'),
                      fit: BoxFit.cover,
                      alignment: Alignment.centerRight,
                    ),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x12FFFFFF), Color(0xF7FFFFFF)],
                      stops: [0, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  right: 14,
                  child: FilledButton.tonalIcon(
                    onPressed: onChangeCover,
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: Text(compact ? 'Cover' : 'Change cover'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: .92),
                      foregroundColor: AppColors.brandDark,
                      minimumSize: const Size(44, 40),
                    ),
                  ),
                ),
                Positioned(
                  left: compact ? 16 : 22,
                  right: compact ? 16 : 22,
                  bottom: compact ? 16 : 22,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: compact ? 58 : 68,
                        height: compact ? 58 : 68,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: .8),
                              width: 2),
                        ),
                        child: const Icon(Icons.storefront_rounded,
                            size: 31, color: AppColors.slate),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              titleCaseWords(vendor['business_name'] ??
                                  vendor['businessName'] ??
                                  'Business'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.brandDark,
                                fontSize: compact ? 20 : 24,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${vendor['name'] ?? 'Vendor'} • Category ${vendor['category_id'] ?? '—'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge(vendor['status']?.toString() ?? 'pending'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _BusinessDetailsCard extends StatelessWidget {
  const _BusinessDetailsCard({required this.vendor, required this.onEdit});

  final Map<String, dynamic> vendor;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) => AppCard(
        elevated: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const _SectionIcon(Icons.store_mall_directory_outlined),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Business details',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
              TextButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit')),
            ]),
            const Divider(height: 22),
            _Detail(Icons.mail_outline_rounded, 'Email', vendor['email']),
            _Detail(Icons.phone_outlined, 'Phone', vendor['mobile']),
            _Detail(
                Icons.location_on_outlined,
                'Location',
                vendor['shop_address'] ??
                    'Area ${vendor['area_id']}, City ${vendor['city_id']}'),
            _Detail(Icons.percent_rounded, 'Commission rate',
                '${vendor['commission_rate'] ?? 0}%'),
          ],
        ),
      );
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.vendor});

  final Map<String, dynamic> vendor;

  @override
  Widget build(BuildContext context) => AppCard(
        elevated: true,
        color: const Color(0xFFF9F7FF),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const _SectionIcon(Icons.workspace_premium_outlined,
                  color: AppColors.violet),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Plan & verification',
                    style: Theme.of(context).textTheme.titleSmall),
              ),
            ]),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current plan',
                        style: TextStyle(color: AppColors.muted, fontSize: 11)),
                    Text(
                      vendor['membership']?.toString() == 'premium'
                          ? 'Premium Plan'
                          : 'Basic Plan',
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                  vendor['plan_payment_status']?.toString() ?? 'unpaid'),
            ]),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => context.push('/plans'),
                  icon: const Icon(Icons.workspace_premium_outlined),
                  label: const Text('Manage plan'),
                ),
                OutlinedButton.icon(
                  onPressed: () => context.push('/kyc'),
                  icon: const Icon(Icons.verified_user_outlined),
                  label: const Text('KYC'),
                ),
              ],
            ),
            if (vendor['plan_transaction_id'] != null) ...[
              const SizedBox(height: 12),
              Text('Transaction: ${vendor['plan_transaction_id']}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
            ],
          ],
        ),
      );
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon(this.icon, {this.color = AppColors.primary});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .11),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      );
}

class _Detail extends StatelessWidget {
  const _Detail(this.icon, this.label, this.value);
  final IconData icon;
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.slate),
          const SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(fontSize: 11, color: AppColors.muted)),
              Text(value?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ),
        ],
      ),
    );
  }
}
