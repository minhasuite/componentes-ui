// v0.21: micro-animações da casa (SsCue) e brilho real no tile (SsDeviceTile.level).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child, {bool reduce = false}) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate],
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduce),
    child: Scaffold(body: Center(child: child)),
  ),
);

Widget _cue(bool active, {SsCueKind kind = SsCueKind.on}) => SsCue(
  kind: kind,
  active: active,
  child: const SizedBox(key: ValueKey('filho'), width: 40, height: 40),
);

bool _animando(WidgetTester t) =>
    find.descendant(of: find.byType(SsCue), matching: find.byType(Transform)).evaluate().isNotEmpty;

void main() {
  testWidgets('SsCue não acena na primeira pintura', (t) async {
    await t.pumpWidget(_app(_cue(true)));
    await t.pump(const Duration(milliseconds: 100));
    expect(_animando(t), isFalse);
  });

  for (final kind in SsCueKind.values) {
    testWidgets('SsCue ${kind.name} acena quando liga e assenta', (t) async {
      await t.pumpWidget(_app(_cue(false, kind: kind)));
      await t.pumpWidget(_app(_cue(true, kind: kind)));
      await t.pump(const Duration(milliseconds: 150));
      expect(_animando(t), isTrue);
      await t.pumpAndSettle();
      expect(_animando(t), isFalse);
      expect(find.byKey(const ValueKey('filho')), findsOneWidget);
    });
  }

  testWidgets('SsCue não acena ao desligar', (t) async {
    await t.pumpWidget(_app(_cue(true)));
    await t.pumpWidget(_app(_cue(false)));
    await t.pump(const Duration(milliseconds: 150));
    expect(_animando(t), isFalse);
  });

  testWidgets('SsCue some com "remover animações"', (t) async {
    await t.pumpWidget(_app(_cue(false), reduce: true));
    await t.pumpWidget(_app(_cue(true), reduce: true));
    await t.pump(const Duration(milliseconds: 150));
    expect(_animando(t), isFalse);
  });

  test('SsDeviceTile.level: intensidade de .35 a 1', () {
    const icon = Icons.lightbulb_outline_rounded;
    expect(const SsDeviceTile(icon: icon, name: 'L').intensity, 1);
    expect(const SsDeviceTile(icon: icon, name: 'L', level: 0).intensity, closeTo(.35, 1e-9));
    expect(const SsDeviceTile(icon: icon, name: 'L', level: 1).intensity, 1);
    expect(const SsDeviceTile(icon: icon, name: 'L', level: 3).intensity, 1);
  });

  testWidgets('SsDeviceTile com level fraco pinta menos que cheio', (t) async {
    Color fundo() {
      final box = t.widget<AnimatedContainer>(find.byType(AnimatedContainer).first);
      return (box.decoration! as BoxDecoration).color!;
    }

    const cor = AppColors.aquecFg;
    await t.pumpWidget(_app(const SsDeviceTile(icon: Icons.lightbulb, name: 'L', on: true, color: cor, level: 1)));
    final cheio = fundo();
    await t.pumpWidget(_app(const SsDeviceTile(icon: Icons.lightbulb, name: 'L', on: true, color: cor, level: 0)));
    await t.pumpAndSettle();
    final fraco = fundo();
    expect(fraco, isNot(cheio));
    // Laranja sobre o branco: mais fraco = mais perto do branco (mais azul).
    expect(fraco.b, greaterThan(cheio.b));
  });
}
