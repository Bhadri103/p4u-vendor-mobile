import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/core/services/api_client.dart';
import 'package:p4u_vendor_app/src/features/vendor/data/vendor_repository.dart';

class _EmailStatusApi extends ApiClient {
  _EmailStatusApi(this.response, {this.error});

  final Map<String, dynamic> response;
  final Object? error;
  String? lastPath;
  Object? lastBody;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool auth = false,
  }) async {
    if (error != null) throw error!;
    lastPath = path;
    lastBody = body;
    return response;
  }
}

void main() {
  test('registration continues when optional email pre-check is unavailable',
      () async {
    final repository = VendorRepository(
      api: _EmailStatusApi(const {},
          error: const ApiException('Not found', statusCode: 404)),
    );

    expect(
        await repository.checkVendorEmailUnique('vendor@example.com'), isNull);
  });

  test('registration reports an email already used when pre-check responds',
      () async {
    final repository =
        VendorRepository(api: _EmailStatusApi(const {'available': false}));

    expect(
      await repository.checkVendorEmailUnique('vendor@example.com'),
      contains('already linked'),
    );
  });

  test('mobile registration submits the canonical web payload fields',
      () async {
    final api = _EmailStatusApi(const {});
    final repository = VendorRepository(api: api);

    await repository.submitVendorApplication({
      'name': 'Selva Kumar',
      'business_name': 'Selva Stores',
      'business_type': 'proprietorship',
      'email': 'selva@example.com',
      'phone': '9876543210',
      'secondary_phone': '9123456789',
      'category': 'product',
      'product_category': 'groceries',
      'service_name': '',
      'gst_number': '22AAAAA0000A1Z5',
      'pan_number': 'AAAAA0000A',
      'aadhaar_number': '123456789012',
      'aadhaar_front_url': 'aadhaar-front.png',
      'aadhaar_back_url': 'aadhaar-back.png',
      'state': 'Tamil Nadu',
      'district': 'Kanniyakumari',
      'shop_address': 'Kanniyakumari',
      'gst_certificate_url': 'gst.pdf',
      'pan_image_url': 'pan.png',
      'bank_name': 'Example Bank',
      'bank_ifsc': 'ABCD0123456',
      'bank_holder_name': 'Selva Kumar',
      'bank_account_number': '123456789',
    });

    expect(api.lastPath, '/api/auth/public/vendor/register');
    final payload = Map<String, dynamic>.from(api.lastBody! as Map);
    expect(payload['ownerName'], 'Selva Kumar');
    expect(payload['businessName'], 'Selva Stores');
    expect(payload['businessType'], 'proprietorship');
    expect(payload['phone'], '+919876543210');
    expect(payload['secondaryPhone'], '+919123456789');
    expect(payload['categoriesJson'], ['groceries']);
    expect(payload['addressJson'], {
      'state': 'Tamil Nadu',
      'stateName': 'Tamil Nadu',
      'district': 'Kanniyakumari',
      'areaLocality': 'Kanniyakumari',
      'address': 'Kanniyakumari',
    });
    expect(payload['documentsJson'], {
      'aadhaarNumber': '123456789012',
      'aadhaarFrontFileName': 'aadhaar-front.png',
      'aadhaarBackFileName': 'aadhaar-back.png',
      'gstCertificateFileName': 'gst.pdf',
      'panCardFileName': 'pan.png',
    });
    final bank = Map<String, dynamic>.from(payload['bankJson'] as Map);
    final account =
        Map<String, dynamic>.from((bank['accounts'] as List).single as Map);
    expect(account['bankName'], 'Example Bank');
    expect(account['ifscCode'], 'ABCD0123456');
    expect(account['accountHolderName'], 'Selva Kumar');
    expect(account['accountNumber'], '123456789');
  });
}
