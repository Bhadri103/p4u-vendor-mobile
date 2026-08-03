import 'package:flutter_test/flutter_test.dart';
import 'package:p4u_vendor_app/src/core/services/api_client.dart';
import 'package:p4u_vendor_app/src/features/auth/data/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _AuthApi extends ApiClient {
  _AuthApi(this.exchange);

  final Map<String, dynamic> exchange;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, Object?> query = const {},
    Object? body,
    bool auth = false,
  }) async {
    if (path == '/api/auth/public/phone/exchange') return exchange;
    return const {};
  }

  @override
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, Object?> query = const {},
    bool auth = false,
  }) async =>
      const {
        'vendor': {
          'id': 'vendor-1',
          'businessName': 'Demo Store',
          'status': 'approved',
        },
      };
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('login persists tokens returned inside nested data and auth objects',
      () async {
    final repository = AuthRepository(
      api: _AuthApi(const {
        'loggedIn': true,
        'data': {
          'auth': {
            'accessToken': 'access-token',
            'refreshToken': 'refresh-token',
            'vendorId': 'vendor-1',
            'roles': ['VENDOR'],
          },
        },
      }),
    );

    final vendor = await repository.signInWithFirebaseIdToken('firebase-id');

    expect(vendor.id, 'vendor-1');
    expect(await apiSession.accessToken(), 'access-token');
    expect(await apiSession.refreshToken(), 'refresh-token');
  });

  test('login rejects a successful-looking response without session tokens',
      () async {
    final repository = AuthRepository(
      api: _AuthApi(const {
        'loggedIn': true,
        'data': {'vendorId': 'vendor-1'},
      }),
    );

    expect(
      () => repository.signInWithFirebaseIdToken('firebase-id'),
      throwsA(isA<ApiException>()),
    );
  });
}
