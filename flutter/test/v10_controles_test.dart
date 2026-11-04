// v0.10 (controles): renderiza cada estado do catálogo em claro e escuro e
// testa os comportamentos das peças novas.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo_v10_controles.dart';

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
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

  group('catálogo v0.10 controles', () {
    test('slugs únicos', () {
      final slugs = catalogoV10Controles.map((c) => c.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    for (final c in catalogoV10Controles) {
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
                  'escuro' => AppTheme.dark,
                  _ => AppTheme.build(Brightness.dark, oled: true),
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
        // Desmonta para os anéis que giram (pending) não sobrarem.
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(seconds: 1));
        tester.view.reset();
      });
    }
  });

  group('SsDeviceTile (ação)', () {
    testWidgets('onPress executa; com confirm pergunta antes', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          Column(
            children: [
              SsDeviceTile(icon: Icons.movie_outlined, name: 'Cena', onPress: () => n++),
              SsDeviceTile(icon: Icons.garage_outlined, name: 'Portão', onPress: () => n += 10, confirm: 'Abrir?'),
              SsDeviceTile(
                icon: Icons.garage_outlined,
                name: 'Travado',
                status: SsDeviceStatus.pending,
                onPress: () => n += 100,
              ),
            ],
          ),
        ),
      );
      await t.tap(find.text('Cena'));
      await t.pump(const Duration(milliseconds: 500));
      expect(n, 1);
      await t.tap(find.text('Travado'));
      await t.pump(const Duration(milliseconds: 500));
      expect(n, 1);
      await t.tap(find.text('Portão'));
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Abrir?'), findsOneWidget);
      expect(n, 1);
      await t.tap(find.text('Confirmar'));
      await t.pump(const Duration(milliseconds: 500));
      expect(n, 11);
    });
  });

  group('SsDeviceTile', () {
    testWidgets('toque abre detalhes e a chave pede o estado contrário', (t) async {
      var aberto = 0;
      bool? pedido;
      await t.pumpWidget(
        _app(
          SsDeviceTile(
            icon: Icons.lightbulb_outline,
            name: 'Luz',
            state: 'Desligada',
            onTap: () => aberto++,
            onToggle: (v) => pedido = v,
          ),
        ),
      );
      await t.tap(find.text('Luz'));
      await t.pumpAndSettle();
      expect(aberto, 1);
      await t.tap(find.byType(SsSwitch));
      await t.pumpAndSettle();
      expect(pedido, isTrue);
    });

    testWidgets('indisponível e sem permissão não deixam ligar', (t) async {
      bool? pedido;
      await t.pumpWidget(
        _app(
          Column(
            children: [
              SsDeviceTile(
                icon: Icons.lightbulb_outline,
                name: 'A',
                status: SsDeviceStatus.unavailable,
                onToggle: (v) => pedido = v,
              ),
              SsDeviceTile(icon: Icons.lock, name: 'B', status: SsDeviceStatus.locked, onToggle: (v) => pedido = v),
            ],
          ),
        ),
      );
      expect(find.text('Indisponível'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline_rounded), findsOneWidget);
      // O B (locked) não tem chave; a do A está travada.
      expect(find.byType(SsSwitch), findsOneWidget);
      await t.tap(find.byType(SsSwitch));
      await t.pumpAndSettle();
      expect(pedido, isNull);
    });

    test('linha de estado por situação', () {
      const base = SsDeviceTile(icon: Icons.abc, name: 'x', state: 'Ligada');
      expect(base.stateLine(), 'Ligada');
      expect(
        const SsDeviceTile(icon: Icons.abc, name: 'x', state: 'Ligada', status: SsDeviceStatus.pending).stateLine(),
        'Ligada · Enviando…',
      );
      expect(
        const SsDeviceTile(
          icon: Icons.abc,
          name: 'x',
          status: SsDeviceStatus.error,
          errorText: 'Sem resposta',
        ).stateLine(),
        'Sem resposta',
      );
    });
  });

  group('SsSlider', () {
    testWidgets('arrastar muda no passo e onChangeEnd vem ao soltar', (t) async {
      double v = 50;
      double? fim;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsSlider(
              value: v,
              step: 10,
              label: 'Brilho',
              onChanged: (n) => set(() => v = n),
              onChangeEnd: (n) => fim = n,
            ),
          ),
        ),
      );
      await t.drag(find.bySemanticsLabel('Brilho'), const Offset(400, 0));
      await t.pumpAndSettle();
      expect(v, 100);
      expect(fim, 100);
      expect(v % 10, 0);
    });

    testWidgets('leitor de tela sobe um passo; apagado não tem ação', (t) async {
      double v = 3;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => Column(
              children: [
                SsSlider(value: v, max: 10, label: 'A', onChanged: (n) => set(() => v = n)),
                const SsSlider(value: 5, label: 'B', onChanged: null),
              ],
            ),
          ),
        ),
      );
      // Pelo leitor de tela (onIncrease) é o mesmo caminho do teclado.
      final s = t.getSemantics(find.bySemanticsLabel('A'));
      expect(s.getSemanticsData().hasAction(SemanticsAction.increase), isTrue);
      expect(
        t.getSemantics(find.bySemanticsLabel('B')).getSemanticsData().hasAction(SemanticsAction.increase),
        isFalse,
      );
    });

    test('kelvin: quente é âmbar, frio é azulado', () {
      final quente = SsSlider.kelvinColor(2000);
      final frio = SsSlider.kelvinColor(9000);
      expect((quente.r * 255).round(), 255);
      expect(quente.b, lessThan(quente.r));
      expect(frio.b, greaterThan(frio.r));
    });
  });

  group('SsThermostat', () {
    testWidgets('+ e − andam o passo e só chamam onChanged depois do debounce', (t) async {
      final vistos = <double>[];
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsThermostat(
              target: 21,
              current: 20,
              debounce: const Duration(milliseconds: 500),
              onChanged: vistos.add,
            ),
          ),
        ),
      );
      final mais = find.bySemanticsLabel('Aumentar');
      await t.tap(mais);
      await t.pump(const Duration(milliseconds: 100));
      await t.tap(mais);
      await t.pump(const Duration(milliseconds: 100));
      expect(vistos, isEmpty);
      expect(find.text('22°'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 600));
      expect(vistos, [22]);
      await t.pumpAndSettle();
    });

    testWidgets('no máximo o + trava; modo troca pelo chip', (t) async {
      String? modo;
      double? alvo;
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsThermostat(
              target: 30,
              max: 30,
              debounce: Duration.zero,
              onChanged: (v) => alvo = v,
              onModeChanged: (m) => modo = m,
            ),
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('Aumentar'));
      await t.pumpAndSettle();
      expect(alvo, isNull);
      await t.tap(find.text('Resfriar'));
      await t.pumpAndSettle();
      expect(modo, 'cool');
    });

    testWidgets('cor sem modos, linha da atual com espaço e texto pronto', (t) async {
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: [
                SsThermostat(
                  target: 21,
                  current: 20,
                  color: const Color(0xFF14B8A6),
                  showModes: false,
                  onChanged: (_) {},
                ),
                SsThermostat(target: 21, current: 20, tone: SsTone.danger, currentText: 'Sala 20°', onChanged: (_) {}),
                SsThermostat(target: 21, current: 19, currentFormat: (v) => 'Fora ${v.round()}', onChanged: (_) {}),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Agora 20°'), findsOneWidget);
      expect(find.text('Sala 20°'), findsOneWidget);
      expect(find.text('Fora 19'), findsOneWidget);
      // Só o segundo e o terceiro mostram os chips.
      expect(find.text('Resfriar'), findsNWidgets(2));
    });

    testWidgets('adjustWhenOff deixa mudar o alvo desligado', (t) async {
      final vistos = <double>[];
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: Column(
              children: [
                SsThermostat(target: 20, mode: 'off', modes: const [], debounce: Duration.zero, onChanged: vistos.add),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('Aumentar'));
      await t.pumpAndSettle();
      expect(vistos, isEmpty);
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsThermostat(
              target: 20,
              mode: 'off',
              modes: const [],
              adjustWhenOff: true,
              debounce: Duration.zero,
              onChanged: vistos.add,
            ),
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('Aumentar'));
      await t.pumpAndSettle();
      expect(vistos, [20.5]);
    });

    test('ação deduzida', () {
      expect(SsThermostat.resolveAction('off', 21, 18), SsThermostatAction.off);
      expect(SsThermostat.resolveAction('heat', 21, 18), SsThermostatAction.heating);
      expect(SsThermostat.resolveAction('cool', 21, 25), SsThermostatAction.cooling);
      expect(SsThermostat.resolveAction('auto', 21, 21), SsThermostatAction.idle);
      expect(SsThermostat.fractionForAngle(135, 0), 0);
      expect(SsThermostat.fractionForAngle(45, 0), 1);
    });
  });

  group('SsCodeKeypad', () {
    testWidgets('com length envia sozinho; errado treme e limpa', (t) async {
      String? enviado;
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCodeKeypad(
              length: 4,
              onSubmit: (c) async {
                enviado = c;
                return false;
              },
            ),
          ),
        ),
      );
      for (final d in ['1', '2', '3', '4']) {
        await t.tap(find.text(d));
        await t.pump();
      }
      await t.pump();
      expect(enviado, '1234');
      expect(find.text('Código incorreto'), findsOneWidget);
      await t.pump(const Duration(milliseconds: 800));
      // Limpou: digitar de novo funciona.
      await t.tap(find.text('5'));
      await t.pumpAndSettle();
      expect(find.text('Código incorreto'), findsNothing);
    });

    testWidgets('ação recebe o código; apagar tira o último', (t) async {
      String? armado;
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCodeKeypad(
              obscure: false,
              actions: [
                SsCodeAction('Armar ausente', (c) async {
                  armado = c;
                  return true;
                }),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('9'));
      await t.tap(find.text('8'));
      await t.tap(find.text('7'));
      await t.pump();
      await t.tap(find.bySemanticsLabel('Apagar'));
      await t.pump();
      await t.tap(find.text('Armar ausente'));
      await t.pumpAndSettle();
      expect(armado, '98');
      expect(find.text('Pronto'), findsOneWidget);
    });

    testWidgets('teclado físico digita e Enter envia', (t) async {
      String? enviado;
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCodeKeypad(
              onSubmit: (c) async {
                enviado = c;
                return true;
              },
            ),
          ),
        ),
      );
      await t.tap(find.text('1'));
      await t.pump();
      await t.sendKeyEvent(LogicalKeyboardKey.digit2);
      await t.sendKeyEvent(LogicalKeyboardKey.enter);
      await t.pumpAndSettle();
      expect(enviado, '12');
    });
  });

  group('SsCodeKeypad (v0.10.1)', () {
    testWidgets('onChanged, controller de fora e ações sem código', (t) async {
      final vistos = <String>[];
      final ctl = TextEditingController();
      String? acao;
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCodeKeypad(
              controller: ctl,
              onChanged: vistos.add,
              actionsNeedCode: false,
              actions: [
                SsCodeAction('Desarmar', (c) async {
                  acao = c;
                  return true;
                }),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('Desarmar'));
      await t.pumpAndSettle();
      expect(acao, '');
      // Depois do ✓, limpar de fora recomeça o teclado.
      ctl.text = '1';
      ctl.clear();
      await t.pump();
      await t.tap(find.text('4'));
      await t.tap(find.text('2'));
      await t.pump();
      expect(vistos, ['4', '42']);
      expect(ctl.text, '42');
      ctl.text = '7';
      await t.pump();
      await t.tap(find.text('Desarmar'));
      await t.pumpAndSettle();
      expect(acao, '7');
    });

    testWidgets('actionsNeedCode padrão: ação apagada com código vazio', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCodeKeypad(
              actions: [
                SsCodeAction('Armar', (c) async {
                  n++;
                  return true;
                }),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('Armar'));
      await t.pumpAndSettle();
      expect(n, 0);
    });
  });

  group('SsWeekdayPicker', () {
    testWidgets('marca, desmarca e atalhos', (t) async {
      var v = <int>{1};
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsWeekdayPicker(value: v, onChanged: (n) => set(() => v = n)),
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('Quarta'));
      await t.pumpAndSettle();
      expect(v, {1, 3});
      await t.tap(find.bySemanticsLabel('Segunda'));
      await t.pumpAndSettle();
      expect(v, {3});
      await t.tap(find.text('Fim de semana'));
      await t.pumpAndSettle();
      expect(v, {6, 7});
      await t.tap(find.text('Todos os dias'));
      await t.pumpAndSettle();
      expect(v.length, 7);
    });

    test('ordem começando no domingo', () {
      expect(SsWeekdayPicker.order(7), [7, 1, 2, 3, 4, 5, 6]);
      expect(SsWeekdayPicker.order(1), [1, 2, 3, 4, 5, 6, 7]);
    });
  });
}
