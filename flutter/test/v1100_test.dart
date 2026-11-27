// v1.10.0: os pares Flutter das peças que só existiam no web: SsProductCard (Ss::ProductCardComponent),
// SsFilterBar/SsFilterSheet (Ss::FilterBarComponent), SsJobProgress (Ss::JobProgressComponent), SsTreeView
// (Ss::TreeViewComponent) e SsPopover (Ss::PopoverComponent).
import 'dart:async';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget home, {Locale locale = const Locale('pt', 'BR'), bool reduce = false, ThemeData? theme}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme ?? AppTheme.light,
      locale: locale,
      supportedLocales: SsStrings.supportedLocales,
      localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      builder: (context, child) =>
          reduce ? MediaQuery(data: MediaQuery.of(context).copyWith(disableAnimations: true), child: child!) : child!,
      home: home,
    );

Widget _tela(Widget w) => Scaffold(
  body: SafeArea(
    child: SingleChildScrollView(padding: const EdgeInsets.all(16), child: w),
  ),
);

const _filtros = [
  SsFilterGroup(
    param: 'status',
    label: 'Situação',
    options: [SsFilterOption('Pago', 'pago'), SsFilterOption('Vencido', 'vencido')],
  ),
  SsFilterGroup(
    param: 'tag',
    label: 'Etiqueta',
    multiple: true,
    options: [SsFilterOption('Atacado', 'atacado'), SsFilterOption('Varejo', 'varejo')],
  ),
];

/// A barra com estado, como o app usa.
class _Barra extends StatefulWidget {
  const _Barra({this.inicio = const {}, this.count, this.views = const []});
  final SsFilterValues inicio;
  final SsFilterCounter? count;
  final List<SsFilterView> views;

  @override
  State<_Barra> createState() => _BarraState();
}

class _BarraState extends State<_Barra> {
  late SsFilterValues v = widget.inicio;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SsFilterBar(
        filters: _filtros,
        values: v,
        views: widget.views,
        count: widget.count,
        onChanged: (n) => setState(() => v = n),
      ),
      Text('valores: ${(v.entries.map((e) => '${e.key}=${e.value.join('+')}').toList()..sort()).join('&')}'),
    ],
  );
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsProductCard', () {
    testWidgets('nome, texto, preço, selo e a ação com o nome no leitor de tela', (t) async {
      final h = t.ensureSemantics();
      var abriu = 0, add = 0;
      await t.pumpWidget(
        _app(
          _tela(
            SizedBox(
              width: 220,
              child: SsProductCard(
                name: 'Costela-de-adão',
                text: 'Meia-sombra',
                price: r'R$ 89,90',
                badge: 'Novo',
                image: const Icon(Icons.local_florist),
                onTap: () => abriu++,
                action: SsProductAction('Adicionar', () => add++),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Costela-de-adão'), findsOneWidget);
      expect(find.text('Meia-sombra'), findsOneWidget);
      expect(find.text('Novo'), findsOneWidget);
      expect(find.bySemanticsLabel('Adicionar: Costela-de-adão'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('Adicionar: Costela-de-adão'));
      await t.pumpAndSettle();
      expect((abriu, add), (0, 1));
      await t.tap(find.text('Meia-sombra'));
      await t.pumpAndSettle();
      expect(abriu, 1);
      // a imagem sobe acima do card: o topo dela fica acima do topo do card
      final img = t.getRect(
        find.ancestor(of: find.byIcon(Icons.local_florist), matching: find.byType(IgnorePointer)).first,
      );
      final card = t.getRect(find.byType(SsCard));
      expect(img.top, lessThan(card.top));
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('ação sem onPressed fica desligada; sem imagem, o ícone de produto', (t) async {
      await t.pumpWidget(
        _app(
          _tela(
            const SizedBox(
              width: 200,
              child: SsProductCard(name: 'Jiboia', action: SsProductAction('Adicionar', null)),
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.inventory_2_outlined), findsOneWidget);
      expect(
        t.getSemantics(find.bySemanticsLabel('Adicionar: Jiboia')),
        isSemantics(isButton: true, hasEnabledState: true, isEnabled: false),
      );
      await ssA11yAudit(t);
    });
  });

  group('SsFilterBar e SsFilterSheet', () {
    test('SsFilters: ativos, trocar, somar, tirar e comparar', () {
      const v = {
        'status': ['vencido'],
        'tag': ['atacado', 'xyz'],
      };
      final a = SsFilters.active(_filtros, v);
      expect(a.map((e) => e.label), ['Vencido', 'Atacado', 'xyz']);
      expect(SsFilters.toggle(v, _filtros[0], 'pago')['status'], ['pago']);
      expect(SsFilters.toggle(v, _filtros[0], 'vencido').containsKey('status'), isFalse);
      expect(SsFilters.toggle(v, _filtros[1], 'varejo')['tag'], ['atacado', 'xyz', 'varejo']);
      expect(SsFilters.remove(v, 'tag', 'xyz')['tag'], ['atacado']);
      expect(
        SsFilters.same(
          {
            'tag': ['b', 'a'],
          },
          {
            'tag': ['a', 'b'],
          },
        ),
        isTrue,
      );
      expect(SsFilters.same({}, v), isFalse);
    });

    testWidgets('barra: número de ativos, × tira só aquele valor e limpar', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          _tela(
            const _Barra(
              inicio: {
                'status': ['vencido'],
                'tag': ['atacado', 'varejo'],
              },
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Filtros, 3 ativos'), findsOneWidget);
      expect(find.text('Etiqueta: Varejo'), findsOneWidget);
      await t.tap(find.byTooltip('Tirar o filtro Etiqueta: Varejo'));
      await t.pumpAndSettle();
      expect(find.text('valores: status=vencido&tag=atacado'), findsOneWidget);
      expect(find.bySemanticsLabel('Filtros, 2 ativos'), findsOneWidget);
      await t.tap(find.text('Limpar filtros'));
      await t.pumpAndSettle();
      expect(find.text('valores: '), findsOneWidget);
      expect(find.text('Limpar filtros'), findsNothing);
      expect(find.bySemanticsLabel('Filtros'), findsOneWidget);
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('folha: "Mostrar N resultados" ao vivo, aplicar e fechar sem aplicar', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(_tela(_Barra(count: (v) => 10 - 3 * SsFilters.count(_filtros, v)))));
      await t.tap(find.bySemanticsLabel('Filtros'));
      await t.pumpAndSettle();
      expect(find.text('Mostrar 10 resultados'), findsOneWidget);
      await t.tap(find.text('Vencido'));
      await t.pump();
      expect(find.text('Mostrar 7 resultados'), findsOneWidget);
      expect(find.text('Situação: Vencido'), findsOneWidget); // chip do ativo no topo
      await t.tap(find.text('Atacado'));
      await t.tap(find.text('Varejo'));
      await t.pump();
      expect(find.text('Mostrar 1 resultado'), findsOneWidget);
      await t.tap(find.text('Varejo'));
      await t.pump();
      h.dispose();
      await ssA11yAudit(t);
      await t.tap(find.text('Mostrar 4 resultados'));
      await t.pumpAndSettle();
      expect(find.text('valores: status=vencido&tag=atacado'), findsOneWidget);
      // abrir, mexer e fechar tocando fora: nada muda
      await t.tap(find.bySemanticsLabel('Filtros, 2 ativos'));
      await t.pumpAndSettle();
      await t.tap(find.text('Limpar filtros').last);
      await t.pump();
      expect(find.text('Mostrar 10 resultados'), findsOneWidget);
      await t.tapAt(const Offset(10, 10));
      await t.pumpAndSettle();
      expect(find.text('valores: status=vencido&tag=atacado'), findsOneWidget);
    });

    testWidgets('folha: contagem assíncrona fica com a resposta mais nova', (t) async {
      final pedidos = <Completer<int>>[];
      await t.pumpWidget(
        _app(
          Scaffold(
            body: SsFilterSheet(
              filters: _filtros,
              onApply: (_) {},
              count: (v) {
                final c = Completer<int>();
                pedidos.add(c);
                return c.future;
              },
            ),
          ),
        ),
      );
      expect(find.text('Mostrar resultados'), findsNothing); // carregando no 1º
      pedidos[0].complete(20);
      await t.pump();
      expect(find.text('Mostrar 20 resultados'), findsOneWidget);
      await t.tap(find.text('Pago'));
      await t.pump();
      await t.tap(find.text('Vencido'));
      await t.pump();
      pedidos[2].complete(5);
      await t.pump();
      pedidos[1].complete(99); // velha: não passa por cima
      await t.pump();
      expect(find.text('Mostrar 5 resultados'), findsOneWidget);
      pedidos[2].isCompleted;
    });

    testWidgets('visões salvas marcam a atual e trocam os filtros', (t) async {
      await t.pumpWidget(
        _app(
          _tela(
            const _Barra(
              views: [
                SsFilterView('Todos'),
                SsFilterView(
                  'Vencidos',
                  values: {
                    'status': ['vencido'],
                  },
                  count: 4,
                ),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('Vencidos'));
      await t.pumpAndSettle();
      expect(find.text('valores: status=vencido'), findsOneWidget);
      expect(find.text('Situação: Vencido'), findsOneWidget);
      await ssA11yAudit(t);
    });

    testWidgets('en e es', (t) async {
      await t.pumpWidget(
        _app(
          _tela(
            const _Barra(
              inicio: {
                'status': ['pago'],
              },
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Clear filters'), findsOneWidget);
      expect(find.bySemanticsLabel('Filters, 1 active'), findsOneWidget);
      expect(SsStrings.es.filterShowResults(3), 'Mostrar 3 resultados');
      expect(SsStrings.en.filterShowResults(0), 'No results');
      expect(SsStrings.es.filterRemove('Situación', 'Pagado'), 'Quitar el filtro Situación: Pagado');
      await ssA11yAudit(t);
    });
  });

  group('SsJobProgress', () {
    testWidgets('rodando: pílula com %, barra, passos e cancelar', (t) async {
      final h = t.ensureSemantics();
      var cancelou = 0;
      await t.pumpWidget(
        _app(
          _tela(
            SsJobProgress(
              title: 'Importar clientes',
              state: SsJobState.running,
              progress: .4,
              steps: const ['Ler arquivo', 'Validar', 'Gravar'],
              currentStep: 1,
              onCancel: () => cancelou++,
            ),
          ),
        ),
      );
      expect(find.text('Rodando · 40%'), findsOneWidget);
      expect(find.bySemanticsLabel('Ler arquivo, Concluída'), findsOneWidget);
      expect(find.bySemanticsLabel('Validar, Rodando'), findsOneWidget);
      expect(find.bySemanticsLabel('Gravar, Pendente'), findsOneWidget);
      final barra = t.widget<SsProgress>(find.byType(SsProgress));
      expect(barra.value, closeTo(.4, .001));
      await t.tap(find.text('Cancelar'));
      expect(cancelou, 1);
      h.dispose();
      await ssA11yAudit(t, settle: const Duration(milliseconds: 50));
    });

    testWidgets('na fila: barra sem número; cancelando fica desligado', (t) async {
      await t.pumpWidget(
        _app(_tela(const SsJobProgress(title: 'Relatório', onCancel: _nada, cancelling: true)), reduce: true),
      );
      expect(find.text('Na fila'), findsOneWidget);
      expect(t.widget<SsProgress>(find.byType(SsProgress)).value, isNull);
      expect(find.text('Cancelando…'), findsOneWidget);
      expect(t.widget<SsButton>(find.byType(SsButton)).onPressed, isNull);
      await ssA11yAudit(t);
    });

    testWidgets('concluído com etapas: sem barra, tempos, total e abrir resultado', (t) async {
      var abriu = 0;
      await t.pumpWidget(
        _app(
          _tela(
            SsJobProgress(
              title: 'Comando de voz',
              state: SsJobState.done,
              stages: const [
                SsJobStage('Ouvir', duration: Duration(milliseconds: 820)),
                SsJobStage('Entender', duration: Duration(milliseconds: 1240)),
                SsJobStage('Executar', status: SsJobStageStatus.skipped, detail: 'Nada a fazer'),
              ],
              onOpenResult: () => abriu++,
              onCancel: _nada,
            ),
          ),
        ),
      );
      expect(find.byType(SsProgress), findsNothing);
      expect(find.text('820 ms'), findsOneWidget);
      expect(find.text('1,2 s'), findsOneWidget);
      expect(find.text('2,1 s'), findsOneWidget); // total
      expect(find.bySemanticsLabel('Executar, Pulada, Nada a fazer'), findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);
      await t.tap(find.text('Abrir resultado'));
      expect(abriu, 1);
      expect(SsJobProgress.durationText(const Duration(seconds: 65), SsStrings.pt), '1 min 5 s');
      expect(SsJobProgress.durationText(const Duration(milliseconds: 1240), SsStrings.en), '1.2 s');
      await ssA11yAudit(t);
    });

    testWidgets('falhou: o motivo, o passo em vermelho e tentar de novo (en, es)', (t) async {
      var tentou = 0;
      await t.pumpWidget(
        _app(
          _tela(
            SsJobProgress(
              title: 'Import',
              state: SsJobState.failed,
              steps: const ['Read', 'Validate'],
              currentStep: 1,
              onRetry: () => tentou++,
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      expect(find.text('Failed'), findsOneWidget);
      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.bySemanticsLabel('Validate, Failed'), findsOneWidget);
      expect(find.byType(SsProgress), findsNothing);
      await t.tap(find.text('Try again'));
      expect(tentou, 1);
      expect(SsStrings.es.jobQueued, 'En cola');
      await ssA11yAudit(t);
    });
  });

  group('SsTreeView', () {
    const nos = [
      SsTreeNode(
        'Receitas',
        count: 2,
        value: r'R$ 12.400,00',
        open: true,
        children: [
          SsTreeNode('Vendas', value: r'R$ 9.000,00'),
          SsTreeNode('Serviços'),
        ],
      ),
      SsTreeNode('Despesas', children: [SsTreeNode('Aluguel')]),
    ];

    testWidgets('abre, recolhe e lê aberto/fechado com a contagem', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(_tela(const SsTreeView(label: 'Plano de contas', nodes: nos))));
      expect(find.text('Vendas'), findsOneWidget);
      expect(find.text('Aluguel'), findsNothing);
      expect(
        t.getSemantics(find.bySemanticsLabel(r'Receitas, 2 itens, R$ 12.400,00')),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: true, hint: 'Recolher'),
      );
      await t.tap(find.text('Despesas'));
      await t.pumpAndSettle();
      expect(find.text('Aluguel'), findsOneWidget);
      await t.tap(find.text('Receitas'));
      await t.pumpAndSettle();
      expect(find.text('Vendas'), findsNothing);
      expect(
        t.getSemantics(find.bySemanticsLabel(r'Receitas, 2 itens, R$ 12.400,00')),
        isSemantics(isButton: true, hasExpandedState: true, isExpanded: false, hint: 'Expandir'),
      );
      expect(t.getSize(find.ancestor(of: find.text('Despesas'), matching: find.byType(AnimatedContainer))).height, 48);
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('escolha única marca a folha; sem seleção, a folha chama o onTap', (t) async {
      Set<String>? sel;
      var abriu = 0;
      await t.pumpWidget(
        _app(
          _tela(
            Column(
              children: [
                SsTreeView(
                  nodes: nos,
                  selection: SsTreeSelection.single,
                  selected: const {'Receitas/Serviços'},
                  onSelectionChanged: (s) => sel = s,
                ),
                SsTreeView(
                  nodes: [
                    SsTreeNode('Pasta', open: true, children: [SsTreeNode('Arquivo', onTap: () => abriu++)]),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      await t.tap(find.text('Vendas'));
      expect(sel, {'Receitas/Vendas'});
      await t.tap(find.text('Arquivo'));
      expect(abriu, 1);
      await ssA11yAudit(t);
    });

    testWidgets('escolha múltipla: o galho marca tudo e fica misturado com parte', (t) async {
      final h = t.ensureSemantics();
      var sel = <String>{'Receitas/Vendas'};
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => _tela(
              SsTreeView(
                nodes: nos,
                selection: SsTreeSelection.multiple,
                selected: sel,
                onSelectionChanged: (s) => set(() => sel = s),
              ),
            ),
          ),
          reduce: true,
        ),
      );
      final caixa = find.bySemanticsLabel('Receitas').first;
      expect(t.getSemantics(caixa), isSemantics(hasCheckedState: true, isCheckStateMixed: true));
      await t.tap(caixa);
      await t.pump();
      expect(sel, {'Receitas/Vendas', 'Receitas/Serviços'});
      expect(t.getSemantics(caixa), isSemantics(hasCheckedState: true, isChecked: true));
      await t.tap(caixa);
      await t.pump();
      expect(sel, isEmpty);
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('en e es', (t) async {
      await t.pumpWidget(_app(_tela(const SsTreeView(nodes: nos)), locale: const Locale('es')));
      expect(find.bySemanticsLabel(RegExp('^Receitas, 2 elementos')), findsOneWidget);
      expect(find.bySemanticsLabel('Árbol'), findsOneWidget);
      expect(SsStrings.en.treeCount(1), '1 item');
      await ssA11yAudit(t);
    });
  });

  group('SsPopover', () {
    Widget pagina({SsPopoverPlacement placement = SsPopoverPlacement.bottomStart, Alignment a = Alignment.topLeft}) =>
        Scaffold(
          body: Align(
            alignment: a,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: SsPopover(
                label: 'Detalhes',
                title: 'Como calculamos',
                placement: placement,
                child: Builder(
                  builder: (ctx) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Média de 3 meses.'),
                      SsButton.text(label: 'Entendi', onPressed: () => SsPopover.close(ctx)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

    testWidgets('abre abaixo do botão, alinhado pelo começo, e fecha ao tocar fora', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(pagina()));
      final botao = t.getRect(find.widgetWithText(SsButton, 'Detalhes'));
      await t.tap(find.text('Detalhes'));
      await t.pumpAndSettle();
      expect(find.text('Média de 3 meses.'), findsOneWidget);
      final balao = t.getRect(find.text('Como calculamos'));
      expect(balao.top, greaterThan(botao.bottom));
      expect((balao.left - botao.left).abs(), lessThan(24));
      expect(find.bySemanticsLabel('Como calculamos'), findsWidgets);
      h.dispose();
      await ssA11yAudit(t);
      await t.tapAt(const Offset(780, 580));
      await t.pumpAndSettle();
      expect(find.text('Média de 3 meses.'), findsNothing);
    });

    testWidgets('sem espaço embaixo vira para cima; Esc e o close de dentro fecham', (t) async {
      await t.pumpWidget(_app(pagina(a: Alignment.bottomLeft)));
      final botao = t.getRect(find.widgetWithText(SsButton, 'Detalhes'));
      await t.tap(find.text('Detalhes'));
      await t.pumpAndSettle();
      expect(t.getRect(find.text('Média de 3 meses.')).bottom, lessThan(botao.top));
      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(find.text('Média de 3 meses.'), findsNothing);
      await t.tap(find.text('Detalhes'));
      await t.pumpAndSettle();
      await t.tap(find.text('Entendi'));
      await t.pumpAndSettle();
      expect(find.text('Média de 3 meses.'), findsNothing);
    });

    testWidgets('alinhado pelo fim, com ícone (dica = label) e reduzir movimento abre direto', (t) async {
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: const SsPopover(
                  label: 'Mais ações',
                  icon: Icons.more_vert,
                  placement: SsPopoverPlacement.bottomEnd,
                  child: Text('Duplicar'),
                ),
              ),
            ),
          ),
          reduce: true,
        ),
      );
      final botao = t.getRect(find.byIcon(Icons.more_vert));
      await t.tap(find.byTooltip('Mais ações'));
      await t.pump();
      await t.pump();
      expect(find.text('Duplicar'), findsOneWidget);
      final texto = t.getRect(find.text('Duplicar'));
      expect(texto.right, lessThanOrEqualTo(800 - 12));
      expect(texto.top, greaterThan(botao.bottom));
      await ssA11yAudit(t);
    });

    testWidgets('voltar fecha (en: o nome do fundo é "Close")', (t) async {
      await t.pumpWidget(_app(pagina(), locale: const Locale('en')));
      await t.tap(find.text('Detalhes'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Close'), findsWidgets);
      final nav = t.state<NavigatorState>(find.byType(Navigator).first);
      await nav.maybePop();
      await t.pumpAndSettle();
      expect(find.text('Média de 3 meses.'), findsNothing);
      await ssA11yAudit(t);
    });
  });
}

void _nada() {}
