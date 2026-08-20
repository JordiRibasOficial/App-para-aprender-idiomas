import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Reads/writes a single opaque string value. Split out from
/// [SecureSupabaseLocalStorage] so tests can inject an in-memory fake
/// instead of exercising the real secure-storage platform channel — same
/// seam as [SecureEmailStore] in shared_preferences_onboarding_repository.dart.
abstract interface class KeyValueSecureStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class _FlutterKeyValueSecureStore implements KeyValueSecureStore {
  const _FlutterKeyValueSecureStore();

  // iOS default (KeychainAccessibility.unlocked) lets this item ride along
  // in an encrypted iCloud/iTunes backup and come back on a *different*
  // physical device — fine for most Keychain items, wrong for a standing
  // credential like a refresh token. `unlocked_this_device` still requires
  // the device to be unlocked to read it, but ties the item to this device,
  // so a restored backup on another device can't resume the session.
  // Android's EncryptedSharedPreferences doesn't need the same treatment:
  // its key lives in the hardware-backed Android Keystore, which never
  // migrates with a backup, so a restored file is unreadable regardless.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Persists the Supabase session (access + refresh token) via
/// `flutter_secure_storage` — Keychain on iOS, EncryptedSharedPreferences on
/// Android — instead of the package default of plaintext `SharedPreferences`.
/// A refresh token is a standing credential (it grants a new session without
/// re-authenticating), so it gets the same protection this app already gives
/// the onboarding email: never sitting in a plaintext prefs file on disk.
class SecureSupabaseLocalStorage extends LocalStorage {
  SecureSupabaseLocalStorage({KeyValueSecureStore? store})
    : _store = store ?? const _FlutterKeyValueSecureStore();

  static const _key = 'sb-session';

  final KeyValueSecureStore _store;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await _store.read(_key) != null;

  @override
  Future<String?> accessToken() => _store.read(_key);

  @override
  Future<void> removePersistedSession() => _store.delete(_key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _store.write(_key, persistSessionString);
}
