import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/supabase_user_data_export_repository.dart';
import '../../domain/repositories/user_data_export_repository.dart';

/// Built lazily inside the provider body (not a top-level constant), same
/// reasoning as SupabaseContentRepository's premium fetcher: this must
/// never touch Supabase.instance.client before Supabase.initialize() has
/// run. Safe here because this provider is only read from
/// DataExportScreen, which no host-only widget test reaches without first
/// overriding it.
final userDataExportRepositoryProvider = Provider<UserDataExportRepository>((
  ref,
) {
  return SupabaseUserDataExportRepository(Supabase.instance.client);
});
