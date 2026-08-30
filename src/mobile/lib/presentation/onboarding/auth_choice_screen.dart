import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/onboarding_state.dart';
import '../account/email_sign_up_dialog.dart';
import '../providers/onboarding_providers.dart';
import '../theme/app_theme.dart';

class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen> {
  bool _completing = false;

  Future<void> _completeOnboarding({
    required AuthMode authMode,
    String? email,
  }) async {
    setState(() => _completing = true);
    final level = ref.read(onboardingSelectedLevelProvider);
    final targetLanguage = ref.read(onboardingSelectedLanguageProvider);
    await ref
        .read(onboardingProvider.notifier)
        .complete(
          level: level,
          targetLanguage: targetLanguage,
          authMode: authMode,
          email: email,
        );
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _continueAsGuest() =>
      _completeOnboarding(authMode: AuthMode.guest);

  Future<void> _showEmailSignUpDialog() async {
    final result = await showDialog<EmailSignUpDialogResult>(
      context: context,
      builder: (dialogContext) => const EmailSignUpDialog(),
    );
    if (result == null) return;

    if (result.confirmationEmail != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Te hemos enviado un email de confirmación a '
            '${result.confirmationEmail}. Mientras tanto, ya puedes usar '
            'la app.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }

    await _completeOnboarding(authMode: AuthMode.account, email: result.email);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Guarda tu progreso')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primaryContainer,
                ),
                child: Icon(
                  Icons.verified_user_outlined,
                  size: 32,
                  color: scheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              '¿Cómo quieres continuar?',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            Text(
              'Crea una cuenta para guardar tu progreso y sincronizarlo '
              'entre dispositivos, o sigue sin cuenta por ahora.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            FilledButton(
              onPressed: _completing ? null : _showEmailSignUpDialog,
              child: const Text('Registrarse con email'),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            OutlinedButton(
              onPressed: _completing ? null : _continueAsGuest,
              child: const Text('Continuar como invitado'),
            ),
            const SizedBox(height: AppTheme.spaceMd),
            Text(
              'Próximamente: Google, Apple y Facebook.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            if (_completing)
              Padding(
                padding: const EdgeInsets.only(top: AppTheme.spaceLg),
                child: Center(
                  child: CircularProgressIndicator(color: scheme.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
