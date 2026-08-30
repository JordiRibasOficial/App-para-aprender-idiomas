import 'package:supabase_flutter/supabase_flutter.dart';

import '../domain/repositories/user_data_export_repository.dart';
import 'supabase_session.dart';

/// Thrown when the export can't be fetched — network failure, a non-2xx
/// response, or a malformed body. Same shape as [CourseContentException] in
/// supabase_content_repository.dart.
class UserDataExportException implements Exception {
  const UserDataExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Same pattern as [SupabasePremiumCourseFetcher]: calls the
/// `export-user-data` Edge Function with the caller's own account session
/// token, so the backend can scope the query to exactly this caller (see
/// the function's own doc comment for why there's no input — there is
/// nothing to specify, the caller only ever gets their own data). Requires
/// a real account — see [requireAccountAccessToken].
class SupabaseUserDataExportRepository implements UserDataExportRepository {
  const SupabaseUserDataExportRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<Map<String, dynamic>> exportUserData() async {
    final accessToken = await requireAccountAccessToken(_client);

    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'export-user-data',
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    } on FunctionException catch (e) {
      throw UserDataExportException(
        'export-user-data respondió ${e.status}: ${e.details}',
      );
    }

    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const UserDataExportException(
        'export-user-data devolvió una respuesta con formato inesperado.',
      );
    }
    return data;
  }
}
