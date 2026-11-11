// v0.19.2: as últimas caixas genéricas do minhas-compras-app e do
// minhas-viagens-app (herói com conteúdo livre, botão sobre o gradiente,
// faixa e contorno no card, monograma, foto escolhida, selo sólido, passos
// numerados, ponto, recado, palco, indicador de página, vidro escuro e chip
// de loja com estado).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate],
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

BoxDecoration _decoracao(WidgetTester t, Finder f) {
  final c = t.widget<Container>(find.ancestor(of: f, matching: find.byType(Container)).first);
  return c.decoration! as BoxDecoration;
}

void main() {
  group('SsHeroCard.custom', () {
    testWidgets('conteúdo livre claro, fundo atrás, toque e rótulo', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          SsHeroCard.custom(
            background: const Positioned(right: 0, top: 0, child: SizedBox(key: Key('arco'), width: 40, height: 20)),
            onTap: () => n++,
            semanticLabel: 'Foto do cupom',
            child: const Row(children: [Icon(Icons.receipt_long), Text('Foto do cupom')]),
          ),
        ),
      );
      final txt = t.widget<RichText>(find.descendant(of: find.text('Foto do cupom'), matching: find.byType(RichText)));
      expect(txt.text.style?.color, AppColors.onDark);
      final ico = t.widget<RichText>(
        find.descendant(of: find.byIcon(Icons.receipt_long), matching: find.byType(RichText)),
      );
      expect(ico.text.style?.color, AppColors.onDark);
      expect(find.byKey(const Key('arco')), findsOneWidget);
      await t.tap(find.byType(SsHeroCard));
      await t.pumpAndSettle();
      expect(n, 1);
      expect(find.bySemanticsLabel('Foto do cupom'), findsOneWidget);
    });

    testWidgets('gradiente da marca, raio e sombra configuráveis; o de número continua igual', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            children: [
              SsHeroCard.custom(radius: AppRadius.sheet, shadow: false, child: Text('login')),
              SsHeroCard(label: 'Saldo', value: 'R\$ 10'),
            ],
          ),
        ),
      );
      final box = t.widget<Container>(find.ancestor(of: find.text('login'), matching: find.byType(Container)).last);
      final dec = box.decoration! as BoxDecoration;
      expect(dec.gradient, isA<LinearGradient>());
      expect(dec.borderRadius, BorderRadius.circular(AppRadius.sheet));
      expect(dec.boxShadow, isNull);
      expect(find.text('Saldo'), findsOneWidget);
      expect(find.text('R\$ 10'), findsOneWidget);
    });
  });

  group('SsButton.onGradient e stacked', () {
    testWidgets('sólido: fundo claro e texto na cor funda da marca, ícone em cima', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 110,
            child: SsButton.onGradient(
              label: 'Hospedagem',
              icon: Icons.hotel,
              solid: true,
              stacked: true,
              onPressed: () => n++,
            ),
          ),
        ),
      );
      final ctx = t.element(find.byType(SsButton));
      final c = SsColors.of(ctx);
      final txt = t.widget<Text>(find.text('Hospedagem'));
      expect(txt.style?.color, c.brandDeep);
      final ico = t.getTopLeft(find.byIcon(Icons.hotel));
      final lab = t.getTopLeft(find.text('Hospedagem'));
      expect(ico.dy, lessThan(lab.dy));
      expect(find.ancestor(of: find.text('Hospedagem'), matching: find.byType(FittedBox)), findsOneWidget);
      final mat = t.widget<Material>(find.ancestor(of: find.text('Hospedagem'), matching: find.byType(Material)).first);
      expect(mat.color, AppColors.onDark);
      await t.tap(find.text('Hospedagem'));
      await t.pumpAndSettle();
      expect(n, 1);
      expect(t.takeException(), isNull);
    });

    testWidgets('translúcido: texto claro com fio; empilhado cabe em 3 colunas de 360 com fonte 1,6×', (t) async {
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(1.6), size: Size(360, 640)),
          child: _app(
            Row(
              spacing: 8,
              children: [
                for (final l in ['Voo', 'Pacote', 'Hospedagem'])
                  Expanded(
                    child: SsButton.onGradient(label: l, icon: Icons.flight, stacked: true, onPressed: () {}),
                  ),
              ],
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      final txt = t.widget<Text>(find.text('Voo'));
      expect(txt.style?.color, AppColors.onDark);
    });

    testWidgets('stacked no botão comum', (t) async {
      await t.pumpWidget(_app(SsButton(label: 'Escanear', icon: Icons.qr_code, stacked: true, onPressed: () {})));
      expect(t.getTopLeft(find.byIcon(Icons.qr_code)).dy, lessThan(t.getTopLeft(find.text('Escanear')).dy));
    });
  });

  group('SsCard(stripe:, outline:)', () {
    testWidgets('faixa de 5 px por dentro, padding a partir dela', (t) async {
      await t.pumpWidget(
        _app(
          const SizedBox(
            width: 300,
            child: SsCard(stripe: AppColors.danger, padding: EdgeInsets.all(12), child: Text('Recall')),
          ),
        ),
      );
      final faixa = find.byWidgetPredicate((w) => w is ColoredBox && w.color == AppColors.danger);
      expect(faixa, findsOneWidget);
      expect(t.getSize(faixa).width, SsCard.stripeWidth);
      final card = t.getTopLeft(find.byType(SsCard));
      expect(t.getTopLeft(find.text('Recall')).dx - card.dx, closeTo(12 + SsCard.stripeWidth, .01));
      final ac = t.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(ac.clipBehavior, Clip.antiAlias);
    });

    testWidgets('contorno na cor, sem trocar o fundo; o active ganha', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            children: [
              SsCard(outline: AppColors.success, child: Text('a')),
              SsCard(outline: AppColors.success, active: true, child: Text('b')),
            ],
          ),
        ),
      );
      final ctx = t.element(find.text('a'));
      final c = SsColors.of(ctx);
      final acs = t.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).toList();
      final d0 = acs[0].decoration! as BoxDecoration;
      expect((d0.border! as Border).top.color, AppColors.success);
      expect((d0.border! as Border).top.width, 2);
      expect(d0.color, c.surface);
      expect(d0.boxShadow, AppShadows.card);
      final d1 = acs[1].decoration! as BoxDecoration;
      expect((d1.border! as Border).top.color, c.accentBright);
    });
  });

  group('SsMonogram', () {
    testWidgets('cor de dado, quadrado de raio size/4, círculo e rótulo', (t) async {
      await t.pumpWidget(
        _app(
          Row(
            children: [
              SsMonogram('Ali', color: ssColorFromHex('#E43225'), size: 20, semanticLabel: 'AliExpress'),
              const SsMonogram('S', size: 24, circle: true),
            ],
          ),
        ),
      );
      final d = _decoracao(t, find.text('Ali'));
      expect(d.color, ssColorFromHex('#E43225'));
      expect(d.borderRadius, BorderRadius.circular(5));
      expect(_decoracao(t, find.text('S')).shape, BoxShape.circle);
      expect(t.getSize(find.byType(SsMonogram).first), const Size(20, 20));
      expect(find.bySemanticsLabel('AliExpress'), findsOneWidget);
      expect(t.widget<Text>(find.text('Ali')).style?.color, AppColors.onDark);
    });
  });

  group('SsPhotoCard v0.19.2', () {
    testWidgets('subtítulo, crédito tocável, escolhido e expand', (t) async {
      var credito = 0;
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 280,
            height: 200,
            child: SsPhotoCard(
              image: const ColoredBox(color: AppColors.scrim),
              title: 'Praia do Rosa',
              subtitle: 'Imbituba, SC',
              credit: 'Foto: Fulano · CC BY',
              onCredit: () => credito++,
              selected: true,
              expand: true,
            ),
          ),
        ),
      );
      expect(find.text('Imbituba, SC'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(t.getSize(find.byType(SsPhotoCard)).height, 200);
      final ctx = t.element(find.byType(SsPhotoCard));
      final ac = t.widget<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(((ac.decoration! as BoxDecoration).border! as Border).top.color, SsColors.of(ctx).accentBright);
      await t.tap(find.text('Foto: Fulano · CC BY'));
      await t.pumpAndSettle();
      expect(credito, 1);
      expect(find.bySemanticsLabel(RegExp('Praia do Rosa, Imbituba, SC')), findsOneWidget);
      expect(
        t.getSemantics(find.bySemanticsLabel('Foto: Fulano · CC BY')),
        matchesSemantics(
          label: 'Foto: Fulano · CC BY',
          hint: SsStrings.en.photoSource,
          isButton: true,
          hasTapAction: true,
        ),
      );
      h.dispose();
    });

    testWidgets('sem os novos, igual ao de antes (proporção)', (t) async {
      await t.pumpWidget(
        _app(
          const SizedBox(
            width: 320,
            child: SsPhotoCard(
              image: ColoredBox(color: AppColors.scrim),
              title: 'Varanda',
            ),
          ),
        ),
      );
      expect(t.getSize(find.byType(SsPhotoCard)), const Size(320, 180));
      expect(find.byIcon(Icons.check), findsNothing);
    });
  });

  group('SsBadge(solid:, mono:)', () {
    testWidgets('sólido no tom com texto claro; muted invertido; mono em DM Mono', (t) async {
      await t.pumpWidget(
        _app(
          const Row(
            children: [
              SsBadge('DIA 3', solid: true, mono: true),
              SsBadge('ANTES', variant: SsBadgeVariant.muted, solid: true),
              SsBadge('Ok', variant: SsBadgeVariant.success, solid: true),
            ],
          ),
        ),
      );
      final c = SsColors.of(t.element(find.text('DIA 3')));
      expect(_decoracao(t, find.text('DIA 3')).color, c.accentSolid);
      expect(t.widget<Text>(find.text('DIA 3')).style?.color, AppColors.onDark);
      expect(t.widget<Text>(find.text('DIA 3')).style?.fontFamily, startsWith('DMMono'));
      expect(_decoracao(t, find.text('ANTES')).color, c.ink);
      expect(t.widget<Text>(find.text('ANTES')).style?.color, c.surface);
      final ok = _decoracao(t, find.text('Ok')).color!;
      expect(ssContrast(ok, AppColors.onDark), greaterThanOrEqualTo(4.5));
    });
  });

  group('SsProseList(ordered:)', () {
    testWidgets('números em círculo e o leitor lê "1. texto"', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(const SsProseList(['Abra Configurações', 'Toque em Bateria'], ordered: true)));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(_decoracao(t, find.text('1')).shape, BoxShape.circle);
      expect(find.bySemanticsLabel(RegExp(r'^1\.\s*Abra Configurações')), findsOneWidget);
      h.dispose();
    });

    testWidgets('start muda o primeiro número; sem ordered, marcador', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            children: [
              SsProseList(['a'], ordered: true, start: 4),
              SsProseList(['b']),
            ],
          ),
        ),
      );
      expect(find.text('4'), findsOneWidget);
      expect(find.text('•  '), findsOneWidget);
    });
  });

  group('SsDot e SsIconBubble(badge:)', () {
    testWidgets('ponto com anel e rótulo; bolha com ponto no canto', (t) async {
      await t.pumpWidget(
        _app(
          const Row(
            children: [
              SsDot(color: AppColors.danger, size: 10, ring: AppColors.onDark, semanticLabel: 'Não lido'),
              SsIconBubble(Icons.wallet, size: 44, badge: AppColors.success, badgeLabel: 'Ligado'),
            ],
          ),
        ),
      );
      final dots = t.widgetList<SsDot>(find.byType(SsDot)).toList();
      expect(dots, hasLength(2));
      expect(t.getSize(find.byType(SsDot).first), const Size(14, 14));
      expect(find.bySemanticsLabel('Não lido'), findsOneWidget);
      expect(find.bySemanticsLabel('Ligado'), findsOneWidget);
      final bubble = t.getRect(find.byType(SsIconBubble));
      final dot = t.getRect(find.byType(SsDot).last);
      expect(dot.right, closeTo(bubble.right + 2, .01));
      expect(dot.bottom, closeTo(bubble.bottom + 2, .01));
      final ctx = t.element(find.byType(SsIconBubble));
      expect(dots.last.ring, SsColors.of(ctx).surface);
    });
  });

  group('SsQuote', () {
    testWidgets('aspas, itálico, canto reto e autor', (t) async {
      await t.pumpWidget(_app(const SsQuote('Deixo na portaria', author: 'Ana')));
      final txt = t.widget<Text>(find.text('“Deixo na portaria”'));
      expect(txt.style?.fontStyle, FontStyle.italic);
      expect(find.text('— Ana'), findsOneWidget);
      final d = _decoracao(t, find.text('“Deixo na portaria”'));
      expect((d.borderRadius! as BorderRadius).topLeft, const Radius.circular(4));
      expect(d.color, SsColors.of(t.element(find.byType(SsQuote))).field);
    });
  });

  group('SsIllustrationStage e SsPageDots', () {
    testWidgets('palco na altura pedida com o degradê do tema', (t) async {
      await t.pumpWidget(_app(const SsIllustrationStage(height: 80, child: SizedBox(width: 300, height: 300))));
      expect(t.getSize(find.byType(SsIllustrationStage)).height, 80 + 24);
      final c = SsColors.of(t.element(find.byType(SsIllustrationStage)));
      final d = t.widget<Container>(
        find.descendant(of: find.byType(SsIllustrationStage), matching: find.byType(Container)).first,
      );
      expect(((d.decoration! as BoxDecoration).gradient! as LinearGradient).colors, [c.accentSoft, c.page]);
    });

    testWidgets('pontos: a atual estica e o leitor lê a página', (t) async {
      await t.pumpWidget(_app(const SsPageDots(count: 3, index: 1)));
      await t.pumpAndSettle();
      // O app dos testes está em inglês (sem locale).
      expect(find.bySemanticsLabel('Page 2 of 3'), findsOneWidget);
      expect(SsStrings.pt.pageOf(2, 3), 'Página 2 de 3');
      expect(SsStrings.es.pageOf(2, 3), 'Página 2 de 3');
      final ws = t.widgetList<AnimatedContainer>(find.byType(AnimatedContainer)).toList();
      expect(ws, hasLength(3));
      // Largura + a margem de 3 de cada lado.
      expect(t.getSize(find.byType(AnimatedContainer).at(1)).width, 24 + 6);
      expect(t.getSize(find.byType(AnimatedContainer).at(0)).width, 8 + 6);
    });

    testWidgets('o SsOnboarding usa o SsPageDots', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [SsStrings.delegate],
          home: Scaffold(
            body: SsOnboarding(
              pages: const [
                SsOnboardingPage(title: 'Um', text: 'a'),
                SsOnboardingPage(title: 'Dois', text: 'b'),
              ],
              onDone: () {},
            ),
          ),
        ),
      );
      expect(find.byType(SsPageDots), findsOneWidget);
    });
  });

  group('SsGlass(tone: dark)', () {
    testWidgets('véu escuro e texto claro', (t) async {
      await t.pumpWidget(_app(const SsGlass(tone: SsGlassTone.dark, child: Text('Aponte para o código'))));
      final txt = t.widget<RichText>(
        find.descendant(of: find.text('Aponte para o código'), matching: find.byType(RichText)),
      );
      expect(txt.text.style?.color, AppColors.onDark);
      final box = t.widget<DecoratedBox>(
        find.descendant(of: find.byType(SsGlass), matching: find.byType(DecoratedBox)).first,
      );
      final g = (box.decoration as BoxDecoration).gradient! as LinearGradient;
      expect(g.colors.last.a, closeTo(.45 + .14 * 1.3, .01));
      expect(g.colors.last.withValues(alpha: 1), AppColors.sheetBg);
    });
  });

  group('SsSourceChip(trailing:)', () {
    testWidgets('ícone depois do nome e rótulo com o estado', (t) async {
      await t.pumpWidget(
        _app(const SsSourceChip('Shopee', trailing: Icon(Icons.check_circle), semanticLabel: 'Shopee: 3 ofertas')),
      );
      expect(t.getTopLeft(find.byIcon(Icons.check_circle)).dx, greaterThan(t.getTopLeft(find.text('Shopee')).dx));
      expect(find.bySemanticsLabel('Shopee: 3 ofertas'), findsOneWidget);
      final ico = t.widget<RichText>(
        find.descendant(of: find.byIcon(Icons.check_circle), matching: find.byType(RichText)),
      );
      expect(ico.text.style?.fontSize, 14);
    });
  });

  testWidgets('textos novos nos três idiomas', (t) async {
    expect(SsStrings.pt.photoSource, 'Abrir a página da foto');
    expect(SsStrings.en.photoSource, 'Open the photo page');
    expect(SsStrings.es.photoSource, 'Abrir la página de la foto');
  });

  testWidgets('escuro: nada quebra', (t) async {
    await t.pumpWidget(
      _app(
        theme: AppTheme.dark,
        SingleChildScrollView(
          child: Column(
            children: [
              SsHeroCard.custom(
                child: SsButton.onGradient(label: 'Voo', solid: true, stacked: true, onPressed: () {}),
              ),
              const SsCard(stripe: AppColors.danger, outline: AppColors.danger, child: Text('x')),
              const SsBadge('DIA 1', solid: true, mono: true),
              const SsQuote('oi'),
              const SsPageDots(count: 2, index: 0),
            ],
          ),
        ),
      ),
    );
    expect(t.takeException(), isNull);
  });
}
