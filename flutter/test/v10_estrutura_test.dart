// v0.10 (estrutura): renderiza cada estado do catálogo em claro, escuro e OLED
// e testa os comportamentos das peças novas.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo_v10_estrutura.dart';

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

  group('catálogo v0.10 estrutura', () {
    test('slugs únicos', () {
      final slugs = catalogoV10Estrutura.map((c) => c.slug).toList();
      expect(slugs.toSet().length, slugs.length);
    });

    for (final c in catalogoV10Estrutura) {
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

  group('SsIconPicker', () {
    const icones = [
      ('lightbulb', Icons.lightbulb_outline),
      ('power-socket', Icons.power_outlined),
      ('ar-condicionado', Icons.ac_unit),
    ];

    test('normalize tira acento, caixa e separadores', () {
      expect(SsIconPicker.normalize('Ar_Condicionádo'), 'ar condicionado');
      expect(SsIconPicker.normalize('power-socket'), 'power socket');
    });

    testWidgets('busca filtra, toque escolhe e vazio avisa', (t) async {
      String? escolhido = 'lightbulb';
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsIconPicker(
              icons: icones,
              value: escolhido,
              allowNone: true,
              onChanged: (v) => set(() => escolhido = v),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel('Sem ícone'), findsOneWidget);
      await t.tap(find.bySemanticsLabel('power-socket'));
      await t.pumpAndSettle();
      expect(escolhido, 'power-socket');
      expect(
        t.getSemantics(find.bySemanticsLabel('power-socket')).flagsCollection.isSelected.toString(),
        'Tristate.isTrue',
      );
      await t.tap(find.bySemanticsLabel('Sem ícone'));
      await t.pumpAndSettle();
      expect(escolhido, isNull);
      await t.enterText(find.byType(TextField), 'condicionado');
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('ar-condicionado'), findsOneWidget);
      expect(find.bySemanticsLabel('lightbulb'), findsNothing);
      await t.enterText(find.byType(TextField), 'piscina');
      await t.pumpAndSettle();
      expect(find.text('Nenhum ícone com “piscina”'), findsOneWidget);
    });
  });

  group('SsLocalePicker', () {
    testWidgets('lista e segmented trocam o idioma', (t) async {
      String v = 'pt-BR';
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (c, set) => SsLocalePicker(value: v, onChanged: (n) => set(() => v = n)),
          ),
        ),
      );
      expect(find.text('Português'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Español'), findsOneWidget);
      await t.tap(find.text('Español'));
      await t.pumpAndSettle();
      expect(v, 'es');
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (c, set) =>
                SsLocalePicker(value: v, segmented: true, showFlag: false, onChanged: (n) => set(() => v = n)),
          ),
        ),
      );
      await t.tap(find.text('EN'));
      await t.pumpAndSettle();
      expect(v, 'en');
    });
  });

  group('SsBlockList', () {
    List<SsBlock> blocos() => const [
      SsBlock(id: 'a', title: 'Quando', summary: 'Porta abrir', body: Text('CORPO A')),
      SsBlock(id: 'b', title: 'Então', error: 'Falta a ação', initiallyExpanded: true, body: Text('CORPO B')),
      SsBlock(id: 'c', title: 'Música', enabled: false),
    ];

    testWidgets('abre e fecha, mostra erro e corpo', (t) async {
      await t.pumpWidget(_app(SingleChildScrollView(child: SsBlockList(blocks: blocos()))));
      expect(find.text('CORPO A'), findsNothing);
      expect(find.text('CORPO B'), findsOneWidget);
      expect(find.text('Falta a ação'), findsOneWidget);
      await t.tap(find.text('Quando'));
      await t.pumpAndSettle();
      expect(find.text('CORPO A'), findsOneWidget);
      await t.tap(find.text('Quando'));
      await t.pumpAndSettle();
      expect(find.text('CORPO A'), findsNothing);
    });

    testWidgets('liga/desliga, mover, duplicar e excluir', (t) async {
      final log = <String>[];
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsBlockList(
              blocks: blocos(),
              onToggle: (b, v) => log.add('toggle ${b.id} $v'),
              onMove: (b, i) => log.add('move ${b.id} $i'),
              onDuplicate: (b) => log.add('dup ${b.id}'),
              onDelete: (b) => log.add('del ${b.id}'),
            ),
          ),
        ),
      );
      await t.tap(find.byType(SsSwitch).last);
      await t.pumpAndSettle();
      // Menu do 1º bloco: só "Mover para baixo" (é o primeiro).
      await t.tap(find.byTooltip('Mais opções').first);
      await t.pumpAndSettle();
      expect(find.text('Mover para cima'), findsNothing);
      await t.tap(find.text('Mover para baixo'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Mais opções').at(1));
      await t.pumpAndSettle();
      await t.tap(find.text('Duplicar'));
      await t.pumpAndSettle();
      await t.tap(find.byTooltip('Mais opções').last);
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      expect(log, ['toggle c true', 'move a 1', 'dup b', 'del c']);
      expect(find.byIcon(Icons.drag_indicator_rounded), findsNWidgets(3));
    });

    testWidgets('aninha filhos dentro do corpo', (t) async {
      await t.pumpWidget(
        _app(
          const SingleChildScrollView(
            child: SsBlockList(
              blocks: [
                SsBlock(
                  id: 'p',
                  title: 'Pai',
                  initiallyExpanded: true,
                  children: [SsBlock(id: 'f', title: 'Filho')],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Filho'), findsOneWidget);
      expect(find.byType(SsBlockList), findsNWidgets(2));
    });
  });

  group('SsCollapsible', () {
    testWidgets('abre com toque e avisa', (t) async {
      final log = <bool>[];
      await t.pumpWidget(
        _app(
          SsCollapsible(title: 'Sala', count: 3, label: '2 ligados', onChanged: log.add, child: const Text('DENTRO')),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.text('2 ligados'), findsOneWidget);
      expect(find.text('DENTRO'), findsNothing);
      await t.tap(find.text('Sala'));
      await t.pumpAndSettle();
      expect(find.text('DENTRO'), findsOneWidget);
      await t.tap(find.text('Sala'));
      await t.pumpAndSettle();
      expect(find.text('DENTRO'), findsNothing);
      expect(log, [true, false]);
    });

    testWidgets('com reduzir movimento troca direto', (t) async {
      await t.pumpWidget(
        _app(
          const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: SsCollapsible(title: 'Sala', child: Text('DENTRO')),
          ),
        ),
      );
      await t.tap(find.text('Sala'));
      await t.pump();
      expect(find.text('DENTRO'), findsOneWidget);
    });
  });
}
