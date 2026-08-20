import 'package:flutter/material.dart';

import 'theme/app_theme.dart';

/// Attribution for every open-source package this app depends on. Flutter's
/// [LicenseRegistry] auto-collects each pub package's LICENSE file at build
/// time — [showLicensePage] is the built-in viewer for it, so this screen is
/// mostly wiring, not content we maintain by hand.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const _appName = 'App para Aprender Idiomas';
  static const _appVersion = '1.0.0';

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_appName, style: textTheme.titleLarge),
            const SizedBox(height: AppTheme.spaceXs),
            Text(
              'Versión $_appVersion',
              style: textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTheme.spaceLg),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.description_outlined),
                title: const Text('Licencias de código abierto'),
                subtitle: const Text(
                  'Avisos de licencia de cada paquete que usa la App',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: _appName,
                  applicationVersion: _appVersion,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
