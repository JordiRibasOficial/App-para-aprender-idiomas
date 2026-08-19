import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

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
              const SizedBox(height: AppTheme.spaceXxl),
              FilledButton(
                onPressed: () => context.push('/onboarding/language'),
                child: const Text('Empezar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
