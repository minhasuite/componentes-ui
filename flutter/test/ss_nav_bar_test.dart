import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _abas = [
  SsNavItem(Icons.home_outlined, 'Início'),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos'),
  SsNavItem(Icons.menu, 'Mais'),
];

Widget _app(int i, ValueChanged<int> onTap, {bool semAnimacao = false}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: semAnimacao, size: const Size(360, 640)),
    child: Scaffold(
      extendBody: true,
      bottomNavigationBar: SsNavBar(items: _abas, currentIndex: i, onTap: onTap),
    ),
  ),
);

/// Centro do círculo (o único Container circular da barra).
Offset _circulo(WidgetTester t) => t.getCenter(
  find.byWidgetPredicate((w) => w is Container && (w.decoration as BoxDecoration?)?.shape == BoxShape.circle),
);
double _circuloX(WidgetTester t) => _circulo(t).dx;

void main() {
  testWidgets('toque avisa a aba e o círculo pula até ela', (t) async {
    final toques = <int>[];
    await t.pumpWidget(_app(0, toques.add));
    final x0 = _circuloX(t);
    final y0 = _circulo(t).dy;
    await t.tap(find.text('Mais'));
    expect(toques, [2]);

    await t.pumpWidget(_app(2, toques.add));
    await t.pump(const Duration(milliseconds: 290));
    final meio = _circuloX(t);
    expect(meio, greaterThan(x0)); // a caminho, ainda não chegou
    expect(_circulo(t).dy, lessThan(y0 - 20)); // no ar
    await t.pumpAndSettle();
    expect(_circulo(t).dy, closeTo(y0, .5)); // pousou
    final fim = _circuloX(t);
    expect(fim, greaterThan(meio));
    expect(fim, closeTo(t.getSize(find.byType(SsNavBar)).width * 5 / 6, 1));
  });

  testWidgets('sem animação o círculo pula direto', (t) async {
    await t.pumpWidget(_app(0, (_) {}, semAnimacao: true));
    await t.pumpWidget(_app(1, (_) {}, semAnimacao: true));
    await t.pump();
    expect(_circuloX(t), closeTo(t.getSize(find.byType(SsNavBar)).width / 2, 1));
  });

  testWidgets('leitor de tela lê a aba e a posição', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(_app(1, (_) {}));
    expect(find.bySemanticsLabel('Pedidos, aba 2 de 3'), findsOneWidget);
    h.dispose();
  });
}
