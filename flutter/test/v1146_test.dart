import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// v1.14.6 · o campo invisível do SsOtpField não herda borda nem fundo do inputDecorationTheme do app.
void main() {
  testWidgets('SsOtpField: campo invisível sem borda de foco nem preenchimento do tema', (t) async {
    final tema = AppTheme.light.copyWith(
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(width: 3)),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(width: 2)),
      ),
    );
    await t.pumpWidget(
      MaterialApp(
        theme: tema,
        home: const Scaffold(
          body: Padding(padding: EdgeInsets.all(16), child: SsOtpField(autofocus: true)),
        ),
      ),
    );
    await t.pumpAndSettle();
    final deco = t.widget<InputDecorator>(find.byType(InputDecorator)).decoration;
    expect(deco.focusedBorder, InputBorder.none);
    expect(deco.enabledBorder, InputBorder.none);
    expect(deco.filled, isFalse);
  });
}
