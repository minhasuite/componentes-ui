// v1.2.2 (achado 17 das videoaulas do minhas-vendas): o rótulo visível dos campos
// (SsFieldLabel acima da caixa) é o nome do campo para o leitor de tela, dentro e
// fora de lista, e não é lido duas vezes.
import 'package:material_ui/material_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate],
  home: Scaffold(body: child),
);

SemanticsData _campo(WidgetTester t, int i) => t.getSemantics(find.byType(EditableText).at(i)).getSemanticsData();

// Quantos nós de semântica dizem só o texto (o rótulo lido à parte, fora do campo).
int _soltos(WidgetTester t, String texto) =>
    find.bySemanticsLabel(RegExp('^${RegExp.escape(texto)}\$')).evaluate().where((e) {
      final n = t.getSemantics(find.byWidget(e.widget));
      return !n.getSemanticsData().flagsCollection.isTextField;
    }).length;

void main() {
  final campos = [
    const SsTextField(label: 'Razão social'),
    const SsTextField(label: 'CNPJ', hint: '00.000.000/0000-00'),
    const SsTextField(label: 'Busca escondida', hideLabel: true),
    SsMoneyField(label: 'Valor', onChanged: (_) {}),
  ];

  for (final lista in [false, true]) {
    testWidgets('rótulo é o nome do campo ${lista ? 'dentro de ListView' : 'fora de lista'}', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          lista
              ? ListView(padding: const EdgeInsets.all(16), children: campos)
              : SingleChildScrollView(child: Column(children: campos)),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(EditableText), findsNWidgets(4));
      final esperado = ['Razão social', 'CNPJ', 'Busca escondida', 'Valor'];
      for (var i = 0; i < 4; i++) {
        final d = _campo(t, i);
        expect(d.flagsCollection.isTextField, isTrue, reason: esperado[i]);
        expect(d.label, contains(esperado[i]), reason: 'campo $i: label="${d.label}" hint="${d.hint}"');
      }
      // O rótulo visível não vira um segundo nó lido à parte.
      for (final r in ['Razão social', 'CNPJ', 'Valor']) {
        expect(_soltos(t, r), 0, reason: r);
      }
      h.dispose();
    });
  }
}
