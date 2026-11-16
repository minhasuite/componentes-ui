import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/src/v15/bar_chart.dart' show ssBarRange;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.28 · a segunda rodada do meulog (par do Ss::DayStripComponent, dos max: dos gráficos, do
// subtitle_wrap: do ListItem e do qr_label: do QrCard).
void main() {
  Widget app(Widget child, {ThemeData? tema}) => MaterialApp(
    theme: tema ?? AppTheme.light,
    localizationsDelegates: const [SsStrings.delegate],
    home: Scaffold(body: ListView(children: [child])),
  );

  test('ssBarRange(max:): o topo é o max (pequenos múltiplos na mesma escala); valor acima alarga', () {
    final (lo, hi) = ssBarRange(
      const [
        SsSeries([3, 5]),
      ],
      2,
      max: 40,
    );
    expect((lo, hi), (0.0, 40.0));
    final (_, hi2) = ssBarRange(
      const [
        SsSeries([3, 50]),
      ],
      2,
      max: 40,
    );
    expect(hi2, 50.0);
    final (_, hi3) = ssBarRange(const [
      SsSeries([3, 5]),
    ], 2);
    expect(hi3, closeTo(5.4, .001));
  });

  testWidgets('SsBarChart e SsLineChart aceitam max:', (t) async {
    await t.pumpWidget(
      app(
        const Column(
          children: [
            SsBarChart(
              labels: ['a', 'b'],
              series: [
                SsSeries([1, 2], name: 'x'),
              ],
              max: 10,
            ),
            SsLineChart(
              labels: ['a', 'b'],
              series: [
                SsSeries([1, 2], name: 'x'),
              ],
              max: 10,
              curved: false,
            ),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('SsDayStrip: um traço por dia, dica por dia e resumo para o leitor de tela', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(
      app(
        const SsDayStrip(
          title: 'Disponibilidade',
          startLabel: 'há 4 dias',
          endLabel: 'hoje',
          days: [
            SsDay('01/11', SsDayTone.ok, text: '100%'),
            SsDay('02/11', SsDayTone.warn, text: '2 falhas'),
            SsDay('03/11', SsDayTone.bad, text: 'fora 3 h'),
            SsDay('04/11', SsDayTone.none),
          ],
        ),
      ),
    );
    expect(find.byType(SsTooltip), findsNWidgets(4));
    expect(find.text('há 4 dias'), findsOneWidget);
    expect(find.text('hoje'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp(r'^Disponibilidade: 4 · (Fora|Down) 1 · (Instável|Unstable) 1$')),
      findsOneWidget,
    );
    sem.dispose();
  });

  testWidgets('SsDayStrip vazio não desenha nada', (t) async {
    await t.pumpWidget(app(const SsDayStrip(title: 'x', days: [])));
    expect(find.byType(SsTooltip), findsNothing);
  });

  testWidgets('SsListItem(subtitleMaxLines:) mostra o subtítulo inteiro', (t) async {
    await t.pumpWidget(app(const SsListItem(title: 'Item', subtitle: 'um subtítulo comprido', subtitleMaxLines: 3)));
    final sub = t.widget<Text>(find.text('um subtítulo comprido'));
    expect(sub.maxLines, 3);
    await t.pumpWidget(app(const SsListItem(title: 'Item', subtitle: 'curto')));
    expect(t.widget<Text>(find.text('curto')).maxLines, 1);
  });

  testWidgets('SsQrCard(qrLabel:) dá nome ao QR para o leitor de tela', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(app(const SsQrCard(qr: SizedBox(), qrLabel: 'QR do autenticador')));
    expect(find.bySemanticsLabel('QR do autenticador'), findsOneWidget);
    await t.pumpWidget(app(const SsQrCard(qr: SizedBox())));
    // Sem qrLabel, o texto do idioma (o teste roda em inglês: "QR code").
    expect(find.bySemanticsLabel(RegExp(r'^QR [Cc]ode$')), findsOneWidget);
    sem.dispose();
  });

  test('SsStrings: os textos novos nos três idiomas', () {
    expect(SsStrings.pt.dayStripBad, 'Fora');
    expect(SsStrings.en.dayStripBad, 'Down');
    expect(SsStrings.es.qrLabel, 'Código QR');
  });
}
