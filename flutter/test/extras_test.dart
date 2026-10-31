import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('SsOdometer.parse lê o formato brasileiro', () {
    expect(SsOdometer.parse(r'R$ 1.234,56'), 1234.56);
    expect(SsOdometer.parse(r'R$ -12,30'), -12.3);
    expect(SsOdometer.parse('3'), 3);
    expect(SsOdometer.parse('—'), isNull);
  });

  testWidgets('SsOdometer rola até o valor novo e lê o texto inteiro', (t) async {
    Widget odo(String v) => _app(SsOdometer(v));
    await t.pumpWidget(odo(r'R$ 9,99'));
    await t.pumpWidget(odo(r'R$ 10,00'));
    await t.pump(const Duration(milliseconds: 100));
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(r'R$ 10,00'), findsOneWidget);
  });

  testWidgets('SsActionButton: carregando → Pronto → normal; erro volta ao normal', (t) async {
    var chamadas = 0;
    await t.pumpWidget(
      _app(
        Column(
          children: [
            SsActionButton(label: 'Salvar', onPressed: () async => chamadas++),
            SsActionButton(label: 'Falhar', onPressed: () async => throw Exception('x')),
          ],
        ),
      ),
    );
    await t.tap(find.text('Salvar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 400));
    expect(chamadas, 1);
    expect(find.text('Pronto'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 1500));
    await t.pumpAndSettle();
    expect(find.text('Salvar'), findsOneWidget);

    await t.tap(find.text('Falhar'));
    await t.pumpAndSettle();
    expect(find.text('Falhar'), findsOneWidget);
    expect(find.text('Pronto'), findsNothing);
  });

  testWidgets('showSsCommandPalette acha sem acento e Enter executa e fecha', (t) async {
    String? rodou;
    await t.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showSsCommandPalette(
              context,
              commands: [
                SsCommand(Icons.add, 'Novo pedido', group: 'Ações', onRun: () => rodou = 'pedido'),
                SsCommand(Icons.bar_chart, 'Relatório de vendas', group: 'Telas', onRun: () => rodou = 'relatorio'),
                SsCommand(Icons.money, 'Títulos', keywords: ['cobrança'], onRun: () => rodou = 'titulos'),
              ],
            ),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    expect(find.text('Novo pedido', findRichText: true), findsOneWidget);

    await t.enterText(find.byType(TextField), 'RELATORIO');
    await t.pump();
    expect(find.text('Novo pedido', findRichText: true), findsNothing);
    expect(find.text('Relatório de vendas', findRichText: true), findsOneWidget);

    await t.enterText(find.byType(TextField), 'cobranca');
    await t.pump();
    expect(find.text('Títulos', findRichText: true), findsOneWidget);

    await t.testTextInput.receiveAction(TextInputAction.go);
    await t.pumpAndSettle();
    expect(rodou, 'titulos');
    expect(find.byType(SsCommandPalette), findsNothing);
  });

  testWidgets('SsContextMenu abre no toque longo e a ação fecha e executa', (t) async {
    var excluiu = false;
    await t.pumpWidget(
      _app(
        Center(
          child: SsContextMenu(
            actions: [
              SsContextAction(Icons.edit, 'Editar', () {}),
              SsContextAction(Icons.delete, 'Excluir', () => excluiu = true, destructive: true),
            ],
            child: const SizedBox(width: 200, height: 60, child: Text('Pedido')),
          ),
        ),
      ),
    );
    await t.longPress(find.text('Pedido'));
    await t.pumpAndSettle();
    expect(find.text('Excluir'), findsOneWidget);
    await t.tap(find.text('Excluir'));
    await t.pumpAndSettle();
    expect(excluiu, isTrue);
    expect(find.text('Editar'), findsNothing);
  });

  testWidgets('SsSelectable e SsSelectionBar', (t) async {
    final marcados = <int>{};
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => Stack(
            children: [
              ListView(
                children: [
                  for (var i = 0; i < 3; i++)
                    SsSelectable(
                      selected: marcados.contains(i),
                      selecting: marcados.isNotEmpty,
                      onToggle: () => set(() => marcados.contains(i) ? marcados.remove(i) : marcados.add(i)),
                      child: ListTile(title: Text('item $i'), onTap: () {}),
                    ),
                ],
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SsSelectionBar(count: marcados.length, actions: const [], onClear: () => set(marcados.clear)),
              ),
            ],
          ),
        ),
      ),
    );
    await t.longPress(find.text('item 0'));
    await t.pumpAndSettle();
    expect(marcados, {0});
    await t.tap(find.text('item 2'), warnIfMissed: false); // o item está sob IgnorePointer: o toque é da seleção
    await t.pumpAndSettle();
    expect(marcados, {0, 2});
    expect(find.text('selecionados'), findsOneWidget);
    await t.tap(find.byTooltip('Limpar seleção'));
    await t.pumpAndSettle();
    expect(marcados, isEmpty);
  });

  testWidgets('SsOpenCard abre a tela e volta', (t) async {
    await t.pumpWidget(
      _app(
        Center(
          child: SsOpenCard(
            closed: const SizedBox(width: 200, height: 80, child: Text('card')),
            open: (_) => Scaffold(appBar: AppBar(), body: const Text('detalhe')),
          ),
        ),
      ),
    );
    await t.tap(find.text('card'));
    await t.pump(const Duration(milliseconds: 200));
    await t.pumpAndSettle();
    expect(find.text('detalhe'), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    expect(find.text('detalhe'), findsNothing);
    expect(find.text('card'), findsOneWidget);
  });

  testWidgets('SsCompare move a divisão no arraste', (t) async {
    final h = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          height: 200,
          child: SsCompare(
            before: Container(color: Colors.red),
            after: Container(color: Colors.blue),
          ),
        ),
      ),
    );
    final f = find.bySemanticsLabel(RegExp('Comparar'));
    expect(t.getSemantics(f).value, '50%');
    await t.tapAt(t.getTopLeft(find.byType(SsCompare)) + const Offset(60, 100));
    await t.pump();
    expect(t.getSemantics(f).value, '20%');
    h.dispose();
  });

  testWidgets('SsKanban arrasta card para outra coluna', (t) async {
    (String, String, String, int)? movido;
    await t.pumpWidget(
      _app(
        SsKanban<String>(
          columnWidth: 180,
          columns: const [
            SsKanbanColumn(id: 'a', title: 'A', items: ['um', 'dois']),
            SsKanbanColumn(id: 'b', title: 'B', items: ['tres']),
          ],
          cardBuilder: (_, s) => SizedBox(height: 60, child: Text(s)),
          onMove: (item, de, para, i) => movido = (item, de, para, i),
        ),
      ),
    );
    final g = await t.startGesture(t.getCenter(find.text('um')));
    await t.pump(kLongPressTimeout + const Duration(milliseconds: 100));
    await g.moveBy(const Offset(20, 0));
    await t.pump();
    // Abaixo do último card da coluna B: vai para o fim.
    await g.moveTo(t.getBottomLeft(find.text('tres')) + const Offset(20, 60));
    await t.pump();
    await g.up();
    await t.pumpAndSettle();
    expect(movido, ('um', 'a', 'b', 1));
  });

  testWidgets('ssFlyTo voa e termina', (t) async {
    final de = GlobalKey(), para = GlobalKey();
    var chegou = false;
    await t.pumpWidget(
      _app(
        Column(
          children: [
            Text('total', key: para),
            const Spacer(),
            Builder(
              builder: (context) => TextButton(
                key: de,
                onPressed: () async {
                  await ssFlyTo(context, from: de, to: para, child: const Text('+1'));
                  chegou = true;
                },
                child: const Text('chip'),
              ),
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('chip'));
    await t.pump(const Duration(milliseconds: 200));
    expect(find.text('+1'), findsOneWidget);
    await t.pumpAndSettle();
    expect(chegou, isTrue);
    expect(find.text('+1'), findsNothing);
  });
}
