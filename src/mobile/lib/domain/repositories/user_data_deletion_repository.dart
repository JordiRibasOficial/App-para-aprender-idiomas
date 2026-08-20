/// RGPD art. 17 (right to erasure): permanently deletes everything the
/// backend holds about the caller's own anonymous session identity — see
/// the `delete-user-data` Edge Function.
abstract interface class UserDataDeletionRepository {
  Future<void> deleteUserData();
}
