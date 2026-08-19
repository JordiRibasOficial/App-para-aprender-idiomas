import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/terms_acceptance_repository.dart';

class SharedPreferencesTermsAcceptanceRepository
    implements TermsAcceptanceRepository {
  static const _key = 'terms_accepted_version';

  @override
  Future<bool> hasAcceptedCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key) == kCurrentTermsVersion;
  }

  @override
  Future<void> acceptCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, kCurrentTermsVersion);
  }
}
