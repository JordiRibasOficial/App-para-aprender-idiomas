import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/onboarding_state.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/sign_up_result.dart';
import '../providers/account_providers.dart';
import '../providers/onboarding_providers.dart';
import '../theme/app_theme.dart';

/// Deliberately simple — this only screens for obviously-malformed input
/// (no "@", no domain), not full RFC 5322 validation. The real validation
/// happens server-side when the account is actually created.
final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

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
    final result = await showDialog<_EmailSignUpDialogResult>(
      context: context,
      builder: (dialogContext) => const _EmailSignUpDialog(),
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

class _EmailSignUpDialogResult {
  const _EmailSignUpDialogResult({required this.email, this.confirmationEmail});

  final String email;

  /// Non-null when Supabase requires email confirmation before the account
  /// is usable — see [SignUpResult.ConfirmationRequired].
  final String? confirmationEmail;
}

class _EmailSignUpDialog extends ConsumerStatefulWidget {
  const _EmailSignUpDialog();

  @override
  ConsumerState<_EmailSignUpDialog> createState() => _EmailSignUpDialogState();
}

class _EmailSignUpDialogState extends ConsumerState<_EmailSignUpDialog> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _marketingOptIn = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _emailController.text.trim();
    if (!_emailFormat.hasMatch(email)) {
      setState(() => _error = 'Escribe un email válido, p. ej. tu@email.com');
      return;
    }
    final password = _passwordController.text;
    if (password.length < 8) {
      setState(
        () => _error = 'La contraseña debe tener al menos 8 caracteres.',
      );
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });

    final AccountRepository repository = ref.read(accountRepositoryProvider);
    final SignUpResult result;
    try {
      result = await repository.signUpWithEmail(
        email: email,
        password: password,
      );
    } on AccountException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _submitting = false;
      });
      return;
    }

    if (_marketingOptIn) {
      // Fire-and-forget: best-effort by design (see
      // MarketingConsentRepository's doc comment) — never blocks or fails
      // account creation, which has already succeeded by this point.
      unawaited(
        ref.read(marketingConsentRepositoryProvider).optIn(email: email),
      );
    }

    if (!mounted) return;
    Navigator.of(context).pop(switch (result) {
      SignedIn() => _EmailSignUpDialogResult(email: email),
      ConfirmationRequired() => _EmailSignUpDialogResult(
        email: email,
        confirmationEmail: email,
      ),
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      title: const Text('Crea tu cuenta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              enabled: !_submitting,
              decoration: const InputDecoration(hintText: 'tu@email.com'),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
            ),
            const SizedBox(height: AppTheme.spaceSm),
            TextField(
              controller: _passwordController,
              obscureText: true,
              enabled: !_submitting,
              decoration: const InputDecoration(hintText: 'Contraseña'),
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.spaceSm),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            const SizedBox(height: AppTheme.spaceSm),
            // Separate, unticked opt-in — never bundled with account
            // creation itself. See MarketingConsentRepository's doc comment
            // for why this needs to be its own explicit consent.
            CheckboxListTile(
              value: _marketingOptIn,
              onChanged: _submitting
                  ? null
                  : (value) => setState(() => _marketingOptIn = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Quiero recibir ofertas, promociones y novedades por email.',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _submitting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submitting ? null : _submit,
          child: _submitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Crear cuenta'),
        ),
      ],
    );
  }
}
