// Lote A da v0.9: renderiza cada estado do catálogo em claro e escuro (com
// CATALOGO_SAIDA=<pasta> grava os PNG, como o catalogo_test) e testa o
// comportamento das peças que têm lógica.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo_v09_a.dart';

const _dpr = 2.0;

double _contraste(Color a, Color b) {
  final la = a.computeLuminance(), lb = b.computeLuminance();
  final (hi, lo) = la > lb ? (la, lb) : (lb, la);
  return (hi + .05) / (lo + .05);
}

Future<void> _fonte(String familia, List<String> arquivos) async {
  final l = FontLoader(familia);
  for (final f in arquivos) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

Widget _app(Widget child, {ThemeData? theme, bool semAnimacao = false}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  themeAnimationDuration: Duration.zero,
  home: MediaQuery(
    data: MediaQueryData(size: const Size(400, 800), disableAnimations: semAnimacao),
    child: Scaffold(body: child),
  ),
);

void main() {
  final saida = Platform.environment['CATALOGO_SAIDA'];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    await _fonte('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  group('catálogo v0.9 lote a', () {
    for (final c in catalogoV09A) {
      testWidgets(c.nome, (tester) async {
        for (final e in c.estados) {
          for (final tema in ['claro', 'escuro']) {
            tester.view.physicalSize = e.tamanho * _dpr;
            tester.view.devicePixelRatio = _dpr;
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                themeAnimationDuration: Duration.zero,
                theme: tema == 'claro' ? AppTheme.light : AppTheme.dark,
                home: RepaintBoundary(
                  key: const Key('shot'),
                  child: Scaffold(
                    key: ValueKey('${c.slug}/${e.slug}/$tema'),
                    body: Builder(builder: e.build),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(Duration(milliseconds: e.aguarde));
            await tester.runAsync(GoogleFonts.pendingFonts);
            if (saida == null) continue;
            final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
            await tester.runAsync(() async {
              final img = await b.toImage(pixelRatio: _dpr);
              final png = await img.toByteData(format: ui.ImageByteFormat.png);
              File('$saida/${c.slug}/${e.slug}-$tema.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png!.buffer.asUint8List());
            });
          }
        }
        // Deixa terminar o que ainda anima (mola, cascata) antes de desmontar.
        await tester.pump(const Duration(seconds: 2));
        tester.view.reset();
      });
    }
  });

  group('paletas e tema', () {
    test('paletas: violeta primeiro, mapa e lista iguais, consts antigas no mapa', () {
      expect(SsBrand.paletas.keys.first, 'Violeta');
      expect(SsBrand.paletas.values.first, SsBrand.violeta);
      expect(SsBrand.paletas.length, greaterThanOrEqualTo(24));
      expect(SsPaleta.todas.map((p) => p.nome), SsBrand.paletas.keys);
      expect(SsPaleta.todas.map((p) => p.brand), SsBrand.paletas.values);
      for (final b in [SsBrand.tokyoNight, SsBrand.eucalipto, SsBrand.marple, SsBrand.violetDusk, SsBrand.neonPop]) {
        expect(SsBrand.paletas.values, contains(b));
      }
      expect(SsPaleta.porSlug('tokyo-night')?.brand, SsBrand.tokyoNight);
      expect(SsPaleta.of(SsBrand.marple)?.slug, 'marple');
      expect(SsPaleta.todas.every((p) => SsPaleta.familias.contains(p.familia)), isTrue);
    });

    test('texto da marca passa AA sobre página e superfície, claro, escuro e OLED', () {
      for (final MapEntry(key: nome, value: b) in SsBrand.paletas.entries) {
        for (final (dark, oled) in [(false, false), (true, false), (true, true)]) {
          final c = SsColors.forDark(dark, b, oled);
          expect(_contraste(c.accentText, c.page), greaterThanOrEqualTo(4.5), reason: '$nome página $dark/$oled');
          expect(
            _contraste(c.accentText, c.surface),
            greaterThanOrEqualTo(4.5),
            reason: '$nome superfície $dark/$oled',
          );
        }
        // Botão primário no claro: texto branco sobre o accent.
        expect(_contraste(AppColors.onDark, b.accentLight), greaterThanOrEqualTo(4.5), reason: '$nome botão');
      }
    });

    test('gradiente de 4 paradas: paleta usa as suas, violeta deriva da marca', () {
      expect(SsBrand.marple.gradient.colors, SsBrand.marple.stops);
      const v = SsBrand.violeta;
      expect(v.gradient.colors, [v.brandDeep, v.brandTo, v.brandFrom, v.accentDark]);
      for (final b in SsBrand.paletas.values) {
        expect(b.gradientColors, hasLength(4));
      }
    });

    testWidgets('OLED: página preta, isOled e contraste da tinta', (t) async {
      late SsColors c;
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) {
              c = SsColors.of(context);
              return const SizedBox();
            },
          ),
          theme: AppTheme.build(Brightness.dark, oled: true),
        ),
      );
      expect(c.isOled, isTrue);
      expect(c.page, const Color(0xFF000000));
      expect(Theme.of(t.element(find.byType(Scaffold))).scaffoldBackgroundColor, const Color(0xFF000000));
      expect(_contraste(c.ink, c.surface), greaterThanOrEqualTo(7));
      expect(_contraste(c.muted, c.surface), greaterThanOrEqualTo(4.5));
      expect(_contraste(c.muted, c.field), greaterThanOrEqualTo(4.5));
      // No claro, oled é ignorado.
      expect(AppTheme.build(Brightness.light, oled: true).scaffoldBackgroundColor, AppColors.pageLight);
      expect(SsColors.forDark(false, SsBrand.violeta, true).isOled, isFalse);
    });

    test('sombra colorida usa a cor e é mais forte no escuro', () {
      const k = Color(0xFF22C483);
      final claro = SsColors.forDark(false).tintedShadow(k).single;
      final escuro = SsColors.forDark(true).tintedShadow(k).single;
      expect(claro.color.r, closeTo(k.r, .01));
      expect(escuro.color.a, greaterThan(claro.color.a));
    });

    test('squircle é um ContinuousRectangleBorder com raio ampliado', () {
      final s = AppRadius.squircle(20);
      expect((s.borderRadius as BorderRadius).topLeft.x, closeTo(46, .01));
    });
  });

  group('comportamento', () {
    test('mosaico: cada bloco vai para a coluna mais baixa e o largo zera', () {
      final cols = SsMosaicGrid.columnsFor([100, 200, 120, 80, 60, 50], [false, false, false, false, true, false], 10);
      // 100→A, 200→B, 120→A (110<210), 80→A? A=240 > B=210 → B; largo; depois volta à A.
      expect(cols, [0, 1, 0, 1, -1, 0]);
    });

    test('herói: destaca só a 1ª ocorrência do trecho', () {
      expect(SsHeroSplash.split('Seu dinheiro, seu dinheiro', 'dinheiro'), ('Seu ', 'dinheiro', ', seu dinheiro'));
      expect(SsHeroSplash.split('Sem destaque', 'xyz'), ('Sem destaque', '', ''));
      expect(SsHeroSplash.split('Sem destaque', null), ('Sem destaque', '', ''));
    });

    test('pilha: altura fechada e aberta', () {
      expect(SsCardStack.heightFor(3, 100, 14, 12, 0), 128);
      expect(SsCardStack.heightFor(3, 100, 14, 12, 1), 324);
    });

    testWidgets('pilha abre e fecha ao tocar', (t) async {
      final estados = <bool>[];
      await t.pumpWidget(
        _app(
          SsCardStack(
            cardHeight: 100,
            onChanged: estados.add,
            children: [for (var i = 0; i < 3; i++) Container(key: ValueKey(i), color: Colors.grey)],
          ),
        ),
      );
      final fechada = t.getSize(find.byType(SsCardStack)).height;
      await t.tap(find.byType(SsCardStack));
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(SsCardStack)).height, greaterThan(fechada + 150));
      expect(
        t.getTopLeft(find.byKey(const ValueKey(2))).dy,
        greaterThan(t.getTopLeft(find.byKey(const ValueKey(1))).dy + 90),
      );
      await t.tap(find.byType(SsCardStack));
      await t.pumpAndSettle();
      expect(t.getSize(find.byType(SsCardStack)).height, closeTo(fechada, .5));
      expect(estados, [true, false]);
    });

    testWidgets('ticket: o recorte fica na altura real da seção de cima', (t) async {
      await t.pumpWidget(
        _app(
          const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                SsTicketCard(
                  top: SizedBox(key: Key('top'), height: 137),
                  bottom: SizedBox(key: Key('bottom'), height: 60),
                  badge: SizedBox(key: Key('badge')),
                ),
              ],
            ),
          ),
        ),
      );
      final card = t.getRect(find.byType(SsTicketCard));
      expect(card.height, 197);
      expect(t.getTopLeft(find.byKey(const Key('bottom'))).dy, card.top + 137);
      final badge = t.getRect(find.byKey(const Key('badge')));
      expect(badge.center.dy, closeTo(card.top + 137, .01));
      expect(badge.right, closeTo(card.right, .01)); // encaixado no recorte, sem sair do card
    });

    testWidgets('ticket: o badge recebe o toque', (t) async {
      var qr = 0;
      await t.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(20),
            child: SsBoardingPass(fromCode: 'GRU', toCode: 'REC', progress: .5, onQr: () => qr++),
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('Mostrar QR do embarque'));
      expect(qr, 1);
    });

    testWidgets('nav bar com ação central: chama o centro e as abas pulam a vaga do meio', (t) async {
      var centro = 0;
      final abas = <int>[];
      const itens = [
        SsNavItem(Icons.home_outlined, 'Início'),
        SsNavItem(Icons.pie_chart_outline, 'Relatórios'),
        SsNavItem(Icons.credit_card, 'Cartões'),
        SsNavItem(Icons.person_outline, 'Perfil'),
      ];
      await t.pumpWidget(
        _app(
          Align(
            alignment: Alignment.bottomCenter,
            child: SsNavBar(
              items: itens,
              currentIndex: 0,
              onTap: abas.add,
              center: SsNavCenter(Icons.add, onTap: () => centro++, label: 'Novo'),
            ),
          ),
        ),
      );
      final bar = t.getRect(find.byType(SsNavBar));
      final botao = t.getCenter(find.byKey(const ValueKey('ss-nav-center')));
      expect(botao.dx, closeTo(bar.center.dx, 1));
      await t.tap(find.byKey(const ValueKey('ss-nav-center')));
      expect(centro, 1);
      // "Cartões" (3ª aba) fica na 4ª vaga de 5.
      expect(t.getCenter(find.text('Cartões')).dx, closeTo(bar.left + bar.width * 3.5 / 5, 1));
      await t.tap(find.text('Cartões'));
      expect(abas, [2]);
    });

    testWidgets('abas sublinhadas: o traço chega embaixo da aba nova', (t) async {
      Widget tabs(int i) => _app(SsTabsUnderline(tabs: const ['A', 'B', 'C', 'D'], index: i, onChanged: (_) {}));
      await t.pumpWidget(tabs(0));
      await t.pumpWidget(tabs(3));
      await t.pump(); // 1º quadro: o ticker começa a contar aqui
      await t.pump(const Duration(milliseconds: 120));
      Rect traco() =>
          t.getRect(find.descendant(of: find.byType(SsTabsUnderline), matching: find.byType(DecoratedBox)).last);
      final w = t.getSize(find.byType(SsTabsUnderline)).width / 4;
      expect(traco().width, greaterThan(w)); // esticado no caminho
      await t.pumpAndSettle();
      expect(traco().center.dx, closeTo(w * 3.5, 1));
      expect(traco().width, closeTo(w - 28, 1));
    });

    testWidgets('sino pulsa só quando a contagem sobe', (t) async {
      Widget sino(int n) => _app(Center(child: SsBellDot(count: n)));
      await t.pumpWidget(sino(1));
      await t.pump();
      expect(find.byType(Transform), findsWidgets);
      final antes = find.descendant(of: find.byType(SsBellDot), matching: find.byType(Transform)).evaluate().length;
      await t.pumpWidget(sino(2));
      await t.pump(const Duration(milliseconds: 100));
      final durante = find.descendant(of: find.byType(SsBellDot), matching: find.byType(Transform)).evaluate().length;
      expect(durante, greaterThan(antes)); // o anel aparece
      await t.pumpAndSettle();
      expect(find.descendant(of: find.byType(SsBellDot), matching: find.byType(Transform)).evaluate().length, antes);
      expect(find.bySemanticsLabel('Notificações: 2 novas'), findsOneWidget);
    });

    testWidgets('duo: tocar no outro lado troca', (t) async {
      final v = <int>[];
      await t.pumpWidget(
        _app(
          SsDuoStat(
            items: const [SsDuoItem('Despesas', r'R$ 1'), SsDuoItem('Receitas', r'R$ 2')],
            index: 0,
            onChanged: v.add,
          ),
        ),
      );
      await t.tap(find.text('Despesas'));
      await t.tap(find.text('Receitas'));
      expect(v, [1]);
    });

    testWidgets('reflexo não passa com menos movimento', (t) async {
      await t.pumpWidget(_app(const SsShimmerGlass(child: SizedBox(width: 100, height: 60)), semAnimacao: true));
      await t.pump(const Duration(milliseconds: 600));
      expect(find.descendant(of: find.byType(SsShimmerGlass), matching: find.byType(CustomPaint)), findsNothing);
    });

    testWidgets('passo do fluxo: leitor de tela e cancelar', (t) async {
      var cancelou = false;
      await t.pumpWidget(_app(SsStepTopBar(step: 3, total: 4, onCancel: () => cancelou = true)));
      expect(find.bySemanticsLabel('Passo 3 de 4'), findsOneWidget);
      await t.tap(find.text('CANCELAR'));
      expect(cancelou, isTrue);
    });
  });
}
