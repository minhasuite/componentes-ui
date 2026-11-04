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

  group('SsCameraTile (v0.10.1)', () {
    testWidgets('status vira selo; offline não esconde o título em tile pequeno', (t) async {
      await t.pumpWidget(
        _app(
          const Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 160,
              child: SsCameraTile(
                title: 'Portão',
                state: SsCameraState.offline,
                status: 'Visto há 2 h',
                onRetry: _nada,
              ),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.text('Visto há 2 h'), findsOneWidget);
      final titulo = t.getRect(find.text('Portão'));
      final aviso = t.getRect(find.text('Câmera offline'));
      expect(aviso.top, greaterThanOrEqualTo(titulo.bottom));
      expect(find.bySemanticsLabel(RegExp('Portão, Câmera offline, Visto há 2 h')), findsOneWidget);
    });
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

    testWidgets('ligar, mudo, − e +, escolher mídia e volume ao soltar', (t) async {
      final log = <String>[];
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsMediaPlayer(
              title: 'TV',
              state: SsMediaState.playing,
              volume: .5,
              power: true,
              onPower: () => log.add('power'),
              muted: false,
              onMute: () => log.add('mute'),
              onVolumeUp: () => log.add('up'),
              onVolumeDown: () => log.add('down'),
              onVolumeEnd: (v) => log.add('fim'),
              mediaPicker: const Text('Netflix'),
            ),
          ),
        ),
      );
      await t.tap(find.byTooltip('Desligar'));
      await t.tap(find.byTooltip('Sem som'));
      await t.tap(find.byTooltip('Aumentar volume'));
      await t.tap(find.byTooltip('Diminuir volume'));
      await t.drag(find.byType(Slider), const Offset(40, 0));
      await t.pumpAndSettle();
      expect(log, ['power', 'mute', 'up', 'down', 'fim']);
      expect(find.text('Netflix'), findsOneWidget);
    });

    testWidgets('sem volume absoluto: − e + aparecem; power nulo esconde o botão', (t) async {
      await t.pumpWidget(
        _app(SsMediaPlayer(title: 'TV', state: SsMediaState.playing, onVolumeUp: () {}, onVolumeDown: () {})),
      );
      expect(find.byTooltip('Aumentar volume'), findsOneWidget);
      expect(find.byType(Slider), findsNothing);
      expect(find.byIcon(Icons.power_settings_new_rounded), findsNothing);
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

  group('SsFlowDiagram (estreito)', () {
    testWidgets('em 330 px os nomes do centro e dos lados não se sobrepõem', (t) async {
      const casa = SsFlowNode('casa', kind: SsFlowKind.home, label: 'Casa', value: '2 kW');
      const solar = SsFlowNode('solar', kind: SsFlowKind.solar, label: 'Solar', value: '3 kW', slot: SsFlowSlot.left);
      const bat = SsFlowNode('bat', kind: SsFlowKind.battery, label: 'Bateria', caption: '82%', slot: SsFlowSlot.right);
      await t.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 330,
              child: SsFlowDiagram(
                center: casa,
                around: [solar, bat],
                links: [SsFlowLink('solar', 'casa', 1000)],
                animate: false,
              ),
            ),
          ),
        ),
      );
      final rSolar = t.getRect(find.text('Solar'));
      final rCasa = t.getRect(find.text('Casa'));
      final rBat = t.getRect(find.text('Bateria · 82%'));
      expect(rSolar.right, lessThan(rCasa.left));
      expect(rCasa.right, lessThan(rBat.left));
      final box = t.getRect(find.byType(SsFlowDiagram));
      expect(rSolar.left, greaterThanOrEqualTo(box.left));
      expect(rBat.right, lessThanOrEqualTo(box.right));
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

    testWidgets('showNavRow, keys e botões aprendidos', (t) async {
      final cmds = <String>[];
      final keys = <SsDPadKey>[];
      await t.pumpWidget(
        _app(
          Center(
            child: SingleChildScrollView(
              child: SsDPad(
                onKey: keys.add,
                onCommand: cmds.add,
                showNavRow: false,
                keys: const {SsDPadKey.ok: 'KEY_ENTER'},
                extraButtons: const [SsDPadButton('netflix', 'Netflix', icon: Icons.movie_outlined)],
              ),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Início'), findsNothing);
      await t.tap(find.bySemanticsLabel('OK'));
      await t.tap(find.bySemanticsLabel('Cima'));
      await t.tap(find.text('Netflix'));
      await t.pumpAndSettle();
      expect(keys, [SsDPadKey.ok, SsDPadKey.up]);
      expect(cmds, ['KEY_ENTER', 'up', 'netflix']);
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

    testWidgets('chance de chuva e sensação agora; chuva por dia', (t) async {
      await t.pumpWidget(
        _app(
          const SsWeatherCard(
            temperature: 18,
            feelsLike: 15,
            rainChance: 70,
            condition: SsWeatherCondition.rain,
            forecast: [SsForecast('Qui', SsWeatherCondition.rain, 21, min: 14, precip: 80)],
          ),
        ),
      );
      expect(find.text('70%'), findsOneWidget);
      expect(find.text('Sensação 15°'), findsOneWidget);
      expect(find.text('80%'), findsOneWidget);
      expect(const SsForecast('x', SsWeatherCondition.rain, 1, precip: 30).rainChance, 30);
      expect(t.takeException(), isNull);
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

    testWidgets('segundos em dígitos e cabe em 160 px', (t) async {
      await t.pumpWidget(
        _app(
          Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 128,
              child: SsClock(now: DateTime(2026, 11, 4, 9, 5, 7), showSeconds: true, seconds: SsClockSeconds.digits),
            ),
          ),
        ),
      );
      expect(find.text(':07'), findsOneWidget);
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(SsClock)).width, lessThanOrEqualTo(128));
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

    testWidgets('compacto: radar pequeno ao lado do texto e dos achados', (t) async {
      await t.pumpWidget(
        _app(const SsScanRadar(compact: true, state: SsScanState.found, items: [SsScanItem('Lâmpada')])),
      );
      await t.pumpAndSettle();
      expect(find.text('1 encontrado'), findsOneWidget);
      expect(find.bySemanticsLabel('Lâmpada'), findsOneWidget);
      final radar = t.getSize(find.descendant(of: find.byType(SsScanRadar), matching: find.byType(CustomPaint)).first);
      expect(radar.height, lessThanOrEqualTo(72));
      final texto = t.getTopLeft(find.text('1 encontrado'));
      expect(texto.dx, greaterThan(72));
    });

    testWidgets('procurando com animate: false não deixa laço', (t) async {
      await t.pumpWidget(_app(const Center(child: SsScanRadar(animate: false))));
      await t.pumpAndSettle();
      expect(find.text('Procurando…'), findsOneWidget);
      expect(t.hasRunningAnimations, isFalse);
    });
  });
}

void _nada() {}
