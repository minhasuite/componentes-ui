// v0.10.3: o que a migração do minha-automacao-app para a v0.10.2 achou.
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {PreferredSizeWidget? appBar, bool disableAnimations = false, Locale? locale}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  home: MediaQuery(
    data: MediaQueryData(size: const Size(390, 844), disableAnimations: disableAnimations),
    child: Scaffold(appBar: appBar, extendBodyBehindAppBar: true, body: child),
  ),
);

/// O RichText que desenha [texto] (o estilo já vem fundido com o DefaultTextStyle).
TextStyle _estilo(WidgetTester t, String texto) {
  final r = t.widgetList<RichText>(find.byType(RichText)).firstWhere((r) => r.text.toPlainText() == texto);
  return r.text.style!;
}

/// Conta as vibrações por tipo.
Map<String, int> _vibracoes(WidgetTester t) {
  final m = <String, int>{};
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') m['${call.arguments}'] = (m['${call.arguments}'] ?? 0) + 1;
    return null;
  });
  return m;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsTopBar', () {
    for (final estilo in SsTopBarStyle.values) {
      testWidgets('título e subtítulo na fonte do tema ($estilo)', (t) async {
        await t.pumpWidget(
          _app(
            const SizedBox(),
            appBar: SsTopBar(title: 'Mapa', subtitle: 'Casa da praia', style: estilo),
          ),
        );
        final ctx = t.element(find.byType(SsTopBar));
        final familia = Theme.of(ctx).textTheme.titleLarge!.fontFamily;
        expect(familia, isNotNull);
        expect(familia, contains('Manrope'));
        expect(_estilo(t, 'Mapa').fontFamily, familia);
        expect(_estilo(t, 'Casa da praia').fontFamily, Theme.of(ctx).textTheme.bodySmall!.fontFamily);
        // Cor por estilo: clara fora da superfície.
        final c = SsColors.of(ctx);
        expect(_estilo(t, 'Mapa').color, estilo == SsTopBarStyle.surface ? c.ink : AppColors.onDark);
        expect(_estilo(t, 'Casa da praia').color, estilo == SsTopBarStyle.surface ? c.muted : AppColors.onDarkSoft);
      });
    }

    testWidgets('overlay: o véu tem a altura da barra e fica atrás do título', (t) async {
      await t.pumpWidget(
        _app(
          const ColoredBox(color: Color(0xFF7FB28A), child: SizedBox.expand()),
          appBar: SsTopBar(
            title: 'Mapa',
            style: SsTopBarStyle.overlay,
            actions: [SsIconButton(icon: Icons.my_location_rounded, tooltip: 'Centralizar', onPressed: () {})],
          ),
        ),
      );
      final veu = find.byKey(const ValueKey('ss-topbar-scrim'));
      expect(veu, findsOneWidget);
      final tam = t.getSize(veu);
      expect(tam.height, greaterThanOrEqualTo(kToolbarHeight));
      expect(tam.width, t.getSize(find.byType(Scaffold)).width);
      final caixa = t.widget<DecoratedBox>(veu).decoration as BoxDecoration;
      expect(caixa.gradient, isA<LinearGradient>());
      expect(find.descendant(of: veu, matching: find.text('Mapa')), findsOneWidget);
      // Os outros estilos não têm véu.
      await t.pumpWidget(_app(const SizedBox(), appBar: const SsTopBar(title: 'Mapa')));
      expect(find.byKey(const ValueKey('ss-topbar-scrim')), findsNothing);
    });
  });

  group('SsDeviceTile (toque longo e duplo)', () {
    testWidgets('onLongPress: chama, vibra e aparece no leitor de tela com a dica', (t) async {
      final h = t.ensureSemantics();
      final vib = _vibracoes(t);
      var longos = 0, toques = 0;
      await t.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 180,
              child: SsDeviceTile(
                icon: Icons.lightbulb_outline_rounded,
                name: 'Luz da sala',
                state: 'Desligada',
                onTap: () => toques++,
                onLongPress: () => longos++,
              ),
            ),
          ),
        ),
      );
      await t.longPress(find.text('Luz da sala'));
      await t.pumpAndSettle();
      expect(longos, 1);
      expect(toques, 0);
      expect(vib['HapticFeedbackType.mediumImpact'], 1);
      await t.tap(find.text('Luz da sala'));
      await t.pumpAndSettle();
      expect(toques, 1);
      expect(vib['HapticFeedbackType.lightImpact'], 1);

      final node = t.getSemantics(find.bySemanticsLabel(RegExp('^Luz da sala: Desligada')));
      final data = node.getSemanticsData();
      expect(data.hasAction(SemanticsAction.longPress), isTrue);
      expect(node.hintOverrides?.onLongPressHint, 'Mais opções');
      h.dispose();
    });

    testWidgets('toque longo vale indisponível; longPressLabel troca a dica; onDoubleTap', (t) async {
      final h = t.ensureSemantics();
      var longos = 0, duplos = 0;
      await t.pumpWidget(
        _app(
          Center(
            child: SizedBox(
              width: 180,
              child: SsDeviceTile(
                icon: Icons.lightbulb_outline_rounded,
                name: 'Luz',
                status: SsDeviceStatus.unavailable,
                onLongPress: () => longos++,
                longPressLabel: 'Editar',
                onDoubleTap: () => duplos++,
              ),
            ),
          ),
        ),
      );
      await t.longPress(find.text('Luz'));
      await t.pumpAndSettle();
      expect(longos, 1);
      await t.tap(find.text('Luz'));
      await t.pump(const Duration(milliseconds: 50));
      await t.tap(find.text('Luz'));
      await t.pumpAndSettle();
      expect(duplos, 1);
      final node = t.getSemantics(find.bySemanticsLabel(RegExp('^Luz: ')));
      expect(node.hintOverrides?.onLongPressHint, 'Editar');
      h.dispose();
    });
  });

  group('SsMicButton (segurar para falar)', () {
    testWidgets('encostar começa (vibra leve), soltar termina', (t) async {
      final vib = _vibracoes(t);
      final ev = <String>[];
      await t.pumpWidget(
        _app(
          Center(
            child: SsMicButton(
              holdToTalk: true,
              compact: true,
              size: 44,
              onHoldStart: () => ev.add('start'),
              onHoldEnd: () => ev.add('end'),
              onHoldCancel: () => ev.add('cancel'),
            ),
          ),
        ),
      );
      // Compacto: a caixa é o botão (alvo de 48), não 1,8×.
      expect(t.getSize(find.byType(SsMicButton)), const Size(48, 48));
      final g = await t.startGesture(t.getCenter(find.byType(SsMicButton)));
      await t.pump(const Duration(milliseconds: 600));
      expect(ev, ['start']);
      expect(vib['HapticFeedbackType.lightImpact'], 1);
      await g.up();
      await t.pumpAndSettle();
      expect(ev, ['start', 'end']);
    });

    testWidgets('arrastar para longe cancela; sem onHoldCancel, cai no onHoldEnd', (t) async {
      final ev = <String>[];
      Widget mic({bool comCancel = true}) => _app(
        Center(
          child: SsMicButton(
            holdToTalk: true,
            onHoldStart: () => ev.add('start'),
            onHoldEnd: () => ev.add('end'),
            onHoldCancel: comCancel ? () => ev.add('cancel') : null,
          ),
        ),
      );
      await t.pumpWidget(mic());
      var g = await t.startGesture(t.getCenter(find.byType(SsMicButton)));
      await t.pump();
      await g.moveBy(const Offset(-120, 0));
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
      expect(ev, ['start', 'cancel']);

      ev.clear();
      await t.pumpWidget(mic(comCancel: false));
      g = await t.startGesture(t.getCenter(find.byType(SsMicButton)));
      await t.pump();
      await g.cancel();
      await t.pumpAndSettle();
      expect(ev, ['start', 'end']);
    });

    testWidgets('leitor de tela: rótulos de segurar e um toque começa, outro termina (pt/en/es)', (t) async {
      final h = t.ensureSemantics();
      final ev = <String>[];
      await t.pumpWidget(
        _app(
          Center(
            child: SsMicButton(holdToTalk: true, onHoldStart: () => ev.add('start'), onHoldEnd: () => ev.add('end')),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Segure para falar'), findsOneWidget);
      final mic = t.getSemantics(find.bySemanticsLabel('Segure para falar'));
      final id = mic.id;
      mic.owner!.performAction(id, SemanticsAction.tap);
      await t.pump();
      mic.owner!.performAction(id, SemanticsAction.tap);
      await t.pump();
      expect(ev, ['start', 'end']);
      await t.pumpWidget(
        _app(
          const Center(
            child: SsMicButton(holdToTalk: true, state: SsMicState.listening, onHoldStart: _nada),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Ouvindo, solte para enviar'), findsOneWidget);
      expect(SsStrings.en.micHold, 'Hold to talk');
      expect(SsStrings.es.micRelease, 'Escuchando, suelta para enviar');
      h.dispose();
    });

    testWidgets('reduzir movimento: não cresce ao segurar e nada fica animando', (t) async {
      await t.pumpWidget(
        _app(
          const Center(
            child: SsMicButton(holdToTalk: true, state: SsMicState.processing, onHoldStart: _nada),
          ),
          disableAnimations: true,
        ),
      );
      final g = await t.startGesture(t.getCenter(find.byType(SsMicButton)));
      await t.pump();
      expect(t.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
      await g.up();
      await t.pump();
      expect(t.hasRunningAnimations, isFalse);
    });
  });

  group('SsChatInput (microfone)', () {
    testWidgets('vazio mostra o microfone; com texto, o enviar; ouvindo, o microfone fica', (t) async {
      final ctl = TextEditingController();
      final ev = <String>[];
      Widget campo({SsMicState st = SsMicState.idle}) => _app(
        Align(
          alignment: Alignment.bottomCenter,
          child: SsChatInput(
            controller: ctl,
            onSend: (_) {},
            onMicHoldStart: () => ev.add('start'),
            onMicHoldEnd: () => ev.add('end'),
            micState: st,
            micLevel: .5,
          ),
        ),
      );
      await t.pumpWidget(campo());
      expect(find.byKey(const ValueKey('ss-chat-mic')), findsOneWidget);
      final g = await t.startGesture(t.getCenter(find.byKey(const ValueKey('ss-chat-mic'))));
      await t.pump();
      await g.up();
      await t.pumpAndSettle();
      expect(ev, ['start', 'end']);

      ctl.text = 'Oi';
      await t.pump();
      expect(find.byKey(const ValueKey('ss-chat-mic')), findsNothing);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      await t.pumpWidget(campo(st: SsMicState.listening));
      expect(find.byKey(const ValueKey('ss-chat-mic')), findsOneWidget);
      // A linha não cresce por causa dos anéis (compacto).
      expect(t.getSize(find.byType(SsChatInput)).height, lessThan(80));
    });

    testWidgets('sem onMicHoldStart, igual à v0.10.2 (só o enviar)', (t) async {
      await t.pumpWidget(_app(SsChatInput(controller: TextEditingController(), onSend: (_) {})));
      expect(find.byType(SsMicButton), findsNothing);
      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    });
  });

  testWidgets('SsIconTile(onGradient:): branco translúcido e ícone branco', (t) async {
    await t.pumpWidget(_app(const Center(child: SsIconTile(Icons.bolt_rounded, onGradient: true, tone: Colors.red))));
    final caixa = t.widget<Container>(find.byType(Container).first).decoration! as BoxDecoration;
    expect(caixa.color, AppColors.onDark.withValues(alpha: .18));
    expect(caixa.gradient, isNull);
    expect(t.widget<Icon>(find.byIcon(Icons.bolt_rounded)).color, AppColors.onDark);
  });

  group('SsChipBar(currentIndex:)', () {
    Widget barra(int atual) => _app(
      ListView(
        children: [
          const SizedBox(height: 300),
          SizedBox(
            width: 390,
            child: SsChipBar(
              currentIndex: atual,
              children: [for (var i = 0; i < 14; i++) SsFilterChip('Cômodo $i', selected: i == atual, onTap: () {})],
            ),
          ),
          const SizedBox(height: 2000),
        ],
      ),
    );

    ScrollPosition faixa(WidgetTester t) => t
        .state<ScrollableState>(find.descendant(of: find.byType(SsChipBar), matching: find.byType(Scrollable)))
        .position;

    testWidgets('abre com o atual à vista, rolando só a faixa', (t) async {
      await t.pumpWidget(barra(11));
      await t.pumpAndSettle();
      expect(faixa(t).pixels, greaterThan(0));
      final chip = t.getRect(find.text('Cômodo 11'));
      expect(chip.left, greaterThanOrEqualTo(0));
      expect(chip.right, lessThanOrEqualTo(t.getSize(find.byType(Scaffold)).width));
      // A lista de fora não andou.
      final fora = t.state<ScrollableState>(find.byType(Scrollable).first).position;
      expect(fora.pixels, 0);
    });

    testWidgets('trocar o atual rola até ele; o primeiro volta ao começo', (t) async {
      await t.pumpWidget(barra(11));
      await t.pumpAndSettle();
      await t.pumpWidget(barra(0));
      await t.pumpAndSettle();
      expect(faixa(t).pixels, 0);
    });
  });

  testWidgets('SsHaptics.light é o toque leve', (t) async {
    final vib = _vibracoes(t);
    await SsHaptics.light();
    expect(vib, {'HapticFeedbackType.lightImpact': 1});
  });
}

void _nada() {}
