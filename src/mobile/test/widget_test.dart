import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app_para_aprender_idiomas/data/in_memory_progress_repository.dart';
import 'package:app_para_aprender_idiomas/main.dart';
import 'package:app_para_aprender_idiomas/presentation/providers/progress_providers.dart';

void main() {
  testWidgets('App boots and shows the lesson list', (WidgetTester tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [progressRepositoryProvider.overrideWithValue(InMemoryProgressRepository())],
      child: const MyApp(),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Inglés · A1'), findsOneWidget);
    expect(find.text('Saludos y presentaciones'), findsOneWidget);
  });
}
