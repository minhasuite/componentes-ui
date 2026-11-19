import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// v1.6 · SsHelpMenu (Aprenda e Novidades no menu lateral) e SsSideMenuItem(external:, badgeLabel:).
void main() {
  Widget app(Widget Function(BuildContext) menu, {Locale locale = const Locale('pt')}) => MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
    home: Scaffold(body: Builder(builder: menu)),
  );

  testWidgets('Aprenda e Novidades com o selo de não vistas, abrindo fora', (tester) async {
    var aprenda = 0, novidades = 0;
    await tester.pumpWidget(
      app(
        (c) => SsSideMenu(
          sections: [SsHelpMenu.section(c, onLearn: () => aprenda++, onNews: () => novidades++, unseenNews: 2)],
        ),
      ),
    );
    expect(find.text('AJUDA'), findsOneWidget);
    expect(find.text('Aprenda'), findsOneWidget);
    expect(find.text('Videoaulas de cada tela'), findsOneWidget);
    expect(find.text('Novidades'), findsOneWidget);
    expect(find.text('2 novas'), findsOneWidget);
    // Aprenda com o ícone de saída; Novidades com o selo no lugar dele.
    expect(find.byIcon(Icons.open_in_new_rounded), findsOneWidget);
    final h = tester.ensureSemantics();
    expect(
      tester.getSemantics(find.ancestor(of: find.text('Aprenda'), matching: find.byType(Semantics)).first),
      isSemantics(
        hint: 'abre no navegador',
        isButton: true,
        hasTapAction: true,
        label: 'Aprenda\nVideoaulas de cada tela',
      ),
    );
    h.dispose();
    await tester.tap(find.text('Aprenda'));
    await tester.tap(find.text('Novidades'));
    expect((aprenda, novidades), (1, 1));
  });

  testWidgets('uma nova no singular; sem não vistas, ícone de saída; sem onNews, só Aprenda', (tester) async {
    await tester.pumpWidget(
      app(
        (c) => SsSideMenu(
          sections: [SsHelpMenu.section(c, onLearn: () {}, onNews: () {}, unseenNews: 1)],
        ),
      ),
    );
    expect(find.text('1 nova'), findsOneWidget);

    await tester.pumpWidget(
      app(
        (c) => SsSideMenu(
          sections: [SsHelpMenu.section(c, onLearn: () {}, onNews: () {})],
        ),
      ),
    );
    expect(find.byType(SsBadge), findsNothing);
    expect(find.byIcon(Icons.open_in_new_rounded), findsNWidgets(2));

    await tester.pumpWidget(app((c) => SsSideMenu(sections: [SsHelpMenu.section(c, onLearn: () {}, unseenNews: 5)])));
    expect(find.text('Novidades'), findsNothing);
    expect(find.byType(SsBadge), findsNothing);
  });

  testWidgets('textos em inglês e espanhol', (tester) async {
    await tester.pumpWidget(
      app(
        (c) => SsSideMenu(
          sections: [SsHelpMenu.section(c, onLearn: () {}, onNews: () {}, unseenNews: 3)],
        ),
        locale: const Locale('en'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learn'), findsOneWidget);
    expect(find.text("What's new"), findsOneWidget);
    expect(find.text('3 new'), findsOneWidget);

    await tester.pumpWidget(
      app(
        (c) => SsSideMenu(
          sections: [SsHelpMenu.section(c, onLearn: () {}, onNews: () {}, unseenNews: 1)],
        ),
        locale: const Locale('es'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aprende'), findsOneWidget);
    expect(find.text('1 nueva'), findsOneWidget);
  });
}
