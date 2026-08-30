import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_account_repository.dart';
import '../../data/supabase_marketing_consent_repository.dart';
import '../../domain/models/account_session.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/marketing_consent_repository.dart';

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return SupabaseAccountRepository(Supabase.instance.client);
});

final marketingConsentRepositoryProvider = Provider<MarketingConsentRepository>(
  (ref) {
    return SupabaseMarketingConsentRepository(Supabase.instance.client);
  },
);

AccountSession? _toAccountSession(Session? session) {
  final user = session?.user;
  if (user == null || user.isAnonymous) return null;
  return AccountSession(userId: user.id, email: user.email);
}

/// The current real account, or null for a guest — null both before any
/// sign-up/sign-in and after [SupabaseUserDataDeletionRepository] deletes
/// the account. Emits the current value immediately on first listen (not
/// just future changes), so a widget can `ref.watch` this directly to
/// decide what to render without a separate synchronous check first.
final accountSessionProvider = StreamProvider<AccountSession?>((ref) async* {
  final auth = Supabase.instance.client.auth;
  yield _toAccountSession(auth.currentSession);
  yield* auth.onAuthStateChange.map((data) => _toAccountSession(data.session));
});
