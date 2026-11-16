import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/src/v27/chart_markers.dart' show ssResolveMarkers, ssMarkerRows, ssMarkerColor;
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.27 · gráficos que o meulog pediu (par do Ss::LineChartComponent e do BarChartComponent).
void main() {
  Widget app(Widget child, {ThemeData? tema}) => MaterialApp(
    theme: tema ?? AppTheme.light,
    home: Scaffold(body: ListView(children: [child])),
  );

  const dias = ['01/11', '02/11', '03/11'];

  test('marcas: só as que caem nos rótulos, empilhadas no mesmo rótulo', () {
    final r = ssResolveMarkers(const [
      SsChartMarker(at: '02/11', label: 'v1'),
      SsChartMarker(at: '02/11', label: 'caiu', kind: SsChartMarkerKind.incident),
      SsChartMarker(at: '09/09', label: 'fora'),
    ], dias);
    expect(r.map((x) => (x.$1, x.$2, x.$3.label)), [(1, 1, 'v1'), (1, 2, 'caiu')]);
    expect(ssMarkerRows(r), 2);
    expect(ssMarkerRows(const []), 0);
  });

  testWidgets('marcas: cor por tipo no tema (incidente = perigo, nota = apagada)', (t) async {
    late BuildContext ctx;
    await t.pumpWidget(app(Builder(builder: (c) => (ctx = c, const SizedBox()).$2)));
    final c = SsColors.of(ctx);
    expect(ssMarkerColor(ctx, SsChartMarkerKind.incident), c.dangerText);
    expect(ssMarkerColor(ctx, SsChartMarkerKind.note), c.muted);
    expect(ssMarkerColor(ctx, SsChartMarkerKind.deploy), SsTone.info.colors(ctx).text);
  });

  testWidgets('SsLineChart: reta, tracejada e marcas, com as marcas no leitor de tela', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(
      app(
        const SsLineChart(
          curved: false,
          labels: dias,
          markers: [SsChartMarker(at: '02/11', label: 'v2.3.1')],
          series: [
            SsSeries([1, 3, 2], name: 'Agora'),
            SsSeries([1, 1, 1], name: 'Anterior', dashed: true),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('02/11: v2.3.1')), findsOneWidget);
    expect(t.takeException(), isNull);
    sem.dispose();
  });

  testWidgets('SsLineChart e SsBarChart: empty mostra o texto; sem empty, nada quebra', (t) async {
    await t.pumpWidget(app(const SsLineChart(labels: [], series: [], empty: 'Sem dados')));
    expect(find.text('Sem dados'), findsOneWidget);
    await t.pumpWidget(app(const SsBarChart(labels: [], series: [], empty: 'Nada aqui')));
    expect(find.text('Nada aqui'), findsOneWidget);
    expect(find.byType(SsChartEmpty), findsOneWidget);
  });

  testWidgets('SsBarChart(horizontal): uma linha por rótulo, reticências, dica e valor', (t) async {
    const longo = 'ActiveRecord::RecordNotFound in UsersController#show com um nome muito comprido';
    await t.pumpWidget(
      app(
        const SizedBox(
          width: 360,
          child: SsBarChart(
            horizontal: true,
            labels: [longo, 'Outros'],
            series: [
              SsSeries([120, 30], name: 'Ocorrências', colors: [null, Color(0xFF999999)]),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final rotulo = t.widget<Text>(find.text(longo));
    expect(rotulo.overflow, TextOverflow.ellipsis);
    expect(rotulo.maxLines, 1);
    expect(find.byWidgetPredicate((w) => w is Tooltip && w.message == longo), findsOneWidget);
    expect(find.text('120'), findsOneWidget);
    // Cor por valor: a 2ª barra na cor passada.
    final caixas = t
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => (d.decoration as BoxDecoration).color);
    expect(caixas, contains(const Color(0xFF999999)));
  });

  testWidgets('SsBarChart: marcas em pé no leitor de tela, e no escuro', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(
      app(
        const SsBarChart(
          labels: dias,
          markers: [SsChartMarker(at: '03/11', label: 'migração', kind: SsChartMarkerKind.note)],
          series: [
            SsSeries([1, 2, 3], name: 'a'),
          ],
        ),
        tema: AppTheme.dark,
      ),
    );
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel(RegExp('03/11: migração')), findsOneWidget);
    sem.dispose();
  });
}
