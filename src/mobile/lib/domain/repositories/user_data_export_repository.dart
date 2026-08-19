/// RGPD art. 15/20 (right of access / data portability): fetches everything
/// the backend holds about the caller's own anonymous session identity —
/// see the `export-user-data` Edge Function.
abstract interface class UserDataExportRepository {
  Future<Map<String, dynamic>> exportUserData();
}
