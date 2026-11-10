// v0.18: botão com várias ações, dinheiro com controller de fora, barra de topo
// no lugar do AppBar e aviso sem BuildContext (o meu-financeiro-app no pacote).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _fabApp(Widget fab, {bool reduce = false, ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: Scaffold(
        body: const Center(child: Text('Página')),
        floatingActionButton: fab,
      ),
    ),
  ),
);

Widget _form(Widget field, {GlobalKey<FormState>? form}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Form(
      key: form,
      child: Column(
        children: [
          field,
          const TextField(key: ValueKey('outro')),
        ],
      ),
    ),
  ),
);

void main() {
  group('SsSpeedDial', () {
    testWidgets('abre a lista, gira, escolhe uma ação (fecha e roda)', (t) async {
      final log = <String>[];
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _fabApp(
          SsSpeedDial(
            onOpenChanged: (v) => log.add('aberto:$v'),
            actions: [
              SsSpeedDialAction('Lançamento', Icons.add_rounded, () => log.add('lanc')),
              SsSpeedDialAction('IA', Icons.auto_awesome, () => log.add('ia'), tooltip: 'Registrar compra com IA'),
            ],
          ),
        ),
      );
      // Fechado: círculo com "Ações rápidas" e o estado recolhido.
      expect(find.text('Lançamento'), findsNothing);
      expect(find.byTooltip('Ações rápidas'), findsOneWidget);
      final node = t.getSemantics(find.byType(SsFab));
      expect(node.label, contains('Ações rápidas'));
      expect(node.flagsCollection.isExpanded, isNot(true));
      expect(t.getSize(find.byType(SsFab)).height, greaterThanOrEqualTo(48));

      await t.tap(find.byType(SsFab));
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      expect(log, ['aberto:true']);
      // No meio da animação, o ícone já girou.
      final girando = t.widget<SsFab>(find.byKey(const ValueKey('ss-speed-dial-close')));
      expect(girando.iconTurns, isNot(0));
      await t.pumpAndSettle();
      expect(find.text('Lançamento'), findsOneWidget);
      expect(find.text('IA'), findsOneWidget);
      expect(find.bySemanticsLabel('Registrar compra com IA'), findsOneWidget);
      final fechar = t.widget<SsFab>(find.byKey(const ValueKey('ss-speed-dial-close')));
      expect(fechar.icon, Icons.close_rounded);
      expect(fechar.iconTurns, 0);
      // A 1ª ação fica mais perto do botão (embaixo da 2ª) e acima dele.
      final yLanc = t.getCenter(find.text('Lançamento')).dy;
      expect(yLanc, greaterThan(t.getCenter(find.text('IA')).dy));
      expect(yLanc, lessThan(t.getTopLeft(find.byKey(const ValueKey('ss-speed-dial-close'))).dy));
      // Alvo de 48: a linha mede 48 e o toque na borda de cima (fora da pílula) vale.
      final linha = t.getRect(find.bySemanticsLabel('Registrar compra com IA'));

      expect(linha.height, greaterThanOrEqualTo(48));
      await t.tapAt(Offset(linha.center.dx, linha.top + 2));
      await t.pumpAndSettle();
      expect(log, ['aberto:true', 'aberto:false', 'ia']);
      expect(find.text('IA'), findsNothing);
      expect(find.byTooltip('Ações rápidas'), findsOneWidget);
      h.dispose();
    });

    testWidgets('véu, × e voltar fecham sem rodar ação', (t) async {
      var n = 0;
      final acoes = [SsSpeedDialAction('A', Icons.add, () => n++), SsSpeedDialAction('B', Icons.remove, () => n++)];
      await t.pumpWidget(_fabApp(SsSpeedDial(actions: acoes)));

      await t.tap(find.byType(SsFab));
      await t.pumpAndSettle();
      await t.tapAt(const Offset(20, 20)); // véu
      await t.pumpAndSettle();
      expect(find.text('A'), findsNothing);

      await t.tap(find.byType(SsFab));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('ss-speed-dial-close')));
      await t.pumpAndSettle();
      expect(find.text('A'), findsNothing);

      await t.tap(find.byType(SsFab));
      await t.pumpAndSettle();
      expect(find.text('A'), findsOneWidget);
      await t.binding.handlePopRoute(); // voltar do sistema
      await t.pumpAndSettle();
      expect(find.text('A'), findsNothing);
      expect(find.text('Página'), findsOneWidget);
      expect(n, 0);
    });

    testWidgets('uma ação só vira SsFab direto', (t) async {
      var n = 0;
      await t.pumpWidget(
        _fabApp(SsSpeedDial(actions: [SsSpeedDialAction('Lançamento', Icons.add_rounded, () => n++)])),
      );
      expect(find.text('Lançamento'), findsOneWidget);
      await t.tap(find.byType(SsFab));
      await t.pumpAndSettle();
      expect(n, 1);
      expect(find.byKey(const ValueKey('ss-speed-dial-close')), findsNothing);
    });

    testWidgets('reduzir movimento: abre de uma vez (escuro, rótulo e textos em inglês)', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          locale: const Locale('en'),
          supportedLocales: const [Locale('en')],
          localizationsDelegates: const [
            SsStrings.delegate,
            DefaultMaterialLocalizations.delegate,
            DefaultWidgetsLocalizations.delegate,
          ],
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: Scaffold(
                floatingActionButton: SsSpeedDial(
                  label: 'New',
                  actions: [SsSpeedDialAction('A', Icons.add, () {}), SsSpeedDialAction('B', Icons.remove, () {})],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.text('New'), findsOneWidget);
      await t.tap(find.byType(SsFab));
      await t.pump();
      expect(find.text('A'), findsOneWidget);
      expect(t.widget<SsFab>(find.byKey(const ValueKey('ss-speed-dial-close'))).iconTurns, 0);
      expect(find.byTooltip('Close'), findsOneWidget);
    });

    test('textos novos nos três idiomas', () {
      expect(SsStrings.pt.quickActions, 'Ações rápidas');
      expect(SsStrings.en.quickActions, 'Quick actions');
      expect(SsStrings.es.quickActions, 'Acciones rápidas');
    });
  });

  group('SsMoneyField(controller:)', () {
    testWidgets('escrever de fora aparece; digitar vai para o controller', (t) async {
      final c = TextEditingController(text: '1234,56');
      await t.pumpWidget(_form(SsMoneyField(controller: c, label: 'Valor', expression: true)));
      await t.pump();
      expect(find.text('1234,56'), findsOneWidget);
      c.text = '57,50'; // IA, boleto, histórico
      await t.pump();
      expect(find.text('57,50'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '45+12,5');
      await t.pump();
      expect(c.text, '45+12,5');
      expect(find.text('= ${money(5750)}'), findsOneWidget);
      expect(SsMoneyField.parse(c.text), 5750);
      // Ao sair do campo, a conta vira o valor.
      await t.tap(find.byKey(const ValueKey('outro')));
      await t.pump();
      expect(c.text, '57,50');
      c.dispose();
    });

    testWidgets('sem conta: texto de fora vai para o formato; dígitos crescem da direita', (t) async {
      final c = TextEditingController(text: '81000,00');
      int? ultimo;
      await t.pumpWidget(_form(SsMoneyField(controller: c, onChanged: (v) => ultimo = v)));
      await t.pump();
      expect(c.text, '81.000,00');
      c.text = '1234.5';
      await t.pump();
      expect(c.text, '1.234,50');
      await t.enterText(find.byType(TextField).first, '');
      await t.enterText(find.byType(TextField).first, '505');
      await t.pump();
      expect(c.text, '5,05');
      expect(ultimo, 505);
      c.dispose();
    });

    testWidgets('validação: required, conta que não fecha, negativo, errorText', (t) async {
      final form = GlobalKey<FormState>();
      final c = TextEditingController();
      Widget campo({String? erro, bool signed = false}) =>
          SsMoneyField(controller: c, expression: true, required: true, errorText: erro, signed: signed);
      await t.pumpWidget(_form(campo(), form: form));
      expect(form.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Informe um valor'), findsOneWidget);
      c.text = '45+';
      await t.pump();
      expect(form.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text(SsStrings.pt.invalidAmount), findsOneWidget);
      c.text = '-10';
      expect(form.currentState!.validate(), isFalse);
      await t.pumpWidget(_form(campo(signed: true), form: form));
      expect(form.currentState!.validate(), isTrue);
      c.text = '12,00';
      await t.pumpWidget(_form(campo(erro: 'Valor acima do limite'), form: form));
      expect(form.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Valor acima do limite'), findsOneWidget);
      c.dispose();
    });

    testWidgets('focusNode e autofocus de fora; calculator: false; onKeypad', (t) async {
      final c = TextEditingController();
      final foco = FocusNode();
      var abriu = 0;
      await t.pumpWidget(_form(SsMoneyField(controller: c, focusNode: foco, autofocus: true, expression: true)));
      await t.pump();
      expect(foco.hasFocus, isTrue);
      expect(find.byTooltip('Calculadora'), findsOneWidget);
      await t.pumpWidget(_form(SsMoneyField(controller: c, expression: true, calculator: false)));
      expect(find.byTooltip('Calculadora'), findsNothing);
      await t.pumpWidget(_form(SsMoneyField(controller: c, expression: true, onKeypad: () => abriu++)));
      await t.tap(find.byTooltip('Calculadora'));
      await t.pump();
      expect(abriu, 1);
      foco.dispose();
      c.dispose();
    });

    testWidgets('teclado do pacote escreve no controller', (t) async {
      final c = TextEditingController(text: '10,00');
      await t.pumpWidget(_form(SsMoneyField(controller: c, expression: true, label: 'Valor')));
      await t.tap(find.byTooltip('Calculadora'));
      await t.pumpAndSettle();
      await t.tap(find.text('+'));
      await t.tap(find.text('5'));
      await t.pump();
      await t.tap(find.text('Confirmar'));
      await t.pumpAndSettle();
      expect(c.text, '15,00');
      c.dispose();
    });

    testWidgets('sem controller continua igual (cents e onChanged)', (t) async {
      int? v;
      await t.pumpWidget(_form(SsMoneyField(cents: 1234, onChanged: (x) => v = x)));
      expect(find.text('12,34'), findsOneWidget);
      await t.enterText(find.byType(TextField).first, '12345');
      expect(v, 12345);
    });

    test('parse', () {
      expect(SsMoneyField.parse('1.234,56'), 123456);
      expect(SsMoneyField.parse('1234.56'), 123456);
      expect(SsMoneyField.parse('3×19,90'), 5970);
      expect(SsMoneyField.parse('-10'), -1000);
      expect(SsMoneyField.parse(''), isNull);
      expect(SsMoneyField.parse('abc'), isNull);
    });
  });

  group('SsTopBar no lugar do AppBar', () {
    testWidgets('título + subtítulo em duas linhas, ações e voltar automático', (t) async {
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(MaterialApp(navigatorKey: nav, theme: AppTheme.light, home: const Scaffold()));
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: SsTopBar(
              title: 'Nubank',
              subtitle: 'Fecha dia 3 · vence dia 10',
              actions: [SsIconButton(icon: Icons.ios_share, tooltip: 'Exportar', onPressed: () {})],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byTooltip('Voltar'), findsOneWidget);
      expect(find.byTooltip('Exportar'), findsOneWidget);
      final titulo = t.getBottomLeft(find.text('Nubank')).dy;
      expect(titulo, lessThanOrEqualTo(t.getTopLeft(find.text('Fecha dia 3 · vence dia 10')).dy));
      expect(t.getBottomLeft(find.text('Fecha dia 3 · vence dia 10')).dy, lessThanOrEqualTo(kToolbarHeight));
      await t.tap(find.byTooltip('Voltar'));
      await t.pumpAndSettle();
      expect(find.text('Nubank'), findsNothing);
    });

    testWidgets('bottom (TabBar) soma na altura; dark e sem voltar', (t) async {
      const bar = SsTopBar(
        title: 'Planejamento',
        style: SsTopBarStyle.dark,
        automaticallyImplyLeading: false,
        bottom: TabBar(
          tabs: [
            Tab(text: 'Mês'),
            Tab(text: 'Ano'),
          ],
        ),
      );
      expect(bar.preferredSize.height, kToolbarHeight + kTextTabBarHeight);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const DefaultTabController(length: 2, child: Scaffold(appBar: bar)),
        ),
      );
      expect(find.text('Mês'), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsNothing);
      expect(t.getSize(find.byType(SsTopBar)).height, kToolbarHeight + kTextTabBarHeight);
    });
  });

  group('showSsToastGlobal', () {
    tearDown(() => SsToastHost.navigatorKey = null);

    testWidgets('sem chave não mostra; com a chave do navegador mostra e a ação roda', (t) async {
      expect(showSsToastGlobal('Nada'), isFalse);
      final key = GlobalKey<NavigatorState>();
      SsToastHost.navigatorKey = key;
      var abriu = 0;
      await t.pumpWidget(MaterialApp(navigatorKey: key, theme: AppTheme.light, home: const Scaffold()));
      expect(showSsToastGlobal('Fatura fechou', actionLabel: 'Abrir', onAction: () => abriu++), isTrue);
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      expect(find.text('Fatura fechou'), findsOneWidget);
      await t.tap(find.text('Abrir'));
      await t.pump();
      expect(abriu, 1);
      expect(find.text('Fatura fechou'), findsNothing);
      await t.pump(const Duration(seconds: 5));
    });

    testWidgets('desfazer global', (t) async {
      final key = GlobalKey<NavigatorState>();
      SsToastHost.navigatorKey = key;
      await t.pumpWidget(MaterialApp(navigatorKey: key, theme: AppTheme.light, home: const Scaffold()));
      final r = showSsUndoGlobal('Lançamento excluído');
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('Desfazer'));
      await t.pump();
      expect(await r, isTrue);
      await t.pump(const Duration(seconds: 6));
    });
  });

  testWidgets('SsButton.text cobre o TextButton (com ícone, tom neutro)', (t) async {
    var n = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Column(
            children: [
              SsButton.text(label: 'Guardar', icon: Icons.savings_outlined, onPressed: () => n++),
              SsButton.text(label: 'Dispensar', tone: SsTone.neutral, onPressed: () => n++),
            ],
          ),
        ),
      ),
    );
    await t.tap(find.text('Guardar'));
    await t.tap(find.text('Dispensar'));
    await t.pump(const Duration(milliseconds: 500));
    expect(n, 2);
  });
}
