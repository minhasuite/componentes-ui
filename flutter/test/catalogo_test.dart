// Renderiza o catálogo em claro e escuro (falha se algum estado quebrar).
// Com CATALOGO_SAIDA=<pasta> grava <pasta>/<componente>/<estado>-<tema>.png e
// meta.json, que a skill `componentes` transforma em SVG.
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

const _dpr = 2.0;

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
    await _fonte('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  for (final c in catalogo) {
    testWidgets(c.nome, (tester) async {
      // O ícone do app (assets/branding) não existe no pacote: erro de imagem não conta.
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if ('${d.exception}'.contains('Unable to load asset')) return;
        original?.call(d);
      };
      addTearDown(() => FlutterError.onError = original);

      for (final e in c.estados) {
        for (final tema in ['claro', 'escuro']) {
          tester.view.physicalSize = e.tamanho * _dpr;
          tester.view.devicePixelRatio = _dpr;
          await tester.pumpWidget(
            MaterialApp(
              debugShowCheckedModeBanner: false,
              // Sem transição de tema: senão o 1º quadro do escuro sai com cores do claro.
              themeAnimationDuration: Duration.zero,
              theme: tema == 'claro' ? AppTheme.light : AppTheme.dark,
              home: RepaintBoundary(
                key: const Key('shot'),
                // Chave por estado: senão o Flutter reaproveita o State do anterior.
                child: Scaffold(
                  key: ValueKey('${c.slug}/${e.slug}/$tema'),
                  body: Builder(builder: e.build),
                ),
              ),
            ),
          );
          // pump fixo: skeleton e ilustração animam para sempre (pumpAndSettle não volta).
          await tester.pump(); // quadro seguinte: callbacks pós-quadro (ex.: troca de aba)
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
      tester.view.reset();
      if (saida != null) {
        File('$saida/${c.slug}/meta.json').writeAsStringSync(
          jsonEncode({
            'nome': c.nome,
            'descricao': c.descricao,
            'comportamentos': c.comportamentos,
            'estados': [
              for (final e in c.estados) {'slug': e.slug, 'titulo': e.titulo},
            ],
          }),
        );
      }
    });
  }
}
