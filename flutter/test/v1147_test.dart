// v1.14.7 · gráficos com tudo zero (visto no SsBarChart do meu-tempo-app: 7 dias sem uso) e a escala redonda de
// todas as peças (SsChartScale). Os casos da escala são os mesmos do rails/sample/test/components/v1_14_7_web_test.rb.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

// Sem delegate: o SsStrings cai no pt.
Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SingleChildScrollView(child: SizedBox(width: 390, child: child)),
  ),
);

const _dias = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
const _zeros = <double>[0, 0, 0, 0, 0, 0, 0];
const _vazio = 'Sem dados no período';

// O formatter do app que arredonda (minutos inteiros): o que fazia o eixo dizer "1 min, 1 min".
String _min(double v) => '${v.round()} min';

/// O pintor de um gráfico (para ler as guias que ele recebeu).
dynamic _pintor(WidgetTester t, String tipo) => t
    .widgetList<CustomPaint>(find.byType(CustomPaint))
    .map((w) => w.painter)
    .firstWhere((p) => p.runtimeType.toString() == tipo);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('versão 1.14.7', () {
    expect(ssComponentesUiVersion, '1.14.7');
  });

  group('SsChartScale (os mesmos casos do ComponentesUi::ChartScale)', () {
    test('passo redondo: 1, 2, 2,5, 5 × 10ⁿ', () {
      expect(SsChartScale.niceStep(.7), 1);
      expect(SsChartScale.niceStep(1.2), 2);
      expect(SsChartScale.niceStep(2.2), 2.5);
      expect(SsChartScale.niceStep(3), 5);
      expect(SsChartScale.niceStep(7), 10);
      expect(SsChartScale.niceStep(.0013), .002);
      expect(SsChartScale.nextStep(2), 2.5);
      expect(SsChartScale.nextStep(5), 10);
    });

    test('tudo zero: 0 a 1, sem guia repetida', () {
      final e = SsChartScale.of(0, 0);
      expect((e.lo, e.hi), (0.0, 1.0));
      expect(e.ticks, [0.0, .5, 1.0]);
    });

    test('todos iguais (3): de 0 a 3, de 1 em 1; sem o zero, em volta do 3', () {
      expect(SsChartScale.of(3, 3).ticks, [0.0, 1.0, 2.0, 3.0]);
      expect(SsChartScale.of(3, 3, zero: false).ticks, [2.5, 3.0, 3.5]);
    });

    test('um só valor (7): de 2,5 em 2,5', () {
      final e = SsChartScale.of(0, 7);
      expect((e.hi, e.step), (7.5, 2.5));
      expect(e.ticks, [0.0, 2.5, 5.0, 7.5]);
    });

    test('valores minúsculos: passo redondo e sem ruído do ponto flutuante', () {
      expect(SsChartScale.of(0, .003).ticks, [0.0, .001, .002, .003]);
      expect(SsChartScale.of(0, .3).ticks, [0.0, .1, .2, .3]);
    });

    test('negativo: o zero dentro, até 3 faixas', () {
      expect(SsChartScale.of(-250, 100).ticks, [-400.0, -200.0, 0.0, 200.0]);
      expect(SsChartScale.of(-250, 100).guides, [-400.0, -200.0, 200.0]);
    });

    test('formatter que arredonda: o passo cresce até nenhum rótulo repetir', () {
      expect(SsChartScale.of(0, 1, format: _min).ticks, [0.0, 1.0]);
      expect(SsChartScale.of(0, .4, format: _min).ticks, [0.0, .5]);
      final e = SsChartScale.of(0, 1, format: _min);
      expect(e.ticks.map(_min).toSet().length, e.ticks.length);
    });

    test('max: é o topo mínimo; valor acima alarga', () {
      expect(SsChartScale.of(3, 5, top: 40).ticks, [0.0, 20.0, 40.0]);
      expect(SsChartScale.of(3, 50, top: 40).hi, 60);
    });

    test('casas decimais do passo e tudo zero', () {
      expect([2.5, .25, .001, 50.0, 1.0].map(SsChartScale.decimals), [1, 2, 3, 0, 0]);
      expect(SsChartScale.allZero([0, null, 0]), isTrue);
      expect(SsChartScale.allZero(const []), isTrue);
      expect(SsChartScale.allZero([0, .01]), isFalse);
    });
  });

  group('SsBarChart com tudo zero', () {
    testWidgets('mostra o vazio de sempre (empty:, ou o padrão)', (t) async {
      await t.pumpWidget(
        _app(
          const SsBarChart(
            labels: _dias,
            series: [SsSeries(_zeros, name: 'Uso')],
            empty: 'Sem uso nesta semana',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(SsChartEmpty), findsOneWidget);
      expect(find.text('Sem uso nesta semana'), findsOneWidget);

      await t.pumpWidget(_app(const SsBarChart(labels: _dias, series: [SsSeries(_zeros)])));
      await t.pumpAndSettle();
      expect(find.text(_vazio), findsOneWidget);
    });

    testWidgets('a linha ou a projeção com valor não é vazio', (t) async {
      await t.pumpWidget(
        _app(const SsBarChart(labels: _dias, series: [SsSeries(_zeros)], line: SsSeries([0, 0, 2, 0, 0, 0, 0]))),
      );
      await t.pumpAndSettle();
      expect(find.byType(SsChartEmpty), findsNothing);
    });

    testWidgets('treatZeroAsEmpty: false desenha as barras no chão', (t) async {
      await t.pumpWidget(
        _app(const SsBarChart(labels: _dias, series: [SsSeries(_zeros)], treatZeroAsEmpty: false, format: _min)),
      );
      await t.pumpAndSettle();
      expect(find.byType(SsChartEmpty), findsNothing);
      final p = _pintor(t, '_BarPainter');
      final guias = List<double>.from(p.guides as List);
      expect(guias.map(_min).toSet().length, guias.length);
    });

    testWidgets('guias redondas e sem "1 min, 1 min" com o formatter que arredonda', (t) async {
      await t.pumpWidget(
        _app(
          const SsBarChart(
            labels: _dias,
            series: [
              SsSeries([1, 0, 0, 1, 0, 0, 0]),
            ],
            format: _min,
          ),
        ),
      );
      await t.pumpAndSettle();
      final p = _pintor(t, '_BarPainter');
      expect(p.hi, 1.0);
      expect(p.guides, [1.0]);
    });

    testWidgets('todos iguais e um só valor: topo redondo', (t) async {
      await t.pumpWidget(
        _app(
          const SsBarChart(
            labels: ['a', 'b', 'c'],
            series: [
              SsSeries([3, 3, 3]),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(_pintor(t, '_BarPainter').guides, [1.0, 2.0, 3.0]);

      await t.pumpWidget(
        _app(
          const SsBarChart(
            labels: ['a'],
            series: [
              SsSeries([7]),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(_pintor(t, '_BarPainter').guides, [2.5, 5.0, 7.5]);
    });
  });

  group('as peças irmãs com tudo zero', () {
    testWidgets('SsLineChart: vazio; com valor, guias redondas sem repetir', (t) async {
      await t.pumpWidget(_app(const SsLineChart(labels: _dias, series: [SsSeries(_zeros)])));
      await t.pumpAndSettle();
      expect(find.text(_vazio), findsOneWidget);

      await t.pumpWidget(
        _app(
          const SsLineChart(
            labels: ['a', 'b', 'c'],
            format: _min,
            series: [
              SsSeries([.2, .4, .3]),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      final ticks = List<double>.from(_pintor(t, '_LinePainter').ticks as List);
      expect(ticks.map(_min).toSet().length, ticks.length);

      await t.pumpWidget(_app(const SsLineChart(labels: _dias, series: [SsSeries(_zeros)], treatZeroAsEmpty: false)));
      await t.pumpAndSettle();
      expect(find.byType(SsChartEmpty), findsNothing);
    });

    testWidgets('SsAreaChart, SsPillBars, SsFloatingBars e SsExplodedDonut: vazio', (t) async {
      await t.pumpWidget(_app(SsAreaChart(values: _zeros, labels: _dias)));
      await t.pumpAndSettle();
      expect(find.text(_vazio), findsOneWidget);

      await t.pumpWidget(_app(SsPillBars(values: _zeros, labels: _dias, empty: 'Nada hoje')));
      await t.pumpAndSettle();
      expect(find.text('Nada hoje'), findsOneWidget);

      await t.pumpWidget(_app(SsFloatingBars(values: _zeros, labels: _dias, title: 'Gastos')));
      await t.pumpAndSettle();
      expect(find.text(_vazio), findsOneWidget);
      expect(find.text('Gastos'), findsOneWidget);

      await t.pumpWidget(_app(const SsExplodedDonut(slices: [SsDonutSlice('Mercado', 0), SsDonutSlice('Lazer', 0)])));
      await t.pumpAndSettle();
      expect(find.text(_vazio), findsOneWidget);

      await t.pumpWidget(_app(SsPillBars(values: _zeros, labels: _dias, treatZeroAsEmpty: false)));
      await t.pumpAndSettle();
      expect(find.byType(SsChartEmpty), findsNothing);
    });

    testWidgets('SsDivergingBars: tudo zero é vazio; um negativo só vai inteiro para a esquerda', (t) async {
      await t.pumpWidget(_app(const SsDivergingBars(items: [SsDivergingBar('Café', 0), SsDivergingBar('Tomate', 0)])));
      await t.pumpAndSettle();
      expect(find.text(_vazio), findsOneWidget);

      await t.pumpWidget(_app(const SsDivergingBars(items: [SsDivergingBar('Tomate', -.6)])));
      await t.pumpAndSettle();
      expect(find.byType(SsChartEmpty), findsNothing);
      expect(find.text('−0,6'), findsOneWidget);
      expect(_pintor(t, '_Divergente').fracao, -1.0);
    });

    testWidgets('SsPeriodCompare: os dois períodos zero mostram o vazio, sem a legenda', (t) async {
      await t.pumpWidget(_app(SsPeriodCompare(labels: _dias, current: _zeros, previous: _zeros, empty: 'Sem gastos')));
      await t.pumpAndSettle();
      expect(find.text('Sem gastos'), findsOneWidget);
      expect(find.byType(SsChartLegend), findsNothing);
    });

    testWidgets('SsTimeChart: só leituras zero é o vazio', (t) async {
      final t0 = DateTime(2026, 11, 20, 8);
      final pts = [for (var i = 0; i < 5; i++) SsTimePoint(t0.add(Duration(hours: i)), 0)];
      await t.pumpWidget(
        _app(
          SsTimeChart(
            series: [SsTimeSeries(name: 'Uso', points: pts)],
            emptyText: 'Sem uso',
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Sem uso'), findsOneWidget);
    });
  });
}
