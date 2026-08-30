import '../domain/repositories/marketing_consent_repository.dart';

/// Session-only [MarketingConsentRepository] used in tests and widget
/// previews.
class InMemoryMarketingConsentRepository implements MarketingConsentRepository {
  final optInCalls = <String>[];

  @override
  Future<void> optIn({required String email}) async {
    optInCalls.add(email);
  }
}
