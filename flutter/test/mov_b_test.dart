// Movimento (lote b): renderiza cada estado do catálogo em claro e escuro
// (com CATALOGO_SAIDA=<pasta> grava os PNG, como o catalogo_test) e testa a
// entrada na tela, os números que rolam e as camadas com mola.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo_mov_b.dart';

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

/// Sonda: guarda o último t que o SsInView entregou.
class _Sonda {
  double t = -1;
  Widget call(BuildContext context, Animation<double> a, Widget? child) {
    t = a.value;
    return const SizedBox(height: 100, child: Placeholder());
  }
}

void main() {
  final saida = Platform.environment['CATALOGO_SAIDA'];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    final icones = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (icones.existsSync()) await _fonte('MaterialIcons', [icones.path]);
  });

  group('catálogo movimento lote b', () {
    test('slugs únicos', () {
      final slugs = catalogoMovB.map((c) => c.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    for (final c in catalogoMovB) {
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
        // Deixa as molas assentarem (nada pode ficar animando para sempre).
        await tester.pumpAndSettle();
        tester.view.reset();
      });
    }
  });

  group('SsInView', () {
    testWidgets('sem Scrollable: dispara no primeiro quadro e chega em 1', (tester) async {
      final s = _Sonda();
      await tester.pumpWidget(_app(SsInView(builder: s.call)));
      await tester.pump(const Duration(milliseconds: 100));
      expect(s.t, greaterThan(0));
      await tester.pumpAndSettle();
      expect(s.t, 1);
    });

    testWidgets('na lista: visível dispara; fora da tela espera a rolagem', (tester) async {
      final topo = _Sonda(), fundo = _Sonda();
      var avisos = 0;
      await tester.pumpWidget(
        _app(
          // Coluna rolável: tudo montado (como o cacheExtent de uma lista).
          SingleChildScrollView(
            child: Column(
              children: [
                SsInView(builder: topo.call),
                const SizedBox(height: 1500),
                SsInView(builder: fundo.call, onVisible: () => avisos++),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(topo.t, 1);
      expect(fundo.t, 0, reason: 'montado mas fora da tela');
      expect(avisos, 0);
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(fundo.t, 1);
      expect(avisos, 1);
      // Volta e vai de novo: não dispara outra vez.
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 1400));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -1400));
      await tester.pumpAndSettle();
      expect(avisos, 1);
    });

    testWidgets('com menos movimento, t já é 1', (tester) async {
      final s = _Sonda();
      await tester.pumpWidget(_app(SsInView(builder: s.call), semAnimacao: true));
      expect(s.t, 1);
    });

    testWidgets('delay segura o modo visible', (tester) async {
      final vistos = <bool>[];
      await tester.pumpWidget(
        _app(
          SsInView.visible(
            delay: const Duration(milliseconds: 200),
            builder: (_, v) {
              vistos.add(v);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      expect(vistos.last, isFalse);
      await tester.pump(const Duration(milliseconds: 250));
      await tester.pump();
      expect(vistos.last, isTrue);
    });

    testWidgets('SsTweenInView: de 0 ao valor e, depois, do atual ao novo', (tester) async {
      double? ultimo;
      Widget w(double end) => _app(
        SsTweenInView(
          end: end,
          builder: (_, v, _) {
            ultimo = v;
            return const SizedBox();
          },
        ),
      );
      await tester.pumpWidget(w(.8));
      expect(ultimo, 0);
      await tester.pumpAndSettle();
      expect(ultimo, .8);
      await tester.pumpWidget(w(.4));
      await tester.pump(const Duration(milliseconds: 100));
      expect(ultimo, inExclusiveRange(.4, .8));
      await tester.pumpAndSettle();
      expect(ultimo, .4);
    });
  });

  group('números', () {
    test('SsAmount.parse e formatLike', () {
      expect(SsAmount.parse(r'R$ 1.234,56'), 1234.56);
      expect(SsAmount.parse(r'R$ -1.234,56'), -1234.56);
      expect(SsAmount.parse('12%'), 12);
      expect(SsAmount.parse('12/03'), isNull);
      expect(SsAmount.formatLike(r'R$ 1.234,56', 617.5), r'R$ 617,50');
      expect(SsAmount.formatLike(r'R$ 1.234,56', 12345.678), r'R$ 12.345,68');
      expect(SsAmount.formatLike(r'-R$ 10,00', 3), r'-R$ 3,00');
      expect(SsAmount.formatLike('1234', 1500), '1500');
    });

    testWidgets('SsAmount(countUp): conta e termina no texto exato', (tester) async {
      await tester.pumpWidget(_app(const SsAmount(r'R$ 1.234,56', countUp: true)));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text(r'R$ 1.234,56'), findsNothing);
      await tester.pumpAndSettle();
      expect(find.text(r'R$ 1.234,56'), findsOneWidget);
    });

    testWidgets('SsAmount(roll): o novo entra por baixo quando aumenta', (tester) async {
      Widget w(String t) => _app(Center(child: SsAmount(t, roll: true)));
      await tester.pumpWidget(w(r'R$ 10,00'));
      await tester.pumpWidget(w(r'R$ 20,00'));
      await tester.pump(const Duration(milliseconds: 60));
      // Os dois na tela durante a troca; o novo abaixo do antigo.
      final novo = tester.getTopLeft(find.text(r'R$ 20,00')).dy;
      final antigo = tester.getTopLeft(find.text(r'R$ 10,00')).dy;
      expect(novo, greaterThan(antigo));
      await tester.pumpAndSettle();
      expect(find.text(r'R$ 10,00'), findsNothing);
      // Caiu: entra por cima.
      await tester.pumpWidget(w(r'R$ 5,00'));
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.getTopLeft(find.text(r'R$ 5,00')).dy, lessThan(tester.getTopLeft(find.text(r'R$ 20,00')).dy));
      await tester.pumpAndSettle();
    });

    testWidgets('SsOdometer: rola e assenta no valor novo', (tester) async {
      Widget w(String t) => _app(Center(child: SsOdometer(t)));
      await tester.pumpWidget(w(r'R$ 1.234,56'));
      await tester.pumpWidget(w(r'R$ 1.299,00'));
      await tester.pump(const Duration(milliseconds: 120));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('SsOdometer(rollIn): parte do 0 e chega no valor', (tester) async {
      await tester.pumpWidget(_app(const Center(child: SsOdometer('987', rollIn: true))));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(tester.hasRunningAnimations, isFalse);
    });
  });

  group('camadas', () {
    testWidgets('showSsConfirm: o cartão abre de 0,9 com mola e assenta em 1', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSsConfirm(context, title: 'Excluir?'),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));
      final escala = find.ancestor(of: find.byType(AlertDialog), matching: find.byType(Transform)).first;
      expect(tester.widget<Transform>(escala).transform.entry(0, 0), lessThan(1));
      // Perto do pico da mola, passa de 1.
      await tester.pump(const Duration(milliseconds: 110));
      expect(tester.widget<Transform>(escala).transform.entry(0, 0), greaterThan(1));
      await tester.pumpAndSettle();
      expect(tester.widget<Transform>(escala).transform.entry(0, 0), closeTo(1, 1e-6));
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('showSsSheet abre e fecha (mola na subida)', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSsSheet<void>(context, title: 'Folha', child: const SizedBox(height: 200)),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('abrir'));
      await tester.pumpAndSettle();
      expect(find.text('Folha'), findsOneWidget);
      final assentada = tester.getTopLeft(find.byType(SsSheet)).dy;
      await tester.tapAt(const Offset(200, 40));
      await tester.pumpAndSettle();
      expect(find.text('Folha'), findsNothing);
      // Na subida, passa um pouco do lugar (fica acima) antes de assentar.
      await tester.tap(find.text('abrir'));
      await tester.pump();
      var menor = double.infinity;
      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final y = tester.getTopLeft(find.byType(SsSheet)).dy;
        if (y < menor) menor = y;
      }
      expect(menor, lessThan(assentada));
      await tester.pumpAndSettle();
      expect(tester.getTopLeft(find.byType(SsSheet)).dy, closeTo(assentada, .5));
    });

    testWidgets('showSsUndo: arrastar para baixo dispensa e conta como não desfeito', (tester) async {
      bool? desfez;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () async => desfez = await showSsUndo(context, 'Pedido excluído'),
              child: const Text('excluir'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('excluir'));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Pedido excluído'), findsOneWidget);
      await tester.timedDrag(find.text('Pedido excluído'), const Offset(0, 90), const Duration(milliseconds: 300));
      await tester.pumpAndSettle();
      expect(find.text('Pedido excluído'), findsNothing);
      expect(desfez, isFalse);
    });

    testWidgets('showSsToast: arrasto curto volta com mola e o aviso fica', (tester) async {
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showSsToast(context, 'Salvo', duration: const Duration(seconds: 3)),
              child: const Text('salvar'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('salvar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      final antes = tester.getCenter(find.text('Salvo'));
      // Devagar e curto (abaixo do limite): volta para o lugar.
      await tester.timedDrag(find.text('Salvo'), const Offset(0, 26), const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 600));
      expect(find.text('Salvo'), findsOneWidget);
      expect(tester.getCenter(find.text('Salvo')).dy, closeTo(antes.dy, 1));
      // Some sozinho no fim do tempo.
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
      expect(find.text('Salvo'), findsNothing);
    });
  });

  group('cards', () {
    testWidgets('SsCardStack: abre com mola física e assenta na altura aberta', (tester) async {
      await tester.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCardStack(cardHeight: 80, children: [for (var i = 0; i < 3; i++) Text('c$i')]),
          ),
        ),
      );
      final fechada = SsCardStack.heightFor(3, 80, 14, 12, 0);
      final aberta = SsCardStack.heightFor(3, 80, 14, 12, 1);
      expect(tester.getSize(find.byType(SsCardStack)).height, fechada);
      await tester.tap(find.byType(SsCardStack));
      var maior = 0.0;
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        final h = tester.getSize(find.byType(SsCardStack)).height;
        if (h > maior) maior = h;
      }
      expect(maior, greaterThan(aberta), reason: 'a mola passa do ponto');
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byType(SsCardStack)).height, aberta);
    });

    testWidgets('SsTimeline: o fio se desenha e tudo assenta', (tester) async {
      await tester.pumpWidget(
        _app(
          const SsTimeline(
            items: [
              SsTimelineItem(title: 'Um', done: true),
              SsTimelineItem(title: 'Dois', current: true),
              SsTimelineItem(title: 'Três'),
            ],
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 60));
      expect(tester.hasRunningAnimations, isTrue);
      await tester.pumpAndSettle();
      expect(find.text('Três'), findsOneWidget);
    });
  });
}
