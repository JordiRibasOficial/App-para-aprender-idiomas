/// A target language offered on the onboarding language-selection screen.
class TargetLanguageOption {
  const TargetLanguageOption({
    required this.code,
    required this.displayName,
    required this.flagEmoji,
    this.requiresPremium = false,
  });

  /// Matches both `assets/content/courses/<code>.json` and the
  /// `targetLanguage` argument threaded through the content/progress layers.
  final String code;
  final String displayName;
  final String flagEmoji;

  /// Whether learning this language requires an active Premium entitlement.
  /// Checked once, at onboarding language selection — not re-verified on
  /// every lesson load, matching the rest of the paywall's current level of
  /// enforcement (see InAppPurchaseSubscriptionRepository's class doc).
  final bool requiresPremium;
}

/// The 4 launch languages (see Paso 3 of the plan). Order is display order.
/// English is free; the other 3 are the paywall's actual value proposition.
const kLaunchTargetLanguages = [
  TargetLanguageOption(code: 'en', displayName: 'Inglés', flagEmoji: '🇬🇧'),
  TargetLanguageOption(
    code: 'pt',
    displayName: 'Portugués',
    flagEmoji: '🇵🇹',
    requiresPremium: true,
  ),
  TargetLanguageOption(
    code: 'fr',
    displayName: 'Francés',
    flagEmoji: '🇫🇷',
    requiresPremium: true,
  ),
  TargetLanguageOption(
    code: 'ja',
    displayName: 'Japonés',
    flagEmoji: '🇯🇵',
    requiresPremium: true,
  ),
];

TargetLanguageOption targetLanguageOption(String code) {
  return kLaunchTargetLanguages.firstWhere((l) => l.code == code);
}

String targetLanguageDisplayName(String code) {
  return kLaunchTargetLanguages.firstWhere((l) => l.code == code).displayName;
}
