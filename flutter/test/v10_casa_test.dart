// v0.10 (casa): renderiza cada estado do catálogo em claro, escuro e OLED e
// testa os comportamentos das peças novas.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo_v10_casa.dart';

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: child),
);

Future<void> _fonte(String familia, List<String> arquivos) async {
  final l = FontLoader(familia);
  for (final f in arquivos) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  final saida = Platform.environment['CATALOGO_SAIDA'];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    final icones = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icones.existsSync()) await _fonte('MaterialIcons', [icones.path]);
  });

  group('catálogo v0.10 casa', () {
    test('slugs únicos', () {
      final slugs = catalogoV10Casa.map((c) => c.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    for (final c in catalogoV10Casa) {
      testWidgets(c.nome, (tester) async {
        for (final e in c.estados) {
          for (final tema in ['claro', 'escuro', 'oled']) {
            tester.view.physicalSize = e.tamanho * 2;
            tester.view.devicePixelRatio = 2;
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                themeAnimationDuration: Duration.zero,
                theme: switch (tema) {
                  'claro' => AppTheme.light,
                  'oled' => AppTheme.build(Brightness.dark, oled: true),
                  _ => AppTheme.dark,
                },
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
            expect(tester.takeException(), isNull, reason: '${c.slug}/${e.slug}/$tema');
            if (saida == null) continue;
            final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
            await tester.runAsync(() async {
              final img = await b.toImage(pixelRatio: 2);
              final png = await img.toByteData(format: ui.ImageByteFormat.png);
              File('$saida/${c.slug}/${e.slug}-$tema.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png!.buffer.asUint8List());
            });
          }
        }
        // Desmonta para as animações em ciclo (ondas) não sobrarem.
        await tester.pumpWidget(const SizedBox());
        tester.view.reset();
      });
    }
  });

  group('SsCameraTile', () {
    test('formatAge', () {
      expect(SsCameraTile.formatAge(const Duration(seconds: 12)), 'há 12 s');
      expect(SsCameraTile.formatAge(const Duration(minutes: 3, seconds: 4)), 'há 3 min');
      expect(SsCameraTile.formatAge(const Duration(hours: 2)), 'há 2 h');
      expect(SsCameraTile.formatAge(const Duration(days: 3)), 'há 3 d');
    });

    testWidgets('ao vivo mostra o selo; offline mostra tentar de novo', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          const SsCameraTile(
            title: 'Garagem',
            child: ColoredBox(color: Colors.black),
          ),
        ),
      );
      expect(find.text('AO VIVO'), findsOneWidget);
      await t.pumpWidget(_app(SsCameraTile(title: 'Garagem', state: SsCameraState.offline, onRetry: () => n++)));
      expect(find.text('AO VIVO'), findsNothing);
      expect(find.text('Câmera offline'), findsOneWidget);
      await t.tap(find.text('Tentar de novo'));
      await t.pumpAndSettle();
      expect(n, 1);
    });

    testWidgets('parado mostra a idade e rótulos são parâmetros', (t) async {
      await t.pumpWidget(
        _app(
          SsCameraTile(
            title: 'Yard',
            state: SsCameraState.stale,
            age: const Duration(seconds: 40),
            ageFormat: (d) => '${d.inSeconds}s ago',
            child: const ColoredBox(color: Colors.black),
          ),
        ),
      );
      expect(find.text('40s ago'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Yard, 40s ago')), findsOneWidget);
    });
  });

  group('SsMediaPlayer', () {
    test('formatTime', () {
      expect(SsMediaPlayer.formatTime(const Duration(minutes: 3, seconds: 7)), '3:07');
      expect(SsMediaPlayer.formatTime(const Duration(hours: 1, minutes: 2, seconds: 3)), '1:02:03');
    });

    testWidgets('tocar, próxima e indisponível trava', (t) async {
      final log = <String>[];
      Widget p(SsMediaState s) => _app(
        SsMediaPlayer(
          title: 'Música',
          state: s,
          position: const Duration(seconds: 30),
          duration: const Duration(minutes: 3),
          onPlayPause: () => log.add('play'),
          onNext: () => log.add('next'),
        ),
      );
      await t.pumpWidget(p(SsMediaState.paused));
      await t.tap(find.bySemanticsLabel('Tocar'));
      await t.tap(find.byTooltip('Próxima'));
      await t.pumpAndSettle();
      expect(log, ['play', 'next']);
      expect(find.text('0:30'), findsOneWidget);
      await t.pumpWidget(p(SsMediaState.playing));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Pausar'), findsOneWidget);
      await t.pumpWidget(p(SsMediaState.unavailable));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Próxima'), warnIfMissed: false);
      await t.tap(find.bySemanticsLabel('Tocar'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(log, ['play', 'next']);
    });
  });

  group('SsNoticeCard', () {
    testWidgets('ações e dispensar', (t) async {
      final log = <String>[];
      await t.pumpWidget(
        _app(
          SsNoticeCard(
            title: 'Porta aberta',
            tone: SsNoticeTone.warn,
            actions: [SsNoticeAction('Fechar', () => log.add('a')), SsNoticeAction('Ignorar', () => log.add('b'))],
            onDismiss: () => log.add('x'),
          ),
        ),
      );
      await t.tap(find.text('Fechar'));
      await t.tap(find.text('Ignorar'));
      await t.tap(find.byTooltip('Dispensar'));
      await t.pumpAndSettle();
      expect(log, ['a', 'b', 'x']);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });

  group('SsMicButton', () {
    testWidgets('rótulo por estado e toque', (t) async {
      var n = 0;
      for (final (s, rotulo) in [
        (SsMicState.idle, 'Falar'),
        (SsMicState.listening, 'Ouvindo, toque para parar'),
        (SsMicState.error, 'Erro no microfone, toque para tentar de novo'),
      ]) {
        await t.pumpWidget(
          _app(
            Center(
              child: SsMicButton(state: s, level: .7, onPressed: () => n++),
            ),
          ),
        );
        await t.pumpAndSettle();
        expect(find.bySemanticsLabel(rotulo), findsOneWidget);
      }
      await t.tap(find.byType(SsMicButton));
      await t.pumpAndSettle();
      expect(n, 1);
      // Processando gira: sem pumpAndSettle; com "reduzir movimento" para.
      await t.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Center(child: SsMicButton(state: SsMicState.processing)),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Processando'), findsOneWidget);
    });
  });

  group('SsLockScreen', () {
    testWidgets('desbloquear chama onUnlock; PIN troca o botão', (t) async {
      var n = 0;
      await t.pumpWidget(_app(SsLockScreen(onUnlock: () => n++, pinFallback: const Text('PIN DO APP'))));
      await t.tap(find.text('Desbloquear'));
      expect(n, 1);
      await t.tap(find.text('Usar PIN'));
      await t.pumpAndSettle();
      expect(find.text('PIN DO APP'), findsOneWidget);
      expect(find.text('Desbloquear'), findsNothing);
      await t.tap(find.text('Usar biometria'));
      await t.pumpAndSettle();
      expect(find.text('Desbloquear'), findsOneWidget);
    });
  });

  group('SsFlowDiagram', () {
    const casa = SsFlowNode('casa', kind: SsFlowKind.home, label: 'Casa', value: '2 kW');
    const rede = SsFlowNode('rede', kind: SsFlowKind.grid, label: 'Rede', value: '2 kW');

    testWidgets('animate: false e reduzir movimento não deixam laço rodando', (t) async {
      await t.pumpWidget(
        _app(
          const SsFlowDiagram(center: casa, around: [rede], links: [SsFlowLink('rede', 'casa', 2000)], animate: false),
        ),
      );
      await t.pumpAndSettle();
      expect(t.hasRunningAnimations, isFalse);
      expect(find.text('Rede'), findsOneWidget);
      await t.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SsFlowDiagram(center: casa, around: [rede], links: [SsFlowLink('rede', 'casa', 2000)]),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('com fluxo e animação, o laço roda; sem fluxo, para', (t) async {
      await t.pumpWidget(
        _app(const SsFlowDiagram(center: casa, around: [rede], links: [SsFlowLink('rede', 'casa', 2000)])),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(t.hasRunningAnimations, isTrue);
      await t.pumpWidget(
        _app(const SsFlowDiagram(center: casa, around: [rede], links: [SsFlowLink('rede', 'casa', 0)])),
      );
      await t.pumpAndSettle();
      expect(t.hasRunningAnimations, isFalse);
      expect(find.bySemanticsLabel(RegExp('Casa 2 kW')), findsOneWidget);
    });
  });

  group('SsDPad', () {
    testWidgets('toque e teclado mandam a tecla', (t) async {
      final keys = <SsDPadKey>[];
      await t.pumpWidget(_app(Center(child: SsDPad(onKey: keys.add, showVolume: true))));
      await t.tap(find.bySemanticsLabel('Cima'));
      await t.tap(find.bySemanticsLabel('OK'));
      await t.tap(find.bySemanticsLabel('Aumentar volume'));
      await t.tap(find.bySemanticsLabel('Voltar'));
      await t.pumpAndSettle();
      expect(keys, [SsDPadKey.up, SsDPadKey.ok, SsDPadKey.volumeUp, SsDPadKey.back]);
      // Foco no D-pad e setas do teclado.
      Focus.of(t.element(find.bySemanticsLabel('Cima'))).requestFocus();
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(keys.sublist(4), [SsDPadKey.left, SsDPadKey.ok]);
    });

    testWidgets('desligado não manda nada', (t) async {
      final keys = <SsDPadKey>[];
      await t.pumpWidget(_app(Center(child: SsDPad(onKey: keys.add, enabled: false))));
      await t.tap(find.bySemanticsLabel('Cima'), warnIfMissed: false);
      await t.pumpAndSettle();
      expect(keys, isEmpty);
    });
  });

  group('SsWeatherCard', () {
    testWidgets('mostra temperatura, condição, umidade e previsão', (t) async {
      await t.pumpWidget(
        _app(
          const SsWeatherCard(
            temperature: 26.6,
            condition: SsWeatherCondition.rain,
            min: 18,
            max: 29,
            humidity: 80,
            wind: 12,
            forecast: [SsForecast('Ter', SsWeatherCondition.clear, 30, min: 20)],
          ),
        ),
      );
      expect(find.text('27°'), findsOneWidget);
      expect(find.text('Chuva'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(find.text('12 km/h'), findsOneWidget);
      expect(find.text('Ter'), findsOneWidget);
      expect(find.text('Máx 29°  ·  Mín 18°'), findsOneWidget);
    });
  });

  group('SsClock', () {
    testWidgets('hora fixa e data em pt-BR', (t) async {
      await t.pumpWidget(_app(SsClock(now: DateTime(2026, 11, 4, 9, 5, 3))));
      expect(find.text('09'), findsOneWidget);
      expect(find.text('05'), findsOneWidget);
      expect(find.text('quarta-feira, 4 de novembro'), findsOneWidget);
      await t.pumpWidget(_app(SsClock(now: DateTime(2026, 11, 4, 21, 5), use24h: false, showDate: false)));
      expect(find.text('9'), findsOneWidget);
      expect(find.text('PM'), findsOneWidget);
    });

    testWidgets('sem now anda e o timer some ao sair', (t) async {
      await t.pumpWidget(_app(const SsClock(showSeconds: true)));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(SsClock), findsOneWidget);
      // Desmontar cancela o Timer (o teste falha se sobrar timer pendente).
      await t.pumpWidget(const SizedBox());
    });
  });

  group('SsScanRadar', () {
    testWidgets('achou conta; nada oferece procurar de novo', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          const Center(
            child: SsScanRadar(state: SsScanState.found, items: [SsScanItem('Lâmpada'), SsScanItem('Tomada')]),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('2 encontrados'), findsOneWidget);
      expect(find.bySemanticsLabel('Lâmpada'), findsOneWidget);
      await t.pumpWidget(
        _app(
          Center(
            child: SsScanRadar(state: SsScanState.empty, onRetry: () => n++),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Nada encontrado'), findsOneWidget);
      await t.tap(find.text('Procurar de novo'));
      expect(n, 1);
    });

    testWidgets('procurando com animate: false não deixa laço', (t) async {
      await t.pumpWidget(_app(const Center(child: SsScanRadar(animate: false))));
      await t.pumpAndSettle();
      expect(find.text('Procurando…'), findsOneWidget);
      expect(t.hasRunningAnimations, isFalse);
    });
  });
}
