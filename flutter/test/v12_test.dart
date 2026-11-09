// v0.12: tile de aparelho com o ícone como chave, faixa do dia inteiro do
// SsDayAgenda, cabeçalho de card, card de indicador e lista ranqueada.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {double width = 390}) => MaterialApp(
  theme: AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 844)),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsDeviceTile (v0.12)', () {
    testWidgets('o ícone é um interruptor acessível; o resto abre os detalhes', (t) async {
      final sem = t.ensureSemantics();
      var aberto = 0;
      bool? pedido;
      await t.pumpWidget(
        _app(
          SsDeviceTile(
            icon: Icons.lightbulb_outline,
            name: 'Luz da sala',
            state: 'Ligada',
            on: true,
            onTap: () => aberto++,
            onToggle: (v) => pedido = v,
          ),
        ),
      );
      final chave = find.bySemanticsLabel('Luz da sala');
      expect(chave, findsOneWidget);
      final data = t.getSemantics(chave).getSemanticsData();
      expect(data.flagsCollection.isToggled.toString(), endsWith('isTrue'));
      expect(data.hint, 'Desligar');
      // Texto ao lado do ícone (mesma linha).
      final ico = t.getCenter(find.byIcon(Icons.lightbulb_outline));
      final nome = t.getCenter(find.text('Luz da sala'));
      expect((ico.dy - nome.dy).abs(), lessThan(14));
      expect(nome.dx, greaterThan(ico.dx));
      await t.tap(find.byIcon(Icons.lightbulb_outline));
      await t.pumpAndSettle();
      expect(pedido, isFalse);
      expect(aberto, 0);
      await t.tap(find.text('Ligada'));
      await t.pumpAndSettle();
      expect(aberto, 1);
      sem.dispose();
    });

    testWidgets('teclado: Enter no ícone com foco alterna', (t) async {
      bool? pedido;
      await t.pumpWidget(_app(SsDeviceTile(icon: Icons.power, name: 'Tomada', onToggle: (v) => pedido = v)));
      final ink = find.ancestor(of: find.byIcon(Icons.power), matching: find.byType(InkWell));
      expect(ink, findsOneWidget);
      // Tab leva o foco ao ícone (o único focável).
      await t.sendKeyEvent(LogicalKeyboardKey.tab);
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(pedido, isTrue);
    });

    testWidgets('enviando trava a chave; sem permissão o ícone não é chave', (t) async {
      bool? pedido;
      await t.pumpWidget(
        _app(
          Column(
            children: [
              SsDeviceTile(icon: Icons.power, name: 'A', status: SsDeviceStatus.pending, onToggle: (v) => pedido = v),
              SsDeviceTile(icon: Icons.lock, name: 'B', status: SsDeviceStatus.locked, onToggle: (v) => pedido = v),
            ],
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 300));
      await t.tap(find.byIcon(Icons.power), warnIfMissed: false);
      await t.pump(const Duration(milliseconds: 300));
      expect(pedido, isNull);
      expect(find.ancestor(of: find.byIcon(Icons.lock), matching: find.byType(InkWell)), findsNothing);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
    });

    testWidgets('cabe em 2 colunas de 360 sem estourar', (t) async {
      await t.pumpWidget(
        _app(
          Row(
            children: [
              for (final n in ['Fita de LED da bancada da cozinha', 'Luz do quarto do casal'])
                Expanded(
                  child: SsDeviceTile(icon: Icons.lightbulb, name: n, state: 'Desligada', onToggle: (_) {}),
                ),
            ],
          ),
          width: 340,
        ),
      );
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('SsDayAgenda(allDay:) não passa da largura, título inteiro no tooltip', (t) async {
    const longo = 'NOTA TÉCNICA S-1.3 Nº 07/2026 - Implantação em produção restrita do novo leiaute do eSocial';
    await t.pumpWidget(
      _app(
        const SsDayAgenda(
          startHour: 15,
          endHour: 17,
          hourHeight: 40,
          allDay: [SsAgendaItem(title: longo, detail: 'Trabalho')],
          events: [
            SsAgendaEvent(start: TimeOfDay(hour: 15, minute: 0), end: TimeOfDay(hour: 16, minute: 0), title: 'R'),
          ],
        ),
        width: 260,
      ),
    );
    expect(t.takeException(), isNull);
    expect(find.text('Dia todo'), findsOneWidget);
    final texto = find.byWidgetPredicate((w) => w is RichText && w.text.toPlainText().startsWith('NOTA'));
    expect(t.getRect(texto).right, lessThanOrEqualTo(260));
    expect(t.widget<RichText>(texto).maxLines, 1);
    expect(find.byWidgetPredicate((w) => w is Tooltip && w.message == '$longo · Trabalho'), findsOneWidget);
  });

  testWidgets('SsCardHeader, SsKpiCard e SsRankList', (t) async {
    final sem = t.ensureSemantics();
    var tocou = 0;
    await t.pumpWidget(
      _app(
        SingleChildScrollView(
          child: Column(
            children: [
              SsKpiCard(
                label: 'Gasto do mês',
                value: r'R$ 312,75',
                caption: '01/11 a 30/11',
                icon: Icons.bolt,
                onTap: () => tocou++,
              ),
              const SsCardHeader(title: 'Consumo por aparelho', subtitle: 'Mês', icon: Icons.bar_chart),
              SsRankList(
                items: [
                  SsRankItem(
                    label: 'Ar',
                    value: '160 kWh',
                    amount: 160,
                    share: '40%',
                    caption: r'R$ 150,00',
                    onTap: () => tocou += 10,
                  ),
                  const SsRankItem(label: 'Chuveiro', value: '80 kWh', amount: 80, share: '20%'),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Gasto do mês'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'^Gasto do mês, R\$ 312,75, 01/11 a 30/11')), findsOneWidget);
    expect(find.bySemanticsLabel('1. Ar 160 kWh 40% R\$ 150,00'), findsOneWidget);
    expect(find.bySemanticsLabel('Ranking'), findsOneWidget);
    // Barras: o 1º cheio, o 2º pela metade.
    final barras = t
        .widgetList<FractionallySizedBox>(find.byType(FractionallySizedBox))
        .map((f) => f.widthFactor)
        .toList();
    expect(barras, [1.0, .5]);
    await t.tap(find.text('Gasto do mês'));
    await t.tap(find.text('Ar'));
    await t.pumpAndSettle();
    expect(tocou, 11);
    // Título de card: 14 / 800.
    final titulo = t.widget<Text>(find.text('Consumo por aparelho'));
    expect(titulo.style!.fontWeight, FontWeight.w800);
    expect(titulo.style!.fontSize, AppType.set);
    sem.dispose();
  });
}
