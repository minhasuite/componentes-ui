// v0.11: as peças base leem a densidade (SsDensity). No padrão, as medidas são
// as de antes; no compacto encolhem sem o toque cair abaixo de 48.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(SsDensity d, Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: SsDensityScope(
      density: d,
      child: Center(child: SizedBox(width: 320, child: child)),
    ),
  ),
);

double _h(WidgetTester t, Finder f) => t.getSize(f).height;

void main() {
  testWidgets('SsSegmented, SsFilterChip, SsSearchField e SsChoiceField: altura pela densidade', (t) async {
    final esperado = {
      SsDensity.compact: (36.0, 30.0, 40.0, 44.0),
      SsDensity.standard: (42.0, 34.0, 48.0, 52.0),
      SsDensity.comfortable: (46.0, 38.0, 52.0, 56.0),
    };
    for (final MapEntry(key: d, value: (seg, chip, busca, campo)) in esperado.entries) {
      await t.pumpWidget(
        _app(
          d,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsSegmented<int>(segments: const [(0, 'Dia'), (1, 'Mês')], value: 0, onChanged: (_) {}),
              SsFilterChip('Luzes', selected: false, onTap: () {}),
              SsSearchField(onChanged: (_) {}),
              SsChoiceField<int>(value: 1, options: const {1: 'Um', 2: 'Dois'}, onChanged: (_) {}),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      final segBox = find.descendant(of: find.byType(SsSegmented<int>), matching: find.byType(Container)).first;
      expect(_h(t, segBox), seg, reason: '${d.name} segmented');
      final chipBox = find.descendant(of: find.byType(SsFilterChip), matching: find.byType(AnimatedContainer)).first;
      expect(_h(t, chipBox), chip, reason: '${d.name} chip');
      final buscaBox = find.descendant(of: find.byType(SsSearchField), matching: find.byType(AnimatedContainer)).first;
      expect(_h(t, buscaBox), busca, reason: '${d.name} busca');
      final campoBox = find.descendant(of: find.byType(SsChoiceField<int>), matching: find.byType(Container)).first;
      expect(_h(t, campoBox), campo, reason: '${d.name} campo');
    }
  });

  testWidgets('compacto: chip de 30 aceita toque logo acima da borda (alvo 48)', (t) async {
    var toques = 0;
    await t.pumpWidget(
      _app(
        SsDensity.compact,
        SizedBox(
          height: 80,
          child: Center(child: SsFilterChip('Luzes', selected: false, onTap: () => toques++)),
        ),
      ),
    );
    final r = t.getRect(find.descendant(of: find.byType(SsFilterChip), matching: find.byType(AnimatedContainer)).first);
    expect(r.height, 30);
    await t.tapAt(Offset(r.center.dx, r.top - 6));
    await t.pump(const Duration(milliseconds: 500));
    expect(toques, 1);
    // Fora da área de 48, não.
    await t.tapAt(Offset(r.center.dx, r.top - 12));
    await t.pump(const Duration(milliseconds: 500));
    expect(toques, 1);
  });

  testWidgets('SsCard, SsIconTile e SsListItem: respiro e quadrado pela densidade', (t) async {
    for (final d in SsDensity.values) {
      await t.pumpWidget(
        _app(
          d,
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SsCard(child: SizedBox(key: Key('dentro'), height: 10)),
              const SsIconTile(Icons.bolt, key: Key('tile')),
              SsListItem(title: 'Pedido', subtitle: 'Mercado', icon: Icons.receipt_long, value: '10', onTap: () {}),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      final card = t.getRect(find.byType(SsCard));
      final dentro = t.getRect(find.byKey(const Key('dentro')));
      expect(dentro.top - card.top, d.cardPad, reason: d.name);
      expect(t.getSize(find.byKey(const Key('tile'))).width, d.iconTile, reason: d.name);
    }
  });

  testWidgets('SsListItem: compacto mais baixo, confortável mais alto', (t) async {
    final alturas = <String, double>{};
    for (final d in SsDensity.values) {
      await t.pumpWidget(
        _app(
          d,
          const Column(
            mainAxisSize: MainAxisSize.min,
            children: [SsListItem(title: 'Pedido', subtitle: 'Mercado', icon: Icons.receipt_long)],
          ),
        ),
      );
      await t.pumpAndSettle();
      alturas[d.name] = _h(t, find.descendant(of: find.byType(SsListItem), matching: find.byType(InkWell)).first);
    }
    expect(alturas['compact']!, lessThan(alturas['standard']!));
    expect(alturas['comfortable']!, greaterThan(alturas['standard']!));
  });
}
