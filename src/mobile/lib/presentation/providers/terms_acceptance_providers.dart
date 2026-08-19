import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/shared_preferences_terms_acceptance_repository.dart';
import '../../domain/repositories/terms_acceptance_repository.dart';

final termsAcceptanceRepositoryProvider = Provider<TermsAcceptanceRepository>(
  (ref) => SharedPreferencesTermsAcceptanceRepository(),
);

class TermsAcceptanceNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() {
    return ref
        .watch(termsAcceptanceRepositoryProvider)
        .hasAcceptedCurrentVersion();
  }

  Future<void> accept() async {
    await ref.read(termsAcceptanceRepositoryProvider).acceptCurrentVersion();
    state = const AsyncData(true);
  }
}

final termsAcceptanceProvider =
    AsyncNotifierProvider<TermsAcceptanceNotifier, bool>(
      TermsAcceptanceNotifier.new,
    );
