import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.27 · menu lateral com a dica de arrastar e a casca SsNavScaffold (faixa acima da barra transparente).
const _abas = [
  SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos'),
  SsNavItem(Icons.menu, 'Mais'),
];

Widget _app({
  int aba = 0,
  ValueChanged<int>? onTap,
  bool peek = false,
  bool semAnimacao = false,
  VoidCallback? onAtalho,
  Widget? body,
}) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('pt'),
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        disableAnimations: semAnimacao,
        size: const Size(390, 760),
        padding: const EdgeInsets.only(bottom: 20),
      ),
      child: SsNavScaffold(
        peek: peek,
        navBar: SsNavBar(items: _abas, currentIndex: aba, onTap: onTap ?? (_) {}),
        sideMenu: SsSideMenu(
          title: 'Meu App',
          subtitle: 'ana@exemplo.com',
          sections: [
            SsSideMenuSection(title: 'Atalhos', [SsSideMenuItem(Icons.sync, 'Sincronização', onTap: onAtalho)]),
          ],
        ),
        body: body ?? const ColoredBox(key: ValueKey('corpo'), color: AppColors.danger, child: SizedBox.expand()),
      ),
    ),
  ),
);

SsSideMenuHostState _host(WidgetTester t) => t.state(find.byType(SsSideMenuHost));

Future<void> _arrastaDaBorda(WidgetTester t) async {
  final g = await t.startGesture(const Offset(8, 300));
  for (var i = 0; i < 10; i++) {
    await g.moveBy(const Offset(30, 0));
    await t.pump(const Duration(milliseconds: 16));
  }
  await g.up();
  await t.pumpAndSettle();
}

void main() {
  setUp(SsSideMenuHost.debugResetPeek);

  testWidgets('SsNavScaffold: o corpo passa por trás da faixa do círculo e recebe padding.bottom = rise', (t) async {
    late EdgeInsets padding;
    await t.pumpWidget(
      _app(
        body: Builder(
          builder: (context) {
            padding = MediaQuery.paddingOf(context);
            return const SizedBox.expand(key: ValueKey('corpo'));
          },
        ),
      ),
    );
    await t.pumpAndSettle();
    final corpo = t.getRect(find.byKey(const ValueKey('corpo')));
    final barra = t.getRect(find.byType(SsNavBar));
    // O corpo termina na borda da barra (barra inteira menos a faixa), não no topo da faixa.
    expect(corpo.bottom, closeTo(barra.top + SsNavBar.rise, .5));
    expect(padding.bottom, SsNavBar.rise);
  });

  testWidgets('menu: arrastar da borda abre, as abas entram com a atual marcada, tocar fora fecha', (t) async {
    await t.pumpWidget(_app(aba: 1));
    await t.pumpAndSettle();
    expect(_host(t).isOpen, isFalse);
    expect(find.text('Meu App'), findsNothing);

    await _arrastaDaBorda(t);
    expect(_host(t).isOpen, isTrue);
    expect(find.text('Meu App'), findsOneWidget);
    expect(find.text('SINCRONIZAÇÃO'.toUpperCase()), findsNothing);
    expect(find.text('ATALHOS'), findsOneWidget);
    // As abas no menu (e na barra): "Pedidos" aparece duas vezes, a do menu selecionada.
    expect(find.text('Pedidos'), findsNWidgets(2));
    final sem = t.ensureSemantics();
    expect(
      t.getSemantics(find.ancestor(of: find.text('Pedidos').last, matching: find.byType(Semantics)).first),
      isSemantics(isButton: true, isSelected: true, label: 'Pedidos'),
    );
    sem.dispose();

    await t.tapAt(const Offset(370, 300)); // fora do painel
    await t.pumpAndSettle();
    expect(_host(t).isOpen, isFalse);
  });

  testWidgets('menu: tocar numa linha chama o onTap e fecha; tocar numa aba troca a aba', (t) async {
    var atalho = 0;
    final abas = <int>[];
    await t.pumpWidget(_app(onAtalho: () => atalho++, onTap: abas.add));
    await t.pumpAndSettle();
    _host(t).open();
    await t.pumpAndSettle();
    await t.tap(find.text('Sincronização'));
    await t.pumpAndSettle();
    expect(atalho, 1);
    expect(_host(t).isOpen, isFalse);

    _host(t).open();
    await t.pumpAndSettle();
    await t.tap(find.text('Mais').last);
    await t.pumpAndSettle();
    expect(abas, [2]);
  });

  testWidgets('voltar: fecha o menu; fora da 1ª aba vai para ela', (t) async {
    final abas = <int>[];
    await t.pumpWidget(_app(aba: 2, onTap: abas.add));
    await t.pumpAndSettle();
    _host(t).open();
    await t.pumpAndSettle();
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(_host(t).isOpen, isFalse);
    expect(abas, isEmpty);

    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(abas, [0]);
  });

  testWidgets('dica: espia uma vez por abertura do app, sem segurar o toque, e volta fechado', (t) async {
    await t.pumpWidget(_app(peek: true));
    await t.pump();
    await t.pump(const Duration(milliseconds: 950));
    await t.pump(const Duration(milliseconds: 600));
    // Fresta aberta com a pílula.
    expect(find.text('Arraste para abrir o menu'), findsOneWidget);
    expect(_host(t).isOpen, isFalse);
    await t.pumpAndSettle();
    expect(find.text('Arraste para abrir o menu'), findsNothing);
    expect(find.text('Meu App'), findsNothing);

    // Outra casca no mesmo processo: não espia de novo.
    await t.pumpWidget(const SizedBox());
    await t.pumpWidget(_app(peek: true));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1500));
    expect(find.text('Arraste para abrir o menu'), findsNothing);
  });

  testWidgets('dica: com "reduzir movimento" não roda', (t) async {
    await t.pumpWidget(_app(peek: true, semAnimacao: true));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1500));
    expect(find.text('Arraste para abrir o menu'), findsNothing);
  });

  testWidgets('leitor de tela: a borda tem o botão "Abrir o menu" (pt, en, es)', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(_app());
    await t.pumpAndSettle();
    expect(find.bySemanticsLabel('Abrir o menu'), findsOneWidget);
    expect(SsStrings.en.sideMenuHint, 'Swipe to open the menu');
    expect(SsStrings.es.sideMenuOpen, 'Abrir el menú');
    sem.dispose();
  });
}
