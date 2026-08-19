import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/user_data_export_providers.dart';
import 'theme/app_theme.dart';

/// RGPD art. 15/20: lets the user pull everything the backend holds about
/// their own anonymous session identity, in one tap — see
/// docs/business/records-of-processing-activities.md and the
/// `export-user-data` Edge Function this calls.
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _loading = false;
  String? _error;
  String? _exportedJson;

  Future<void> _export() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final repository = ref.read(userDataExportRepositoryProvider);
      final data = await repository.exportUserData();
      const encoder = JsonEncoder.withIndent('  ');
      if (!mounted) return;
      setState(() => _exportedJson = encoder.convert(data));
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyToClipboard() async {
    final json = _exportedJson;
    if (json == null) return;
    await Clipboard.setData(ClipboardData(text: json));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Copiado al portapapeles')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis datos')),
      body: Padding(
        padding: const EdgeInsets.all(AppTheme.spaceMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Descarga una copia de los datos que guardamos sobre tu '
              'identidad anónima en nuestro backend: estado de tu '
              'suscripción e intentos de verificación de compra. El '
              'progreso de tus lecciones vive solo en este dispositivo y '
              'no forma parte de esta exportación.',
            ),
            const SizedBox(height: AppTheme.spaceMd),
            FilledButton(
              onPressed: _loading ? null : _export,
              child: _loading
                  ? Semantics(
                      label: 'Exportando datos',
                      child: const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Text('Exportar mis datos'),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                'No se pudo exportar: $_error',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_exportedJson != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              OutlinedButton(
                onPressed: _copyToClipboard,
                child: const Text('Copiar al portapapeles'),
              ),
              const SizedBox(height: AppTheme.spaceSm),
              Expanded(
                child: SingleChildScrollView(
                  child: SelectableText(
                    _exportedJson!,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
