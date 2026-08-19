import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/domain/repositories/user_data_export_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/data_export_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/user_data_export_providers.dart';

class _FakeUserDataExportRepository implements UserDataExportRepository {
  _FakeUserDataExportRepository({this.result, this.error});

  final Map<String, dynamic>? result;
  final Object? error;

  @override
  Future<Map<String, dynamic>> exportUserData() async {
    if (error != null) throw error!;
    return result ?? const {};
  }
}

Widget _wrap(UserDataExportRepository repository) {
  return ProviderScope(
    overrides: [userDataExportRepositoryProvider.overrideWithValue(repository)],
    child: const MaterialApp(home: DataExportScreen()),
  );
}

void main() {
  testWidgets('shows nothing exported before the button is pressed', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(_FakeUserDataExportRepository(result: {})));
    await tester.pumpAndSettle();

    expect(find.text('Exportar mis datos'), findsOneWidget);
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('a successful export renders the JSON and a copy button', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _FakeUserDataExportRepository(
          result: {
            'userId': 'abc-123',
            'subscriptions': [],
            'verificationAttempts': [],
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exportar mis datos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('abc-123'), findsOneWidget);
    expect(find.text('Copiar al portapapeles'), findsOneWidget);
  });

  testWidgets('a failed export shows an inline error, not a crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _FakeUserDataExportRepository(
          error: Exception('export-user-data respondió 500'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Exportar mis datos'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo exportar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
