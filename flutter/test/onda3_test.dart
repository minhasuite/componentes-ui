import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('ssMonthDays: começa no domingo e fecha semanas', () {
    final d = ssMonthDays(DateTime(2026, 10)); // 1/10/2026 é quinta
    expect(d.first, DateTime(2026, 9, 27));
    expect(d.first.weekday, DateTime.sunday);
    expect(d.length % 7, 0);
    expect(d.last, DateTime(2026, 10, 31));
    expect(ssMonthDays(DateTime(2026, 2)).length, 28); // 1/2 é domingo
    expect(ssMonthDays(DateTime(2026, 8)).length, 42); // 1/8 é sábado
  });

  test('ssMonthName e ssHeatLevel', () {
    expect(ssMonthName(DateTime(2026, 10)), 'Outubro 2026');
    expect(ssHeatLevel(null, 10), 0);
    expect(ssHeatLevel(0, 10), 0);
    expect(ssHeatLevel(.1, 10), 1);
    expect(ssHeatLevel(5, 10), 2);
    expect(ssHeatLevel(10, 10), 4);
  });

  test('SsGauge.bandOf', () {
    const b = <(double, String, Color)>[
      (.3, 'barato', Colors.green),
      (.7, 'normal', Colors.grey),
      (1.0, 'caro', Colors.red),
    ];
    expect(SsGauge.bandOf(.1, b).$2, 'barato');
    expect(SsGauge.bandOf(.3, b).$2, 'barato');
    expect(SsGauge.bandOf(.5, b).$2, 'normal');
    expect(SsGauge.bandOf(2, b).$2, 'caro');
  });

  testWidgets('SsLineChart: arrastar mostra o balão com haptic a cada ponto', (tester) async {
    var cliques = 0;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') cliques++;
      return null;
    });
    await tester.pumpWidget(
      _app(
        const SsLineChart(
          series: [
            SsSeries([1, 2, 3, 4], name: 'Preço'),
          ],
          labels: ['a', 'b', 'c', 'dia D'],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Preço'), findsNothing); // eixo é pintado; balão fechado
    final box = tester.getRect(find.byType(SsLineChart));
    final g = await tester.startGesture(box.centerLeft + const Offset(4, 0));
    await g.moveBy(const Offset(30, 0));
    await tester.pump();
    await g.moveTo(box.centerRight - const Offset(2, 0));
    await tester.pump();
    expect(find.text('Preço'), findsOneWidget);
    expect(find.text('dia D'), findsOneWidget); // balão no último ponto
    expect(cliques, greaterThanOrEqualTo(2));
    await g.up();
    await tester.pump();
    expect(find.text('Preço'), findsNothing);
  });

  testWidgets('SsMonthSwitcher: setas respeitam o max e o título volta ao mês atual', (tester) async {
    final agora = DateTime(DateTime.now().year, DateTime.now().month);
    DateTime? foi;
    await tester.pumpWidget(_app(SsMonthSwitcher(month: agora, max: agora, onChanged: (m) => foi = m)));
    await tester.tap(find.byTooltip('Próximo mês'));
    expect(foi, isNull);
    await tester.tap(find.byTooltip('Mês anterior'));
    expect(foi, DateTime(agora.year, agora.month - 1));

    foi = null;
    final antes = DateTime(agora.year, agora.month - 3);
    await tester.pumpWidget(_app(SsMonthSwitcher(month: antes, onChanged: (m) => foi = m)));
    await tester.tap(find.text(ssMonthName(antes)));
    expect(foi, agora);
  });

  testWidgets('SsMonthGrid: toque seleciona e arrasto troca de mês', (tester) async {
    DateTime? dia, mes;
    await tester.pumpWidget(
      _app(
        SsMonthGrid(
          month: DateTime(2026, 10),
          today: DateTime(2026, 10, 31),
          onSelect: (d) => dia = d,
          onMonthChanged: (m) => mes = m,
        ),
      ),
    );
    await tester.tap(find.text('15'));
    expect(dia, DateTime(2026, 10, 15));
    await tester.fling(find.text('15'), const Offset(-300, 0), 1000);
    expect(mes, DateTime(2026, 11));
    await tester.fling(find.text('15'), const Offset(300, 0), 1000);
    expect(mes, DateTime(2026, 9));
  });

  testWidgets('SsHeatCalendar: toque mostra o valor do dia', (tester) async {
    await tester.pumpWidget(
      _app(SsHeatCalendar(values: {DateTime(2026, 10, 31): 3}, end: DateTime(2026, 10, 31), weeks: 4)),
    );
    await tester.tap(find.bySemanticsLabel('31/10/2026: 3'));
    await tester.pump();
    expect(find.text('31/10/2026: 3'), findsOneWidget);
  });

  testWidgets('SsProportionBar: toque na legenda destaca e desfaz', (tester) async {
    await tester.pumpWidget(_app(const SsProportionBar(parts: [(3, 'A', null), (1, 'B', null)])));
    await tester.pumpAndSettle();
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(tester.widget<Text>(find.text('B')).style!.fontWeight, FontWeight.w800);
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(tester.widget<Text>(find.text('B')).style!.fontWeight, FontWeight.w600);
  });

  testWidgets('SsProgress: compatível e com estouro na semântica', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            SsProgress(.5),
            SsProgress(1.3, marker: .5, markerLabel: 'hoje'),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('hoje'), findsOneWidget);
    expect(tester.getSemantics(find.byType(SsProgress).last).value, '130%, estourou');
  });

  testWidgets('SsTimeline e SsCountdownRing montam', (tester) async {
    await tester.pumpWidget(
      _app(
        const Column(
          children: [
            SsTimeline(
              items: [
                SsTimelineItem(title: 'Um', done: true),
                SsTimelineItem(title: 'Dois', current: true),
                SsTimelineItem(title: 'Três'),
              ],
            ),
            SsCountdownRing(total: 10, left: 2),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Dois'), findsOneWidget);
    expect(find.bySemanticsLabel('Faltam 2 de 10 dias'), findsOneWidget);
  });
}
