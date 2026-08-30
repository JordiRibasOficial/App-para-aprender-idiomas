import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/account_providers.dart';
import 'email_sign_up_dialog.dart';

/// Blocks on having a real account before letting the caller proceed with
/// something that needs one (purchase, restore, "Mis datos") — purchase/
/// premium/data-export/deletion all require an account server-side now
/// (see requireAccountAccessToken), so this gates *before* attempting the
/// operation rather than letting it fail after the fact (critically, before
/// a real store purchase is even attempted — failing only at the
/// verification step would mean charging the user for nothing).
///
/// Returns true once a real account exists and is immediately usable
/// (either it already existed, or sign-up just returned a live session).
/// Returns false if the user cancels, or if sign-up succeeded but requires
/// email confirmation first — that account isn't usable yet, so whatever
/// needed it still can't proceed this run.
Future<bool> requireAccount(BuildContext context, WidgetRef ref) async {
  // Synchronous read through the Riverpod provider (overridable in tests)
  // rather than Supabase.instance directly. Relies on every screen that
  // calls this (PaywallScreen, DataExportScreen) already `ref.watch`-ing
  // accountSessionProvider somewhere in its own build() — that keeps the
  // provider actively subscribed well before a user can tap anything here,
  // so by the time this runs it already reflects the real current session,
  // not a transient "just started listening" loading state.
  final account = ref.read(accountSessionProvider).value;
  if (account != null) return true;

  final wantsToCreateAccount = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Necesitas una cuenta'),
      content: const Text(
        'Para esto necesitas una cuenta — así no pierdes tu compra ni tus '
        'datos si cambias de dispositivo.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Crear cuenta'),
        ),
      ],
    ),
  );
  if (wantsToCreateAccount != true) return false;
  if (!context.mounted) return false;

  final result = await showDialog<EmailSignUpDialogResult>(
    context: context,
    builder: (dialogContext) => const EmailSignUpDialog(),
  );
  if (result == null) return false;

  if (result.confirmationEmail != null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Te hemos enviado un email de confirmación a '
            '${result.confirmationEmail}. Confírmalo y vuelve a intentarlo.',
          ),
          duration: const Duration(seconds: 6),
        ),
      );
    }
    // The account exists but has no live session yet — nothing that needs
    // one can proceed this run.
    return false;
  }

  return true;
}
