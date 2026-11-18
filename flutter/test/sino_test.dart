import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.25 · SsNotificationBell: o sino com o número de não lidos (par do Ss::NotificationBellComponent).
void main() {
  Widget app(Widget child) => MaterialApp(
    theme: AppTheme.light,
    home: Scaffold(body: Center(child: child)),
  );

  testWidgets('mostra o número, 99+ acima de 99, e toca', (tester) async {
    var tocou = 0;
    await tester.pumpWidget(app(SsNotificationBell(count: 3, onPressed: () => tocou++)));
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Avisos, 3 não lidos'), findsOneWidget);
    await tester.tap(find.byType(SsNotificationBell));
    expect(tocou, 1);

    await tester.pumpWidget(app(const SsNotificationBell(count: 120)));
    expect(find.text('99+'), findsOneWidget);
  });

  testWidgets('sem não lidos: sem selo e o nome simples', (tester) async {
    await tester.pumpWidget(
      app(SsNotificationBell(count: 0, label: 'Alerts', unreadLabel: (n) => '$n unread', onPressed: () {})),
    );
    expect(find.byType(Badge), findsNothing);
    expect(find.byTooltip('Alerts'), findsOneWidget);
    expect(find.byIcon(Icons.notifications_none_rounded), findsOneWidget);
  });
}
