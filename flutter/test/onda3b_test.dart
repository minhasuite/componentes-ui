import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

Widget _lista(List<String> itens, void Function(String) remover, void Function() comprei) => ListView(
  children: [
    for (final i in itens)
      SsSwipeAction(
        key: ValueKey(i),
        start: SsSwipeSide(icon: Icons.check, label: 'Comprei', color: AppColors.success, onTrigger: comprei),
        end: SsSwipeSide(
          icon: Icons.delete,
          label: 'Excluir',
          color: AppColors.danger,
          destructive: true,
          onTrigger: () => remover(i),
        ),
        child: SizedBox(height: 56, child: Text(i)),
      ),
  ],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('rubber: igual até o limite, depois cresce menos e nunca passa de +25%', () {
    expect(SsSwipeAction.rubber(100, 400), 100);
    expect(SsSwipeAction.rubber(-140, 400), -140);
    final a = SsSwipeAction.rubber(200, 400);
    final b = SsSwipeAction.rubber(300, 400);
    expect(a, greaterThan(140));
    expect(a, lessThan(200));
    expect(b - a, lessThan(a - 140));
    expect(SsSwipeAction.rubber(-100000, 400), greaterThan(-240));
  });

  testWidgets('SsSwipeAction: soltar depois do limite exclui; antes, volta', (tester) async {
    final itens = ['Leite', 'Pão'];
    var comprei = 0;
    late StateSetter set;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (_, s) {
            set = s;
            return _lista(itens, (i) => set(() => itens.remove(i)), () => comprei++);
          },
        ),
      ),
    );

    // Antes do limite (800 px de largura → 280): volta e nada acontece.
    await tester.drag(find.text('Leite'), const Offset(-150, 0));
    await tester.pumpAndSettle();
    expect(find.text('Leite'), findsOneWidget);
    expect(tester.getTopLeft(find.text('Leite')).dx, 0);

    // Não destrutivo depois do limite: aciona e volta.
    await tester.drag(find.text('Pão'), const Offset(400, 0));
    await tester.pumpAndSettle();
    expect(comprei, 1);
    expect(tester.getTopLeft(find.text('Pão')).dx, 0);

    // Destrutivo: encolhe e sai da lista.
    await tester.drag(find.text('Leite'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(itens, ['Pão']);
    expect(find.text('Leite'), findsNothing);
  });

  testWidgets('SsSwipeAction: item que o app não tira volta ao lugar', (tester) async {
    var chamou = 0;
    await tester.pumpWidget(_app(_lista(['Leite'], (_) => chamou++, () {})));
    await tester.drag(find.text('Leite'), const Offset(-400, 0));
    await tester.pumpAndSettle();
    expect(chamou, 1);
    expect(tester.getSize(find.byType(SsSwipeAction)).height, 56);
    expect(tester.getTopLeft(find.text('Leite')).dx, 0);
  });

  testWidgets('SsSwipeAction: leitor de tela aciona pelas ações', (tester) async {
    final h = tester.ensureSemantics();
    var comprei = 0;
    await tester.pumpWidget(_app(_lista(['Leite'], (_) {}, () => comprei++)));
    final node = tester.getSemantics(find.byType(SsSwipeAction));
    final acoes = node.getSemanticsData().customSemanticsActionIds!;
    expect(acoes, hasLength(2));
    final comp = CustomSemanticsAction.getAction(acoes.first)!;
    expect(comp.label, 'Comprei');
    node.owner!.performAction(node.id, SemanticsAction.customAction, acoes.first);
    await tester.pumpAndSettle();
    expect(comprei, 1);
    h.dispose();
  });

  testWidgets('SsStatusBadge: mapa dá o tom; fora do mapa sai neutro com o próprio status', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            SsStatusBadge('pago', map: {'pago': SsTone.success}, label: 'Pago'),
            SsStatusBadge('estranho'),
          ],
        ),
      ),
    );
    expect(find.text('Pago'), findsOneWidget);
    expect(find.text('estranho'), findsOneWidget);
    final ctx = tester.element(find.text('Pago'));
    expect(tester.widget<Text>(find.text('Pago')).style!.color, SsColors.of(ctx).successText);
    expect(tester.widget<Text>(find.text('estranho')).style!.color, SsColors.of(ctx).muted);
  });

  testWidgets('SsValueRow: rótulo inteiro, valor encolhe; toque', (tester) async {
    var tocou = 0;
    await tester.pumpWidget(
      _app(
        Center(
          child: SizedBox(width: 220, child: SsValueRow('Saldo devedor', r'R$ 1.234.567.890,00', onTap: () => tocou++)),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    final rotulo = tester.getSize(find.text('Saldo devedor'));
    expect(rotulo.height, lessThan(30)); // uma linha, não espremido
    await tester.tap(find.byType(SsValueRow));
    expect(tocou, 1);
  });

  testWidgets('SsHighlight: acende ao ativar e apaga em ~600 ms', (tester) async {
    Widget w(bool a) => _app(SsHighlight(active: a, child: const SizedBox(width: 100, height: 40)));
    DecoratedBox caixa() => tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(SsHighlight), matching: find.byType(DecoratedBox)).first,
    );
    await tester.pumpWidget(w(false));
    expect((caixa().decoration as BoxDecoration).color, isNull);
    await tester.pumpWidget(w(true));
    await tester.pump(const Duration(milliseconds: 120));
    expect((caixa().decoration as BoxDecoration).color, isNotNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect((caixa().decoration as BoxDecoration).color, isNull);
  });

  testWidgets('SsNetImage sem url mostra as iniciais', (tester) async {
    await tester.pumpWidget(_app(const SsNetImage(null, width: 48, height: 48, name: 'Leite Integral')));
    expect(find.text('LI'), findsOneWidget);
  });

  testWidgets('SsOfferCard: fita na mais barata e toque', (tester) async {
    var tocou = 0;
    await tester.pumpWidget(
      _app(
        Column(
          children: [
            SsOfferCard(source: 'Amazon', title: 'Air Fryer', price: r'R$ 329,90', best: true, onTap: () => tocou++),
            const SsOfferCard(source: 'Magalu', title: 'Air Fryer', price: r'R$ 359,00'),
          ],
        ),
      ),
    );
    expect(find.text('MAIS BARATA'), findsOneWidget);
    await tester.tap(find.text(r'R$ 329,90'));
    expect(tocou, 1);
  });
}
