// v0.9 (lote b): renderiza cada estado do catálogo em claro e escuro e testa
// os comportamentos das peças novas.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo_v09_b.dart';

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

  group('catálogo v0.9 b', () {
    test('slugs únicos', () {
      final slugs = catalogoV09B.map((c) => c.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    for (final c in catalogoV09B) {
      testWidgets(c.nome, (tester) async {
        for (final e in c.estados) {
          for (final tema in ['claro', 'escuro']) {
            tester.view.physicalSize = e.tamanho * 2;
            tester.view.devicePixelRatio = 2;
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

  group('SsSplitSlider', () {
    test('redistribute mantém a soma exata', () {
      final r = SsSplitSlider.redistribute([20086, 45000, 10000], 0, 50000, 75086);
      expect(r[0], 50000);
      expect(r.reduce((a, b) => a + b), 75086);
      // Proporção 45:10 mantida entre as outras.
      expect((r[1] / r[2]).toStringAsFixed(1), '4.5');
    });

    test('redistribute com as outras zeradas divide igual', () {
      final r = SsSplitSlider.redistribute([10000, 0, 0], 0, 4000, 10000);
      expect(r, [4000, 3000, 3000]);
    });

    test('redistribute limita ao total', () {
      final r = SsSplitSlider.redistribute([5000, 5000], 1, 99999, 10000);
      expect(r, [0, 10000]);
    });

    testWidgets('arrastar numa linha com soma travada mantém o total', (t) async {
      List<int>? visto;
      await t.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: SsSplitSlider(
              total: 30000,
              entries: const [SsSplitEntry('Ana', 10000), SsSplitEntry('Bia', 10000), SsSplitEntry('Caio', 10000)],
              onChanged: (v) => visto = v,
            ),
          ),
        ),
      );
      final sliders = find.bySemanticsLabel('Parte de Ana');
      await t.drag(sliders, const Offset(120, 0));
      await t.pumpAndSettle();
      expect(visto, isNotNull);
      expect(visto!.reduce((a, b) => a + b), 30000);
      expect(visto![0], greaterThan(10000));
    });

    testWidgets('modo livre não mexe nas outras', (t) async {
      List<int>? visto;
      await t.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: SsSplitSlider(
              total: 30000,
              locked: false,
              entries: const [SsSplitEntry('Ana', 10000), SsSplitEntry('Bia', 10000)],
              onChanged: (v) => visto = v,
            ),
          ),
        ),
      );
      await t.drag(find.bySemanticsLabel('Parte de Ana'), const Offset(-400, 0));
      await t.pumpAndSettle();
      expect(visto, [0, 10000]);
      expect(find.text('Falta'), findsOneWidget);
    });
  });

  group('SsHoldToConfirm', () {
    testWidgets('só dispara quando segura até o fim', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          Center(
            child: SsHoldToConfirm(label: 'Segure', onConfirmed: () => n++),
          ),
        ),
      );
      // Solta antes do fim: nada.
      final g = await t.startGesture(t.getCenter(find.byType(SsHoldToConfirm)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 600));
      await g.up();
      await t.pump(const Duration(milliseconds: 400));
      expect(n, 0);
      // Segura até o fim: dispara uma vez.
      final g2 = await t.startGesture(t.getCenter(find.byType(SsHoldToConfirm)));
      await t.pump();
      await t.pump(const Duration(milliseconds: 1300));
      expect(n, 1);
      await g2.up();
      expect(find.text('Confirmado'), findsWidgets);
      await t.pump(const Duration(seconds: 2));
    });
  });

  group('SsSwipeToConfirm', () {
    testWidgets('arrastar até o fim confirma; pouco volta', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: SsSwipeToConfirm(label: 'Arraste para pagar', doneLabel: 'Pago', onConfirm: () async => n++),
          ),
        ),
      );
      final ini = t.getTopLeft(find.byType(SsSwipeToConfirm)) + const Offset(30, 30);
      await t.dragFrom(ini, const Offset(80, 0));
      await t.pumpAndSettle();
      expect(n, 0);
      await t.dragFrom(ini, const Offset(1200, 0));
      await t.pumpAndSettle();
      expect(n, 1);
      expect(find.text('Pago'), findsOneWidget);
    });
  });

  group('SsDateStrip', () {
    testWidgets('tocar num dia escolhe ele', (t) async {
      DateTime? escolhido;
      await t.pumpWidget(
        _app(
          SsDateStrip(selected: DateTime(2026, 11, 12), today: DateTime(2026, 11, 1), onChanged: (d) => escolhido = d),
        ),
      );
      await t.tap(find.text('13'));
      expect(escolhido, DateTime(2026, 11, 13));
    });

    testWidgets('o cabeçalho abre o calendário do mês', (t) async {
      DateTime? escolhido;
      await t.pumpWidget(
        _app(
          SsDateStrip(selected: DateTime(2026, 11, 12), today: DateTime(2026, 11, 1), onChanged: (d) => escolhido = d),
        ),
      );
      await t.tap(find.text('Novembro 2026'));
      await t.pumpAndSettle();
      expect(find.byType(SsMonthGrid), findsOneWidget);
      await t.tap(find.descendant(of: find.byType(SsMonthGrid), matching: find.text('20')));
      await t.pumpAndSettle();
      expect(escolhido, DateTime(2026, 11, 20));
    });
  });

  group('SsDayAgenda', () {
    test('lanes divide só os que se sobrepõem', () {
      const e = [
        SsAgendaEvent(start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 10, minute: 0), title: 'a'),
        SsAgendaEvent(start: TimeOfDay(hour: 9, minute: 30), end: TimeOfDay(hour: 11, minute: 0), title: 'b'),
        SsAgendaEvent(start: TimeOfDay(hour: 12, minute: 0), end: TimeOfDay(hour: 13, minute: 0), title: 'c'),
      ];
      expect(SsDayAgenda.lanes(e), [(0, 2), (1, 2), (0, 1)]);
    });

    testWidgets('altura proporcional à duração e builder próprio', (t) async {
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsDayAgenda(
              startHour: 8,
              endHour: 12,
              hourHeight: 60,
              eventBuilder: (_, ev) => ColoredBox(key: ValueKey(ev.title), color: Colors.teal),
              events: const [
                SsAgendaEvent(start: TimeOfDay(hour: 8, minute: 0), end: TimeOfDay(hour: 9, minute: 0), title: 'uma'),
                SsAgendaEvent(start: TimeOfDay(hour: 9, minute: 0), end: TimeOfDay(hour: 11, minute: 0), title: 'duas'),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final h1 = t.getSize(find.byKey(const ValueKey('uma'))).height;
      final h2 = t.getSize(find.byKey(const ValueKey('duas'))).height;
      expect(h1, closeTo(56, .5));
      expect(h2, closeTo(116, .5));
    });
  });

  group('SsAreaChart', () {
    testWidgets('arrastar troca o ponto ativo', (t) async {
      final vistos = <int>[];
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 300,
            child: SsAreaChart(
              values: const [1, 4, 2, 5, 3],
              labels: const ['a', 'b', 'c', 'd', 'e'],
              onSelect: vistos.add,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      final box = t.getRect(find.byType(SsAreaChart));
      // Toque no 2º ponto (de 5) e depois arrasta até o começo.
      await t.tapAt(Offset(box.left + 12 + (box.width - 24) / 4, box.center.dy));
      await t.pumpAndSettle();
      expect(vistos, [1]);
      await t.dragFrom(box.centerRight - const Offset(5, 0), Offset(-box.width + 10, 0));
      await t.pumpAndSettle();
      expect(vistos.last, 0);
    });
  });

  group('SsExplodedDonut', () {
    testWidgets('legenda seleciona e tocar de novo volta ao total', (t) async {
      final vistos = <int?>[];
      await t.pumpWidget(
        _app(
          SsExplodedDonut(slices: const [SsDonutSlice('Mercado', 60), SsDonutSlice('Casa', 40)], onSelect: vistos.add),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
      await t.tap(find.text('Casa'));
      await t.pumpAndSettle();
      expect(find.text('40%'), findsOneWidget);
      await t.tap(find.text('Casa').last);
      await t.pumpAndSettle();
      expect(vistos, [1, null]);
    });
  });

  group('SsDial e SsVerticalSlider', () {
    test('fractionForAngle', () {
      expect(SsDial.fractionForAngle(135, 0), 0);
      expect(SsDial.fractionForAngle(270, 0), closeTo(.5, 1e-9));
      expect(SsDial.fractionForAngle(45, 0), 1);
      expect(SsDial.fractionForAngle(90, .9), 1); // boca de baixo: gruda na ponta perto
      expect(SsDial.fractionForAngle(90, .1), 0);
    });

    testWidgets('leitor de tela aumenta um passo', (t) async {
      double v = 20;
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (_, set) => Column(
              children: [
                SsVerticalSlider(value: v, label: 'Luz', onChanged: (n) => set(() => v = n)),
                SsDial(value: v, label: 'Giro', onChanged: (n) => set(() => v = n)),
              ],
            ),
          ),
        ),
      );
      final sem = t.getSemantics(find.bySemanticsLabel(RegExp('^Luz')));
      sem.owner!.performAction(sem.id, SemanticsAction.increase);
      await t.pump();
      expect(v, 21);
      final dial = t.getSemantics(find.bySemanticsLabel(RegExp('^Giro')));
      dial.owner!.performAction(dial.id, SemanticsAction.decrease);
      await t.pump();
      expect(v, 20);
      h.dispose();
    });
  });

  group('SsPeoplePicker e avatares', () {
    testWidgets('tocar alterna a pessoa', (t) async {
      Set<String>? visto;
      await t.pumpWidget(
        _app(
          SsPeoplePicker(
            people: const ['Ana Lima', 'Bia Melo'],
            selected: const {'Ana Lima'},
            onChanged: (s) => visto = s,
          ),
        ),
      );
      await t.tap(find.text('Bia'));
      expect(visto, {'Ana Lima', 'Bia Melo'});
      await t.tap(find.text('Ana'));
      expect(visto, <String>{});
    });

    testWidgets('SsAvatarStack com "+" chama onAdd; SsAvatar mostra 99+', (t) async {
      var add = 0;
      await t.pumpWidget(
        _app(
          Row(
            children: [
              SsAvatarStack(const ['Ana', 'Bia'], onAdd: () => add++),
              const SsAvatar('Caio', unread: 150),
            ],
          ),
        ),
      );
      await t.tap(find.bySemanticsLabel('Adicionar pessoa'));
      expect(add, 1);
      expect(find.text('99+'), findsOneWidget);
      expect(find.bySemanticsLabel('Caio, 150 não lidas'), findsOneWidget);
    });
  });

  group('SsPulseAvatar e SsCelebrate', () {
    testWidgets('ondas param quando inativo', (t) async {
      await t.pumpWidget(_app(const SsPulseAvatar(name: 'Ana', active: true)));
      await t.pump(const Duration(milliseconds: 100));
      expect(t.binding.hasScheduledFrame, isTrue);
      await t.pumpWidget(_app(const SsPulseAvatar(name: 'Ana', active: false)));
      await t.pump();
      expect(t.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('celebra só na virada para true', (t) async {
      await t.pumpWidget(_app(const SsCelebrate(achieved: false, child: Text('meta'))));
      await t.pumpWidget(_app(const SsCelebrate(achieved: true, child: Text('meta'))));
      await t.pump(const Duration(milliseconds: 100));
      // Confete no overlay enquanto anima.
      expect(find.byType(CustomPaint), findsWidgets);
      await t.pump(const Duration(seconds: 2));
      expect(t.takeException(), isNull);
    });
  });

  group('SsMorphButton', () {
    testWidgets('vira círculo, mostra ✗ no erro e volta', (t) async {
      await t.pumpWidget(
        _app(
          Padding(
            padding: const EdgeInsets.all(16),
            child: SsMorphButton(label: 'Enviar', onPressed: () async => throw Exception('falhou')),
          ),
        ),
      );
      await t.tap(find.text('Enviar'));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      await t.pump(const Duration(seconds: 2));
      await t.pumpAndSettle();
      expect(find.text('Enviar'), findsOneWidget);
    });
  });
}
