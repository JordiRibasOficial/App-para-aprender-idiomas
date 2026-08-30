import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_account_repository.dart';
import '../../data/supabase_marketing_consent_repository.dart';
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
