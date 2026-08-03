import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/async_value_ui.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/vendor_page_intro.dart';
import '../../../../core/widgets/vendor_scaffold.dart';
import '../../data/vendor_providers.dart';

class VendorKycPage extends ConsumerStatefulWidget {
  const VendorKycPage({super.key});
  @override
  ConsumerState<VendorKycPage> createState() => _VendorKycPageState();
}

class _VendorKycPageState extends ConsumerState<VendorKycPage> {
  bool _busy = false;
  Map<String, dynamic> _documents(Object? raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final value = jsonDecode(raw);
        if (value is Map) return Map<String, dynamic>.from(value);
      } catch (_) {}
    }
    return {};
  }

  Future<void> _upload(String urlKey, String fileNameKey) async {
    final vendorId = ref.read(vendorIdProvider);
    if (vendorId == null) return;
    final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'pdf']);
    final path = result?.files.single.path;
    if (path == null) return;
    setState(() => _busy = true);
    try {
      final profile =
          await ref.read(vendorRepositoryProvider).profile(vendorId);
      final documents =
          _documents(profile['documentsJson'] ?? profile['documents_json']);
      final ext = path.split('.').last.toLowerCase();
      final url = await ref.read(vendorRepositoryProvider).uploadVendorAsset(
          vendorId,
          File(path),
          'vendor-kyc',
          result!.files.single.name,
          ext == 'pdf' ? 'application/pdf' : 'image/$ext');
      documents[urlKey] = url;
      documents[fileNameKey] = result.files.single.name;
      documents['${urlKey}UploadedAt'] =
          DateTime.now().toUtc().toIso8601String();
      await ref
          .read(vendorRepositoryProvider)
          .updateProfile(vendorId, {'documentsJson': documents});
      ref.invalidate(vendorProfileProvider);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('KYC document saved')));
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(vendorProfileProvider);
    return VendorScaffold(
        title: 'KYC & Verification',
        child: profile.whenUi(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (vendor) {
              final docs = _documents(
                  vendor['documentsJson'] ?? vendor['documents_json']);
              final status =
                  (vendor['kycStatus'] ?? vendor['kyc_status'] ?? 'not_started')
                      .toString()
                      .toLowerCase();
              const fields = <(String, String, String, List<String>, IconData)>[
                (
                  'gstCertificateUrl',
                  'gstCertificateFileName',
                  'GST certificate',
                  ['gstCertificate'],
                  Icons.receipt_long_rounded
                ),
                (
                  'panCardUrl',
                  'panCardFileName',
                  'PAN card',
                  ['panImage'],
                  Icons.badge_rounded
                ),
                (
                  'aadhaarCardUrl',
                  'aadhaarCardFileName',
                  'Aadhaar card',
                  ['aadhaarFront'],
                  Icons.credit_card_rounded
                ),
                (
                  'aadhaarBackUrl',
                  'aadhaarBackFileName',
                  'Aadhaar back',
                  ['aadhaarBack'],
                  Icons.credit_card_rounded
                ),
              ];
              return ListView(
                  padding: VendorLayout.pagePadding(context),
                  children: [
                    const VendorPageIntro(
                      icon: Icons.verified_user_rounded,
                      title: 'Business verification',
                      subtitle:
                          'Build customer trust with clear, secure and up-to-date business documents.',
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                        child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                                status == 'verified' || status == 'approved'
                                    ? Icons.verified_rounded
                                    : Icons.pending_actions_rounded,
                                color:
                                    status == 'verified' || status == 'approved'
                                        ? AppColors.primary
                                        : Colors.orange),
                            title: Text(
                                'Verification: ${status.replaceAll('_', ' ').toUpperCase()}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                                'Upload clear JPG, PNG or PDF files. Admin approval controls your verification status.'))),
                    const SizedBox(height: 12),
                    ...fields.map((field) {
                      final candidates = [field.$1, ...field.$4];
                      final value = candidates
                          .map((key) => docs[key]?.toString().trim() ?? '')
                          .firstWhere((item) => item.isNotEmpty,
                              orElse: () => '');
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: AppCard(
                              child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(field.$5),
                                  title: Text(field.$3,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: Text(value.isEmpty
                                      ? 'Not uploaded'
                                      : 'Uploaded'),
                                  trailing: OutlinedButton(
                                      onPressed: _busy
                                          ? null
                                          : () => _upload(field.$1, field.$2),
                                      child: Text(value.isEmpty
                                          ? 'Upload'
                                          : 'Replace')))));
                    }),
                    if (_busy) const LinearProgressIndicator(),
                  ]);
            }));
  }
}
