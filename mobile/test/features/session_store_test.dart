import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rentra/features/auth/data/session_store.dart';
import 'package:rentra/features/auth/models/app_user.dart';
import 'package:rentra/features/auth/models/session.dart';
import 'package:rentra/features/landlord/models/organization.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SecureSessionStore store;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    store = SecureSessionStore(const FlutterSecureStorage());
  });

  const user = AppUser(
    id: 'u1',
    role: UserRole.landlord,
    firstName: 'Wanjiru',
    lastName: 'Kamau',
    email: 'w@example.com',
    organizationId: 'org1',
  );
  const org = Organization(id: 'org1', name: "Wanjiru's Organization", ownerId: 'u1');

  test('returns null when nothing is saved', () async {
    expect(await store.read(), isNull);
  });

  test('round-trips token, user and organization', () async {
    await store.save(const Session(token: 't-123', user: user, organization: org));
    final restored = await store.read();
    expect(restored, isNotNull);
    expect(restored!.token, 't-123');
    expect(restored.user.id, 'u1');
    expect(restored.user.role, UserRole.landlord);
    expect(restored.user.fullName, 'Wanjiru Kamau');
    expect(restored.user.organizationId, 'org1');
    expect(restored.organization!.name, "Wanjiru's Organization");
  });

  test('saving without an organization removes a previous one', () async {
    await store.save(const Session(token: 't1', user: user, organization: org));
    await store.save(const Session(token: 't2', user: user));
    final restored = await store.read();
    expect(restored!.token, 't2');
    expect(restored.organization, isNull);
  });

  test('clear removes everything', () async {
    await store.save(const Session(token: 't', user: user, organization: org));
    await store.clear();
    expect(await store.read(), isNull);
  });

  test('corrupted data is discarded instead of crashing', () async {
    FlutterSecureStorage.setMockInitialValues({
      SecureSessionStore.tokenKey: 't',
      SecureSessionStore.userKey: '{not json',
    });
    store = SecureSessionStore(const FlutterSecureStorage());
    expect(await store.read(), isNull);
    expect(
      await const FlutterSecureStorage().read(key: SecureSessionStore.tokenKey),
      isNull,
    );
  });

  test('session description never includes the token', () {
    const session = Session(token: 'secret-token', user: user);
    expect(session.toString(), isNot(contains('secret-token')));
  });
}
