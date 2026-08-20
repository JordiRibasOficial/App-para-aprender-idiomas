import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/user_data_deletion_providers.dart';
import 'providers/user_data_export_providers.dart';
import 'theme/app_theme.dart';

/// RGPD art. 15/20/17: lets the user pull, or permanently delete,
/// everything the backend holds about their own anonymous session identity
/// — see docs/business/records-of-processing-activities.md and the
/// `export-user-data`/`delete-user-data` Edge Functions this calls.
class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _loading = false;
  String? _error;
  String? _exportedJson;

  bool _deleting = false;
  String? _deleteError;
  bool _deleted = false;

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

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar tus datos?'),
        content: const Text(
          'Esto borra permanentemente tu suscripción y tus intentos de '
          'verificación de compra guardados en nuestro backend. No se '
          'puede deshacer. Tu progreso de lecciones en este dispositivo '
          'no se ve afectado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _deleting = true;
      _deleteError = null;
    });

    try {
      final repository = ref.read(userDataDeletionRepositoryProvider);
      await repository.deleteUserData();
      if (!mounted) return;
      setState(() {
        _deleted = true;
        _exportedJson = null;
      });
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _deleteError = e.toString());
    } finally {
      if (mounted) setState(() => _deleting = false);
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
            const SizedBox(height: AppTheme.spaceLg),
            const Divider(),
            const SizedBox(height: AppTheme.spaceLg),
            Text(
              'Borrado de datos',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppTheme.spaceSm),
            const Text(
              'Borra permanentemente el estado de tu suscripción y tus '
              'intentos de verificación de compra guardados en nuestro '
              'backend. Esta acción no se puede deshacer.',
            ),
            const SizedBox(height: AppTheme.spaceMd),
            OutlinedButton(
              onPressed: (_deleting || _deleted) ? null : _confirmAndDelete,
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
                side: BorderSide(color: Theme.of(context).colorScheme.error),
              ),
              child: _deleting
                  ? Semantics(
                      label: 'Eliminando datos',
                      child: const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : const Text('Eliminar mis datos'),
            ),
            if (_deleteError != null) ...[
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                'No se pudo eliminar: $_deleteError',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_deleted) ...[
              const SizedBox(height: AppTheme.spaceMd),
              const Text('Tus datos se han eliminado.'),
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
