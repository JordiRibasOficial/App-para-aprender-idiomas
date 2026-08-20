import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/user_data_deletion_repository.dart';
import 'supabase_session.dart';

/// Thrown when the deletion can't be completed — network failure or a
/// non-2xx response. Same shape as [UserDataExportException].
class UserDataDeletionException implements Exception {
  const UserDataDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Same pattern as [SupabaseUserDataExportRepository]: calls the
/// `delete-user-data` Edge Function with the caller's own anonymous session
/// token, so the backend deletes exactly this caller's identity — never
/// anyone else's.
///
/// Signs out locally right after a successful call: the Edge Function just
/// deleted the Supabase Auth user backing this session's token, so it stops
/// being valid immediately. Signing out clears that stale token instead of
/// leaving it around to fail confusingly on the next call — the next
/// authenticated action transparently creates a fresh anonymous identity
/// via [ensureAnonymousSession].
class SupabaseUserDataDeletionRepository implements UserDataDeletionRepository {
  const SupabaseUserDataDeletionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<void> deleteUserData() async {
    final accessToken = await ensureAnonymousSession(_client);

    try {
      await _client.functions.invoke(
        'delete-user-data',
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } on FunctionException catch (e) {
      throw UserDataDeletionException(
        'delete-user-data respondió ${e.status}: ${e.details}',
      );
    }

    await _client.auth.signOut();
  }
}
