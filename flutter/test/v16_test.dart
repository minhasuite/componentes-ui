// v0.16: o que a migração do minhas-compras e do minhas-viagens pediu (etapa 5): legenda,
// oferta completa, chip removível, série em variante de texto, alto contraste, cabeçalho com
// capa, escolha com texto livre, calendário público, barras divergentes, validadores de texto,
// foto com cor, linha do tempo com fim e alerta, estrelas, comparação e os ajustes pedidos.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child, {ThemeData? theme, double scale = 1}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)),
      child: Scaffold(body: child),
    ),
  ),
);

Color _cor(WidgetTester t, String texto) => t.widget<Text>(find.text(texto)).style!.color!;

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsChartLegend', () {
    testWidgets('cor + rótulo + valor, sem repetir, e reticências na largura', (t) async {
      await t.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 150,
              child: SsChartLegend(
                items: [
                  SsLegendItem('Atacadão Centro da Cidade Grande', Color(0xFF3B82F6)),
                  SsLegendItem('menor', AppColors.success, value: 'R\$ 2.148'),
                  SsLegendItem('alvo', AppColors.mutedLight, value: 'R\$ 1.990', line: true, dashed: true),
                  SsLegendItem('menor', AppColors.success, value: 'R\$ 2.148'),
                ],
              ),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('menor'), findsOneWidget);
      expect(find.text('R\$ 1.990'), findsOneWidget);
      expect(t.widget<Text>(find.text('Atacadão Centro da Cidade Grande')).overflow, TextOverflow.ellipsis);
      expect(find.bySemanticsLabel('alvo: R\$ 1.990'), findsOneWidget);
    });
  });

  group('SsOfferCard v0.16', () {
    testWidgets('selos, meta, ações, menu e preço no alvo sem quebrar o uso antigo', (t) async {
      var viu = 0;
      await t.pumpWidget(
        _app(
          ListView(
            children: [
              const SsOfferCard(source: 'Magalu', title: 'Air Fryer', price: 'R\$ 359,00'),
              SsOfferCard(
                source: 'Mercado Livre',
                title: 'Fone JBL',
                price: 'R\$ 219,90',
                note: 'à vista · ou 10x R\$ 23,90',
                hit: true,
                badges: const [SsBadge('promoção de verdade', variant: SsBadgeVariant.success, micro: true)],
                meta: 'verificado 12/10/2026 14:00',
                actions: [SsButton.text(label: 'Ver oferta', onPressed: () => viu++)],
                menu: SsOverflowMenu(items: [SsMenuAction(Icons.flag_outlined, 'Reportar', () {})]),
              ),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('PROMOÇÃO DE VERDADE'), findsOneWidget);
      expect(find.text('verificado 12/10/2026 14:00'), findsOneWidget);
      expect(_cor(t, 'R\$ 219,90'), SsColors.forDark(false).successText);
      expect(_cor(t, 'R\$ 359,00'), AppColors.inkLight);
      await t.tap(find.text('Ver oferta'));
      expect(viu, 1);
      expect(find.byType(SsOverflowMenu), findsOneWidget);
      expect(find.text('MAIS BARATA'), findsNothing);
    });

    testWidgets('tipo, estimativa (≈ e tracejado), unidade, economia e fill numa fileira', (t) async {
      await t.pumpWidget(
        _app(
          Row(
            children: [
              const SizedBox(
                width: 190,
                height: 260,
                child: SsOfferCard(
                  source: 'CVC',
                  kind: 'Pacote (voo + hotel)',
                  title: 'Viasui Hotel · café da manhã',
                  price: 'R\$ 7.808,00',
                  unit: 'R\$ 3.904,00 por pessoa',
                  savings: 'R\$ 112,00 abaixo do alvo',
                  best: true,
                  fill: true,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 190,
                height: 260,
                child: SsOfferCard(
                  source: 'Kayak + Booking',
                  kind: 'voo + hospedagem',
                  title: 'Voo + hotel mais baratos',
                  price: 'R\$ 8.120,00',
                  estimate: true,
                  savings: '+R\$ 312,00 que a mais barata',
                  savingsGood: false,
                  fill: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('PACOTE (VOO + HOTEL)'), findsOneWidget);
      expect(find.text('ESTIMATIVA · VOO + HOSPEDAGEM'), findsOneWidget);
      expect(find.text('≈ R\$ 8.120,00'), findsOneWidget);
      expect(find.text('R\$ 3.904,00 por pessoa'), findsOneWidget);
      expect(_cor(t, 'R\$ 112,00 abaixo do alvo'), SsColors.forDark(false).successText);
      expect(_cor(t, '+R\$ 312,00 que a mais barata'), AppColors.mutedLight);
      // fill: o preço desce para a base do cartão.
      final base = t.getRect(find.byType(SsOfferCard).first).bottom;
      expect(base - t.getRect(find.text('R\$ 112,00 abaixo do alvo')).bottom, lessThan(24));
      expect(
        find.bySemanticsLabel(RegExp(r'^Kayak \+ Booking, Estimativa · voo \+ hospedagem, .*≈ R\$ 8\.120,00')),
        findsOneWidget,
      );
    });
  });

  group('SsInputChip', () {
    testWidgets('✕ tira, toque edita, sem onDeleted não tem ✕ e rótulo longo termina em …', (t) async {
      var tirou = 0, editou = 0;
      await t.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 140,
              child: Wrap(
                children: [
                  SsInputChip(
                    'Lisboa, Portugal, Europa Ocidental',
                    icon: Icons.place_outlined,
                    onPressed: () => editou++,
                    onDeleted: () => tirou++,
                  ),
                  const SsInputChip('Porto'),
                ],
              ),
            ),
          ),
          scale: 1.3,
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byTooltip('Remover Lisboa, Portugal, Europa Ocidental'), findsOneWidget);
      await t.tap(find.byIcon(Icons.close_rounded));
      await t.tap(find.text('Lisboa, Portugal, Europa Ocidental'));
      expect((tirou, editou), (1, 1));
      expect(t.getSize(find.byType(SsInputChip).first).width, lessThanOrEqualTo(140));
    });
  });

  group('série em variante de texto e alto contraste', () {
    test('seriesInk passa 4,5:1 sobre superfície, página e campo nas 30 paletas, claro e escuro', () {
      for (final p in SsPaleta.todas) {
        for (final dark in [false, true]) {
          final c = SsColors.forDark(dark, p.brand);
          expect(c.seriesInk, hasLength(c.series.length));
          for (final ink in c.seriesInk) {
            for (final bg in [c.surface, c.page, c.field]) {
              expect(ssContrast(ink, bg), greaterThanOrEqualTo(4.5), reason: '${p.slug} dark=$dark $ink');
            }
          }
        }
      }
      // Já passando, a cor volta a mesma.
      final c = SsColors.forDark(false);
      expect(c.inkFor(AppColors.inkLight), AppColors.inkLight);
    });

    test('SsBrand.highContrast: accent a 7:1 nos fundos e sólido a 7:1 com branco, nas 30 paletas', () {
      for (final p in SsPaleta.todas) {
        final hc = p.brand.highContrast();
        for (final bg in [AppColors.surfaceLight, AppColors.pageLight, AppColors.fieldLight, hc.accentSoftLight]) {
          expect(ssContrast(hc.accentLight, bg), greaterThanOrEqualTo(7), reason: '${p.slug} claro');
        }
        for (final bg in [AppColors.surfaceDark, AppColors.pageDark, AppColors.pageOled, hc.accentSoftDark]) {
          expect(ssContrast(hc.accentDark, bg), greaterThanOrEqualTo(7), reason: '${p.slug} escuro');
        }
        expect(ssContrast(hc.accentSolidLight, AppColors.onDark), greaterThanOrEqualTo(7));
        expect(ssContrast(hc.accentSolidDark, AppColors.onDark), greaterThanOrEqualTo(7));
        expect(hc.gradientColors, p.brand.gradientColors);
      }
    });

    testWidgets('AppTheme.build(highContrast: true): SsColors com acento forte, muted no ink2 e linha forte', (
      t,
    ) async {
      late SsColors c;
      final tema = AppTheme.build(Brightness.light, brand: SsBrand.petroleo, highContrast: true);
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              c = SsColors.of(context);
              return const SizedBox();
            },
          ),
          theme: tema,
        ),
      );
      expect(c.isHighContrast, isTrue);
      expect(c.accent, SsBrand.petroleo.highContrast().accentLight);
      expect(ssContrast(c.accent, c.page), greaterThanOrEqualTo(7));
      expect(c.muted, AppColors.ink2Light);
      expect(ssContrast(c.muted, c.page), greaterThanOrEqualTo(7));
      expect(c.line.a, greaterThan(AppColors.lineLight.a));
      expect(tema.colorScheme.onSurfaceVariant, AppColors.ink2Light);
      expect(SsColors.forDark(false).isHighContrast, isFalse);
      final escuro = AppTheme.build(Brightness.dark, brand: SsBrand.petroleo, highContrast: true);
      expect(escuro.colorScheme.primary, SsBrand.petroleo.highContrast().accentDark);
    });
  });

  group('SsSliverHeader(background:)', () {
    testWidgets('capa no lugar do título grande, título sempre na barra, abas presas', (t) async {
      final scroll = ScrollController();
      await t.pumpWidget(
        _app(
          CustomScrollView(
            controller: scroll,
            slivers: [
              SsSliverHeader(
                title: 'Lisboa em maio',
                background: const ColoredBox(
                  color: Color(0xFF0E7C86),
                  child: Center(child: Text('capa')),
                ),
                backgroundHeight: 160,
                bottom: SsTabsUnderline(tabs: const ['Cronograma', 'Gastos'], index: 0, onChanged: (_) {}),
              ),
              SliverList.list(children: [for (var i = 0; i < 40; i++) SizedBox(height: 60, child: Text('linha $i'))]),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('capa'), findsOneWidget);
      expect(find.text('Lisboa em maio'), findsOneWidget);
      final abasAntes = t.getRect(find.text('Cronograma')).top;
      scroll.jumpTo(600);
      await t.pump();
      expect(find.text('Lisboa em maio'), findsOneWidget);
      expect(find.text('Cronograma'), findsOneWidget);
      expect(t.getRect(find.text('Cronograma')).top, lessThan(abasAntes));
      expect(t.takeException(), isNull);
    });
  });

  group('showSsPicker(allowCustom:)', () {
    Future<void> abre(WidgetTester t, void Function(String?) onResult, {String? noneLabel}) async {
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => onResult(
                await showSsPicker<String>(
                  context,
                  title: 'Onde comprou?',
                  items: const ['Atacadão', 'Carrefour'],
                  allowCustom: true,
                  noneLabel: noneLabel,
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
    }

    testWidgets('texto novo vira "Usar “…”" e volta como escolha; igual a um item não repete', (t) async {
      String? r = 'x';
      await abre(t, (v) => r = v);
      await t.enterText(find.byType(TextField), 'Feira do bairro');
      await t.pumpAndSettle();
      expect(find.text('Usar “Feira do bairro”'), findsOneWidget);
      await t.tap(find.text('Usar “Feira do bairro”'));
      await t.pumpAndSettle();
      expect(r, 'Feira do bairro');

      await abre(t, (v) => r = v);
      await t.enterText(find.byType(TextField), 'atacadao');
      await t.pumpAndSettle();
      expect(find.textContaining('Usar'), findsNothing);
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pumpAndSettle();
      expect(r, 'Atacadão');
    });

    testWidgets('noneLabel devolve texto vazio', (t) async {
      String? r;
      await abre(t, (v) => r = v, noneLabel: 'Sem loja');
      await t.tap(find.text('Sem loja'));
      await t.pumpAndSettle();
      expect(r, '');
    });
  });

  group('showSsDatePicker', () {
    testWidgets('textos do pacote, data inicial presa no intervalo e devolve o dia', (t) async {
      DateTime? r;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt', 'BR'),
          supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
          localizationsDelegates: const [
            SsStrings.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async => r = await showSsDatePicker(
                  context,
                  initialDate: DateTime(2020, 1, 1),
                  firstDate: DateTime(2026, 11, 3),
                  lastDate: DateTime(2026, 11, 30),
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Escolher data'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      await t.tap(find.text('Confirmar'));
      await t.pumpAndSettle();
      expect(r, DateTime(2026, 11, 3));
    });
  });

  group('SsDivergingBars', () {
    testWidgets('sinal no idioma, unidade e cor pelo sentido', (t) async {
      await t.pumpWidget(
        _app(
          const Padding(
            padding: EdgeInsets.all(16),
            child: SsDivergingBars(
              unit: 'p.p.',
              items: [
                SsDivergingBar('Café torrado', 1.8, detail: '+32% · 9% da cesta'),
                SsDivergingBar('Tomate', -0.6),
                SsDivergingBar('Arroz', 0),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      final c = SsColors.forDark(false);
      expect(_cor(t, '+1,8 p.p.'), c.dangerText);
      expect(_cor(t, '−0,6 p.p.'), c.successText);
      expect(_cor(t, '0 p.p.'), c.muted);
      expect(find.bySemanticsLabel('Café torrado: +1,8 p.p., +32% · 9% da cesta'), findsOneWidget);
      expect(SsDivergingBars.signed(-2.25, SsFormats.usd), '−2.3');
    });
  });

  group('SsValidators', () {
    test('qty: vazio, inválido, negativo e zero', () {
      expect(SsValidators.qty(''), 'Informe a quantidade');
      expect(SsValidators.qty('', required: false), isNull);
      expect(SsValidators.qty('abc'), 'Número inválido');
      expect(SsValidators.qty('-1'), 'Não pode ser negativo');
      expect(SsValidators.qty('0'), isNull);
      expect(SsValidators.qty('0', allowZero: false), 'Precisa ser maior que zero');
      expect(SsValidators.qty('1,5'), isNull);
      expect(SsValidators.qty('2.25'), isNull);
      expect(SsValidators.qty('x', strings: SsStrings.en), 'Invalid number');
    });

    test('moneyText: vazio passa sem required e texto inválido', () {
      expect(SsValidators.moneyText(''), isNull);
      expect(SsValidators.moneyText('', required: true), 'Informe um valor');
      expect(SsValidators.moneyText('12,50'), isNull);
      expect(SsValidators.moneyText('R\$ 1.234,56'), isNull);
      expect(SsValidators.moneyText('doze'), 'Valor inválido');
      expect(SsValidators.moneyText('doze', strings: SsStrings.es), 'Valor inválido');
      final FormFieldValidator<String> v = SsValidators.moneyText;
      expect(v('1'), isNull);
    });
  });

  testWidgets('SsNetImage(placeholderColor:): degradê da cor no vazio', (t) async {
    await t.pumpWidget(
      _app(
        const Center(
          child: SsNetImage(null, width: 120, height: 80, name: 'Lisboa', placeholderColor: Color(0xFF2E6A8C)),
        ),
      ),
    );
    final caixa = t.widget<DecoratedBox>(
      find.descendant(of: find.byType(SsNetImage), matching: find.byType(DecoratedBox)).first,
    );
    final g = (caixa.decoration as BoxDecoration).gradient as LinearGradient;
    expect(g.colors.first, const Color(0xFF2E6A8C));
    expect(_cor(t, 'L'), AppColors.onDarkIcon);
  });

  testWidgets('SsTimelineItem(endTime:, alert:): fim apagado e horário em vermelho com ⚠', (t) async {
    await t.pumpWidget(
      _app(
        const SingleChildScrollView(
          child: SsTimeline(
            items: [
              SsTimelineItem(title: 'Voo LIS', time: '09:30', endTime: '11:00', done: true),
              SsTimelineItem(title: 'Check-in', time: '10:45', alert: true),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('– 11:00'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(_cor(t, '10:45'), SsColors.forDark(false).dangerText);
    expect(find.bySemanticsLabel(RegExp(r', Atenção')), findsOneWidget);
  });

  group('SsRating e SsCompareTable', () {
    testWidgets('estrelas: leitura com meia e edição por toque (alvo de 48)', (t) async {
      var nota = 0;
      await t.pumpWidget(
        _app(
          Column(
            children: [
              const SsRating(4.5),
              StatefulBuilder(
                builder: (context, set) => SsRating(nota.toDouble(), size: 32, onChanged: (v) => set(() => nota = v)),
              ),
            ],
          ),
        ),
      );
      expect(find.bySemanticsLabel('Nota 4,5 de 5'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('3 estrelas'));
      await t.pump();
      expect(nota, 3);
      expect(t.getSize(find.bySemanticsLabel('3 estrelas')).height, greaterThanOrEqualTo(48));
    });

    testWidgets('comparação: recomendado, ✓/—, melhor valor em verde e rola de lado', (t) async {
      await t.pumpWidget(
        _app(
          const SsCompareTable(
            caption: 'Destinos',
            plans: [
              SsComparePlan('Lisboa', price: 'maio'),
              SsComparePlan('Porto', recommended: true),
              SsComparePlan('Madri'),
            ],
            features: [
              SsCompareFeature('Total', ['R\$ 8.000', 'R\$ 7.200', 'R\$ 9.100'], best: 1),
              SsCompareFeature('Visto', [false, true, null], mono: false),
            ],
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('Recomendado'), findsOneWidget);
      expect(find.bySemanticsLabel('Incluído'), findsOneWidget);
      expect(find.bySemanticsLabel('Não incluído'), findsNWidgets(2));
      expect(_cor(t, 'R\$ 7.200'), SsColors.forDark(false).successText);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });
  });

  group('ajustes pedidos', () {
    testWidgets('SsFilterChip com rótulo longo a 1,3× num Wrap estreito termina em … (não estoura)', (t) async {
      await t.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 160,
              child: Wrap(
                children: [
                  SsFilterChip('Quanto gastei com café este ano?', selected: false, onTap: () {}),
                  SsFilterChip('Mercado', selected: true, onTap: () {}, count: 3),
                ],
              ),
            ),
          ),
          scale: 1.3,
        ),
      );
      expect(t.takeException(), isNull);
      expect(t.widget<Text>(find.text('Quanto gastei com café este ano?')).overflow, TextOverflow.ellipsis);
      expect(t.getSize(find.byType(SsFilterChip).first).width, lessThanOrEqualTo(160));
    });

    testWidgets('SsFilterChip numa faixa que rola de lado continua do tamanho do texto', (t) async {
      await t.pumpWidget(
        _app(
          SizedBox(
            height: 60,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [SsFilterChip('Todos os produtos da casa', selected: false, onTap: () {})],
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('Todos os produtos da casa'), findsOneWidget);
    });

    testWidgets('SsButton.text: ícone no fim, tom de aviso e sobre fundo escuro', (t) async {
      await t.pumpWidget(
        _app(
          Column(
            children: [
              SsButton.text(label: 'Ver todas', trailingIcon: Icons.chevron_right_rounded, onPressed: () {}),
              SsButton.text(label: 'Vence logo', tone: SsTone.warning, onPressed: () {}),
              SsButton.text(label: 'Usar inteira', onDark: true, onPressed: () {}),
              SsButton(label: 'Abrir', icon: Icons.open_in_new, trailingIcon: Icons.arrow_forward, onPressed: () {}),
            ],
          ),
        ),
      );
      expect(
        t.getRect(find.byIcon(Icons.chevron_right_rounded)).left,
        greaterThan(t.getRect(find.text('Ver todas')).right),
      );
      expect(_cor(t, 'Vence logo'), SsColors.forDark(false).aquecText);
      expect(_cor(t, 'Usar inteira'), AppColors.onDark);
      expect(_cor(t, 'Ver todas'), SsColors.forDark(false).accentText);
    });

    testWidgets('SsDelta.neutral: traço e tom apagado', (t) async {
      await t.pumpWidget(_app(const Center(child: SsDelta.neutral('0%'))));
      expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
      expect(_cor(t, '0%'), AppColors.mutedLight);
    });

    testWidgets('SsCountdownRing(warnAt:): aquece com a conta fixa', (t) async {
      await t.pumpWidget(
        _app(
          const Row(
            children: [
              SsCountdownRing(total: 7, left: 2, warnAt: 2, label: 'dias'),
              SsCountdownRing(total: 7, left: 2, label: 'dia'),
            ],
          ),
        ),
      );
      final textos = t.widgetList<Text>(find.text('2')).toList();
      expect(textos[0].style!.color, SsColors.forDark(false).aquecText);
      expect(textos[1].style!.color, AppColors.inkLight);
    });

    testWidgets('SsProportionBar(onDark:, legendValue: count): "3 vencidos", zerados fora, texto claro', (t) async {
      await t.pumpWidget(
        _app(
          const ColoredBox(
            color: Color(0xFF0E7C86),
            child: SsProportionBar(
              onDark: true,
              legendValue: SsLegendValue.count,
              parts: [(3, 'vencidos', null), (0, 'vencem na semana', null), (9, 'em dia', null)],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('vencidos'), findsOneWidget);
      expect(find.text('vencem na semana'), findsNothing);
      expect(_cor(t, '3'), AppColors.onDark);
      expect(find.bySemanticsLabel('9 em dia'), findsWidgets);
      expect(find.textContaining('%'), findsNothing);
    });

    testWidgets('SsSparkline(target:, markMin:) desenha sem erro e SsReorderableList(primary: false)', (t) async {
      await t.pumpWidget(
        _app(
          Column(
            children: [
              const SsSparkline([30, 10, 20, 25], target: 5, markMin: true),
              Expanded(
                child: SsReorderableList(
                  primary: false,
                  itemCount: 2,
                  onReorder: (_, _) {},
                  itemBuilder: (context, i) => SizedBox(key: ValueKey(i), height: 40, child: Text('item $i')),
                ),
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      expect(t.widget<ReorderableListView>(find.byType(ReorderableListView)).primary, isFalse);
    });
  });
}
