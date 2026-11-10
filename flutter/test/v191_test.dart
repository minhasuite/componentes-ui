// v0.19.1: conteúdo das abas, aba com ícone em cima, dica ao segurar, fio em
// pé, item de menu com widget, tela cheia, cor que vem de dado, glifo de ícone
// no canvas e os tokens novos (o que o minhas-compras e o minhas-viagens pediam).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget home, {ThemeData? theme}) =>
    MaterialApp(theme: theme ?? AppTheme.light, localizationsDelegates: const [SsStrings.delegate], home: home);

class _Abas extends StatefulWidget {
  const _Abas({this.stacked = false, this.swipe = true});
  final bool stacked;
  final bool swipe;

  @override
  State<_Abas> createState() => _AbasState();
}

class _AbasState extends State<_Abas> with SingleTickerProviderStateMixin {
  late final _tabs = TabController(length: 5, vsync: this)..addListener(() => setState(() {}));

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        SsTabsUnderline(
          tabs: const ['Cronograma', 'Passeios', 'Reservas', 'Gastos', 'Resumo'],
          icons: const [
            Icons.view_timeline_outlined,
            Icons.local_activity_outlined,
            Icons.confirmation_number_outlined,
            Icons.payments_outlined,
            Icons.pie_chart_outline,
          ],
          stacked: widget.stacked,
          index: _tabs.index,
          onChanged: _tabs.animateTo,
        ),
        Expanded(
          child: SsTabsView(
            controller: _tabs,
            swipe: widget.swipe,
            children: [for (var i = 0; i < 5; i++) Center(child: Text('página $i'))],
          ),
        ),
      ],
    ),
  );
}

class _Pintor extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      ssPaintIcon(canvas, Icons.flight, size.center(Offset.zero), size: 20, color: AppColors.danger, angle: .5);

  @override
  bool shouldRepaint(_Pintor old) => false;
}

void main() {
  group('SsTabsView', () {
    testWidgets('segue o controlador: toque na aba e arrastar trocam a página', (t) async {
      await t.pumpWidget(_app(const _Abas()));
      expect(find.text('página 0'), findsOneWidget);
      await t.tap(find.text('Reservas'));
      await t.pumpAndSettle();
      expect(find.text('página 2'), findsOneWidget);
      await t.fling(find.text('página 2'), const Offset(-400, 0), 1500);
      await t.pumpAndSettle();
      expect(find.text('página 3'), findsOneWidget);
    });

    testWidgets('swipe: false não troca ao arrastar', (t) async {
      await t.pumpWidget(_app(const _Abas(swipe: false)));
      await t.fling(find.text('página 0'), const Offset(-400, 0), 1500);
      await t.pumpAndSettle();
      expect(find.text('página 0'), findsOneWidget);
    });

    testWidgets('sem controller usa o DefaultTabController', (t) async {
      await t.pumpWidget(
        _app(
          const DefaultTabController(
            length: 2,
            child: Scaffold(body: SsTabsView(children: [Text('a'), Text('b')])),
          ),
        ),
      );
      expect(find.text('a'), findsOneWidget);
    });
  });

  group('SsTabsUnderline(stacked:)', () {
    testWidgets('5 abas com ícone cabem em 360 px sem rolar, na altura do stackedHeight', (t) async {
      t.view.physicalSize = const Size(360, 640) * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(const _Abas(stacked: true)));
      expect(t.takeException(), isNull);
      expect(
        find.descendant(of: find.byType(SsTabsUnderline), matching: find.byType(SingleChildScrollView)),
        findsNothing,
      );
      final ctx = t.element(find.byType(SsTabsUnderline));
      expect(SsTabsUnderline.stackedHeight(ctx), 66);
      expect(t.getSize(find.byType(SsTabsUnderline)).height, greaterThanOrEqualTo(66));
      // Ícone em cima do nome.
      final icone = t.getCenter(find.byIcon(Icons.payments_outlined));
      final nome = t.getCenter(find.text('Gastos'));
      expect(icone.dy, lessThan(nome.dy));
      expect((icone.dx - nome.dx).abs(), lessThan(1));
    });

    testWidgets('fonte 1,6× não estoura', (t) async {
      t.view.physicalSize = const Size(360, 640) * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(size: Size(360, 640), textScaler: TextScaler.linear(1.6)),
            child: _Abas(stacked: true),
          ),
        ),
      );
      expect(t.takeException(), isNull);
    });

    testWidgets('sem stacked e com ícones, rola quando não cabe (como antes)', (t) async {
      t.view.physicalSize = const Size(360, 640) * 2;
      t.view.devicePixelRatio = 2;
      addTearDown(t.view.reset);
      await t.pumpWidget(_app(const _Abas()));
      expect(
        find.descendant(of: find.byType(SsTabsUnderline), matching: find.byType(SingleChildScrollView)),
        findsOneWidget,
      );
    });
  });

  group('SsTooltip', () {
    testWidgets('segurar mostra a mensagem com os tokens do tema', (t) async {
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: Center(
              child: SsTooltip(message: 'Trocar a cidade', child: Text('Fortaleza')),
            ),
          ),
        ),
      );
      await t.longPress(find.text('Fortaleza'));
      await t.pump(const Duration(milliseconds: 300));
      expect(find.text('Trocar a cidade'), findsOneWidget);
      final tip = t.widget<Tooltip>(find.byType(Tooltip));
      expect((tip.decoration! as BoxDecoration).color, AppColors.inkLight);
      expect(tip.textStyle!.color, AppColors.surfaceLight);
      expect(tip.triggerMode, TooltipTriggerMode.longPress);
      await t.pumpAndSettle(const Duration(seconds: 3));
    });

    testWidgets('no escuro, fundo do campo com borda', (t) async {
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: SsTooltip(message: 'x', child: Text('y')),
          ),
          theme: AppTheme.dark,
        ),
      );
      final tip = t.widget<Tooltip>(find.byType(Tooltip));
      expect((tip.decoration! as BoxDecoration).color, AppColors.fieldDark);
      expect((tip.decoration! as BoxDecoration).border, isNotNull);
    });

    testWidgets('o leitor de tela lê a mensagem', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: SsTooltip(message: 'Amazon: 3 ofertas', child: Text('Amazon')),
          ),
        ),
      );
      expect(find.byTooltip('Amazon: 3 ofertas'), findsOneWidget);
      expect(t.getSemantics(find.text('Amazon')).getSemanticsData().tooltip, 'Amazon: 3 ofertas');
      h.dispose();
    });
  });

  group('SsDivider.vertical', () {
    testWidgets('fio em pé de 1 px com a cor da linha', (t) async {
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: SizedBox()),
                  SsDivider.vertical(),
                  Expanded(child: SizedBox()),
                ],
              ),
            ),
          ),
        ),
      );
      expect(t.getSize(find.byType(SsDivider)), const Size(1, 200));
      final v = t.widget<VerticalDivider>(find.byType(VerticalDivider));
      expect(v.color, SsColors.forDark(false).line);
    });

    testWidgets('vertical: true com largura e recuo', (t) async {
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: SizedBox(height: 100, child: Row(children: [SsDivider(vertical: true, height: 17, indent: 8)])),
          ),
        ),
      );
      expect(t.getSize(find.byType(SsDivider)).width, 17);
      expect(t.widget<VerticalDivider>(find.byType(VerticalDivider)).indent, 8);
    });
  });

  group('SsMenuAction(leading:) e SsOverflowMenu(child:)', () {
    testWidgets('âncora própria abre o menu com o widget no lugar do ícone', (t) async {
      var escolhida = '';
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Center(
              child: SsOverflowMenu(
                tooltip: 'Buscar no app da loja',
                items: [
                  SsMenuAction(
                    Icons.storefront,
                    'Buscar no app da Shopee',
                    () => escolhida = 'shopee',
                    leading: const SizedBox(key: Key('logo'), width: 18, height: 18),
                  ),
                ],
                child: const Text('No app'),
              ),
            ),
          ),
        ),
      );
      // Com child, uma ação só não vira botão de ícone: abre o menu.
      await t.tap(find.text('No app'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('logo')), findsOneWidget);
      expect(find.byIcon(Icons.storefront), findsNothing);
      await t.tap(find.text('Buscar no app da Shopee'));
      await t.pumpAndSettle();
      expect(escolhida, 'shopee');
    });

    testWidgets('sem child segue o ⋮ e uma ação só vira o botão dela', (t) async {
      await t.pumpWidget(
        _app(Scaffold(body: SsOverflowMenu(items: [SsMenuAction(Icons.delete_outline, 'Excluir', () {})]))),
      );
      expect(find.byIcon(Icons.delete_outline), findsOneWidget);
    });
  });

  group('showSsFullscreen', () {
    Widget abre({bool dismissOnTap = false}) => Scaffold(
      body: Builder(
        builder: (context) => Center(
          child: SsButton(
            label: 'abrir',
            expand: false,
            onPressed: () => showSsFullscreen<void>(
              context,
              title: 'Frase',
              dismissOnTap: dismissOnTap,
              child: const Center(child: Text('Où sont les toilettes ?')),
            ),
          ),
        ),
      ),
    );

    testWidgets('abre por cima com título; o × fecha', (t) async {
      await t.pumpWidget(_app(abre()));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.byType(SsFullscreenPage), findsOneWidget);
      expect(find.text('Frase'), findsOneWidget);
      final ctx = t.element(find.byType(SsFullscreenPage));
      await t.tap(find.byTooltip(SsStrings.of(ctx).close));
      await t.pumpAndSettle();
      expect(find.byType(SsFullscreenPage), findsNothing);
    });

    testWidgets('dismissOnTap fecha com um toque e diz a dica', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(abre(dismissOnTap: true)));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(t.getSemantics(find.text('Où sont les toilettes ?')), isNotNull);
      expect(find.bySemanticsLabel(RegExp('toilettes')), findsWidgets);
      await t.tap(find.text('Où sont les toilettes ?'));
      await t.pumpAndSettle();
      expect(find.byType(SsFullscreenPage), findsNothing);
      h.dispose();
    });

    testWidgets('textos pt/en/es', (t) async {
      expect(SsStrings.pt.tapToClose, 'Toque para fechar');
      expect(SsStrings.en.tapToClose, 'Tap to close');
      expect(SsStrings.es.tapToClose, 'Toca para cerrar');
    });
  });

  group('cor que vem de dado', () {
    test('hex em texto', () {
      expect(ssColorFromHex('#E43225'), const Color(0xFFE43225));
      expect(ssColorFromHex('e43225'), const Color(0xFFE43225));
      expect(ssColorFromHex('#fff'), const Color(0xFFFFFFFF));
      expect(ssColorFromHex('#11223380'), const Color(0x80112233));
      expect(() => ssColorFromHex('azul'), throwsFormatException);
    });

    test('tentativa devolve nulo', () {
      expect(ssTryColorFromHex(null), isNull);
      expect(ssTryColorFromHex(''), isNull);
      expect(ssTryColorFromHex('#12345'), isNull);
      expect(ssTryColorFromHex(' #3A6EA5 '), const Color(0xFF3A6EA5));
    });

    test('inteiro 0xRRGGBB', () {
      expect(ssColorFromRgb(0x3A6EA5), const Color(0xFF3A6EA5));
      expect(ssColorFromRgb(0x7F3A6EA5), const Color(0xFF3A6EA5));
    });
  });

  group('glifo de ícone no canvas', () {
    test('ssIconTextStyle leva a fonte do ícone', () {
      final s = ssIconTextStyle(Icons.flight, size: 20, color: AppColors.danger);
      expect(s.fontFamily, Icons.flight.fontFamily);
      expect(s.fontSize, 20);
      expect(s.color, AppColors.danger);
      expect(s.inherit, isFalse);
    });

    testWidgets('ssPaintIcon pinta sem erro', (t) async {
      await t.pumpWidget(
        _app(
          Scaffold(
            body: CustomPaint(size: const Size(60, 60), painter: _Pintor()),
          ),
        ),
      );
      expect(t.takeException(), isNull);
    });
  });

  test('tokens novos', () {
    expect(AppColors.transparent.a, 0);
    expect(AppType.solid, 1.0);
    expect(AppType.tight, 1.2);
    expect(AppType.snug, 1.3);
    expect(AppType.trackingTight, .5);
    expect(AppType.trackingTitle, -.3);
  });
}
