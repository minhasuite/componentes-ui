// v0.14: nota no lugar do conteúdo, tarefa com comando e foto no ícone tonal.
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate],
  home: Scaffold(body: SizedBox(width: 390, child: child)),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('SsNote: frase, ícone e tom de aviso', (t) async {
    await t.pumpWidget(
      _app(
        const Column(
          children: [
            SsNote('Nenhum alerta aberto', icon: Icons.check_circle_outline, tone: SsTone.success),
            SsNote('O robô parou', tone: SsTone.danger),
          ],
        ),
      ),
    );
    expect(find.text('Nenhum alerta aberto'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
    final ok = t.widget<Text>(find.text('Nenhum alerta aberto'));
    final perigo = t.widget<Text>(find.text('O robô parou'));
    expect(ok.style!.fontWeight, FontWeight.w400);
    expect(perigo.style!.fontWeight, FontWeight.w600);
    expect(perigo.style!.color, isNot(ok.style!.color));
    expect(
      find.ancestor(
        of: find.text('O robô parou'),
        matching: find.byWidgetPredicate((w) => w is Semantics && w.properties.liveRegion == true),
      ),
      findsOneWidget,
    );
  });

  testWidgets('SsTaskItem: marca, risca e remove', (t) async {
    bool? marcou;
    var removeu = false;
    await t.pumpWidget(
      _app(
        Column(
          children: [
            SsTaskItem('Comprar pão', onChanged: (v) => marcou = v, onDelete: () => removeu = true),
            const SsTaskItem('Regar', done: true),
          ],
        ),
      ),
    );
    await t.tap(find.text('Comprar pão'));
    expect(marcou, isTrue);
    await t.tap(find.byIcon(Icons.close_rounded));
    expect(removeu, isTrue);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(t.widget<Text>(find.text('Regar')).style!.decoration, TextDecoration.lineThrough);
    expect(t.widget<SsIconButton>(find.byType(SsIconButton)).tooltip, endsWith(': Comprar pão'));
  });

  testWidgets('SsIconTile(image:): foto que falha volta ao ícone', (t) async {
    await t.pumpWidget(_app(SsIconTile(Icons.eco_outlined, image: MemoryImage(Uint8List(0)))));
    expect(find.byType(Image), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.byIcon(Icons.eco_outlined), findsOneWidget);
  });
}
