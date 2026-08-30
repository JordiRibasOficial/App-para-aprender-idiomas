import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/domain/models/account_session.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/user_data_deletion_repository.dart';
import 'package:app_para_aprender_idiomas/domain/repositories/user_data_export_repository.dart';
import 'package:app_para_aprender_idiomas/presentation/data_export_screen.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/account_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/user_data_deletion_providers.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/user_data_export_providers.dart';

const _fakeAccount = AccountSession(
  userId: 'test-user',
  email: 'test@example.com',
);

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

class _FakeUserDataDeletionRepository implements UserDataDeletionRepository {
  _FakeUserDataDeletionRepository({this.error});

  final Object? error;
  int callCount = 0;

  @override
  Future<void> deleteUserData() async {
    callCount++;
    if (error != null) throw error!;
  }
}

Widget _wrap(
  UserDataExportRepository repository, {
  UserDataDeletionRepository? deletionRepository,
  AccountSession? account = _fakeAccount,
}) {
  return ProviderScope(
    overrides: [
      userDataExportRepositoryProvider.overrideWithValue(repository),
      userDataDeletionRepositoryProvider.overrideWithValue(
        deletionRepository ?? _FakeUserDataDeletionRepository(),
      ),
      accountSessionProvider.overrideWith((ref) => Stream.value(account)),
    ],
    child: const MaterialApp(home: DataExportScreen()),
  );
}

void main() {
  testWidgets(
    'shows a "create account" prompt instead of the export UI for a guest',
    (tester) async {
      await tester.pumpWidget(
        _wrap(_FakeUserDataExportRepository(result: {}), account: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('Crear cuenta'), findsOneWidget);
      expect(find.text('Exportar mis datos'), findsNothing);
    },
  );

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

  testWidgets('deletion asks for confirmation before calling the repository', (
    tester,
  ) async {
    final deletionRepository = _FakeUserDataDeletionRepository();
    await tester.pumpWidget(
      _wrap(
        _FakeUserDataExportRepository(result: {}),
        deletionRepository: deletionRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar mis datos').first);
    await tester.pumpAndSettle();

    expect(find.text('¿Eliminar tus datos?'), findsOneWidget);
    expect(deletionRepository.callCount, 0);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(deletionRepository.callCount, 0);
  });

  testWidgets('confirming deletion calls the repository and shows success', (
    tester,
  ) async {
    final deletionRepository = _FakeUserDataDeletionRepository();
    await tester.pumpWidget(
      _wrap(
        _FakeUserDataExportRepository(result: {}),
        deletionRepository: deletionRepository,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar mis datos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(deletionRepository.callCount, 1);
    expect(find.text('Tus datos se han eliminado.'), findsOneWidget);
  });

  testWidgets('a failed deletion shows an inline error, not a crash', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        _FakeUserDataExportRepository(result: {}),
        deletionRepository: _FakeUserDataDeletionRepository(
          error: Exception('delete-user-data respondió 500'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Eliminar mis datos').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(find.textContaining('No se pudo eliminar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
