// v1.14.5: peças de medida e cartões de dado sem estourar com o texto em 1,6x (o ssA11yAudit completo), em
// cartão estreito (duas colunas no celular) e largo. Começou pela legenda do SsGauge no painel da minha-automacao.
import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

/// [peca] recebe a largura que sobra dentro do cartão (como o app faz com o LayoutBuilder).
Widget _app(Widget Function(double largura) peca, double largura) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Scaffold(
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: largura,
          child: SsCard(child: LayoutBuilder(builder: (_, box) => peca(box.maxWidth))),
        ),
      ),
    ),
  ),
);

/// As peças, cada uma com textos do tamanho dos que os apps usam.
final Map<String, Widget Function(double largura)> _pecas = {
  'SsGauge (legenda e faixa longas)': (w) => SsGauge(
    value: .62,
    width: w.clamp(80, 200).toDouble(),
    bands: const [(1.0, 'Consumo da casa agora', AppColors.success)],
    label: 'Medidor de energia da cozinha',
    center: const Text('3,2 kW'),
  ),
  'SsGauge (faixas padrão)': (w) => SsGauge(value: .9, width: w.clamp(80, 200).toDouble(), label: 'Preço do café'),
  'SsBigRing': (w) => SsBigRing(.72, caption: 'da meta do mês atingida', size: w.clamp(80, 200).toDouble()),
  'SsRings': (w) =>
      SsRings(const [SsRing(.8), SsRing(.5), SsRing(.3)], size: w.clamp(80, 128).toDouble(), center: const Text('80%')),
  'SsThermostat': (w) => SsThermostat(
    target: 21.5,
    current: 19,
    onChanged: (_) {},
    onModeChanged: (_) {},
    label: 'Ar-condicionado da sala',
    size: w.clamp(120, 280).toDouble(),
  ),
  'SsKpiCard': (w) => SsKpiCard(
    label: 'Gasto do mês com energia',
    value: r'R$ 1.312,75',
    caption: '01/11 a 30/11, comparado ao mês passado',
    icon: Icons.bolt,
    delta: const SsDelta('12%', up: true, good: false),
    onTap: () {},
  ),
  'SsStatCard': (w) => SsStatCard(
    label: 'Vendas de hoje no balcão',
    value: r'R$ 12.480,00',
    caption: 'até as 15h',
    icon: Icons.point_of_sale,
    delta: const SsDelta('8%', up: true),
    onTap: () {},
  ),
  'SsDuoStat': (w) => SsDuoStat(
    items: const [SsDuoItem('Despesas do mês', r'R$ 4.320,00'), SsDuoItem('Receitas do mês', r'R$ 6.900,00')],
    index: 0,
    onChanged: (_) {},
  ),
  'SsValueTile': (w) => SsValueTile(
    title: 'Conta de luz de novembro',
    subtitle: 'Vence em 10/12',
    value: r'R$ 312,75',
    valueNote: 'em aberto',
    leading: const Icon(Icons.receipt_long),
    onTap: () {},
  ),
  'SsProgressRow': (w) => SsProgressRow(
    label: 'Mercado e padaria',
    value: 820,
    limit: 1000,
    icon: Icons.shopping_cart,
    caption: 'faltam 9 dias',
    onTap: () {},
  ),
};

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('versão 1.14.6', () {
    expect(ssComponentesUiVersion, '1.14.6');
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: 1.14.6'));
  });

  for (final largura in [150.0, 328.0]) {
    group('cartão de $largura', () {
      _pecas.forEach((nome, peca) {
        testWidgets('$nome passa no ssA11yAudit com o texto em 1,6x', (t) async {
          await t.pumpWidget(_app(peca, largura));
          await t.pumpAndSettle();
          await ssA11yAudit(t);
        });
      });
    });
  }
}
