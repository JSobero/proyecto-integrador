import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/main.dart';

void main() {
  testWidgets('La aplicación SAAC se inicia correctamente', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const SaacApp(isLoggedIn: false, rol: 'invitado'));

    await tester.pump();

    expect(find.byType(SaacApp), findsOneWidget);
  });
}
