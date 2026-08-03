import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/text_formatters.dart';
import '../../../core/widgets/app_card.dart';
import '../../vendor/data/vendor_providers.dart';

String _categoryString(Map<String, dynamic> row, String key) =>
    row[key]?.toString().trim() ?? '';

class VendorRegisterPage extends ConsumerStatefulWidget {
  const VendorRegisterPage({super.key});

  @override
  ConsumerState<VendorRegisterPage> createState() => _VendorRegisterPageState();
}

class _VendorRegisterPageState extends ConsumerState<VendorRegisterPage> {
  int step = 1;
  bool loading = false;
  bool categoriesLoading = false;
  bool servicesLoading = false;
  String? categoriesError;
  String? servicesError;
  List<Map<String, dynamic>> productCategories = const [];
  List<Map<String, dynamic>> serviceCategories = const [];

  static const _addNewCategory = '__add_new_category__';
  static const _addNewService = '__add_new_service__';
  final ScrollController _scrollController = ScrollController();

  final form = <String, dynamic>{
    'name': '',
    'phone': '',
    'secondary_phone': '',
    'email': '',
    'business_name': '',
    'business_type': '',
    'category': '',
    'product_category': '',
    'product_category_id': '',
    'service_name': '',
    'service_category_id': '',
    'state': '',
    'district': '',
    'shop_address': '',
    'aadhaar_number': '',
    'aadhaar_front_url': '',
    'aadhaar_back_url': '',
    'pan_number': '',
    'pan_image_url': '',
    'gst_number': '',
    'gst_certificate_url': '',
    'bank_name': '',
    'bank_holder_name': '',
    'bank_account_number': '',
    'bank_confirm_account': '',
    'bank_ifsc': '',
  };
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadProductCategories);
    Future<void>.microtask(_loadServiceCategories);
  }

  Future<void> _loadProductCategories() async {
    setState(() {
      categoriesLoading = true;
      categoriesError = null;
    });
    try {
      final rows = await ref
          .read(vendorRepositoryProvider)
          .registrationProductCategories();
      if (!mounted) return;
      setState(() => productCategories = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => categoriesError =
          'Categories could not be loaded. You can add one manually.');
    } finally {
      if (mounted) setState(() => categoriesLoading = false);
    }
  }

  Future<void> _loadServiceCategories() async {
    setState(() {
      servicesLoading = true;
      servicesError = null;
    });
    try {
      final rows = await ref
          .read(vendorRepositoryProvider)
          .registrationServiceCategories();
      if (!mounted) return;
      setState(() => serviceCategories = rows);
    } catch (_) {
      if (!mounted) return;
      setState(() => servicesError =
          'Services could not be loaded. You can add one manually.');
    } finally {
      if (mounted) setState(() => servicesLoading = false);
    }
  }

  void _set(String key, Object? value) =>
      setState(() => form[key] = value ?? '');

  void _changeStep(int nextStep) {
    setState(() => step = nextStep.clamp(1, 5));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.arrow_back_rounded)),
        title: const Text('Create vendor account'),
        actions: [
          TextButton(
            onPressed: () => context.go('/login'),
            child: const Text('Sign in'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.pageGradient),
        child: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: ListView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                children: [
                  if (step == 1) ...[
                    _registrationHero(),
                    const SizedBox(height: 16),
                  ],
                  _registrationProgress(),
                  const SizedBox(height: 14),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 280),
                    switchInCurve: Curves.easeOutCubic,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween(
                          begin: const Offset(.04, 0),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(step),
                      child: switch (step) {
                        1 => _personalStep(),
                        2 => _businessStep(),
                        3 => _kycStep(),
                        4 => _bankStep(),
                        _ => _reviewStep(),
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (step > 1)
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed:
                                loading ? null : () => _changeStep(step - 1),
                            icon: const Icon(Icons.arrow_back_rounded),
                            label: const Text('Back'),
                          ),
                        ),
                      if (step > 1) const SizedBox(width: 10),
                      Expanded(
                        flex: step > 1 ? 2 : 1,
                        child: FilledButton.icon(
                          onPressed:
                              loading ? null : (step < 5 ? _next : _submit),
                          icon: loading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Icon(step < 5
                                  ? Icons.arrow_forward_rounded
                                  : Icons.rocket_launch_rounded),
                          label: Text(loading
                              ? 'Please wait...'
                              : (step < 5 ? 'Next' : 'Submit application')),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _registrationHero() => Container(
        height: 190,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF9FCFE), Color(0xFFE9F5FD)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              width: 240,
              child: Opacity(
                opacity: .60,
                child: Image.asset('assets/images/vendor/vendor-onboarding.png',
                    fit: BoxFit.cover, alignment: Alignment.centerRight),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF9FCFE),
                    const Color(0xFFF9FCFE).withValues(alpha: .94),
                    const Color(0xFFF9FCFE).withValues(alpha: .16),
                  ],
                  stops: const [0, .58, 1],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(22),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.storefront_rounded,
                      color: AppColors.slate, size: 28),
                  SizedBox(height: 10),
                  Text('Turn your business into a brand.',
                      style: TextStyle(
                          color: AppColors.brandDark,
                          fontSize: 23,
                          fontWeight: FontWeight.w600)),
                  SizedBox(height: 5),
                  Text(
                    'Join Planext4u and manage products, services, bookings and earnings from one workspace.',
                    style: TextStyle(
                        color: AppColors.muted, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _registrationProgress() => AppCard(
        elevated: true,
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Step $step of 5',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ),
                Text('${_completion()}% complete',
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                value: step / 5,
                color: AppColors.primary,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 13),
            Row(
              children: [
                for (final entry in const [
                  (Icons.person_rounded, 'Personal'),
                  (Icons.store_rounded, 'Business'),
                  (Icons.verified_user_rounded, 'KYC'),
                  (Icons.account_balance_rounded, 'Bank'),
                  (Icons.fact_check_rounded, 'Review'),
                ].asMap().entries)
                  Expanded(
                    child: Column(
                      children: [
                        Icon(entry.value.$1, size: 18, color: AppColors.slate),
                        const SizedBox(height: 4),
                        FittedBox(
                          child: Text(entry.value.$2,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: step == entry.key + 1
                                      ? AppColors.brandDark
                                      : AppColors.muted,
                                  fontWeight: step == entry.key + 1
                                      ? FontWeight.w600
                                      : FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      );

  Widget _personalStep() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Personal Details',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('All registration fields are optional.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 12),
          _field('Owner Name', 'name',
              textCapitalization: TextCapitalization.words),
          _field('Phone', 'phone',
              keyboard: TextInputType.phone, maxLength: 10),
          _field('Secondary Phone', 'secondary_phone',
              keyboard: TextInputType.phone, maxLength: 10),
          _field('Email', 'email', keyboard: TextInputType.emailAddress),
        ],
      ),
    );
  }

  Widget _businessStep() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Business Details',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _field('Business Name', 'business_name',
              textCapitalization: TextCapitalization.words),
          _dropdown('Business Type', 'business_type',
              const ['proprietorship', 'partnership', 'pvt_ltd']),
          _dropdown(
              'Vendor Type', 'category', const ['product', 'service', 'both']),
          if (form['category'] == 'product' || form['category'] == 'both')
            _productCategoryDropdown(),
          if (form['category'] == 'service' || form['category'] == 'both')
            _serviceCategoryDropdown(),
          _field('State', 'state',
              textCapitalization: TextCapitalization.words),
          _field('District', 'district',
              textCapitalization: TextCapitalization.words),
          _field('Shop Address', 'shop_address', maxLines: 3),
        ],
      ),
    );
  }

  Widget _kycStep() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('KYC & Documents',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('All KYC details are optional during registration.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 12),
          _field('Aadhaar Number', 'aadhaar_number',
              keyboard: TextInputType.number, maxLength: 12),
          _uploadTile('aadhaar_front_url', 'Aadhaar Front'),
          _uploadTile('aadhaar_back_url', 'Aadhaar Back'),
          const Divider(height: 28),
          _field('PAN Number', 'pan_number',
              textCapitalization: TextCapitalization.characters, maxLength: 10),
          _uploadTile('pan_image_url', 'PAN Card'),
          const Divider(height: 28),
          _field('GST Number', 'gst_number',
              textCapitalization: TextCapitalization.characters, maxLength: 15),
          _uploadTile('gst_certificate_url', 'GST Certificate'),
        ],
      ),
    );
  }

  Widget _bankStep() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bank Details',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          const Text('Optional settlement account details.',
              style: TextStyle(fontSize: 12, color: AppColors.muted)),
          const SizedBox(height: 12),
          _field('Bank Name', 'bank_name'),
          _field('Account Holder Name', 'bank_holder_name'),
          _field('Account Number', 'bank_account_number',
              keyboard: TextInputType.number, maxLength: 18),
          _field('Confirm Account Number', 'bank_confirm_account',
              keyboard: TextInputType.number, maxLength: 18),
          _field('IFSC Code', 'bank_ifsc',
              textCapitalization: TextCapitalization.characters, maxLength: 11),
        ],
      ),
    );
  }

  Widget _reviewStep() {
    final vendorType = form['category'].toString();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Review & Submit',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _review('Owner Name', form['name']),
          _review('Phone', form['phone']),
          _review('Secondary Phone', form['secondary_phone']),
          _review('Email', form['email']),
          _review('Business Name', titleCaseWords(form['business_name'])),
          _review('Business Type', form['business_type']),
          _review('Vendor Type', vendorType),
          if (vendorType == 'product' || vendorType == 'both')
            _review('Product Category', form['product_category']),
          if (vendorType == 'service' || vendorType == 'both')
            _review('Service Name', form['service_name']),
          _review('State', form['state']),
          _review('District', form['district']),
          _review('Shop Address', form['shop_address']),
          _review('Aadhaar', form['aadhaar_number']),
          _review('PAN', form['pan_number']),
          _review('GST', form['gst_number']),
          _review('Bank Name', form['bank_name']),
          _review('Account Holder', form['bank_holder_name']),
          _review('Account Number',
              form['bank_account_number'].toString().isEmpty ? '' : 'Provided'),
          _review('IFSC', form['bank_ifsc']),
        ],
      ),
    );
  }

  Widget _serviceCategoryDropdown() {
    final selected = form['service_category_id'].toString();
    final validSelection = selected.isEmpty ||
        selected == _addNewService ||
        serviceCategories.any((row) => _categoryString(row, 'id') == selected);
    final dropdownValue = validSelection ? selected : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(
              'vendor-registration-service-category-${serviceCategories.length}'),
          initialValue: dropdownValue,
          decoration: const InputDecoration(labelText: 'Service'),
          items: [
            const DropdownMenuItem(
                value: '', child: Text('No service selected')),
            ...serviceCategories.map((row) => DropdownMenuItem(
                  value: _categoryString(row, 'id'),
                  child: Text(_categoryString(row, 'name')),
                )),
            const DropdownMenuItem(
              value: _addNewService,
              child: Text('+ Add new service'),
            ),
          ],
          onChanged: (value) {
            final next = value ?? '';
            setState(() {
              form['service_category_id'] = next;
              if (next == _addNewService || next.isEmpty) {
                form['service_name'] = '';
              } else {
                final row = serviceCategories.firstWhere(
                  (item) => _categoryString(item, 'id') == next,
                  orElse: () => const <String, dynamic>{},
                );
                form['service_name'] = _categoryString(row, 'slug').isNotEmpty
                    ? _categoryString(row, 'slug')
                    : _categoryString(row, 'name');
              }
            });
          },
        ),
        if (servicesLoading)
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (servicesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(servicesError!,
                style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ),
        if (form['service_category_id'] == _addNewService)
          _field('New Service', 'service_name'),
      ],
    );
  }

  Widget _productCategoryDropdown() {
    final selected = form['product_category_id'].toString();
    final validSelection = selected.isEmpty ||
        selected == _addNewCategory ||
        productCategories.any((row) => _categoryString(row, 'id') == selected);
    final dropdownValue = validSelection ? selected : '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(
              'vendor-registration-product-category-${productCategories.length}'),
          initialValue: dropdownValue,
          decoration: const InputDecoration(labelText: 'Product Category'),
          items: [
            const DropdownMenuItem(
                value: '', child: Text('No category selected')),
            ...productCategories.map((row) => DropdownMenuItem(
                  value: _categoryString(row, 'id'),
                  child: Text(_categoryString(row, 'name')),
                )),
            const DropdownMenuItem(
              value: _addNewCategory,
              child: Text('+ Add new category'),
            ),
          ],
          onChanged: (value) {
            final next = value ?? '';
            setState(() {
              form['product_category_id'] = next;
              if (next == _addNewCategory || next.isEmpty) {
                form['product_category'] = '';
              } else {
                final row = productCategories.firstWhere(
                  (item) => _categoryString(item, 'id') == next,
                  orElse: () => const <String, dynamic>{},
                );
                form['product_category'] =
                    _categoryString(row, 'slug').isNotEmpty
                        ? _categoryString(row, 'slug')
                        : _categoryString(row, 'name');
              }
            });
          },
        ),
        if (categoriesLoading)
          const Padding(
            padding: EdgeInsets.only(top: 6, bottom: 8),
            child: LinearProgressIndicator(),
          ),
        if (categoriesError != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 8),
            child: Text(categoriesError!,
                style: const TextStyle(fontSize: 12, color: Colors.orange)),
          ),
        if (form['product_category_id'] == _addNewCategory)
          _field('New Product Category', 'product_category'),
      ],
    );
  }

  Widget _field(String label, String key,
      {TextInputType? keyboard,
      int? maxLength,
      int maxLines = 1,
      TextCapitalization textCapitalization = TextCapitalization.none}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        key: ValueKey('vendor-registration-field-$key'),
        initialValue: form[key]?.toString() ?? '',
        keyboardType: keyboard,
        maxLength: maxLength,
        maxLines: maxLines,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(labelText: label, counterText: ''),
        onChanged: (v) {
          final clean = keyboard == TextInputType.phone ||
                  keyboard == TextInputType.number
              ? v.replaceAll(RegExp(r'\D'), '')
              : v;
          form[key] = clean;
        },
      ),
    );
  }

  Widget _dropdown(String label, String key, List<String> values,
      {ValueChanged<String>? onChanged}) {
    final value = values.contains(form[key]) ? form[key] as String : null;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        key: ValueKey('vendor-registration-dropdown-$key'),
        initialValue: value,
        decoration: InputDecoration(labelText: label),
        items: values
            .map((v) => DropdownMenuItem(value: v, child: Text(v)))
            .toList(),
        onChanged: (v) {
          if (v == null) return;
          if (onChanged == null) {
            _set(key, v);
          } else {
            onChanged(v);
          }
        },
      ),
    );
  }

  Widget _uploadTile(String key, String label) {
    final hasFile = form[key]?.toString().isNotEmpty == true;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          OutlinedButton.icon(
            onPressed: () => _pickUpload(key),
            icon: Icon(
                hasFile ? Icons.check_circle_rounded : Icons.upload_rounded,
                color: hasFile ? AppColors.success : null),
            label: Text(hasFile ? 'Selected' : 'Select'),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
          if (hasFile)
            IconButton(
                onPressed: () => _set(key, ''),
                icon: const Icon(Icons.close_rounded)),
        ],
      ),
    );
  }

  Widget _review(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: const TextStyle(color: AppColors.muted))),
          Expanded(
              child: Text(value?.toString() ?? '',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }

  Future<void> _pickUpload(String key) async {
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf']);
    if (result == null || result.files.single.path == null) return;
    final file = File(result.files.single.path!);
    if (await file.length() > 2 * 1024 * 1024) {
      _snack('File must be under 2MB');
      return;
    }
    final ext = result.files.single.extension?.toLowerCase();
    final contentType = ext == 'pdf' ? 'application/pdf' : 'image/jpeg';
    setState(() => loading = true);
    try {
      final url = await ref
          .read(vendorRepositoryProvider)
          .uploadRegistrationFile(file, key, contentType);
      _set(key, url);
      _snack('File selected for the application');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _next() async {
    final err = _validate();
    if (err != null) {
      _snack(err);
      return;
    }
    if (step == 1) {
      setState(() => loading = true);
      try {
        final repo = ref.read(vendorRepositoryProvider);
        final phoneErr =
            await repo.checkVendorPhoneUnique(form['phone'].toString());
        if (phoneErr != null) return _snack(phoneErr);
        final emailErr =
            await repo.checkVendorEmailUnique(form['email'].toString());
        if (emailErr != null) return _snack(emailErr);
      } catch (e) {
        _snack(e is ApiException
            ? e.message
            : 'Could not verify your details. Please try again.');
        return;
      } finally {
        if (mounted) setState(() => loading = false);
      }
    }
    _changeStep(step + 1);
  }

  Future<void> _submit() async {
    final err = _validate();
    if (err != null) {
      _snack(err);
      return;
    }
    setState(() => loading = true);
    try {
      final payload = Map<String, dynamic>.from(form)
        ..addAll({
          'user_id': form['email'],
          'status': 'submitted',
        });
      await ref.read(vendorRepositoryProvider).submitVendorApplication(payload);
      if (mounted) {
        _snack('Application submitted. Our team will review it.');
        context.go('/login');
      }
    } catch (e) {
      _snack(e is ApiException
          ? e.message
          : 'Could not submit the application. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String? _validate() {
    if (step == 1) {
      final name = form['name'].toString().trim();
      final phone = form['phone'].toString().trim();
      final secondaryPhone = form['secondary_phone'].toString().trim();
      final email = form['email'].toString().trim();
      if (name.isNotEmpty && name.length < 2) {
        return 'Owner name must be at least 2 characters';
      }
      if (phone.isNotEmpty && !RegExp(r'^[6-9]\d{9}$').hasMatch(phone)) {
        return 'Enter a valid 10-digit phone number';
      }
      if (secondaryPhone.isNotEmpty &&
          !RegExp(r'^[6-9]\d{9}$').hasMatch(secondaryPhone)) {
        return 'Enter a valid 10-digit secondary phone number';
      }
      if (email.isNotEmpty &&
          !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
        return 'Enter a valid email';
      }
    }
    if (step == 3) {
      final aadhaar = form['aadhaar_number'].toString();
      final pan = form['pan_number'].toString().toUpperCase();
      final gst = form['gst_number'].toString().toUpperCase();
      if (aadhaar.isNotEmpty && !RegExp(r'^\d{12}$').hasMatch(aadhaar)) {
        return 'Aadhaar must contain 12 digits';
      }
      if (pan.isNotEmpty && !RegExp(r'^[A-Z0-9]{10}$').hasMatch(pan)) {
        return 'PAN must contain 10 letters and digits';
      }
      if (gst.isNotEmpty && !RegExp(r'^[0-9A-Z]{15}$').hasMatch(gst)) {
        return 'GST must contain 15 letters and digits';
      }
    }
    if (step == 4) {
      final account = form['bank_account_number'].toString();
      final confirmation = form['bank_confirm_account'].toString();
      if (account.isNotEmpty && !RegExp(r'^\d{9,18}$').hasMatch(account)) {
        return 'Account number must contain 9 to 18 digits';
      }
      if (confirmation.isNotEmpty && confirmation != account) {
        return 'Account numbers do not match';
      }
      final ifsc = form['bank_ifsc'].toString().toUpperCase();
      if (ifsc.isNotEmpty &&
          !RegExp(r'^[A-Z]{4}0[A-Z0-9]{6}$').hasMatch(ifsc)) {
        return 'Enter a valid IFSC code';
      }
    }
    return null;
  }

  int _completion() => ((step / 5) * 100).round();
  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
