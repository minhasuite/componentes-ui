// v0.17: botão flutuante só com o ícone e rótulo (o FAB de toda tela) e a linha de cima no SsTopBar.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget fab, {double width = 390, ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 844)),
    child: Scaffold(body: const SizedBox(), floatingActionButton: fab),
  ),
);

void main() {
  group('SsFab (v0.17)', () {
    testWidgets('extended: false: círculo, rótulo vira dica e nome lido, toque chama', (t) async {
      var n = 0;
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(SsFab(icon: Icons.mic_none_rounded, label: 'Falar com a casa', extended: false, onPressed: () => n++)),
      );
      expect(find.text('Falar com a casa'), findsNothing);
      expect(find.byTooltip('Falar com a casa'), findsOneWidget);
      expect(find.bySemanticsLabel('Falar com a casa'), findsOneWidget);
      final size = t.getSize(find.byType(SsFab));
      expect(size.width, size.height);
      expect(size.width, greaterThanOrEqualTo(48));
      await t.tap(find.byType(SsFab));
      await t.pump(const Duration(milliseconds: 500));
      expect(n, 1);
      h.dispose();
    });

    testWidgets('extendedFrom: texto só com a tela larga', (t) async {
      Widget fab() => SsFab(icon: Icons.mic_none_rounded, label: 'Falar', extendedFrom: 640, onPressed: () {});
      await t.pumpWidget(_app(fab()));
      expect(find.text('Falar'), findsNothing);
      expect(find.byTooltip('Falar'), findsOneWidget);
      await t.pumpWidget(_app(fab(), width: 1280));
      expect(find.text('Falar'), findsOneWidget);
      expect(find.byTooltip('Falar'), findsNothing);
    });

    testWidgets('padrão continua estendido com label', (t) async {
      await t.pumpWidget(
        _app(
          SsFab(icon: Icons.add, label: 'Seção', onPressed: () {}),
          theme: AppTheme.dark,
        ),
      );
      expect(find.text('Seção'), findsOneWidget);
    });
  });

  group('SsTopBar(eyebrow:)', () {
    testWidgets('linha de cima em caixa alta, apagada, acima do título', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            appBar: SsTopBar(
              eyebrow: 'Casa · 10 de novembro',
              title: 'Sala de estar',
              actions: [SsIconButton(icon: Icons.edit_outlined, tooltip: 'Editar painel', onPressed: () {})],
            ),
          ),
        ),
      );
      final eyebrow = find.text('CASA · 10 DE NOVEMBRO');
      expect(eyebrow, findsOneWidget);
      expect(find.text('Sala de estar'), findsOneWidget);
      expect(t.getTopLeft(eyebrow).dy, lessThan(t.getTopLeft(find.text('Sala de estar')).dy));
      final ctx = t.element(eyebrow);
      expect(t.widget<Text>(eyebrow).style?.color, SsColors.of(ctx).muted);
      expect(t.getBottomLeft(find.text('Sala de estar')).dy, lessThanOrEqualTo(kToolbarHeight));
      expect(find.byTooltip('Editar painel'), findsOneWidget);
    });
  });
}
