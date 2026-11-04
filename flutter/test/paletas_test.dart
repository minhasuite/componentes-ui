// Paridade com o Rails: as paletas do Flutter são as de paletas/paletas.json
// (fonte única; gerar.py escreve paletas.g.dart, o CSS e o Ruby). Se o container
// só monta flutter/, o JSON não está à vista e o teste de paridade é pulado.
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo_paletas.dart';

Color _cor(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

void main() {
  final json = File('../paletas/paletas.json');

  test(
    'mesmas paletas do paletas.json (slug, nome, família e cores)',
    () {
      final dados = jsonDecode(json.readAsStringSync()) as Map<String, dynamic>;
      final lista = (dados['paletas'] as List).cast<Map<String, dynamic>>();
      expect(SsPaleta.todas.length, lista.length);
      expect(SsPaleta.familias, dados['familias']);
      for (final (i, p) in lista.indexed) {
        final f = SsPaleta.todas[i];
        expect(f.slug, p['slug']);
        expect(f.nome, p['nome']);
        expect(f.familia, p['familia']);
        expect(f.brand.accentLight, _cor(p['accentLight'] as String), reason: f.slug);
        expect(f.brand.accentDark, _cor(p['accentDark'] as String), reason: f.slug);
        expect(f.brand.gradientColors, [for (final s in p['stops'] as List) _cor(s as String)], reason: f.slug);
      }
    },
    skip: json.existsSync() ? false : 'paletas/paletas.json fora do container (só flutter/ montado)',
  );

  test('accent sólido: texto branco ≥ 4,5:1 no claro e no escuro (checkbox, switch, botão sólido)', () {
    double lum(Color c) => c.computeLuminance();
    double contraste(Color a, Color b) {
      final (x, y) = (lum(a), lum(b));
      return (math.max(x, y) + .05) / (math.min(x, y) + .05);
    }

    for (final p in SsPaleta.todas) {
      for (final c in [p.brand.accentSolidLight, p.brand.accentSolidDark]) {
        expect(contraste(c, Colors.white), greaterThanOrEqualTo(4.5), reason: p.slug);
      }
    }
    expect(SsColors.forDark(false).accentSolid, const Color(0xFF5A45E8));
    expect(SsColors.forDark(true).accentSolid, const Color(0xFF6D5CF6));
  });

  test('slugs únicos e no formato do data-palette', () {
    final slugs = SsPaleta.todas.map((p) => p.slug).toList();
    expect(slugs.toSet().length, slugs.length);
    expect(slugs.every(RegExp(r'^[a-z0-9]+(-[a-z0-9]+)*$').hasMatch), isTrue);
  });

  testWidgets('SsPalettePicker: toque troca, anel desliza e o nome marcado muda', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: Builder(builder: catalogoPaletas.single.estados.first.build)),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('Paleta · Violeta'), findsOneWidget);
    await t.tap(find.text('Safira'));
    await t.pump(const Duration(milliseconds: 120));
    expect(find.text('Paleta · Safira'), findsOneWidget);
    await t.pumpAndSettle();
    // A última fica fora da vista: rolar e tocar.
    final ultima = SsPaleta.todas.last.nome;
    await t.scrollUntilVisible(find.text(ultima), 200, scrollable: find.byType(Scrollable).last);
    await t.tap(find.text(ultima));
    await t.pumpAndSettle();
    expect(find.text('Paleta · $ultima'), findsOneWidget);
    expect(find.bySemanticsLabel(ultima), findsOneWidget);
  });
}
