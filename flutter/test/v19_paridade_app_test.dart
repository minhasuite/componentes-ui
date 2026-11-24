// v1.9 · paridade_app: os pares no app das peças que só existiam no web (SsGantt, SsTour,
// SsWizard, SsDateRangeField, SsOtpField, SsTagField, SsAuditTrail, SsReviewCard, SsPersonCard,
// SsBentoGrid, SsWhatsNew, SsSkeleton, SsSplitView, SsAdaptiveScaffold).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Locale locale = const Locale('pt'), bool scroll = true, bool reduce = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: Scaffold(
        body: scroll ? SingleChildScrollView(padding: const EdgeInsets.all(16), child: child) : child,
      ),
    ),
  ),
);

Future<void> _tela(WidgetTester t, Size s) async {
  t.view.physicalSize = s * 2;
  t.view.devicePixelRatio = 2;
  addTearDown(t.view.reset);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('textos', () {
    test('pt/en/es têm os textos da área', () {
      expect(SsStrings.pt.tourNext, 'Próximo');
      expect(SsStrings.en.tourNext, 'Next');
      expect(SsStrings.es.wizardSaveLater, 'Guardar y seguir después');
      expect(SsStrings.en.dateRangeLastMonth, 'Last month');
      expect(ssFill(SsStrings.pt.tourCount, {'n': 2, 'total': 5}), '2 de 5');
      expect(ssFill(SsStrings.en.otpDigit, {'n': 1, 'total': 6}), 'Digit 1 of 6');
      expect(SsStrings.en.copyWith(splitList: 'Orders').splitList, 'Orders');
    });
  });

  group('SsGantt', () {
    final ini = DateTime(2026, 11, 2);
    test('spanFor: recorta na janela e some fora dela (a conta do web)', () {
      SsGanttTask t(int a, int b) => SsGanttTask(
        label: 'x',
        from: ini.add(Duration(days: a)),
        to: ini.add(Duration(days: b)),
      );
      expect(SsGantt.spanFor(t(0, 3), ini, 8), (0, 4));
      expect(SsGantt.spanFor(t(-2, 1), ini, 8), (0, 2));
      expect(SsGantt.spanFor(t(6, 12), ini, 8), (6, 8));
      expect(SsGantt.spanFor(t(9, 12), ini, 8), isNull);
      expect(SsGantt.spanFor(t(-5, -1), ini, 8), isNull);
      expect(SsGantt.pct(SsGanttTask(label: 'x', from: _d, to: _d, progress: 1.4)), 100);
    });

    testWidgets('barra com o leitor de tela "de … a …, n% feito"; hoje marcado', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          SsGantt(
            start: ini,
            days: 8,
            today: DateTime(2026, 11, 4),
            tasks: [
              SsGanttTask(label: 'Projeto', from: ini, to: DateTime(2026, 11, 5), progress: .6),
              SsGanttTask(
                label: 'Compras',
                from: DateTime(2026, 11, 5),
                to: DateTime(2026, 11, 8),
                tone: SsTone.warning,
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Projeto, de 02/11 a 05/11, 60% feito'), findsOneWidget);
      expect(find.text('60%'), findsOneWidget);
      expect(find.text('Compras'), findsOneWidget);
      expect(t.takeException(), isNull);
      h.dispose();
    });
  });

  group('SsDateRangeField', () {
    final hoje = DateTime(2026, 11, 24);
    test('atalhos: 7 dias conta hoje; este mês é o mês inteiro; mês passado', () {
      final s7 = SsDateRangeShortcut.last7Days.rangeFrom(hoje);
      expect(s7.start, DateTime(2026, 11, 18));
      expect(s7.end, DateTime(2026, 11, 24));
      final m = SsDateRangeShortcut.thisMonth.rangeFrom(hoje);
      expect((m.start, m.end), (DateTime(2026, 11), DateTime(2026, 11, 30)));
      final p = SsDateRangeShortcut.lastMonth.rangeFrom(DateTime(2026, 1, 10));
      expect((p.start, p.end), (DateTime(2025, 12), DateTime(2025, 12, 31)));
    });

    testWidgets('o atalho que bate fica marcado; tocar troca o período', (t) async {
      DateTimeRange? v = SsDateRangeShortcut.thisMonth.rangeFrom(hoje);
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsDateRangeField(today: hoje, value: v, onChanged: (r) => set(() => v = r)),
          ),
        ),
      );
      await t.pumpAndSettle();
      SsFilterChip chip(String l) => t.widget<SsFilterChip>(find.widgetWithText(SsFilterChip, l));
      expect(chip('Este mês').selected, isTrue);
      expect(chip('7 dias').selected, isFalse);
      await t.tap(find.text('Mês passado'));
      await t.pumpAndSettle();
      expect(v!.start, DateTime(2026, 10));
      expect(chip('Mês passado').selected, isTrue);
      expect(find.text('Período'), findsOneWidget);
    });
  });

  group('SsOtpField', () {
    testWidgets('colar o código inteiro (com traço) preenche tudo e completa; autofill do SMS', (t) async {
      String? fim;
      await t.pumpWidget(_app(SsOtpField(onCompleted: (c) => fim = c)));
      final campo = t.widget<TextField>(find.byType(TextField));
      expect(campo.autofillHints, contains(AutofillHints.oneTimeCode));
      expect(campo.keyboardType, TextInputType.number);
      await t.enterText(find.byType(TextField), '123-456');
      await t.pump();
      expect(fim, '123456');
      for (final d in ['1', '2', '3', '4', '5', '6']) {
        expect(find.text(d), findsOneWidget);
      }
    });

    testWidgets('mais dígitos que o tamanho são cortados; erro aparece embaixo', (t) async {
      final c = TextEditingController();
      await t.pumpWidget(_app(SsOtpField(length: 4, controller: c, errorText: 'Código errado')));
      await t.enterText(find.byType(TextField), '987654');
      await t.pump();
      expect(c.text, '9876');
      expect(find.text('Código errado'), findsOneWidget);
    });
  });

  group('SsTagField', () {
    test('split separa por vírgula e quebra de linha, sem vazias', () {
      expect(SsTagField.split(' a, b,,\nc '), ['a', 'b', 'c']);
    });

    testWidgets('vírgula vira chip, confirmar vira chip, repetida não entra, ✕ tira', (t) async {
      var tags = <String>['doce'];
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) =>
                SsTagField(label: 'Etiquetas', values: tags, onChanged: (v) => set(() => tags = v)),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'salgado, DOCE,');
      await t.pump();
      expect(tags, ['doce', 'salgado']);
      await t.enterText(find.byType(TextField), 'vegano');
      await t.testTextInput.receiveAction(TextInputAction.done);
      await t.pump();
      expect(tags, ['doce', 'salgado', 'vegano']);
      expect(find.byType(SsInputChip), findsNWidgets(3));
      await t.tap(find.byTooltip('Remover salgado'));
      await t.pump();
      expect(tags, ['doce', 'vegano']);
    });
  });

  group('SsAuditTrail', () {
    test('diff por palavra igual ao do web', () {
      final (a, b) = SsAuditTrail.diff('R\$ 1.250,00', 'R\$ 1.320,00');
      expect(a, ('R\$ ', '1.250,00', ''));
      expect(b, ('R\$ ', '1.320,00', ''));
      final (c, d) = SsAuditTrail.diff('Entrega amanhã cedo', 'Entrega sexta cedo');
      expect(c.$2, 'amanhã');
      expect(d.$2, 'sexta');
    });

    testWidgets('quem, o quê, quando e "de → para" para o leitor de tela', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          SsAuditTrail(
            entries: [
              SsAuditEntry(
                who: 'Ana Souza',
                action: 'alterou o pedido 1042',
                at: DateTime(2026, 11, 2, 14, 30),
                changes: const [
                  SsAuditChange('Valor', from: 'R\$ 1.250,00', to: 'R\$ 1.320,00'),
                  SsAuditChange('Obs', to: 'urgente'),
                ],
              ),
              const SsAuditEntry(who: 'Bruno', action: 'criou o pedido 1042', note: 'pelo app'),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Valor: R\$ 1.250,00 para R\$ 1.320,00'), findsOneWidget);
      expect(find.bySemanticsLabel('Obs: vazio para urgente'), findsOneWidget);
      expect(find.textContaining('02/11 14:30', findRichText: true), findsOneWidget);
      expect(find.text('pelo app'), findsOneWidget);
      h.dispose();
    });
  });

  group('cartões', () {
    testWidgets('depoimento e pessoa', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            children: [
              SsReviewCard(
                name: 'Carla Mendes',
                role: 'Padaria Central',
                date: 'out/2026',
                rating: 4.5,
                text: 'Ótimo.',
              ),
              SsPersonCard(
                name: 'Ana Souza',
                role: 'Vendedora · Zona Sul',
                status: SsTone.success,
                metrics: [('Vendido', 'R\$ 48 mil'), ('Pedidos', '214')],
                team: ['Bruno', 'Caio', 'Duda', 'Eva', 'Fábio'],
              ),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Padaria Central · out/2026'), findsOneWidget);
      expect(find.byType(SsRating), findsOneWidget);
      expect(find.text('214'), findsOneWidget);
      expect(find.text('Equipe'), findsOneWidget);
      expect(find.byType(SsAvatarStack), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('SsBentoGrid', () {
    test('colunas pela largura (4 / 2 / 1, como o web)', () {
      expect(SsBentoGrid.columnsFor(1200, 4), 4);
      expect(SsBentoGrid.columnsFor(800, 4), 2);
      expect(SsBentoGrid.columnsFor(360, 4), 1);
    });

    test('posicionamento como o CSS grid (sem dense)', () {
      expect(SsBentoGrid.place([(2, 2), (1, 1), (1, 1), (1, 1), (1, 1)], 4), [(0, 0), (0, 2), (0, 3), (1, 2), (1, 3)]);
      expect(SsBentoGrid.place([(1, 1), (2, 1), (2, 1)], 2), [(0, 0), (1, 0), (2, 0)]);
    });

    for (final w in [360.0, 800.0, 1200.0]) {
      testWidgets('monta sem estourar em $w', (t) async {
        await _tela(t, Size(w, 900));
        await t.pumpWidget(
          _app(
            SsBentoGrid(
              blocks: [
                const SsBentoBlock(cols: 2, rows: 2, tone: SsBentoTone.grad, child: Text('Destaque')),
                for (final tone in [SsBentoTone.surface, SsBentoTone.soft, SsBentoTone.ink])
                  SsBentoBlock(tone: tone, child: Text(tone.name)),
              ],
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.text('Destaque'), findsOneWidget);
        expect(t.takeException(), isNull);
      });
    }
  });

  group('SsTour', () {
    testWidgets('abre uma vez, anda, conclui e grava "1" em ss-tour:<id>', (t) async {
      final a = GlobalKey(), b = GlobalKey();
      final store = SsMemorySeenStore();
      bool? fim;
      Widget tela() => _app(
        SsTour(
          id: 'painel',
          store: store,
          onFinish: (v) => fim = v,
          steps: [
            SsTourStep(target: a, title: 'Seus números', text: 'Os indicadores do mês.'),
            SsTourStep(target: b, title: 'Pedidos'),
          ],
          child: Column(
            children: [
              Container(key: a, height: 80, color: AppColors.success),
              const SizedBox(height: 300),
              Container(key: b, height: 80, color: AppColors.danger),
            ],
          ),
        ),
      );
      await t.pumpWidget(tela());
      await t.pumpAndSettle();
      expect(find.text('1 de 2'), findsOneWidget);
      expect(find.text('Seus números'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
      await t.tap(find.text('Próximo'));
      await t.pumpAndSettle();
      expect(find.text('2 de 2'), findsOneWidget);
      expect(find.text('Pular'), findsNothing);
      await t.tap(find.text('Concluir'));
      await t.pumpAndSettle();
      expect(fim, isTrue);
      expect(store.values['ss-tour:painel'], '1');
      expect(find.text('Pedidos'), findsNothing);

      // De novo: já viu, não abre.
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(tela());
      await t.pumpAndSettle();
      expect(find.text('1 de 2'), findsNothing);
    });

    testWidgets('Pular encerra e também grava; alvo fora da árvore é pulado', (t) async {
      final a = GlobalKey();
      final store = SsMemorySeenStore();
      bool? fim;
      await t.pumpWidget(
        _app(
          reduce: true,
          SsTour(
            id: 'x',
            store: store,
            onFinish: (v) => fim = v,
            steps: [
              SsTourStep(target: GlobalKey(), title: 'Fantasma'),
              SsTourStep(target: a, title: 'Real'),
              SsTourStep(target: GlobalKey(), title: 'Outro'),
            ],
            child: SizedBox(key: a, height: 40),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('1 de 1'), findsOneWidget);
      expect(find.text('Concluir'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      final b = GlobalKey();
      await t.pumpWidget(
        _app(
          SsTour(
            id: 'y',
            store: store,
            onFinish: (v) => fim = v,
            steps: [
              SsTourStep(target: b, title: 'A'),
              SsTourStep(target: b, title: 'B'),
            ],
            child: SizedBox(key: b, height: 40),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Pular'));
      await t.pumpAndSettle();
      expect(fim, isFalse);
      expect(store.values['ss-tour:y'], '1');
    });
  });

  group('SsWizard', () {
    testWidgets('valida o passo, avança, revisa, salva para depois e conclui', (t) async {
      await _tela(t, const Size(360, 720));
      var enviado = false;
      int? salvo;
      var escolha = false;
      await t.pumpWidget(
        _app(
          scroll: false,
          SsWizard(
            onSubmit: () async => enviado = true,
            onSaveForLater: (i) => salvo = i,
            summary: (_) => const Text('Tudo certo?'),
            steps: [
              SsWizardStep(
                title: 'Dados',
                builder: (_) =>
                    SsTextField(label: 'Nome', validator: (v) => (v ?? '').isEmpty ? 'Informe o nome' : null),
              ),
              SsWizardStep(title: 'Plano', validate: () => escolha, builder: (_) => const Text('Escolha um plano')),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Dados'), findsOneWidget);
      await t.tap(find.text('Avançar'));
      await t.pumpAndSettle();
      expect(find.text('Informe o nome'), findsOneWidget);
      await t.enterText(find.byType(TextFormField), 'Ana');
      await t.tap(find.text('Avançar'));
      await t.pumpAndSettle();
      expect(find.text('Escolha um plano'), findsOneWidget);
      await t.tap(find.text('Avançar'));
      await t.pumpAndSettle();
      expect(find.text('Tudo certo?').hitTestable(), findsNothing);
      escolha = true;
      await t.tap(find.text('Avançar'));
      await t.pumpAndSettle();
      expect(find.text('Revisão'), findsOneWidget);
      expect(find.text('Tudo certo?').hitTestable(), findsOneWidget);
      await t.tap(find.text('Salvar e continuar depois'));
      expect(salvo, 2);
      await t.tap(find.text('Concluir'));
      await t.pumpAndSettle();
      expect(enviado, isTrue);
      // Voltar mantém o digitado (os passos ficam montados).
      await t.tap(find.text('Voltar'));
      await t.pumpAndSettle();
      await t.tap(find.text('Voltar'));
      await t.pumpAndSettle();
      expect(find.text('Ana'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('SsWhatsNew', () {
    final itens = [
      SsWhatsNewItem(id: 'b', date: DateTime(2026, 11, 20), title: 'Pergunte à IA', text: 'Novo assistente.'),
      SsWhatsNewItem(id: 'a', date: DateTime(2026, 10, 2), title: 'Relatórios'),
    ];

    testWidgets('ponto no sino com não vistas; abrir marca tudo e o selo fica nos novos', (t) async {
      final store = SsMemorySeenStore({'ss-whats-new:fin': '["a"]'});
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(SsWhatsNew(id: 'fin', items: itens, store: store)));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Novidades, 1 nova'), findsOneWidget);
      await t.tap(find.byType(SsWhatsNew));
      await t.pumpAndSettle();
      expect(find.text('Pergunte à IA'), findsOneWidget);
      expect(find.text('NOVO'), findsOneWidget);
      expect(store.values['ss-whats-new:fin'], '["b","a"]');
      h.dispose();
    });

    testWidgets('autoShow abre sozinho uma vez', (t) async {
      final store = SsMemorySeenStore();
      await t.pumpWidget(_app(SsWhatsNew(id: 'x', items: itens, store: store, autoShow: true)));
      await t.pumpAndSettle();
      expect(find.text('Relatórios'), findsOneWidget);
      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(_app(SsWhatsNew(id: 'x', items: itens, store: store, autoShow: true)));
      await t.pumpAndSettle();
      expect(find.text('Relatórios'), findsNothing);
    });
  });

  group('SsSkeleton', () {
    for (final shape in SsSkeletonShape.values) {
      testWidgets('forma ${shape.name}: "Carregando…" e parado com menos movimento', (t) async {
        final h = t.ensureSemantics();
        await t.pumpWidget(_app(SsSkeleton(shape: shape), reduce: true));
        await t.pump();
        expect(find.bySemanticsLabel('Carregando…'), findsOneWidget);
        expect(t.hasRunningAnimations, isFalse);
        expect(t.takeException(), isNull);
        h.dispose();
      });
    }
  });

  group('SsSplitView e SsAdaptiveScaffold', () {
    Widget split(Widget? detalhe, VoidCallback voltar) => _app(
      scroll: false,
      SsSplitView(
        list: ListView(children: const [ListTile(title: Text('Pedido 1'))]),
        detail: detalhe,
        onBack: voltar,
      ),
    );

    testWidgets('celular: lista sozinha; com detalhe, o detalhe com Voltar', (t) async {
      await _tela(t, const Size(360, 720));
      var voltou = 0;
      await t.pumpWidget(split(null, () {}));
      expect(find.text('Pedido 1'), findsOneWidget);
      await t.pumpWidget(split(const Text('Detalhe 1'), () => voltou++));
      await t.pumpAndSettle();
      expect(find.text('Pedido 1'), findsNothing);
      await t.tap(find.text('Voltar'));
      expect(voltou, 1);
    });

    testWidgets('tela larga: lado a lado, vazio com o texto padrão', (t) async {
      await _tela(t, const Size(1000, 700));
      await t.pumpWidget(split(null, () {}));
      await t.pumpAndSettle();
      expect(find.text('Pedido 1'), findsOneWidget);
      expect(find.text('Escolha um item da lista.'), findsOneWidget);
      expect(find.text('Voltar'), findsNothing);
    });

    const abas = [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.list_alt_outlined, 'Pedidos')];
    testWidgets('casca: barra embaixo no celular, trilho acima de 840', (t) async {
      await _tela(t, const Size(400, 800));
      Widget casca() => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
        home: SsAdaptiveScaffold(items: abas, currentIndex: 0, onTap: (_) {}, body: const Text('corpo')),
      );
      await t.pumpWidget(casca());
      expect(find.byType(SsNavBar), findsOneWidget);
      expect(find.byType(SsSideRail), findsNothing);
      await _tela(t, const Size(1000, 700));
      await t.pumpWidget(casca());
      await t.pumpAndSettle();
      expect(find.byType(SsNavBar), findsNothing);
      expect(find.byType(SsSideRail), findsOneWidget);
      expect(find.text('corpo'), findsOneWidget);
    });
  });
}

final _d = DateTime(2026, 11, 2);
