import 'package:app_para_aprender_idiomas/data/secure_supabase_local_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeKeyValueSecureStore implements KeyValueSecureStore {
  final _values = <String, String>{};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

void main() {
  late _FakeKeyValueSecureStore store;
  late SecureSupabaseLocalStorage storage;

  setUp(() {
    store = _FakeKeyValueSecureStore();
    storage = SecureSupabaseLocalStorage(store: store);
  });

  test('hasAccessToken is false before any session is persisted', () async {
    expect(await storage.hasAccessToken(), isFalse);
  });

  test('persistSession makes hasAccessToken true and roundtrips accessToken', () async {
    await storage.persistSession('{"access_token":"abc"}');

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), '{"access_token":"abc"}');
  });

  test('removePersistedSession clears the stored session', () async {
    await storage.persistSession('{"access_token":"abc"}');
    await storage.removePersistedSession();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('persistSession overwrites a previously persisted session', () async {
    await storage.persistSession('{"access_token":"old"}');
    await storage.persistSession('{"access_token":"new"}');

    expect(await storage.accessToken(), '{"access_token":"new"}');
  });

  test('writes go through the injected store under a stable key', () async {
    await storage.persistSession('{"access_token":"abc"}');

    expect(await store.read('sb-session'), '{"access_token":"abc"}');
  });
}
