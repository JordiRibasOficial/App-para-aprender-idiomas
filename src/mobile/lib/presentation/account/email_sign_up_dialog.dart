import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/sign_up_result.dart';
import '../providers/account_providers.dart';
import '../theme/app_theme.dart';

/// Deliberately simple — this only screens for obviously-malformed input
/// (no "@", no domain), not full RFC 5322 validation. The real validation
/// happens server-side when the account is actually created.
final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Result of a successful [EmailSignUpDialog] submission. Shared by every
/// call site that needs to create a real account — onboarding
/// (AuthChoiceScreen) and the account-required gate ([requireAccount]) both
/// show this same dialog rather than duplicating the form/validation logic.
class EmailSignUpDialogResult {
  const EmailSignUpDialogResult({required this.email, this.confirmationEmail});

  final String email;

  /// Non-null when Supabase requires email confirmation before the account
  /// is usable — see [SignUpResult.ConfirmationRequired].
  final String? confirmationEmail;
}

class EmailSignUpDialog extends ConsumerStatefulWidget {
  const EmailSignUpDialog({super.key});

  @override
  ConsumerState<EmailSignUpDialog> createState() => _EmailSignUpDialogState();
}

class _EmailSignUpDialogState extends ConsumerState<EmailSignUpDialog> {
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
      SignedIn() => EmailSignUpDialogResult(email: email),
      ConfirmationRequired() => EmailSignUpDialogResult(
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
