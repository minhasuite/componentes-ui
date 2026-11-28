// v1.14.4: o SsDeviceTile limpo no ssA11yAudit (o nó de detalhes com pelo menos 48 e sem tocável sem rótulo por
// fora) e o SsPressable(excludeFromSemantics:).
import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {SsDensity density = SsDensity.standard}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.build(Brightness.light, density: density),
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Scaffold(
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
  ),
);

/// Os modos do painel de casa: detalhes com chave (largura toda e em grade), só detalhes, ação e com rodapé.
Widget _painel() => Column(
  crossAxisAlignment: CrossAxisAlignment.stretch,
  children: [
    SsDeviceTile(icon: Icons.lightbulb_outline, name: 'Luz', on: true, onToggle: (_) {}, onTap: () {}),
    const SizedBox(height: 8),
    Row(
      children: [
        Expanded(
          child: SsDeviceTile(
            icon: Icons.lightbulb_outline,
            name: 'Luz da sala',
            onToggle: (_) {},
            onTap: () {},
            onLongPress: () {},
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SsDeviceTile(icon: Icons.power_outlined, name: 'Tomada', on: true, onToggle: (_) {}, onTap: () {}),
        ),
      ],
    ),
    const SizedBox(height: 8),
    SsDeviceTile(icon: Icons.bolt_outlined, name: 'Potência', state: '320 W', onTap: () {}),
    const SizedBox(height: 8),
    SsDeviceTile(icon: Icons.garage_outlined, name: 'Portão', onPress: () {}),
    const SizedBox(height: 8),
    SsDeviceTile(
      icon: Icons.lightbulb_outline,
      name: 'Abajur',
      on: true,
      onToggle: (_) {},
      onTap: () {},
      footer: const Text('Brilho 60%'),
    ),
  ],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('versão 1.14.4', () {
    expect(ssComponentesUiVersion, '1.14.4');
    expect(File('pubspec.yaml').readAsStringSync(), contains('version: 1.14.4'));
  });

  group('SsDeviceTile limpo no ssA11yAudit', () {
    for (final d in [SsDensity.compact, SsDensity.standard, SsDensity.comfortable]) {
      testWidgets('painel com todos os modos (${d.name})', (t) async {
        await t.pumpWidget(_app(_painel(), density: d));
        await t.pumpAndSettle();
        await ssA11yAudit(t);
      });
    }

    testWidgets('o nó de detalhes cobre o cartão (fora o rodapé) e tem pelo menos 48', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(_painel(), density: SsDensity.compact));
      await t.pumpAndSettle();
      final no = t.getSemantics(find.bySemanticsLabel(RegExp(r'^Potência: ')));
      expect(no.rect.height, greaterThanOrEqualTo(48));
      final cartao = t.getRect(find.widgetWithText(SsDeviceTile, 'Potência'));
      // O cartão menos a borda (1 a 1,4 de cada lado), que o Container põe por fora do respiro.
      expect(no.rect.height, closeTo(cartao.height, 3));
      expect(no.rect.width, closeTo(cartao.width, 3));
      expect(no.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
      h.dispose();
    });

    testWidgets('o desenho não muda: o cartão de uma linha tem o quadrado do ícone mais o respiro', (t) async {
      for (final d in [SsDensity.compact, SsDensity.standard]) {
        await t.pumpWidget(
          _app(
            SsDeviceTile(icon: Icons.bolt_outlined, name: 'Potência', onTap: () {}),
            density: d,
          ),
        );
        await t.pumpAndSettle();
        final cartao = t.getSize(find.byType(SsDeviceTile));
        final pad = d.cardPad - 4;
        // A linha tem a altura do quadrado do ícone (iconTile + 2) ou do texto, o que for maior.
        expect(cartao.height, greaterThanOrEqualTo(d.iconTile + 2 + 2 * pad));
        final quadrado = t.getRect(find.byIcon(Icons.bolt_outlined));
        final caixa = t.getRect(find.byType(SsDeviceTile));
        expect(quadrado.left - caixa.left, greaterThanOrEqualTo(pad));
      }
    });

    testWidgets('toque no cartão ainda abre os detalhes e o toque longo ainda chama', (t) async {
      var toques = 0, longos = 0;
      await t.pumpWidget(
        _app(
          SsDeviceTile(
            icon: Icons.lightbulb_outline,
            name: 'Luz',
            onToggle: (_) {},
            onTap: () => toques++,
            onLongPress: () => longos++,
          ),
        ),
      );
      await t.tap(find.text('Luz'));
      await t.longPress(find.text('Luz'));
      await t.pumpAndSettle();
      expect((toques, longos), (1, 1));
    });
  });

  testWidgets('SsPressable(excludeFromSemantics: true) não cria ações no nó de cima', (t) async {
    final h = t.ensureSemantics();
    Future<SemanticsNode> no(bool excluir) async {
      await t.pumpWidget(
        _app(
          SsPressable(
            excludeFromSemantics: excluir,
            onTap: () {},
            child: const SizedBox(width: 100, height: 60, key: ValueKey('alvo')),
          ),
        ),
      );
      return t.getSemantics(find.byKey(const ValueKey('alvo')));
    }

    expect((await no(false)).getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect((await no(true)).getSemanticsData().hasAction(SemanticsAction.tap), isFalse);
    h.dispose();
  });
}
