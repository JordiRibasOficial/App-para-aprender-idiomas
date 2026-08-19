import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app_para_aprender_idiomas/data/shared_preferences_terms_acceptance_repository.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/terms_acceptance_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('SharedPreferencesTermsAcceptanceRepository', () {
    test(
      'hasAcceptedCurrentVersion defaults to false when nothing was saved',
      () async {
        final repository = SharedPreferencesTermsAcceptanceRepository();

        final accepted = await repository.hasAcceptedCurrentVersion();

        expect(accepted, isFalse);
      },
    );

    test(
      'acceptCurrentVersion persists acceptance for the current version',
      () async {
        final repository = SharedPreferencesTermsAcceptanceRepository();

        await repository.acceptCurrentVersion();

        expect(await repository.hasAcceptedCurrentVersion(), isTrue);
      },
    );

    test(
      'a stale version stored under a future kCurrentTermsVersion bump requires re-acceptance',
      () async {
        SharedPreferences.setMockInitialValues({
          'terms_accepted_version': '2020-01-01',
        });
        final repository = SharedPreferencesTermsAcceptanceRepository();

        // kCurrentTermsVersion is '2026-08-19' today — a stored value from
        // a materially older terms revision must not count as accepted.
        expect(await repository.hasAcceptedCurrentVersion(), isFalse);
      },
    );
  });

  test(
    'kCurrentTermsVersion is set (guards against an empty/placeholder value)',
    () {
      expect(kCurrentTermsVersion, isNotEmpty);
    },
  );
}
