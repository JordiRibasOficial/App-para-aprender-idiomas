import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/onboarding_state.dart';
import '../providers/onboarding_providers.dart';
import '../theme/app_theme.dart';

/// Deliberately simple — this only screens for obviously-malformed input
/// (no "@", no domain), not full RFC 5322 validation. Nothing downstream
/// depends on the address being deliverable yet (see the screen's own
/// disclaimer text: no real account exists today).
final _emailFormat = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

class AuthChoiceScreen extends ConsumerStatefulWidget {
  const AuthChoiceScreen({super.key});

  @override
  ConsumerState<AuthChoiceScreen> createState() => _AuthChoiceScreenState();
}

class _AuthChoiceScreenState extends ConsumerState<AuthChoiceScreen> {
  bool _completing = false;

  Future<void> _complete(AuthMode authMode, {String? email}) async {
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

  Future<void> _showEmailDialog() async {
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => const _EmailDialog(),
    );

    if (email != null) {
      await _complete(AuthMode.email, email: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Guarda tu progreso')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
              'Tu progreso se guarda en este dispositivo. Aún no hay cuentas '
              'reales — cuando las añadamos podrás sincronizarlo entre '
              'dispositivos.',
              textAlign: TextAlign.center,
              style: textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceXl),
            FilledButton(
              onPressed: _completing ? null : _showEmailDialog,
              child: const Text('Continuar con email'),
            ),
            const SizedBox(height: AppTheme.spaceSm),
            OutlinedButton(
              onPressed: _completing ? null : () => _complete(AuthMode.guest),
              child: const Text('Continuar como invitado'),
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

class _EmailDialog extends StatefulWidget {
  const _EmailDialog();

  @override
  State<_EmailDialog> createState() => _EmailDialogState();
}

class _EmailDialogState extends State<_EmailDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final email = _controller.text.trim();
    if (!_emailFormat.hasMatch(email)) {
      setState(() => _error = 'Escribe un email válido, p. ej. tu@email.com');
      return;
    }
    Navigator.of(context).pop(email);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      title: const Text('Tu email'),
      content: TextField(
        controller: _controller,
        keyboardType: TextInputType.emailAddress,
        autofocus: true,
        decoration: InputDecoration(
          hintText: 'tu@email.com',
          errorText: _error,
        ),
        onChanged: (_) {
          if (_error != null) setState(() => _error = null);
        },
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continuar')),
      ],
    );
  }
}
