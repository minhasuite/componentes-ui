// v1.9.1: alvo de toque de 48 e texto grande nas peças interativas mais usadas, conferidos pelo
// próprio `ssA11yAudit` (testing.dart) que os apps rodam. Cada peça vai numa tela própria, longe da
// borda (a regra do Flutter pula o que encosta na borda da tela), no compacto (o pior caso: desenha
// menor que 48) e no padrão.
//
// Desenho deliberado (o que a auditoria não cobra aqui):
// - o botão `small` e o chip desenham 32–36; o toque e o nó do leitor de tela já têm 48 pelo
//   `SsTapTarget(semantics: true)`. Numa linha densa que já é o alvo (ex. `SsListItem` com o botão
//   dentro), a área do pai também vale; nada a fazer no produto.
// - `SsNavBar` e `SsDateStrip` encostam na borda quando estão no lugar de uso (fundo da tela, faixa
//   rolável): aqui vão com respiro para a regra medir.
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

/// Peça solta, centrada numa coluna (com largura de celular).
Widget _solta(Widget w) => Center(child: w);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  final pecas = <String, Widget Function()>{
    'SsSegmented': () =>
        _solta(SsSegmented<int>(segments: const [(0, 'Dia'), (1, 'Semana'), (2, 'Mês')], value: 0, onChanged: (_) {})),
    'SsButton small': () => _solta(SsButton(label: 'Salvar', small: true, expand: false, onPressed: () {})),
    'SsButton ghost small': () => _solta(
      SsButton(
        label: 'Marcar todas como lidas',
        icon: Icons.done_all_rounded,
        variant: SsButtonVariant.ghost,
        small: true,
        expand: false,
        onPressed: () {},
      ),
    ),
    'SsButton.text': () => _solta(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SsButton.text(label: 'Ver tudo', onPressed: () {}),
          const SizedBox(width: 24),
          SsButton.text(label: 'Ok', small: true, onPressed: () {}),
        ],
      ),
    ),
    'SsFilterChip': () => _solta(
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SsFilterChip('Todos', selected: true, onTap: () {}),
          SsFilterChip('Pendentes', selected: false, count: 3, onTap: () {}),
          SsFilterChip('Com ícone', icon: Icons.star_rounded, selected: false, onTap: () {}),
        ],
      ),
    ),
    'SsIconButton': () => _solta(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SsIconButton(icon: Icons.edit_outlined, tooltip: 'Editar', onPressed: () {}),
          SsIconButton(icon: Icons.delete_outline, tooltip: 'Excluir', onPressed: () {}),
        ],
      ),
    ),
    'SsHeaderAction': () => _solta(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SsHeaderAction(icon: Icons.search_rounded, tooltip: 'Buscar', onPressed: () {}),
          SsHeaderAction(icon: Icons.notifications_none_rounded, tooltip: 'Avisos', badge: '3', onPressed: () {}),
        ],
      ),
    ),
    'SsSwitchRow': () =>
        _solta(SsSwitchRow(title: 'Lembrete diário', subtitle: 'Às 8h', value: true, onChanged: (_) {})),
    'SsCheckRow': () => _solta(SsCheckRow(title: 'Aceito os termos', value: false, onChanged: (_) {})),
    'SsTabsUnderline': () =>
        _solta(SsTabsUnderline(tabs: const ['Painel', 'Histórico', 'Lojas'], index: 0, onChanged: (_) {})),
    'SsCountTabs': () =>
        _solta(SsCountTabs(tabs: const [('Abertos', 3), ('Pagos', 12), ('Atrasados', 0)], index: 0, onChanged: (_) {})),
    'SsNavBar': () => Align(
      alignment: Alignment.bottomCenter,
      child: SsNavBar(
        items: const [
          SsNavItem(Icons.home_outlined, 'Início'),
          SsNavItem(Icons.receipt_long_outlined, 'Pedidos', badge: 2),
          SsNavItem(Icons.person_outline, 'Conta'),
        ],
        currentIndex: 0,
        onTap: (_) {},
      ),
    ),
    'SsDateStrip': () =>
        _solta(SsDateStrip(selected: DateTime(2026, 11, 24), today: DateTime(2026, 11, 24), onChanged: (_) {})),
    'SsPlanLocked': () =>
        _solta(SsPlanLocked(feature: 'Assistente com IA', text: 'Converse com a IA no plano Pro.', onUpgrade: () {})),
    'SsChatActionCard': () => _solta(
      SsChatActionCard(
        title: 'Lançar despesa',
        icon: Icons.credit_card,
        rows: const [('Valor', 'R\$ 45,00'), ('Cartão', 'Nubank')],
        onConfirm: () {},
        onCancel: () {},
      ),
    ),
    'SsQuota com rótulo longo': () => _solta(
      const SizedBox(width: 240, child: SsQuota(used: 3, limit: 10, label: 'neste mês de cobrança do plano Pro')),
    ),
    'SsAssistantView (atalhos no vazio)': () => SsAssistantView(
      messages: const [],
      onSend: (_) {},
      shortcuts: const [SsAssistantShortcut('Resumo da semana'), SsAssistantShortcut('Metas')],
      onShortcut: (_) {},
    ),
    'SsAssistantView (faixa de atalhos)': () => SsAssistantView(
      messages: const [
        SsAssistantMessage(id: '1', text: 'Oi', fromMe: true),
        SsAssistantMessage(id: '2', text: 'Olá!'),
      ],
      onSend: (_) {},
      shortcuts: const [SsAssistantShortcut('Resumo da semana'), SsAssistantShortcut('Metas')],
      onShortcut: (_) {},
    ),
    'SsNotificationCenter (faixa de cima)': () => SsNotificationCenter(
      now: () => DateTime(2026, 11, 24, 15),
      load: (p) async => SsNotificationPage([
        SsNotificationItem(
          id: '1',
          title: 'Pedido novo',
          body: 'Mercado Bom Preço',
          createdAt: DateTime(2026, 11, 24, 10),
        ),
        SsNotificationItem(
          id: '2',
          title: 'Pagamento',
          body: 'Recebido',
          createdAt: DateTime(2026, 11, 23, 9),
          read: true,
        ),
      ], hasMore: false),
      markRead: (_) async {},
      markAllRead: () async {},
      archive: (_) async {},
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
    });
  }

  testWidgets('SsSegmented: toque na sobra de 48 (fora do desenho) troca a opção', (t) async {
    int? escolhido;
    await t.pumpWidget(
      _app(
        _solta(
          SizedBox(
            height: 48,
            child: Center(
              child: SsSegmented<int>(
                segments: const [(0, 'Dia'), (1, 'Semana')],
                value: 0,
                onChanged: (v) => escolhido = v,
              ),
            ),
          ),
        ),
        SsDensity.compact,
      ),
    );
    final r = t.getRect(find.byType(SsSegmented<int>));
    expect(r.height, lessThan(48)); // o desenho continua compacto
    await t.tapAt(Offset(r.left + r.width * .75, r.top - 4)); // acima do desenho, dentro dos 48
    expect(escolhido, 1);
  });

  testWidgets('SsAssistantView: a faixa de atalhos tem 48 de altura (a rolagem não corta o alvo do chip)', (t) async {
    for (final d in [SsDensity.compact, SsDensity.standard, SsDensity.comfortable]) {
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [SsAssistantMessage(id: '1', text: 'Oi', fromMe: true)],
            onSend: (_) {},
            shortcuts: const [SsAssistantShortcut('Metas')],
            onShortcut: (_) {},
          ),
          d,
        ),
      );
      await t.pump();
      final faixa = find.ancestor(of: find.byType(SsFilterChip), matching: find.byType(SingleChildScrollView));
      expect(t.getSize(faixa).height, greaterThanOrEqualTo(48), reason: d.name);
    }
  });

  testWidgets('SsQuota: rótulo longo com texto 1,6× quebra sem estourar', (t) async {
    await t.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: ssA11yLargeText),
        child: _app(
          _solta(const SizedBox(width: 200, child: SsQuota(used: 9, limit: 10, label: 'neste mês de cobrança'))),
          SsDensity.standard,
        ),
      ),
    );
    expect(t.takeException(), isNull);
  });

  group('SsTour aponta para a alça do menu e para uma aba', () {
    testWidgets('SsNavScaffold(handleKey:) e SsNavBar(itemKeys:)', (t) async {
      final alca = GlobalKey();
      final abas = [GlobalKey(), GlobalKey(), GlobalKey()];
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('pt'),
          supportedLocales: const [Locale('pt')],
          localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
          home: SsNavScaffold(
            peek: false,
            handleKey: alca,
            sideMenu: const SsSideMenu(title: 'Meu App'),
            navBar: SsNavBar(
              itemKeys: abas,
              items: const [
                SsNavItem(Icons.home_outlined, 'Início'),
                SsNavItem(Icons.receipt_long_outlined, 'Pedidos'),
                SsNavItem(Icons.person_outline, 'Conta'),
              ],
              currentIndex: 0,
              onTap: (_) {},
            ),
            body: const SizedBox.expand(),
          ),
        ),
      );
      await t.pumpAndSettle();
      // A chave da alça fica na borda esquerda; a da aba, em volta do nome dela.
      expect(t.getRect(find.byKey(alca)).left, 0);
      expect(t.getRect(find.byKey(abas[1])).contains(t.getCenter(find.text('Pedidos'))), isTrue);

      bool? fim;
      SsTour.show(
        t.element(find.byType(SsNavScaffold)),
        steps: [
          SsTourStep(target: alca, title: 'Menu', text: 'Toque na alça para abrir o menu.'),
          SsTourStep(target: abas[1], title: 'Pedidos'),
        ],
      ).then((v) => fim = v);
      await t.pumpAndSettle();
      expect(find.text('1 de 2'), findsOneWidget); // os dois alvos montados (passo sem alvo é pulado)
      await t.tap(find.text('Próximo'));
      await t.pumpAndSettle();
      expect(find.text('2 de 2'), findsOneWidget);
      await t.tap(find.text('Concluir'));
      await t.pumpAndSettle();
      expect(fim, isTrue);
    });

    testWidgets('SsSideMenuHost(handleKey:) sozinho', (t) async {
      final alca = GlobalKey();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SsSideMenuHost(
            peek: false,
            handleKey: alca,
            menu: const SsSideMenu(title: 'Meu App'),
            child: const Scaffold(body: SizedBox.expand()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byKey(alca), findsOneWidget);
      expect(t.getRect(find.byKey(alca)).left, 0);
    });
  });

  group('ssA11yAudit com FlutterError.onError trocado pelo teste', () {
    Widget ruim() => MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(40),
          child: GestureDetector(onTap: () {}, child: const SizedBox(width: 20, height: 20)),
        ),
      ),
    );

    tearDown(() => debugSsA11yAuditReporter = null);

    testWidgets('handler que engole tudo: registra a falha e volta na hora (não trava)', (t) async {
      await t.pumpWidget(ruim());
      TestFailure? registrada;
      debugSsA11yAuditReporter = (f) => registrada = f;
      final old = FlutterError.onError;
      FlutterError.onError = (_) {};
      try {
        await ssA11yAudit(t, textScale: null).timeout(const Duration(seconds: 5));
      } finally {
        FlutterError.onError = old;
      }
      expect(registrada?.message, contains('48 × 48'));
      expect(registrada?.message, contains('não repassa ao binding'));
    });

    testWidgets('handler que repassa ao binding: continua lançando a falha', (t) async {
      await t.pumpWidget(ruim());
      var registrada = false;
      debugSsA11yAuditReporter = (_) => registrada = true;
      final old = FlutterError.onError;
      FlutterError.onError = (d) => old?.call(d);
      Object? erro;
      try {
        await ssA11yAudit(t, textScale: null);
      } on TestFailure catch (e) {
        erro = e;
      } finally {
        FlutterError.onError = old;
      }
      expect('$erro', contains('48 × 48'));
      expect(registrada, isFalse);
      expect(t.takeException(), isNull); // a sonda não ficou pendente
    });
  });
}
