// v0.11 · densidade: tokens, escopo, alvo de toque e as capturas das peças
// representativas nas três densidades (claro e escuro). Falha se alguma estourar
// (o RenderFlex overflow vira erro do teste).
// Com DENSIDADE_SAIDA=<pasta> grava <pasta>/<densidade>/<componente>-<estado>-<tema>.png.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';
import 'catalogo_v11.dart';

const _dpr = 2.0;

/// Peças do catálogo capturadas nas três densidades (o conjunto representativo).
const _representativos = [
  'ss-button',
  'ss-text-field',
  'ss-segmented',
  'ss-filter-chip',
  'ss-search-field',
  'ss-list-item',
  'ss-switch-row',
  'ss-card',
  'ss-icon-button',
  'ss-rows',
  'ss-top-bar',
  'ss-device-tile',
  'ss-thermostat',
  'ss-code-keypad',
  'ss-data-table',
];

Future<void> _fonte(String familia, List<String> arquivos) async {
  final l = FontLoader(familia);
  for (final f in arquivos) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

double _altura(WidgetTester t, Finder f) => t.getSize(f).height;

void main() {
  final saida = Platform.environment['DENSIDADE_SAIDA'];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    await _fonte('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  test('três densidades, por nome, e a padrão igual aos valores de antes', () {
    expect(SsDensity.values, [SsDensity.compact, SsDensity.standard, SsDensity.comfortable]);
    expect(SsDensity.byName('compact'), SsDensity.compact);
    expect(SsDensity.byName('confortavel'), SsDensity.comfortable);
    expect(SsDensity.byName('x'), SsDensity.standard);
    const s = SsDensity.standard;
    expect(
      [s.fieldHeight, s.chipHeight, s.segmentHeight, s.cardPad, s.radiusField, s.radiusCard],
      [52, 34, 42, 16, 14, 18],
    );
    expect(s.controlHeight, 48, reason: 'botão: 50 → 48 (alvo do Material)');
    for (final d in SsDensity.values) {
      expect(d.minTarget, 48);
    }
    expect(
      SsDensity.compact.controlHeight < s.controlHeight && s.controlHeight < SsDensity.comfortable.controlHeight,
      isTrue,
    );
  });

  testWidgets('tema e escopo: o escopo ganha do tema e alinha o visualDensity', (t) async {
    late SsDensity doTema, doEscopo;
    late VisualDensity vd;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.build(Brightness.light, density: SsDensity.comfortable),
        home: Builder(
          builder: (c) {
            doTema = SsDensity.of(c);
            return SsDensityScope(
              density: SsDensity.compact,
              child: Builder(
                builder: (c2) {
                  doEscopo = SsDensity.of(c2);
                  vd = Theme.of(c2).visualDensity;
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    expect(doTema, SsDensity.comfortable);
    expect(doEscopo, SsDensity.compact);
    expect(vd, VisualDensity.compact);
    expect(AppTheme.light.extension<SsDensity>(), SsDensity.standard);
  });

  testWidgets('botão: altura pela densidade; no compacto o toque continua com 48', (t) async {
    var toques = 0;
    for (final d in SsDensity.values) {
      await t.pumpWidget(
        MaterialApp(
          themeAnimationDuration: Duration.zero,
          theme: AppTheme.build(Brightness.light, density: d),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 200,
                height: 80,
                child: Center(
                  child: SsButton(label: 'Salvar', onPressed: () => toques++),
                ),
              ),
            ),
          ),
        ),
      );
      final caixa = find.descendant(of: find.byType(SsButton), matching: find.byType(Container)).first;
      expect(_altura(t, caixa), d.controlHeight, reason: d.name);
    }
    // Compacto (40 de desenho): um toque 3,5 px acima da borda ainda vale.
    await t.pumpWidget(
      MaterialApp(
        themeAnimationDuration: Duration.zero,
        theme: AppTheme.build(Brightness.light, density: SsDensity.compact),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 80,
              child: Center(
                child: SsButton(label: 'Salvar', onPressed: () => toques++),
              ),
            ),
          ),
        ),
      ),
    );
    final r = t.getRect(find.byType(SsTapTarget).first);
    toques = 0;
    await t.tapAt(Offset(r.center.dx, r.top - 3.5));
    await t.pump(const Duration(milliseconds: 500));
    expect(toques, 1, reason: 'área de toque de 48 no compacto');
    await t.tapAt(Offset(r.center.dx, r.top - 10));
    await t.pump(const Duration(milliseconds: 500));
    expect(toques, 1, reason: 'fora dos 48 não vale');
  });

  testWidgets('seletor: três opções nos três idiomas e devolve a densidade', (t) async {
    SsDensity? escolhida;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SsDensityPicker(value: SsDensity.standard, onChanged: (d) => escolhida = d),
          ),
        ),
      ),
    );
    expect(find.text('Compacta'), findsOneWidget);
    expect(find.text('Padrão'), findsOneWidget);
    await t.tap(find.text('Confortável'));
    await t.pump(const Duration(milliseconds: 600));
    expect(escolhida, SsDensity.comfortable);
    expect(SsStrings.en.densityCompact, 'Compact');
    expect(SsStrings.es.densityStandard, 'Estándar');
  });

  final pecas = [
    ...catalogoV11.where((c) => c.slug == 'ss-density'),
    ...catalogo.where((c) => _representativos.contains(c.slug)),
  ];

  for (final d in SsDensity.values) {
    testWidgets('capturas na densidade ${d.name}', (t) async {
      final original = FlutterError.onError;
      FlutterError.onError = (e) {
        if ('${e.exception}'.contains('Unable to load asset')) return;
        original?.call(e);
      };
      addTearDown(() => FlutterError.onError = original);
      final temas = {
        'claro': AppTheme.build(Brightness.light, density: d),
        'escuro': AppTheme.build(Brightness.dark, density: d),
      };
      for (final c in pecas) {
        // ss-density: a amostra já traz o escopo dela; aqui vale só a do tema.
        final estados = c.slug == 'ss-density' ? [c.estados[1]] : c.estados;
        for (final e in estados) {
          for (final tema in temas.keys) {
            // O catálogo mede a caixa na padrão; a confortável é mais alta de propósito.
            final caixa = d.isComfortable ? Size(e.tamanho.width, e.tamanho.height * 1.25) : e.tamanho;
            t.view.physicalSize = caixa * _dpr;
            t.view.devicePixelRatio = _dpr;
            await t.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                themeAnimationDuration: Duration.zero,
                theme: temas[tema],
                home: RepaintBoundary(
                  key: const Key('shot'),
                  child: Scaffold(
                    key: ValueKey('${d.name}/${c.slug}/${e.slug}/$tema'),
                    body: c.slug == 'ss-density' ? const AmostraDensidade() : Builder(builder: e.build),
                  ),
                ),
              ),
            );
            await t.pump();
            await t.pump(Duration(milliseconds: e.aguarde));
            await t.runAsync(GoogleFonts.pendingFonts);
            if (saida == null) continue;
            final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
            await t.runAsync(() async {
              final img = await b.toImage(pixelRatio: _dpr);
              final png = await img.toByteData(format: ui.ImageByteFormat.png);
              File('$saida/${d.name}/${c.slug}-${e.slug}-$tema.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png!.buffer.asUint8List());
            });
          }
        }
      }
      t.view.reset();
    });
  }
}
