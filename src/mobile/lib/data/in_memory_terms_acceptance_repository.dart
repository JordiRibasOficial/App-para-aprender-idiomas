import '../domain/repositories/terms_acceptance_repository.dart';

/// Session-only [TermsAcceptanceRepository] used in tests and widget
/// previews — avoids needing a real SharedPreferences platform-channel
/// mock just to exercise the welcome screen's accept-and-continue flow.
class InMemoryTermsAcceptanceRepository implements TermsAcceptanceRepository {
  InMemoryTermsAcceptanceRepository({bool initiallyAccepted = false})
    : _accepted = initiallyAccepted;

  bool _accepted;

  @override
  Future<bool> hasAcceptedCurrentVersion() async => _accepted;

  @override
  Future<void> acceptCurrentVersion() async => _accepted = true;
}
