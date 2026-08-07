import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether banner ads should actually be requested from AdMob.
///
/// Defaults to false everywhere — production included — because the ads
/// SDK needs a real platform channel that host-side widget tests (test/)
/// don't have. `main()` is the one place that overrides this to true.
/// integration_test/ deliberately does not override it either: that suite
/// boots [MyApp] directly (not through `main()`) and stays decoupled from
/// this feature for now, so a flaky ad-network call never threatens the
/// device/emulator test it took real work to get green.
final adsEnabledProvider = Provider<bool>((ref) => false);
