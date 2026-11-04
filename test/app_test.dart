import 'package:donde_esta_mi_camion/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('sin Firebase configurado muestra la guía', (tester) async {
    await tester.pumpWidget(const AppCamion(firebaseListo: false));
    expect(find.text('Falta conectar Firebase'), findsOneWidget);
  });
}
