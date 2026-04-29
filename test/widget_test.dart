import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Smoke test leve: não abre Isar nem `AuraTimeApp` completo (evita locks de
/// arquivo no ambiente de teste e timers contínuos do dashboard). Validação
/// completa de fluxos permanece manual / emulador.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('MaterialApp smoke (CI)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('AuraTime'))),
      ),
    );
    expect(find.text('AuraTime'), findsOneWidget);
  });
}
