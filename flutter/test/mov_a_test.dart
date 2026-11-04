// Movimento (lote a): renderiza cada estado do catálogo em claro e escuro
// (com CATALOGO_SAIDA=<pasta> grava os PNG, como o catalogo_test) e testa as
// molas: indicador que desliza e estica, toque que volta passando do ponto,
// interruptor líquido (estica, amassa, a cor escorre), caixa que pula e
// estoura, abas e barra "minhoca", anel e estouro de uma vez só.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo_mov_a.dart';

const _dpr = 2.0;

Future<void> _fonte(String familia, List<String> arquivos) async {
  final l = FontLoader(familia);
  for (final f in arquivos) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

Widget _app(Widget child, {bool semAnimacao = false}) => MaterialApp(
  theme: AppTheme.light,
  themeAnimationDuration: Duration.zero,
  home: MediaQuery(
    data: MediaQueryData(size: const Size(400, 800), disableAnimations: semAnimacao),
    child: Scaffold(body: child),
  ),
);

/// Escala do Transform mais de fora dentro de [de].
double _escala(WidgetTester t, Finder de) =>
    t.widget<Transform>(find.descendant(of: de, matching: find.byType(Transform)).first).transform.entry(0, 0);

void main() {
  final saida = Platform.environment['CATALOGO_SAIDA'];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    await _fonte('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  group('catálogo movimento lote a', () {
    for (final c in catalogoMovA) {
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
        // Deixa terminar o que ainda anima antes de desmontar.
        await tester.pump(const Duration(seconds: 2));
        tester.view.reset();
      });
    }

    test('slugs únicos e com o prefixo do lote', () {
      final slugs = catalogoMovA.map((c) => c.slug).toList();
      expect(slugs.toSet().length, slugs.length);
      expect(slugs.every((s) => s.startsWith('mov-')), isTrue);
    });
  });

  group('SsSlidingIndicator', () {
    test('pose: sai do início, estica no caminho e termina exatamente no alvo', () {
      const de = Rect.fromLTWH(0, 0, 50, 20), ate = Rect.fromLTWH(150, 0, 50, 20);
      expect(SsSlidingIndicator.pose(de, ate, 0).$1, de);
      expect(SsSlidingIndicator.pose(de, ate, 1), (ate, 0.0));
      final (meio, estica) = SsSlidingIndicator.pose(de, ate, .3);
      expect(meio.width, greaterThan(50));
      expect(estica, greaterThan(0));
      // Passa do alvo (mola) mas no máximo 22% do tamanho dele.
      var passou = 0.0;
      for (var t = 0.0; t <= 1; t += .01) {
        passou = [passou, SsSlidingIndicator.pose(de, ate, t).$1.right - ate.right].reduce((a, b) => a > b ? a : b);
      }
      expect(passou, greaterThan(0));
      expect(passou, lessThanOrEqualTo(50 * .22 + .001));
    });

    test('pose vertical: estica na altura', () {
      const de = Rect.fromLTWH(0, 0, 40, 40), ate = Rect.fromLTWH(0, 200, 40, 40);
      final (r, _) = SsSlidingIndicator.pose(de, ate, .3, axis: Axis.vertical);
      expect(r.height, greaterThan(40));
      expect(r.width, 40);
    });
  });

  group('SsSegmented', () {
    Widget seg(int v, {bool semAnimacao = false}) => _app(
      Padding(
        padding: const EdgeInsets.all(20),
        child: SsSegmented<int>(segments: const [(0, 'A'), (1, 'B'), (2, 'C')], value: v, onChanged: (_) {}),
      ),
      semAnimacao: semAnimacao,
    );
    Rect pilula(WidgetTester t) =>
        t.getRect(find.descendant(of: find.byType(SsSlidingIndicator), matching: find.byType(DecoratedBox)));

    testWidgets('a pílula estica no caminho e assenta na opção nova', (t) async {
      await t.pumpWidget(seg(0));
      final parada = pilula(t);
      await t.pumpWidget(seg(2));
      await t.pump();
      await t.pump(const Duration(milliseconds: 140));
      expect(pilula(t).width, greaterThan(parada.width * 1.3));
      await t.pumpAndSettle();
      final fim = pilula(t);
      expect(fim.width, closeTo(parada.width, .5));
      expect(fim.left, closeTo(parada.left + parada.width * 2, 1));
    });

    testWidgets('com menos movimento, pula direto', (t) async {
      await t.pumpWidget(seg(0, semAnimacao: true));
      final parada = pilula(t);
      await t.pumpWidget(seg(2, semAnimacao: true));
      await t.pump();
      expect(pilula(t).left, closeTo(parada.left + parada.width * 2, 1));
      expect(pilula(t).width, closeTo(parada.width, .5));
    });
  });

  testWidgets('SsPressable: afunda no toque e volta passando do tamanho', (t) async {
    await t.pumpWidget(
      _app(
        Center(
          child: SsPressable(onTap: () {}, child: const SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    final g = await t.startGesture(t.getCenter(find.byType(SsPressable)));
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    expect(_escala(t, find.byType(SsPressable)), closeTo(.97, .001));
    await g.up();
    var maior = 0.0;
    for (var i = 0; i < 30; i++) {
      await t.pump(const Duration(milliseconds: 16));
      final s = _escala(t, find.byType(SsPressable));
      if (s > maior) maior = s;
    }
    expect(maior, greaterThan(1)); // a mola passa do ponto
    await t.pumpAndSettle();
    expect(_escala(t, find.byType(SsPressable)), 1);
  });

  testWidgets('SsPressable: o dedo andando (rolagem) solta o afundado', (t) async {
    await t.pumpWidget(
      _app(
        Center(
          child: SsPressable(onTap: () {}, child: const SizedBox(width: 100, height: 50)),
        ),
      ),
    );
    final g = await t.startGesture(t.getCenter(find.byType(SsPressable)));
    await t.pump(const Duration(milliseconds: 120));
    await g.moveBy(const Offset(0, 40));
    await t.pumpAndSettle();
    expect(_escala(t, find.byType(SsPressable)), 1);
    await g.up();
  });

  group('SsSwitch', () {
    testWidgets('toque alterna: estica no caminho, amassa no fim e chega do outro lado com ✓', (t) async {
      var v = false;
      await t.pumpWidget(
        _app(
          Center(
            child: StatefulBuilder(
              builder: (context, set) => SsSwitch(value: v, onChanged: (n) => set(() => v = n)),
            ),
          ),
        ),
      );
      Rect bolinha() => t.getRect(find.descendant(of: find.byType(SsSwitch), matching: find.byType(DecoratedBox)).last);
      final checks = find.descendant(of: find.byType(SsSwitch), matching: find.byType(SsCheckMark));
      final antes = bolinha();
      expect(antes.width, 24);
      expect(checks, findsNothing);
      await t.tap(find.byType(SsSwitch));
      await t.pump();
      await t.pump(const Duration(milliseconds: 110));
      expect(v, isTrue);
      expect(bolinha().width, greaterThan(32)); // estica até 1,45×
      // Depois da batida, amassa (mais estreita e mais alta que a bola).
      var estreita = 24.0, alta = 0.0;
      for (var i = 0; i < 12; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final r = bolinha();
        if (r.width < estreita) estreita = r.width;
        if (r.height > alta) alta = r.height;
      }
      expect(estreita, lessThan(22));
      expect(alta, greaterThan(25));
      await t.pumpAndSettle();
      expect(bolinha().width, 24);
      expect(bolinha().height, 24);
      expect(bolinha().left - antes.left, closeTo(20, .5));
      expect(checks, findsOneWidget);
      expect(t.getSemantics(find.byType(SsSwitch)), isSemantics(isToggled: true));
      // O anel do toque (SsRipple) já sumiu.
      expect(find.descendant(of: find.byType(SsRipple), matching: find.byType(CustomPaint)), findsNothing);
    });

    testWidgets('com menos movimento, chega direto e sem anel', (t) async {
      Widget sw(bool v) => _app(
        Center(
          child: SsSwitch(value: v, onChanged: (_) {}),
        ),
        semAnimacao: true,
      );
      await t.pumpWidget(sw(false));
      await t.pumpWidget(sw(true));
      await t.pump();
      expect(t.hasRunningAnimations, isFalse);
      expect(find.descendant(of: find.byType(SsRipple), matching: find.byType(CustomPaint)), findsNothing);
      final r = t.getRect(find.descendant(of: find.byType(SsSwitch), matching: find.byType(DecoratedBox)).last);
      expect(r.width, 24);
    });

    testWidgets('desabilitado não alterna', (t) async {
      await t.pumpWidget(_app(const Center(child: SsSwitch(value: false, onChanged: null))));
      await t.tap(find.byType(SsSwitch));
      await t.pumpAndSettle();
      expect(t.getSemantics(find.byType(SsSwitch)), isSemantics(isToggled: false, isEnabled: false));
    });

    testWidgets('SsMenuSwitch: tocar na linha alterna', (t) async {
      var v = false;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsMenuSwitch(label: 'Compacto', value: v, onChanged: (n) => set(() => v = n)),
          ),
        ),
      );
      await t.tap(find.text('Compacto'));
      await t.pumpAndSettle();
      expect(v, isTrue);
    });
  });

  group('SsCheckBox', () {
    double giro(WidgetTester t) {
      final m = t
          .widget<Transform>(find.descendant(of: find.byType(SsCheckBox), matching: find.byType(Transform)).first)
          .transform;
      return m.entry(1, 0); // seno do ângulo (escala 1 ao desmarcar)
    }

    testWidgets('SsCheckRow: antecipa, pula passando de 1,1, estoura e assenta', (t) async {
      var v = false;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsCheckRow(title: 'Lembrar', value: v, onChanged: (n) => set(() => v = n)),
          ),
        ),
      );
      // Parado, só a pintura da caixa; estourando, mais a do estouro.
      final burst = find.descendant(of: find.byType(SsBurst), matching: find.byType(CustomPaint));
      expect(burst, findsOneWidget);
      await t.tap(find.text('Lembrar'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 60));
      expect(_escala(t, find.byType(SsCheckBox)), lessThan(.9)); // antecipação
      var maior = 0.0;
      var estourou = false;
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final s = _escala(t, find.byType(SsCheckBox));
        if (s > maior) maior = s;
        if (burst.evaluate().length == 2) estourou = true;
      }
      expect(maior, greaterThan(1.1));
      expect(estourou, isTrue);
      await t.pumpAndSettle();
      expect(v, isTrue);
      expect(_escala(t, find.byType(SsCheckBox)), 1);
      expect(burst, findsOneWidget);
      expect(t.getSemantics(find.byType(SsCheckRow)), isSemantics(isChecked: true));
    });

    testWidgets('desmarcar balança (−6° → 4°) e não estoura', (t) async {
      Widget caixa(bool v) => _app(Center(child: SsCheckBox(value: v)));
      await t.pumpWidget(caixa(true));
      await t.pumpWidget(caixa(false));
      await t.pump();
      var menor = 0.0, maior = 0.0;
      for (var i = 0; i < 24; i++) {
        await t.pump(const Duration(milliseconds: 16));
        final g = giro(t);
        if (g < menor) menor = g;
        if (g > maior) maior = g;
        expect(find.descendant(of: find.byType(SsBurst), matching: find.byType(CustomPaint)), findsOneWidget);
      }
      expect(menor, lessThan(-.08)); // ~ sen(−6°)
      expect(maior, greaterThan(.05)); // ~ sen(4°)
      await t.pumpAndSettle();
      expect(giro(t), 0);
    });

    testWidgets('com menos movimento, marca direto', (t) async {
      Widget caixa(bool v) => _app(Center(child: SsCheckBox(value: v)), semAnimacao: true);
      await t.pumpWidget(caixa(false));
      await t.pumpWidget(caixa(true));
      await t.pump();
      expect(t.hasRunningAnimations, isFalse);
      expect(_escala(t, find.byType(SsCheckBox)), 1);
    });
  });

  group('SsRipple e SsBurst', () {
    Widget anel(int n, {bool semAnimacao = false}) => _app(
      Center(
        child: SsRipple(trigger: n, child: const SizedBox(width: 20, height: 20)),
      ),
      semAnimacao: semAnimacao,
    );
    final pintando = find.descendant(of: find.byType(SsRipple), matching: find.byType(CustomPaint));

    testWidgets('não toca ao montar; toca uma vez quando o gatilho muda', (t) async {
      await t.pumpWidget(anel(0));
      await t.pump(const Duration(milliseconds: 50));
      expect(pintando, findsNothing);
      await t.pumpWidget(anel(1));
      await t.pump(const Duration(milliseconds: 100));
      expect(pintando, findsOneWidget);
      await t.pumpAndSettle();
      expect(pintando, findsNothing);
    });

    testWidgets('com menos movimento, não toca', (t) async {
      await t.pumpWidget(anel(0, semAnimacao: true));
      await t.pumpWidget(anel(1, semAnimacao: true));
      await t.pump(const Duration(milliseconds: 100));
      expect(pintando, findsNothing);
    });

    testWidgets('SsBurst com play falso não toca', (t) async {
      Widget estouro(bool v) => _app(
        Center(
          child: SsBurst(trigger: v, play: v, child: const SizedBox(width: 20, height: 20)),
        ),
      );
      final p = find.descendant(of: find.byType(SsBurst), matching: find.byType(CustomPaint));
      await t.pumpWidget(estouro(true));
      await t.pumpWidget(estouro(false));
      await t.pump(const Duration(milliseconds: 100));
      expect(p, findsNothing);
      await t.pumpWidget(estouro(true));
      await t.pump(const Duration(milliseconds: 100));
      expect(p, findsOneWidget);
      await t.pumpAndSettle();
    });
  });

  group('minhoca', () {
    testWidgets('SsTabsUnderline: rastro no caminho, rótulo sobe e o traço amassa ao chegar', (t) async {
      Widget tabs(int i) => _app(SsTabsUnderline(tabs: const ['A', 'B', 'C', 'D'], index: i, onChanged: (_) {}));
      DecoratedBox ultimo() => t.widget<DecoratedBox>(
        find.descendant(of: find.byType(SsTabsUnderline), matching: find.byType(DecoratedBox)).last,
      );
      Rect traco() =>
          t.getRect(find.descendant(of: find.byType(SsTabsUnderline), matching: find.byType(DecoratedBox)).last);
      final caixas = find.descendant(of: find.byType(SsSlidingIndicator), matching: find.byType(DecoratedBox));
      await t.pumpWidget(tabs(0));
      final parado = traco();
      expect(parado.height, 3);
      expect(caixas, findsOneWidget);
      await t.pumpWidget(tabs(3));
      await t.pump();
      await t.pump(const Duration(milliseconds: 120));
      expect(caixas, findsNWidgets(2)); // rastro + traço
      expect(traco().height, lessThan(2.6)); // afina esticado
      expect((ultimo().decoration as BoxDecoration).gradient, isNull);
      // O rótulo novo sobe (translate negativo).
      final dy = t
          .widget<Transform>(find.ancestor(of: find.text('D'), matching: find.byType(Transform)).first)
          .transform
          .getTranslation()
          .y;
      expect(dy, lessThan(0));
      await t.pumpAndSettle();
      expect(caixas, findsOneWidget);
      expect(traco().width, closeTo(parado.width, .5));
      expect(traco().height, 3);
    });

    testWidgets('SsTabsUnderline: amassa (≈8% mais largo) no fim da viagem', (t) async {
      Widget tabs(int i) => _app(SsTabsUnderline(tabs: const ['A', 'B'], index: i, onChanged: (_) {}));
      Rect traco() =>
          t.getRect(find.descendant(of: find.byType(SsTabsUnderline), matching: find.byType(DecoratedBox)).last);
      await t.pumpWidget(tabs(0));
      final parado = traco();
      await t.pumpWidget(tabs(1));
      await t.pump();
      await t.pump(const Duration(milliseconds: 440)); // t ≈ 0,85: pico do amassado
      expect(traco().width, greaterThan(parado.width * 1.04));
      expect(traco().height, greaterThan(3.3));
      await t.pumpAndSettle();
    });

    testWidgets('SsStepTopBar: o número pula, solta o anel e a barra assenta', (t) async {
      Widget barra(int p) => _app(SsStepTopBar(step: p, total: 4));
      await t.pumpWidget(barra(1));
      await t.pumpWidget(barra(2));
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      expect(find.descendant(of: find.byType(SsRipple), matching: find.byType(CustomPaint)), findsOneWidget);
      final escala = t
          .widget<ScaleTransition>(find.ancestor(of: find.text('2'), matching: find.byType(ScaleTransition)).first)
          .scale
          .value;
      expect(escala, greaterThan(1.05)); // passando de 1 no pulo
      await t.pumpAndSettle();
      expect(find.text('1'), findsNothing);
      expect(find.descendant(of: find.byType(SsRipple), matching: find.byType(CustomPaint)), findsNothing);
      expect(find.bySemanticsLabel('Passo 2 de 4'), findsOneWidget);
    });

    testWidgets('SsWormProgress: anima ao mudar e, com menos movimento, pula direto', (t) async {
      Widget barra(double v, {bool semAnimacao = false}) => _app(SsWormProgress(value: v), semAnimacao: semAnimacao);
      await t.pumpWidget(barra(.25));
      expect(t.hasRunningAnimations, isFalse); // montar não anima
      await t.pumpWidget(barra(.5));
      await t.pump();
      expect(t.hasRunningAnimations, isTrue);
      await t.pumpAndSettle();
      await t.pumpWidget(barra(.25, semAnimacao: true));
      await t.pumpWidget(barra(.75, semAnimacao: true));
      await t.pump();
      expect(t.hasRunningAnimations, isFalse);
    });
  });

  testWidgets('SsPop: não pula ao montar nem ao desligar', (t) async {
    Widget pop(bool a) => _app(
      Center(
        child: SsPop(active: a, child: const SizedBox(width: 20, height: 20)),
      ),
    );
    await t.pumpWidget(pop(true));
    await t.pump(const Duration(milliseconds: 30));
    expect(_escala(t, find.byType(SsPop)), 1);
    await t.pumpWidget(pop(false));
    await t.pump(const Duration(milliseconds: 30));
    expect(_escala(t, find.byType(SsPop)), 1);
    await t.pumpWidget(pop(true));
    await t.pump(const Duration(milliseconds: 30));
    expect(_escala(t, find.byType(SsPop)), lessThan(1));
    await t.pumpAndSettle();
  });

  testWidgets('SsCountTabs: o círculo desliza até o contador da aba nova', (t) async {
    Widget tabs(int i) =>
        _app(SsCountTabs(tabs: const [('Todas', 24), ('Pendentes', 8), ('Feitas', 14)], index: i, onChanged: (_) {}));
    await t.pumpWidget(tabs(0));
    await t.pumpAndSettle(); // mede os contadores
    Rect circulo() =>
        t.getRect(find.descendant(of: find.byType(SsSlidingIndicator), matching: find.byType(DecoratedBox)));
    await t.pumpWidget(tabs(2));
    await t.pump();
    await t.pump(const Duration(milliseconds: 120));
    final meio = circulo();
    await t.pumpAndSettle();
    final numero = t.getRect(find.text('14'));
    expect(circulo().center.dx, closeTo(numero.center.dx, 1));
    expect(meio.center.dx, lessThan(circulo().center.dx));
  });

  testWidgets('SsDateStrip: a pílula termina embaixo do dia novo', (t) async {
    Widget faixa(int d) =>
        _app(SsDateStrip(selected: DateTime(2026, 11, d), today: DateTime(2026, 11, 1), onChanged: (_) {}));
    await t.pumpWidget(faixa(12));
    await t.pumpWidget(faixa(13));
    await t.pumpAndSettle();
    final pilula = t.getRect(find.descendant(of: find.byType(SsSlidingIndicator), matching: find.byType(DecoratedBox)));
    expect(pilula.center.dx, closeTo(t.getCenter(find.text('13')).dx, 1));
    expect(pilula.height, 96);
  });

  testWidgets('SsSideRail: o círculo assenta no item novo', (t) async {
    const itens = [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.person_outline, 'Perfil')];
    var i = 0;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => Row(
            children: [
              SsSideRail(items: itens, currentIndex: i, onTap: (n) => set(() => i = n)),
              const Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await t.tap(find.byTooltip('Perfil'));
    await t.pumpAndSettle();
    expect(i, 1);
    // O ícone ativo do Perfil fica no círculo, na altura do item.
    final icones = find.byIcon(Icons.person_outline);
    expect(icones, findsNWidgets(2));
    expect(t.getCenter(icones.first).dy, closeTo(t.getCenter(icones.last).dy, 1));
  });
}
