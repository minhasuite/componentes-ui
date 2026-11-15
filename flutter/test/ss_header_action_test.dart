import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.25.2 · achado das videoaulas do meu-gestor: com selo, o leitor de tela lia só o número ("7") e o botão
// ficava sem nome. O nome do botão é o tooltip (que já diz quantas novas); o número do selo é só visual.
void main() {
  Widget app(Widget acao) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: acao)),
  );

  testWidgets('com selo, o leitor lê o nome (tooltip) uma vez só, sem o número solto', (t) async {
    final semantics = t.ensureSemantics();
    var toques = 0;
    await t.pumpWidget(
      app(
        SsHeaderAction(
          icon: Icons.notifications_none,
          tooltip: 'Notificações, 7 novas',
          badge: '7',
          onPressed: () => toques++,
        ),
      ),
    );
    final node = t.getSemantics(find.byType(IconButton));
    expect(node.label, 'Notificações, 7 novas');
    expect(node.tooltip, isEmpty, reason: 'o nome já vai no rótulo; o tooltip repetiria');
    expect(find.bySemanticsLabel('7'), findsNothing);
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    await t.tap(find.byType(SsHeaderAction));
    expect(toques, 1);
    // O tooltip visual continua (toque longo).
    await t.longPress(find.byType(SsHeaderAction));
    await t.pumpAndSettle();
    expect(find.text('Notificações, 7 novas'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('sem selo, o nome também vem do tooltip', (t) async {
    final semantics = t.ensureSemantics();
    await t.pumpWidget(app(SsHeaderAction(icon: Icons.search, tooltip: 'Buscar', onPressed: () {})));
    expect(t.getSemantics(find.byType(IconButton)).label, 'Buscar');
    semantics.dispose();
  });
}
