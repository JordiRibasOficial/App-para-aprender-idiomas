import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_user_data_deletion_repository.dart';
import '../../domain/repositories/user_data_deletion_repository.dart';

/// Built lazily inside the provider body, same reasoning as
/// userDataExportRepositoryProvider: this must never touch
/// Supabase.instance.client before Supabase.initialize() has run. Safe here
/// because this provider is only read from DataExportScreen.
final userDataDeletionRepositoryProvider = Provider<UserDataDeletionRepository>((
  ref,
) {
  return SupabaseUserDataDeletionRepository(Supabase.instance.client);
});
