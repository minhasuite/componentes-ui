import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// v1.0.1 · find.ssTooltip acha o tooltip do material_ui mesmo fora da semântica.
void main() {
  testWidgets('find.ssTooltip: SsHeaderAction (excludeFromSemantics) e IconButton', (t) async {
    var toques = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Row(
            children: [
              SsHeaderAction(
                icon: Icons.notifications_none_rounded,
                tooltip: 'Notificações, 3 novas',
                badge: '3',
                onPressed: () => toques++,
              ),
              IconButton(icon: const Icon(Icons.edit), tooltip: 'Editar', onPressed: () => toques++),
            ],
          ),
        ),
      ),
    );
    expect(find.ssTooltip('Notificações, 3 novas'), findsOneWidget);
    expect(find.ssTooltip(RegExp(r'^Notificações')), findsOneWidget);
    await t.tap(find.ssTooltip('Notificações, 3 novas'));
    // Um alvo só por tooltip (Tooltip e o RawTooltip dele não contam duas vezes).
    expect(find.ssTooltip('Editar'), findsOneWidget);
    await t.tap(find.ssTooltip('Editar'));
    expect(toques, 2);
    expect(find.ssTooltip('Nada'), findsNothing);
  });
}
