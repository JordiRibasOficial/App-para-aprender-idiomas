import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/onboarding_state.dart';
import '../providers/onboarding_providers.dart';

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
    await ref.read(onboardingProvider.notifier).complete(
          level: level,
          targetLanguage: targetLanguage,
          authMode: authMode,
          email: email,
        );
    if (!mounted) return;
    context.go('/');
  }

  Future<void> _showEmailDialog() async {
    final controller = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Tu email'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(hintText: 'tu@email.com'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (email != null && email.isNotEmpty) {
      await _complete(AuthMode.email, email: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guarda tu progreso')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '¿Cómo quieres continuar?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tu progreso se guarda en este dispositivo. Aún no hay cuentas '
              'reales — cuando las añadamos podrás sincronizarlo entre '
              'dispositivos.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _completing ? null : _showEmailDialog,
              child: const Text('Continuar con email'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _completing ? null : () => _complete(AuthMode.guest),
              child: const Text('Continuar como invitado'),
            ),
            if (_completing)
              const Padding(
                padding: EdgeInsets.only(top: 24),
                child: Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
