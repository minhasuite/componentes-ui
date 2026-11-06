// v0.11: as peças da v0.9 com controle leem a altura da SsDensity e, no
// compacto, o toque continua com 48 (SsTapTarget, sem mudar o layout).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

// Sem animação de tema: senão o 1º quadro sai com a densidade anterior.
Widget _app(SsDensity d, Widget child) => MaterialApp(
  themeAnimationDuration: Duration.zero,
  theme: AppTheme.build(Brightness.light, density: d),
  home: Scaffold(
    body: Center(
      child: Padding(padding: const EdgeInsets.all(24), child: child),
    ),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('SsHoldToConfirm e SsMorphButton: altura do botão da densidade', (tester) async {
    for (final d in SsDensity.values) {
      await tester.pumpWidget(
        _app(
          d,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsHoldToConfirm(key: const Key('hold'), label: 'Segure', onConfirmed: () {}),
              SsMorphButton(key: const Key('morph'), label: 'Enviar', onPressed: () async {}),
              SsSwipeToConfirm(key: const Key('swipe'), label: 'Deslize', onConfirm: () async {}),
            ],
          ),
        ),
      );
      // AnimatedContainer (morph, swipe) anima a troca de altura entre densidades.
      await tester.pump(const Duration(seconds: 1));
      expect(tester.getSize(find.byKey(const Key('hold'))).height, d.controlHeight, reason: d.name);
      expect(tester.getSize(find.byKey(const Key('morph'))).height, d.controlHeight, reason: d.name);
      expect(tester.getSize(find.byKey(const Key('swipe'))).height, d.controlHeight + 8, reason: d.name);
    }
  });

  testWidgets('SsTabsUnderline: 42/48/52 e toque de 48 no compacto', (tester) async {
    for (final d in SsDensity.values) {
      var tocada = -1;
      await tester.pumpWidget(
        _app(
          d,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              SsTabsUnderline(
                key: const Key('abas'),
                tabs: const ['Um', 'Dois'],
                index: 0,
                onChanged: (i) => tocada = i,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      );
      final box = tester.getRect(find.byKey(const Key('abas')));
      expect(box.height, d.segmentHeight + 6, reason: d.name);
      if (d.isCompact) {
        // 2 px abaixo do desenho (dentro dos 48 de toque): ainda acerta a aba 2.
        await tester.tapAt(Offset(box.left + box.width * .75, box.bottom + 2));
        await tester.pump();
        expect(tocada, 1);
      }
    }
  });

  testWidgets('SsCountTabs encolhe no compacto e mantém 48 de toque', (tester) async {
    for (final d in SsDensity.values) {
      await tester.pumpWidget(
        _app(
          d,
          SsCountTabs(key: const Key('c'), tabs: const [('Abertos', 3), ('Feitos', 12)], index: 0, onChanged: (_) {}),
        ),
      );
      await tester.pump();
      expect(tester.getSize(find.byKey(const Key('c'))).height, greaterThanOrEqualTo(48), reason: d.name);
    }
  });
}
