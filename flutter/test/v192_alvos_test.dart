// v1.9.2: o que os apps acharam ao adotar a v1.9.1 (o `ssA11yAudit` acusou alvos de 40–44) e o que faltava
// nas peças v1.9: anexos no assistente, chave do tour no botão central da barra e o aviso rico na central.
// (O `v192_test.dart` é da v0.19.2; este arquivo segue o `v191_alvos_test.dart`.)
//
// Cada peça vai numa tela própria, longe da borda (a regra do Flutter pula o que encosta na borda), no
// compacto (o pior caso: desenha menor que 48) e no padrão.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, SsDensity d) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  supportedLocales: const [Locale('pt')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Scaffold(
    body: SsDensityScope(
      density: d,
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);

Widget _solta(Widget w) => Center(child: w);

Future<void> _tela(WidgetTester t, Size s) async {
  t.view.physicalSize = s;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
}

/// O retângulo do nó do leitor de tela que leva [f].
Rect _noDe(WidgetTester t, Finder f) {
  final no = t.getSemantics(f);
  return MatrixUtils.transformRect(no.transform ?? Matrix4.identity(), no.rect);
}

SsNotificationItem _rico({
  VoidCallback? onMute,
  List<SsNotificationAction> actions = const [],
  SsNotificationLevel? level,
  Widget? image,
  bool read = false,
}) => SsNotificationItem(
  id: '1',
  title: 'Portão aberto',
  body: 'Há 10 min',
  createdAt: DateTime(2026, 11, 24, 14),
  read: read,
  level: level,
  image: image,
  actions: actions,
  onMute: onMute,
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Widget central(List<SsNotificationItem> itens, {Future<void> Function(String)? markRead}) => SsNotificationCenter(
    now: () => DateTime(2026, 11, 24, 15),
    load: (p) async => SsNotificationPage(itens, hasMore: false),
    markRead: markRead ?? (_) async {},
    markAllRead: () async {},
    archive: (_) async {},
    onOpen: (_) {},
  );

  final pecas = <String, Widget Function()>{
    // 1. Os achados dos apps.
    'SsSearchField': () => _solta(const SsSearchField()),
    'SsSearchField com texto (✕ Limpar)': () => _solta(SsSearchField(controller: TextEditingController(text: 'arroz'))),
    'SsListItem com leading e sem subtítulo': () => _solta(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SsListItem(title: 'Ana', leading: const SsAvatar('Ana', size: 24), onTap: () {}),
          SsListItem(title: 'Bruno', leading: const SsAvatar('Bruno', size: 32), onTap: () {}),
          SsListItem(
            title: 'Carla',
            leading: const SsAvatar('Carla', size: 24),
            onTap: () {},
            trailing: SsIconButton(icon: Icons.more_vert_rounded, tooltip: 'Mais', onPressed: () {}),
          ),
        ],
      ),
    ),
    'SsSection (Ver todos)': () => _solta(SsSection('Vence logo', action: 'Ver todos', onAction: () {})),
    'SsSectionHeader (TextButton)': () => _solta(
      SsSectionHeader(
        'Histórico',
        subtitle: 'Últimos 30 dias',
        action: TextButton(onPressed: () {}, child: const Text('Ver todos')),
      ),
    ),
    // 5. As peças v1.9.
    'SsNotificationCenter (aviso rico)': () => central([
      _rico(
        level: SsNotificationLevel.critical,
        image: const ColoredBox(color: AppColors.scrim),
        actions: [SsNotificationAction('Fechar', () {}), SsNotificationAction('Ignorar', () {})],
        onMute: () {},
      ),
      SsNotificationItem(id: '2', title: 'Resumo do dia', createdAt: DateTime(2026, 11, 23, 19), read: true),
    ]),
    'SsAssistantView (conversa, erro e cota)': () => SsAssistantView(
      messages: const [
        SsAssistantMessage(id: '1', text: 'Oi', fromMe: true),
        SsAssistantMessage(id: '2', status: SsAssistantStatus.failed, error: 'Sem rede'),
      ],
      onSend: (_) {},
      onRetryMessage: (_) {},
      quotaUsed: 3,
      quotaLimit: 10,
      attachments: const [SsChatAttachment('cupom.jpg', icon: Icons.image_outlined)],
      onRemoveAttachment: (_) {},
    ),
    'SsAssistantView (conversas ao lado)': () => SsAssistantView(
      messages: const [SsAssistantMessage(id: '1', text: 'Oi', fromMe: true)],
      onSend: (_) {},
      conversations: const [
        SsAssistantConversation(id: 'a', title: 'Treino'),
        SsAssistantConversation(id: 'b'),
      ],
      currentConversationId: 'a',
      onOpenConversation: (_) {},
      onNewConversation: () {},
      onDeleteConversation: (_) {},
      sideBreakpoint: 300,
    ),
    'SsCaptureHub': () => SingleChildScrollView(
      child: SsCaptureHub(
        options: [
          SsCaptureOption(kind: SsCaptureKind.camera, title: 'Foto do cupom', highlighted: true, onTap: () {}),
          SsCaptureOption(kind: SsCaptureKind.paste, group: 'Compra', onTap: () {}),
          SsCaptureOption(kind: SsCaptureKind.barcode, group: 'Produto', onTap: () {}),
          SsCaptureOption(
            kind: SsCaptureKind.file,
            group: 'Produto',
            disabledReason: 'No plano Pro',
            onDisabledTap: () {},
          ),
        ],
      ),
    ),
    'SsWizard': () => SsWizard(
      onSubmit: () async {},
      onSaveForLater: (_) {},
      onCancel: () {},
      steps: [
        SsWizardStep(title: 'Dados', builder: (_) => const Text('Seus dados')),
        SsWizardStep(title: 'Plano', builder: (_) => const Text('Escolha um plano')),
      ],
    ),
    'SsWhatsNewList': () => SingleChildScrollView(
      child: SsWhatsNewList(
        items: [
          SsWhatsNewItem(id: 'b', date: DateTime(2026, 11, 20), title: 'Pergunte à IA', text: 'Novo assistente.'),
          SsWhatsNewItem(id: 'a', date: DateTime(2026, 10, 2), title: 'Relatórios'),
        ],
        seen: const {'a'},
      ),
    ),
    'SsSyncPanel': () => SsSyncPanel(
      state: SsSyncState.failed,
      pendingCount: 2,
      failedCount: 1,
      lastSyncedAt: DateTime(2026, 11, 24, 14, 32),
      now: DateTime(2026, 11, 24, 18),
      error: 'Sem conexão: usando os dados do aparelho.',
      details: '120 clientes no aparelho',
      onSyncNow: () {},
    ),
  };

  for (final d in [SsDensity.compact, SsDensity.standard]) {
    group('${d.name}: ssA11yAudit', () {
      for (final MapEntry(key: nome, value: peca) in pecas.entries) {
        testWidgets(nome, (t) async {
          await t.pumpWidget(_app(peca(), d));
          await t.pump();
          await t.pump(const Duration(milliseconds: 400));
          await ssA11yAudit(t);
        });
      }

      testWidgets('SsAdaptiveScaffold (celular e trilho)', (t) async {
        const abas = [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.list_alt_outlined, 'Pedidos')];
        for (final tamanho in [const Size(400, 800), const Size(1000, 700)]) {
          await _tela(t, tamanho);
          await t.pumpWidget(
            MaterialApp(
              theme: AppTheme.build(Brightness.light, density: d),
              localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
              home: SsAdaptiveScaffold(
                items: abas,
                currentIndex: 0,
                onTap: (_) {},
                body: const Center(child: Text('corpo')),
              ),
            ),
          );
          await t.pump(const Duration(milliseconds: 400));
          // A barra de baixo encosta na borda (a regra pula); o trilho e o corpo são medidos.
          await ssA11yAudit(t);
        }
      });

      testWidgets('SsTour (balão aberto)', (t) async {
        final alvo = GlobalKey();
        await t.pumpWidget(
          _app(
            Center(
              child: SsButton(key: alvo, label: 'Novo pedido', expand: false, onPressed: () {}),
            ),
            d,
          ),
        );
        SsTour.show(
          t.element(find.byType(SsButton)),
          steps: [
            SsTourStep(target: alvo, title: 'Pedidos', text: 'Comece por aqui.'),
            SsTourStep(target: alvo, title: 'De novo'),
          ],
        );
        await t.pumpAndSettle();
        await t.tap(find.text('Próximo'));
        await t.pumpAndSettle();
        expect(find.text('2 de 2'), findsOneWidget);
        await ssA11yAudit(t, textScale: null);
      });
    });
  }

  group('1. alvos de 48 sem mudar o desenho', () {
    testWidgets('SsSearchField: a caixa continua com 40 no compacto; o nó do campo tem 48', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(_solta(const SsSearchField(hint: 'Buscar produto')), SsDensity.compact));
      final caixa = find.descendant(of: find.byType(SsSearchField), matching: find.byType(AnimatedContainer));
      expect(t.getSize(caixa).height, 40);
      expect(_noDe(t, find.byType(TextField)).height, greaterThanOrEqualTo(48));
      // O campo continua sendo campo de texto (digitar, foco).
      await t.enterText(find.byType(TextField), 'arroz');
      expect(find.text('arroz'), findsOneWidget);
      h.dispose();
    });

    testWidgets('SsListItem com leading e sem subtítulo: 44 desenhado, 48 no toque e no leitor', (t) async {
      final h = t.ensureSemantics();
      var toques = 0;
      await t.pumpWidget(
        _app(
          // Numa lista (o uso real): o respiro acima da linha é dela, e o toque ali chega à linha.
          ListView(
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: SsListItem(title: 'Ana', leading: const SsAvatar('Ana', size: 32), onTap: () => toques++),
              ),
            ],
          ),
          SsDensity.compact,
        ),
      );
      final r = t.getRect(find.byType(InkWell));
      expect(r.height, 44); // o desenho é o mesmo
      expect(_noDe(t, find.text('Ana')).height, greaterThanOrEqualTo(48));
      await t.tapAt(Offset(r.center.dx, r.top - 1)); // na sobra de cima
      expect(toques, 1);
      h.dispose();
    });

    testWidgets('SsListItem com trailing: a linha cresce até 48 e o botão de dentro continua um nó próprio', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          _solta(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SsListItem(
                  title: 'Ana',
                  leading: const SsAvatar('Ana', size: 32),
                  onTap: () {},
                  trailing: SsIconButton(icon: Icons.more_vert_rounded, tooltip: 'Mais', onPressed: () {}),
                ),
              ],
            ),
          ),
          SsDensity.compact,
        ),
      );
      expect(t.getSize(find.byType(InkWell).first).height, greaterThanOrEqualTo(48));
      expect(t.getSemantics(find.byType(SsIconButton)).id, isNot(t.getSemantics(find.text('Ana')).id));
      h.dispose();
    });

    testWidgets('SsSection: "Ver todos" com 48 no leitor e o toque na sobra', (t) async {
      final h = t.ensureSemantics();
      var vistos = 0;
      await t.pumpWidget(
        _app(_solta(SsSection('Vence logo', action: 'Ver todos', onAction: () => vistos++)), SsDensity.compact),
      );
      final r = t.getRect(find.byType(TextButton));
      expect(r.height, lessThan(48));
      expect(_noDe(t, find.text('Ver todos')).height, greaterThanOrEqualTo(48));
      await t.tapAt(Offset(r.center.dx, r.top - 2));
      expect(vistos, 1);
      h.dispose();
    });
  });

  group('2. SsAssistantView(attachments:, onRemoveAttachment:)', () {
    testWidgets('chip do anexo na barra do campo; enviar com só o anexo; ✕ chama o callback', (t) async {
      final h = t.ensureSemantics();
      final enviados = <String>[];
      SsChatAttachment? removido;
      const anexo = SsChatAttachment('cupom.jpg', icon: Icons.image_outlined);
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [SsAssistantMessage(id: '1', text: 'Oi', fromMe: true)],
            onSend: enviados.add,
            attachments: const [anexo],
            onRemoveAttachment: (a) => removido = a,
          ),
          SsDensity.standard,
        ),
      );
      expect(find.text('cupom.jpg'), findsOneWidget);
      expect(t.getSemantics(find.bySemanticsLabel('Enviar')), isSemantics(isEnabled: true));
      await t.tap(find.bySemanticsLabel('Enviar'));
      expect(enviados, ['']);
      await t.tap(find.descendant(of: find.byType(SsInputChip), matching: find.byIcon(Icons.close_rounded)));
      expect(removido, same(anexo));
      h.dispose();
    });

    testWidgets('sem anexo e sem texto, enviar fica desabilitado (como antes)', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(SsAssistantView(messages: const [], onSend: (_) {}), SsDensity.standard));
      expect(t.getSemantics(find.bySemanticsLabel('Enviar')), isSemantics(isEnabled: false));
      h.dispose();
    });
  });

  testWidgets('3. SsNavBar(centerKey:) / SsNavCenter(key:): o SsTour aponta para o botão central', (t) async {
    final centro = GlobalKey();
    final pelaAcao = GlobalKey();
    Widget barra({GlobalKey? centerKey, GlobalKey? key}) => MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('pt'),
      supportedLocales: const [Locale('pt')],
      localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        bottomNavigationBar: SsNavBar(
          centerKey: centerKey,
          items: const [
            SsNavItem(Icons.home_outlined, 'Início'),
            SsNavItem(Icons.receipt_long_outlined, 'Pedidos'),
            SsNavItem(Icons.bar_chart_rounded, 'Relatórios'),
            SsNavItem(Icons.person_outline, 'Conta'),
          ],
          currentIndex: 0,
          onTap: (_) {},
          center: SsNavCenter(Icons.add_rounded, label: 'Novo pedido', onTap: () {}, key: key),
        ),
        body: const SizedBox.expand(),
      ),
    );
    await t.pumpWidget(barra(centerKey: centro));
    await t.pumpAndSettle();
    final botao = find.byKey(const ValueKey('ss-nav-center'));
    expect(t.getRect(find.byKey(centro)), t.getRect(botao));

    bool? fim;
    SsTour.show(
      t.element(find.byType(SsNavBar)),
      steps: [SsTourStep(target: centro, title: 'Novo pedido', text: 'Toque aqui para lançar.')],
    ).then((v) => fim = v);
    await t.pumpAndSettle();
    expect(find.text('1 de 1'), findsOneWidget);
    await t.tap(find.text('Concluir'));
    await t.pumpAndSettle();
    expect(fim, isTrue);

    // A chave também pode vir na própria ação central.
    await t.pumpWidget(barra(key: pelaAcao));
    await t.pumpAndSettle();
    expect(t.getRect(find.byKey(pelaAcao)), t.getRect(botao));
  });

  group('4. aviso rico no SsNotificationCenter', () {
    testWidgets('nível com selo e tom, foto, botões (responder marca lida) e Silenciar', (t) async {
      await _tela(t, const Size(400, 800));
      final h = t.ensureSemantics();
      final feito = <String>[];
      final lidos = <String>[];
      await t.pumpWidget(
        _app(
          central([
            _rico(
              level: SsNotificationLevel.critical,
              image: const SizedBox(key: ValueKey('foto')),
              actions: [
                SsNotificationAction('Fechar', () => feito.add('fechar')),
                const SsNotificationAction('Ignorar', null),
              ],
              onMute: () => feito.add('silenciar'),
            ),
          ], markRead: (id) async => lidos.add(id)),
          SsDensity.standard,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('CRÍTICO'), findsOneWidget); // o selo é o micro (caixa alta)
      expect(find.byKey(const ValueKey('foto')), findsOneWidget);
      expect(t.getSize(find.byKey(const ValueKey('foto'))).aspectRatio, closeTo(16 / 9, .01));
      // O topo é um nó (com o nível no rótulo); cada botão, outro.
      expect(
        find.bySemanticsLabel(RegExp(r'^Crítico\. Portão aberto\. Há 10 min\. 14:00\. não lida$')),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Fechar'), findsOneWidget);
      expect(find.bySemanticsLabel('Silenciar'), findsOneWidget);
      await t.tap(find.text('Fechar'));
      await t.pump();
      expect(feito, ['fechar']);
      expect(lidos, ['1']);
      await t.tap(find.text('Ignorar')); // desabilitado
      await t.tap(find.text('Silenciar'));
      expect(feito, ['fechar', 'silenciar']);
      h.dispose();
    });

    testWidgets('aviso e info: o selo só no aviso; o tom/ícone passados ganham do nível', (t) async {
      await t.pumpWidget(
        _app(
          SsNotificationTile(
            item: SsNotificationItem(id: 'a', title: 'Bateria baixa', level: SsNotificationLevel.warning),
          ),
          SsDensity.standard,
        ),
      );
      expect(find.text('AVISO'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsWidgets);
      await t.pumpWidget(
        _app(
          const SsNotificationTile(
            item: SsNotificationItem(
              id: 'b',
              title: 'Backup feito',
              level: SsNotificationLevel.info,
              icon: Icons.backup,
            ),
          ),
          SsDensity.standard,
        ),
      );
      expect(find.text('INFORMAÇÃO'), findsNothing);
      expect(find.byIcon(Icons.backup), findsOneWidget);
    });

    testWidgets('sem os campos novos, a linha é igual: um nó só, um botão', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(SsNotificationTile(item: _rico(), onTap: () {}), SsDensity.standard));
      expect(find.byType(SsButton), findsNothing);
      expect(find.bySemanticsLabel('Portão aberto. Há 10 min. 14:00. não lida'), findsOneWidget);
      h.dispose();
    });

    testWidgets('textos em inglês e espanhol', (t) async {
      expect(SsStrings.en.notifMute, 'Mute');
      expect(SsStrings.en.notifLevelCritical, 'Critical');
      expect(SsStrings.es.notifLevelWarning, 'Aviso');
      expect(SsStrings.pt.copyWith(notifMute: 'Calar').notifMute, 'Calar');
    });
  });
}
