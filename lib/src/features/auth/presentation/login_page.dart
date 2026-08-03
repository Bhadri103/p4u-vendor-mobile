import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:firebase_core/firebase_core.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/api_client.dart';
import '../../../core/theme/app_theme.dart';
import '../../../../firebase_options.dart';
import '../data/auth_repository.dart';

class VendorLoginPage extends ConsumerStatefulWidget {
  const VendorLoginPage({super.key});

  @override
  ConsumerState<VendorLoginPage> createState() => _VendorLoginPageState();
}

class _VendorLoginPageState extends ConsumerState<VendorLoginPage> {
  final _phone = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _otpSent = false;
  String? _verificationId;

  Future<void> _sendOtp() async {
    final digits = _phone.text.replaceAll(RegExp(r'\D'), '');
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(digits)) {
      _snack('Please enter a valid 10-digit phone number');
      return;
    }
    setState(() => _loading = true);
    // Match the web flow: avoid sending an OTP to an account that cannot log
    // in. The exchange endpoint remains the authoritative backstop.
    try {
      final account = await ApiClient().postJson(
        '/api/auth/public/vendor/phone-status',
        body: {'phone': '+91$digits'},
      );
      final status = account['status']?.toString().toLowerCase();
      if (status == 'not_registered') {
        if (mounted) {
          setState(() => _loading = false);
          _snack('No vendor account found. Please register first.');
          context.go('/register');
        }
        return;
      }
      if (status == 'pending') {
        if (mounted) setState(() => _loading = false);
        _snack('Your vendor application is still pending approval.');
        return;
      }
      if (status == 'rejected') {
        if (mounted) setState(() => _loading = false);
        _snack('Your vendor application was rejected. Please contact support.');
        return;
      }
    } catch (_) {
      // A transient pre-check failure should not block login; token exchange
      // performs the same account validation after Firebase verifies the OTP.
    }
    final firebaseReady = await _ensureFirebase();
    if (!firebaseReady) {
      if (mounted) setState(() => _loading = false);
      _snack(
        'Firebase is not ready. Check google-services.json and try again.',
      );
      return;
    }
    try {
      await firebase.FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91$digits',
        verificationCompleted: (credential) async {
          await _signInWithCredential(credential);
        },
        verificationFailed: (error) {
          if (mounted) {
            setState(() => _loading = false);
            _snack(_friendly(error));
          }
        },
        codeSent: (verificationId, _) {
          if (mounted) {
            setState(() {
              _verificationId = verificationId;
              _otpSent = true;
              _loading = false;
            });
          }
        },
        codeAutoRetrievalTimeout: (verificationId) =>
            _verificationId = verificationId,
      );
    } catch (e) {
      _snack('$e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _ensureFirebase() async {
    if (Firebase.apps.isNotEmpty) return true;
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 8));
      return Firebase.apps.isNotEmpty;
    } catch (e) {
      debugPrint('Firebase init failed before OTP: $e');
      return false;
    }
  }

  Future<void> _verifyOtp() async {
    if (_verificationId == null || _otp.text.length != 6) {
      _snack('Enter the 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    try {
      final credential = firebase.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _otp.text,
      );
      await _signInWithCredential(credential);
    } catch (e) {
      _snack(_friendly(e));
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithCredential(
      firebase.PhoneAuthCredential credential) async {
    final auth = firebase.FirebaseAuth.instance;
    try {
      final userCredential = await auth.signInWithCredential(credential);
      final token = await userCredential.user?.getIdToken(true);
      if (token == null) throw StateError('Missing Firebase ID token');
      await ref.read(authRepositoryProvider).signInWithFirebaseIdToken(token);
      ref.invalidate(authStateProvider);
      if (mounted) context.go('/');
    } catch (e) {
      _snack(_friendly(e));
    } finally {
      await auth.signOut().catchError((_) {});
      if (mounted) setState(() => _loading = false);
    }
  }

  String _friendly(Object e) {
    if (e is ApiException) return e.message;
    if (e is firebase.FirebaseAuthException) {
      if (e.code == 'invalid-verification-code') {
        return 'Incorrect OTP. Please try again.';
      }
      if (e.code == 'session-expired' || e.code == 'code-expired') {
        return 'OTP expired. Please request a new code.';
      }
      final message = e.message ?? '';
      if (e.code == 'app-not-authorized' ||
          message.toLowerCase().contains('missing a valid app identifier')) {
        return 'Phone verification is not authorized for this vendor APK yet. Please update the Firebase signing fingerprints for com.p4u.p4u_vendor and install the latest build.';
      }
      return message.isNotEmpty ? message : 'OTP failed. Please try again.';
    }
    return e.toString().replaceFirst('Exception: ', '');
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authStateProvider, (_, next) {
      if (next.valueOrNull != null && mounted) context.go('/');
    });
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF7FBFE), Colors.white, Color(0xFFE9F5FD)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 260,
                        width: double.infinity,
                        child: Stack(fit: StackFit.expand, children: [
                          Opacity(
                            opacity: .55,
                            child: Image.asset(
                              'assets/images/vendor/vendor-onboarding.png',
                              fit: BoxFit.cover,
                              alignment: Alignment.center,
                            ),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  const Color(0xFFE9F5FD)
                                      .withValues(alpha: .18),
                                  const Color(0xFFF9FCFE)
                                      .withValues(alpha: .98),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 52,
                                  height: 52,
                                  padding: const EdgeInsets.all(7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                  ),
                                  child: Image.asset(
                                    'assets/images/p4u-logo.png',
                                    fit: BoxFit.contain,
                                    semanticLabel: 'Planext4u',
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text('Your business, in motion.',
                                    style: TextStyle(
                                        color: AppColors.brandDark,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600)),
                                const SizedBox(height: 3),
                                const Text(
                                    'Products, bookings, orders and growth—one smart workspace.',
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 11)),
                              ],
                            ),
                          ),
                        ]),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
                        child: Column(
                          children: [
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Welcome back, partner',
                                      style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600)),
                                  SizedBox(height: 3),
                                  Text(
                                      'Sign in securely with your phone number',
                                      style: TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 11)),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Row(
                              children: [
                                Expanded(
                                    child: _LoginBenefit(
                                        icon: Icons.bolt_rounded,
                                        label: 'Fast orders')),
                                SizedBox(width: 7),
                                Expanded(
                                    child: _LoginBenefit(
                                        icon: Icons.payments_rounded,
                                        label: 'Easy payouts')),
                                SizedBox(width: 7),
                                Expanded(
                                    child: _LoginBenefit(
                                        icon: Icons.insights_rounded,
                                        label: 'Live insights')),
                              ],
                            ),
                            const SizedBox(height: 18),
                            if (!_otpSent) ...[
                              TextField(
                                controller: _phone,
                                keyboardType: TextInputType.phone,
                                maxLength: 10,
                                autofocus: true,
                                autofillHints: const [
                                  AutofillHints.telephoneNumber
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(10),
                                ],
                                onChanged: (_) => setState(() {}),
                                onSubmitted: (_) => _sendOtp(),
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.phone_rounded),
                                    prefixText: '+91 ',
                                    labelText: 'Registered phone number',
                                    hintText: '98765 43210',
                                    counterText: ''),
                              ),
                            ] else ...[
                              Row(children: [
                                Expanded(
                                  child: Text(
                                      'Verification code sent to +91 ${_phone.text}',
                                      style: const TextStyle(
                                          color: AppColors.muted,
                                          fontSize: 12)),
                                ),
                                TextButton(
                                  onPressed: _loading
                                      ? null
                                      : () => setState(() {
                                            _otpSent = false;
                                            _otp.clear();
                                            _verificationId = null;
                                          }),
                                  child: const Text('Edit'),
                                ),
                              ]),
                              const SizedBox(height: 10),
                              TextField(
                                controller: _otp,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                autofocus: true,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode
                                ],
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(6),
                                ],
                                onSubmitted: (_) => _verifyOtp(),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 8),
                                decoration: const InputDecoration(
                                    hintText: '000000', counterText: ''),
                              ),
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: _loading ? null : _sendOtp,
                                  icon: const Icon(Icons.refresh_rounded,
                                      size: 17),
                                  label: const Text('Resend OTP'),
                                ),
                              ),
                            ],
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              onPressed: _loading
                                  ? null
                                  : (_otpSent ? _verifyOtp : _sendOtp),
                              icon: _loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white))
                                  : Icon(_otpSent
                                      ? Icons.verified_user_rounded
                                      : Icons.arrow_forward_rounded),
                              label: Text(_loading
                                  ? 'Please wait...'
                                  : (_otpSent ? 'Verify OTP' : 'Send OTP')),
                              style: FilledButton.styleFrom(
                                  minimumSize: const Size.fromHeight(46)),
                            ),
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.accent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Expanded(
                                    child: Text('New to Planext4u Vendor?',
                                        style: TextStyle(
                                            color: AppColors.muted,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600)),
                                  ),
                                  TextButton(
                                    onPressed: () => context.go('/register'),
                                    child: const Text('Create account'),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.lock_outline_rounded,
                                    size: 15, color: AppColors.muted),
                                SizedBox(width: 6),
                                Text('Secure Firebase phone verification',
                                    style: TextStyle(
                                        color: AppColors.muted, fontSize: 11)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginBenefit extends StatelessWidget {
  const _LoginBenefit({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
        decoration: BoxDecoration(
          color: AppColors.accent,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.slate),
            const SizedBox(height: 4),
            FittedBox(
              child: Text(label,
                  style: const TextStyle(
                      color: AppColors.brandDark,
                      fontSize: 10,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );
}
