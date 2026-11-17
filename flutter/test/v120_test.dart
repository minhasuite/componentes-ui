// v1.2: o que a auditoria de UX (V02, U03) do minhas-vendas achou nas peças
// genéricas, lado Flutter: a linha compacta do SsRepeater no celular e os
// rótulos do eixo X do SsBarChart que colavam no vizinho do ativo.
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {double width = 360, SsStrings? strings}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate],
  home: SsStringsScope(
    strings: strings ?? SsStrings.pt,
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  ),
);

Widget _campo(String rotulo) => Builder(
  builder: (context) =>
      SsTextField(key: ValueKey('f-$rotulo'), label: rotulo, hideLabel: !SsRepeater.compactOf(context)),
);

Widget _pedido({SsRepeaterMobile mobile = SsRepeaterMobile.compact, bool detailsOpen = false}) => SsRepeater(
  mobile: mobile,
  itemCount: 1,
  header: const ['Produto', 'Descrição', 'Qtd', 'Unitário', 'Desc.', 'Total'],
  flex: const [4, 2, 1, 2, 1, 2],
  onRemove: (_) {},
  itemBuilder: (_, i) => SsRepeater.cells(
    [
      SsRepeaterCell(_campo('Produto')),
      SsRepeaterCell(_campo('Descrição'), role: SsRepeaterRole.detail),
      SsRepeaterCell(_campo('Qtd'), role: SsRepeaterRole.inline),
      SsRepeaterCell(_campo('Unitário'), role: SsRepeaterRole.inline),
      SsRepeaterCell(_campo('Desc.'), role: SsRepeaterRole.detail),
      const SsRepeaterCell(Text('R\$ 10,00'), role: SsRepeaterRole.inline),
    ],
    flex: const [4, 2, 1, 2, 1, 2],
    detailsOpen: detailsOpen,
  ),
);

double _left(WidgetTester t, String rotulo) => t.getTopLeft(find.byKey(ValueKey('f-$rotulo'))).dx;
double _top(WidgetTester t, String rotulo) => t.getTopLeft(find.byKey(ValueKey('f-$rotulo'))).dy;

void main() {
  group('SsRepeater(mobile: compact) v1.2', () {
    testWidgets('em 360: produto inteiro, qtd × preço × total numa linha, detalhes recolhidos atrás do Detalhes', (
      t,
    ) async {
      await t.pumpWidget(_app(_pedido()));
      // Sem o cabeçalho (os rótulos dos campos voltam).
      expect(find.text('PRODUTO'), findsNothing);
      expect(find.text('Produto'), findsWidgets);
      // Qtd e Unitário na mesma linha, embaixo do produto.
      expect(_top(t, 'Qtd'), _top(t, 'Unitário'));
      expect(_top(t, 'Qtd'), greaterThan(_top(t, 'Produto')));
      expect(_left(t, 'Unitário'), greaterThan(_left(t, 'Qtd')));
      // Detalhes fechados: descrição e desconto montados, mas fora da vista.
      expect(find.byKey(const ValueKey('f-Descrição')).hitTestable(), findsNothing);
      expect(find.text('Detalhes'), findsOneWidget);
      await t.tap(find.text('Detalhes'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('f-Descrição')).hitTestable(), findsOneWidget);
      expect(_top(t, 'Descrição'), greaterThan(_top(t, 'Qtd')));
      await t.tap(find.text('Detalhes'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('f-Descrição')).hitTestable(), findsNothing);
    });

    testWidgets('detailsOpen: true deixa aberto; texto em en/es', (t) async {
      await t.pumpWidget(_app(_pedido(detailsOpen: true), strings: SsStrings.en));
      expect(find.byKey(const ValueKey('f-Descrição')).hitTestable(), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);
      await t.pumpWidget(_app(_pedido(), strings: SsStrings.es));
      expect(find.text('Detalles'), findsOneWidget);
    });

    testWidgets('em tela larga (e sem mobile:) as colunas de sempre: cabeçalho, tudo numa linha, sem Detalhes', (
      t,
    ) async {
      await t.pumpWidget(_app(_pedido(), width: 900));
      expect(find.text('PRODUTO'), findsOneWidget);
      expect(find.text('Detalhes'), findsNothing);
      expect(_top(t, 'Produto'), _top(t, 'Descrição'));
      expect(_top(t, 'Produto'), _top(t, 'Qtd'));
      await t.pumpWidget(_app(_pedido(mobile: SsRepeaterMobile.row)));
      expect(find.text('Detalhes'), findsNothing);
      expect(_top(t, 'Produto'), _top(t, 'Qtd'));
    });
  });

  group('SsBarChart: rótulos do eixo X v1.2', () {
    const meses = ['DEZ', 'JAN', 'FEV', 'MAR', 'ABR', 'MAI', 'JUN', 'JUL', 'AGO', 'SET', 'OUT', 'NOV'];

    // Quantos textos o desenho das barras escreve (rótulos do eixo + valores das guias).
    Future<int> textos(WidgetTester t, List<String> labels, {int? active, double width = 320}) async {
      await t.pumpWidget(
        _app(
          SsBarChart(
            labels: labels,
            series: [
              SsSeries([for (var i = 0; i < labels.length; i++) 10.0 + i], name: 'Faturamento'),
            ],
            active: active,
            legend: false,
          ),
          width: width,
        ),
      );
      await t.pumpAndSettle();
      var n = 0;
      for (final e in find.descendant(of: find.byType(SsBarChart), matching: find.byType(CustomPaint)).evaluate()) {
        final p = (e.widget as CustomPaint).painter;
        if (p == null) continue;
        expect(
          e.renderObject,
          paints..everything((m, a) {
            if (m == #drawParagraph) n++;
            return true;
          }),
        );
      }
      return n;
    }

    testWidgets('o mês ativo não ganha um vizinho colado: a contagem parte dele', (t) async {
      final semAtivo = await textos(t, meses);
      final comAtivo = await textos(t, meses, active: 11);
      expect(comAtivo, semAtivo);
    });

    testWidgets('rótulo largo ("Seg 10/11") sai de N em N em vez de cortar em "Se…"', (t) async {
      final curtos = await textos(t, ['a', 'b', 'c', 'd', 'e', 'f', 'g']);
      final longos = await textos(t, [
        'Seg 10/11',
        'Ter 11/11',
        'Qua 12/11',
        'Qui 13/11',
        'Sex 14/11',
        'Sáb 15/11',
        'Dom 16/11',
      ]);
      expect(curtos - longos, greaterThanOrEqualTo(3));
    });

    test('ssAxisLabelStep: largura do maior rótulo + respiro, dividida pelo grupo', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      const style = TextStyle(fontSize: 10);
      expect(ssAxisLabelStep(const [], slot: 20, style: style), 1);
      expect(ssAxisLabelStep(meses, slot: 200, style: style), 1);
      expect(ssAxisLabelStep(meses, slot: 10, style: style), greaterThan(2));
    });
  });
}
