import 'package:app_para_aprender_idiomas/error_reporting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reportError does not throw for an error with a stack trace', () {
    expect(
      () => reportError(StateError('boom'), StackTrace.current),
      returnsNormally,
    );
  });

  test('reportError does not throw when the stack trace is null', () {
    expect(() => reportError('boom', null), returnsNormally);
  });
}
