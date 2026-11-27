// v1.9.3: o que a conferência no emulador dos 8 apps achou (27/11/2026): a alça do menu dentro do gesto de
// voltar do Android, o trilho da tela larga fora da árvore do leitor de tela (e a faixa clara sob a barra de
// status), o sino que lia só o número, rótulos cortados com texto 1,6× (barra de abas, card de indicador,
// selo "99+"), o ".." no aviso, o milhar da cota e os alvos de 48 do chip e do campo compacto.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  Widget home, {
  Locale locale = const Locale('pt', 'BR'),
  SsDensity density = SsDensity.standard,
  EdgeInsets? padding,
  EdgeInsets? gestures,
  double? textScale,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: SsStrings.supportedLocales,
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  builder: (context, child) {
    var mq = MediaQuery.of(context);
    if (padding != null) mq = mq.copyWith(padding: padding, viewPadding: padding);
    if (gestures != null) mq = mq.copyWith(systemGestureInsets: gestures);
    if (textScale != null) mq = mq.copyWith(textScaler: TextScaler.linear(textScale));
    return MediaQuery(
      data: mq,
      child: SsDensityScope(density: density, child: child!),
    );
  },
  home: home,
);

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

const _abas = [
  SsNavItem(Icons.home_outlined, 'Início'),
  SsNavItem(Icons.receipt_long_outlined, 'Lançamentos'),
  SsNavItem(Icons.auto_awesome_outlined, 'Assistente'),
  SsNavItem(Icons.account_balance_wallet_outlined, 'Carteira'),
  SsNavItem(Icons.insights_outlined, 'Planejar'),
];

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('1. SsSideMenuHost fora do gesto de voltar do sistema', () {
    Widget host(GlobalKey<SsSideMenuHostState> k, GlobalKey alca) => SsSideMenuHost(
      key: k,
      peek: false,
      handleKey: alca,
      menu: const SizedBox.expand(child: Text('Painel')),
      child: const Scaffold(body: Center(child: Text('Tela'))),
    );

    testWidgets('com gesto do sistema (24): a alça e a faixa de arrastar começam depois dele', (t) async {
      await _tela(t, const Size(400, 800));
      final k = GlobalKey<SsSideMenuHostState>();
      final alca = GlobalKey();
      await t.pumpWidget(_app(host(k, alca), gestures: const EdgeInsets.only(left: 24, right: 24)));
      final r = t.getRect(find.byKey(alca));
      expect(r.left, greaterThanOrEqualTo(24));
      // O nó "Abrir o menu" (a faixa) também fica fora do gesto.
      final h = t.ensureSemantics();
      expect(_noDe(t, find.bySemanticsLabel('Abrir o menu')).left, greaterThanOrEqualTo(24));
      h.dispose();
      // A pílula solta da borda arredonda as duas pontas.
      final pilula = t.widget<Container>(find.descendant(of: find.byKey(alca), matching: find.byType(Container)));
      expect((pilula.decoration! as BoxDecoration).borderRadius, BorderRadius.circular(99));

      // Tocar na alça abre o menu.
      await t.tapAt(r.center);
      await t.pumpAndSettle();
      expect(k.currentState!.isOpen, isTrue);
      k.currentState!.close();
      await t.pumpAndSettle();

      // Arrastar a partir da alça (fora do gesto) também abre.
      await t.dragFrom(r.center, const Offset(260, 0));
      await t.pumpAndSettle();
      expect(k.currentState!.isOpen, isTrue);
    });

    testWidgets('sem gesto do sistema (botões, iOS): colada na borda, como antes', (t) async {
      await _tela(t, const Size(400, 800));
      final k = GlobalKey<SsSideMenuHostState>();
      final alca = GlobalKey();
      await t.pumpWidget(_app(host(k, alca)));
      expect(t.getRect(find.byKey(alca)).left, 0);
      final pilula = t.widget<Container>(find.descendant(of: find.byKey(alca), matching: find.byType(Container)));
      expect(
        (pilula.decoration! as BoxDecoration).borderRadius,
        const BorderRadius.horizontal(right: Radius.circular(99)),
      );
      await t.dragFrom(const Offset(4, 400), const Offset(260, 0));
      await t.pumpAndSettle();
      expect(k.currentState!.isOpen, isTrue);
    });

    test('gestureFreeLeft soma o gesto e o recorte', () {
      const mq = MediaQueryData(systemGestureInsets: EdgeInsets.only(left: 30), padding: EdgeInsets.only(left: 8));
      expect(SsSideMenuHost.gestureFreeLeft(mq), 38);
    });
  });

  group('2. SsAdaptiveScaffold na tela larga', () {
    Widget casca({int i = 0, ValueChanged<int>? onTap}) => SsAdaptiveScaffold(
      items: _abas,
      currentIndex: i,
      onTap: onTap ?? (_) {},
      railHeader: IconButton(onPressed: () {}, icon: const Icon(Icons.search), tooltip: 'Buscar'),
      railFooter: IconButton(onPressed: () {}, icon: const Icon(Icons.person), tooltip: 'Conta'),
      body: const Center(child: Text('Corpo')),
    );

    testWidgets('cada aba do trilho é um botão com rótulo, estado e toque; topo e rodapé na árvore', (t) async {
      await _tela(t, const Size(1000, 800));
      var tocou = -1;
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(casca(i: 2, onTap: (v) => tocou = v)));
      expect(
        t.getSemantics(find.bySemanticsLabel('Assistente, aba 3 de 5')),
        isSemantics(isButton: true, isSelected: true, hasSelectedState: true, hasTapAction: true),
      );
      final outra = find.bySemanticsLabel('Lançamentos, aba 2 de 5');
      expect(t.getSemantics(outra), isSemantics(isButton: true, isSelected: false, hasTapAction: true));
      await t.tap(outra);
      expect(tocou, 1);
      expect(
        t.getSemantics(find.byTooltip('Buscar')),
        isSemantics(tooltip: 'Buscar', isButton: true, hasTapAction: true),
      );
      expect(
        t.getSemantics(find.byTooltip('Conta')),
        isSemantics(tooltip: 'Conta', isButton: true, hasTapAction: true),
      );
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('o trilho pinta sob a barra de status e a de navegação', (t) async {
      await _tela(t, const Size(1000, 800));
      await t.pumpWidget(_app(casca(), padding: const EdgeInsets.only(top: 24, bottom: 16)));
      final ctx = t.element(find.byType(SsSideRail));
      final accent = SsColors.of(ctx).accent;
      final faixas = find.byWidgetPredicate((w) => w is Container && w.color == accent);
      final rects = faixas.evaluate().map((e) => t.getRect(find.byWidget(e.widget))).toList();
      // (o Container da faixa inclui a margem do recorte, 23 à direita)
      expect(rects.where((r) => r.left == 0 && r.top == 0 && r.height == 24), hasLength(1));
      expect(rects.where((r) => r.left == 0 && r.bottom == 800 && r.height == 16), hasLength(1));
      // O conteúdo fica depois da barra de status.
      expect(t.getRect(find.byTooltip('Buscar')).top, greaterThanOrEqualTo(24));
    });
  });

  group('3 e 6. SsNotificationBell', () {
    Future<String> rotulo(WidgetTester t, int n, Locale l) async {
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: SsNotificationBell(count: n, onPressed: () {}),
            ),
          ),
          locale: l,
        ),
      );
      return t.getSemantics(find.byType(SsNotificationBell)).label;
    }

    testWidgets('lê "Notificações, N não lidas" com o plural certo (pt, en, es), e não só o número', (t) async {
      final h = t.ensureSemantics();
      const pt = Locale('pt', 'BR');
      expect(await rotulo(t, 3, pt), 'Notificações, 3 não lidas');
      expect(find.bySemanticsLabel('3'), findsNothing);
      expect(await rotulo(t, 1, pt), 'Notificações, 1 não lida');
      expect(await rotulo(t, 0, pt), 'Notificações');
      expect(await rotulo(t, 120, pt), 'Notificações, 120 não lidas');
      expect(await rotulo(t, 3, const Locale('en')), 'Notifications, 3 unread');
      expect(await rotulo(t, 1, const Locale('es')), 'Notificaciones, 1 no leída');
      expect(await rotulo(t, 3, const Locale('es')), 'Notificaciones, 3 no leídas');
      final no = t.getSemantics(find.byType(SsNotificationBell)).getSemanticsData();
      expect(no.flagsCollection.isButton, isTrue);
      expect(no.hasAction(SemanticsAction.tap), isTrue);
      h.dispose();
    });

    testWidgets('"99+" cabe no alvo do botão com texto 1,6×, mesmo encostado na borda direita', (t) async {
      await _tela(t, const Size(360, 640));
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Align(
              alignment: Alignment.topRight,
              child: SsNotificationBell(count: 120, onPressed: () {}),
            ),
          ),
          textScale: 1.6,
        ),
      );
      final sino = t.getRect(find.byType(SsNotificationBell));
      final selo = t.getRect(find.byType(Badge));
      final texto = t.getRect(find.text('99+'));
      expect(sino.right, lessThanOrEqualTo(360));
      expect(texto.right, lessThanOrEqualTo(sino.right));
      expect(selo.right, lessThanOrEqualTo(sino.right));
      expect(t.renderObject<RenderParagraph>(find.text('99+')).didExceedMaxLines, isFalse);
      expect(t.takeException(), isNull);
    });

    testWidgets('nome e texto próprios continuam valendo', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: SsNotificationBell(count: 2, label: 'Avisos', unreadLabel: (n) => 'Avisos, $n novos'),
            ),
          ),
        ),
      );
      expect(t.getSemantics(find.byType(SsNotificationBell)).label, 'Avisos, 2 novos');
      h.dispose();
    });
  });

  group('4. SsNavBar com texto 1,6×', () {
    testWidgets('5 abas em 360: nenhum rótulo cortado, alvo de toque preservado', (t) async {
      await _tela(t, const Size(360, 640));
      await t.pumpWidget(
        _app(
          Scaffold(
            body: const SizedBox.expand(),
            bottomNavigationBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
          ),
          textScale: 1.6,
        ),
      );
      for (final a in _abas) {
        final p = t.renderObject<RenderParagraph>(find.text(a.label));
        expect(p.didExceedMaxLines, isFalse, reason: '${a.label} cortado');
        expect(t.getSize(find.text(a.label)).width, lessThanOrEqualTo(360 / 5));
      }
      // Só o rótulo encolhe, e nunca abaixo do tamanho normal.
      final lanc = t.widget<Text>(find.text('Lançamentos'));
      final escala = lanc.textScaler!.scale(AppType.label);
      expect(escala, lessThan(AppType.label * 1.6));
      expect(escala, greaterThanOrEqualTo(SsNavBar.minLabelSize));
      // Rótulo curto fica com a escala inteira.
      expect(t.widget<Text>(find.text('Início')).textScaler!.scale(AppType.label), closeTo(AppType.label * 1.6, .01));
      final h = t.ensureSemantics();
      final aba = _noDe(t, find.bySemanticsLabel('Lançamentos, aba 2 de 5'));
      expect(aba.height, greaterThanOrEqualTo(48));
      expect(aba.width, greaterThanOrEqualTo(48));
      h.dispose();
      expect(t.takeException(), isNull);
    });
  });

  testWidgets('5. SsStatCard a 1,6×: o rótulo quebra a linha em vez de cortar', (t) async {
    await _tela(t, const Size(360, 640));
    await t.pumpWidget(
      _app(
        const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 156,
              child: SsStatCard(label: 'Receita recorrente', value: 'R\$ 1.234,00', icon: Icons.trending_up),
            ),
          ),
        ),
        textScale: 1.6,
      ),
    );
    final p = t.renderObject<RenderParagraph>(find.text('Receita recorrente'));
    expect(p.didExceedMaxLines, isFalse);
    expect(t.getSize(find.text('Receita recorrente')).height, greaterThan(AppType.sub * 1.6 * 1.5));
    // "recorrente" não cabe ao lado do ícone: o ícone sobe e a palavra não parte no meio.
    final ico = t.getRect(find.byIcon(Icons.trending_up));
    final rot = t.getRect(find.text('Receita recorrente'));
    expect(ico.bottom, lessThanOrEqualTo(rot.top));
    // Com texto normal, o ícone fica ao lado.
    await t.pumpWidget(
      _app(
        const Scaffold(
          body: SizedBox(
            width: 156,
            child: SsStatCard(label: 'Receita recorrente', value: 'R\$ 1.234,00', icon: Icons.trending_up),
          ),
        ),
      ),
    );
    expect(t.getRect(find.byIcon(Icons.trending_up)).right, lessThan(t.getRect(find.text('Receita recorrente')).left));
    expect(t.takeException(), isNull);
  });

  group('7. SsNotificationTile', () {
    testWidgets('o leitor não lê ".." quando o corpo termina em ponto', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          Scaffold(
            body: SsNotificationTile(
              item: SsNotificationItem(
                id: '1',
                title: 'Boleto disponível!',
                body: 'Chegou o boleto de dezembro.',
                createdAt: DateTime(2026, 11, 27, 10, 30),
              ),
              onTap: () {},
            ),
          ),
        ),
      );
      final no = find.bySemanticsLabel(RegExp('Chegou o boleto'));
      final texto = t.getSemantics(no).label;
      expect(texto, isNot(contains('..')));
      expect(texto, isNot(contains('!.')));
      expect(texto, startsWith('Boleto disponível! Chegou o boleto de dezembro. 10:30'));
      h.dispose();
    });

    test('ssJoinSentences', () {
      expect(ssJoinSentences(['Título', 'Corpo.', '10:30', 'não lida']), 'Título. Corpo. 10:30. não lida');
      expect(ssJoinSentences(['Pergunta?', '', ' Fim… ', 'x']), 'Pergunta? Fim… x');
    });
  });

  group('8. SsQuota com milhar', () {
    testWidgets('"36 de 1.500 este mês"', (t) async {
      await t.pumpWidget(_app(const Scaffold(body: Center(child: SsQuota(used: 36, limit: 1500)))));
      expect(find.text('36 de 1.500 este mês'), findsOneWidget);
    });

    test('quotaText usa o SsFormats e não mexe em número pequeno nem dentro de outro', () {
      expect(SsQuota.quotaText(SsStrings.pt, SsFormats.brl, 1500, 1500, 'este mês'), '1.500 de 1.500 este mês');
      expect(SsQuota.quotaText(SsStrings.en, SsFormats.usd, 36, 1500, 'this month'), '36 of 1,500 this month');
      expect(SsQuota.quotaText(SsStrings.es, SsFormats.eur, 2, 3, 'este mes'), '2 de 3 este mes');
      expect(SsQuota.quotaText(SsStrings.pt, SsFormats.brl, 15, 1500, 'este mês'), '15 de 1.500 este mês');
    });
  });

  group('9 e 10. alvos de 48 no compacto', () {
    Widget solto(Widget w) => Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(24), child: w),
      ),
    );

    testWidgets('SsFilterChip de rótulo curto: 48 de largura de toque, o desenho igual', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(solto(SsFilterChip('Pix', selected: false, onTap: () {})), density: SsDensity.compact));
      final no = _noDe(t, find.bySemanticsLabel('Pix'));
      expect(no.width, greaterThanOrEqualTo(48));
      expect(no.height, greaterThanOrEqualTo(48));
      // O desenho continua do tamanho do rótulo.
      final caixa = t.getSize(find.byType(AnimatedContainer).first);
      expect(caixa.width, lessThan(48));
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('SsTextField compacto: o nó do campo tem 48', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          solto(
            const SizedBox(
              width: 280,
              child: SsTextField(label: 'Nome', hint: 'Seu nome'),
            ),
          ),
          density: SsDensity.compact,
        ),
      );
      final no = _noDe(t, find.bySemanticsLabel(RegExp('Nome')));
      expect(no.height, greaterThanOrEqualTo(48));
      expect(
        t.getSemantics(find.bySemanticsLabel(RegExp('Nome'))).getSemanticsData().flagsCollection.isTextField,
        isTrue,
      );
      h.dispose();
      await t.enterText(find.byType(EditableText), 'Ana');
      expect(find.text('Ana'), findsOneWidget);
      await ssA11yAudit(t);
    });

    testWidgets('SsTextField com suffix: o botão continua um nó próprio', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          solto(
            SizedBox(
              width: 280,
              child: SsTextField(
                label: 'Senha',
                obscureText: true,
                suffix: IconButton(onPressed: () {}, icon: const Icon(Icons.visibility), tooltip: 'Mostrar senha'),
              ),
            ),
          ),
          density: SsDensity.compact,
        ),
      );
      expect(
        t.getSemantics(find.byTooltip('Mostrar senha')),
        isSemantics(tooltip: 'Mostrar senha', isButton: true, hasTapAction: true),
      );
      h.dispose();
    });
  });
}
