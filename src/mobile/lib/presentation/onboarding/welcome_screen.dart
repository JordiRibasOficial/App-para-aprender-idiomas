import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../legal_urls.dart';
import '../providers/terms_acceptance_providers.dart';
import '../theme/app_theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  // Local, not read from termsAcceptanceProvider: this screen only shows
  // when onboarding hasn't completed yet (see RootScreen), so there's
  // nothing meaningful to pre-check even on a re-visit within the same
  // onboarding pass.
  bool _accepted = false;
  // Separate from _accepted on purpose: this is a factual declaration
  // ("I am at least this old"), not agreement to a contract — kept as its
  // own checkbox so it stands as distinct evidence of that specific fact,
  // not blended into contract acceptance. See terms-of-service-draft.md
  // § 10 for why 16, not the app's actual jurisdiction-by-jurisdiction
  // minimum (LOPDGDD sets 14 in Spain, UK GDPR sets 13): one number above
  // every relevant threshold avoids per-country logic this app has no way
  // to apply anyway, since age here is self-declared, not verified.
  bool _ageConfirmed = false;

  Future<void> _start() async {
    await ref.read(termsAcceptanceProvider.notifier).accept();
    if (!mounted) return;
    context.push('/onboarding/language');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spaceLg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Solid scheme.primary, not a primary→tertiary gradient:
                    // the tertiary (accent orange) corner only gave ~2.8:1
                    // contrast against the white text, below the WCAG AA
                    // 3:1 minimum for large/bold text. scheme.primary alone
                    // measures ~5.2:1, comfortably passing.
                    color: scheme.primary,
                  ),
                  child: const Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          '¡Hola!',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              Text(
                'App para Aprender Idiomas',
                textAlign: TextAlign.center,
                style: textTheme.headlineLarge,
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                'Aprende inglés y otros idiomas con lecciones breves cada día.',
                textAlign: TextAlign.center,
                style: textTheme.bodyLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppTheme.spaceXl),
              // Explicit clickwrap acceptance, not just implied-by-use: a
              // checkbox the user must tick themselves, not pre-checked —
              // stronger evidence of consent than the terms' own "al usar
              // la app, aceptas" fallback language if it's ever disputed.
              CheckboxListTile(
                value: _accepted,
                onChanged: (value) =>
                    setState(() => _accepted = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('He leído y acepto los '),
                    _InlineLinkButton(label: 'Términos', url: kTermsUrl),
                    const Text(' y la '),
                    _InlineLinkButton(
                      label: 'Política de Privacidad',
                      url: kPrivacyUrl,
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: _ageConfirmed,
                onChanged: (value) =>
                    setState(() => _ageConfirmed = value ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                title: const Text('Confirmo que tengo 16 años o más.'),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              FilledButton(
                onPressed: (_accepted && _ageConfirmed) ? _start : null,
                child: const Text('Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// TextButton, not a bare InkWell/GestureDetector: gets correct button
/// semantics and the platform's tap-target handling for free, same as the
/// paywall's own links to these same URLs. Shrink-wrapped because these
/// sit inline inside a sentence — WCAG 2.5.8 explicitly exempts inline
/// text links from the 24x24 CSS px minimum target size that applies to
/// standalone controls.
class _InlineLinkButton extends StatelessWidget {
  const _InlineLinkButton({required this.label, required this.url});

  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () => launchUrl(Uri.parse(url)),
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }
}
