import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.24 · auditoria de UX de novembro (minhas-vendas C01; meu-gestor-app B16, B18, U08/U12).
// Cada teste reproduz o achado: falha na v0.23.6 e passa com a correção.
void main() {
  Widget app(Widget home, {Locale locale = const Locale('pt')}) => MaterialApp(
    theme: AppTheme.light,
    locale: locale,
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
    home: home,
  );

  Future<void> celular(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
  }

  bool focado(WidgetTester tester, Finder campo) {
    final e = tester.widget<EditableText>(find.descendant(of: campo, matching: find.byType(EditableText)));
    return e.focusNode.hasFocus;
  }

  group('C01 SsDataTable(mobile: compact)', () {
    Widget tabela({SsDataTableMobile mobile = SsDataTableMobile.compact}) => Scaffold(
      body: SingleChildScrollView(
        child: SsDataTable(
          mobile: mobile,
          columns: const [
            SsDataColumn('Nº', mobile: SsDataSlot.meta),
            SsDataColumn('Cliente', mobile: SsDataSlot.title),
            SsDataColumn('Emissão', mobile: SsDataSlot.meta),
            SsDataColumn('Situação', mobile: SsDataSlot.badge),
            SsDataColumn('Total', numeric: true, mobile: SsDataSlot.value),
          ],
          rows: [
            SsDataRow.text(const ['#2904', 'Sabor Caseiro', '14/11/2026', 'Aguarda', r'R$ 2.380,00']),
            SsDataRow.text(const ['#2903', 'Consumidor final', '14/11/2026', 'Entregue', r'R$ 22,87']),
          ],
        ),
      ),
    );

    testWidgets('linha em duas: título e valor em cima, meta e selo embaixo, sem os rótulos', (tester) async {
      await celular(tester);
      await tester.pumpWidget(app(tabela()));
      await tester.pumpAndSettle();
      expect(find.text('CLIENTE'), findsNothing, reason: 'o cartão "RÓTULO valor" saiu');
      final titulo = tester.getRect(find.text('Sabor Caseiro'));
      final valor = tester.getRect(find.text(r'R$ 2.380,00'));
      final meta = tester.getRect(find.text('#2904'));
      final selo = tester.getRect(find.text('Aguarda'));
      expect((titulo.center.dy - valor.center.dy).abs(), lessThan(4));
      expect(valor.left, greaterThan(titulo.left));
      expect(meta.top, greaterThan(titulo.bottom - 1));
      expect((meta.center.dy - selo.center.dy).abs(), lessThan(6));
      expect(selo.left, greaterThan(meta.right));
      // As duas linhas do registro cabem em bem menos que o cartão de 5 rótulos.
      final segundo = tester.getRect(find.text('Consumidor final'));
      expect(segundo.top - titulo.top, lessThan(90));
    });

    testWidgets('o padrão continua o cartão com rótulos', (tester) async {
      await celular(tester);
      await tester.pumpWidget(app(tabela(mobile: SsDataTableMobile.cards)));
      await tester.pumpAndSettle();
      expect(find.text('TOTAL'), findsWidgets);
    });

    testWidgets('sem papel: 1ª coluna é o título e a 1ª numérica o valor', (tester) async {
      await celular(tester);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SsDataTable(
              mobile: SsDataTableMobile.compact,
              columns: const [SsDataColumn('Cliente'), SsDataColumn('Cidade'), SsDataColumn('Total', numeric: true)],
              rows: [
                SsDataRow.text(const ['Ana', 'Recife', r'R$ 10,00']),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final titulo = tester.getRect(find.text('Ana'));
      expect((tester.getRect(find.text(r'R$ 10,00')).center.dy - titulo.center.dy).abs(), lessThan(4));
      expect(tester.getRect(find.text('Recife')).top, greaterThan(titulo.bottom - 1));
    });
  });

  testWidgets('B18 SsMenuView: voltar de um item não devolve o foco (e o teclado) à busca do menu', (tester) async {
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) => Scaffold(
            body: SsMenuView(
              name: 'Ana',
              email: 'ana@x.com',
              themeMode: ThemeMode.light,
              onThemeMode: (_) {},
              onLogout: () {},
              sections: [
                SsMenuSection('Equipe', [
                  SsMenuItem(
                    Icons.people_outline,
                    'Pessoas',
                    onTap: () => Navigator.of(context)
                        .push(MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('tela de pessoas')))),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
    final busca = find.byType(TextField).first;
    await tester.tap(busca);
    await tester.pump();
    expect(focado(tester, busca), isTrue);
    await tester.tap(find.text('Pessoas'));
    await tester.pumpAndSettle();
    expect(find.text('tela de pessoas'), findsOneWidget);
    Navigator.of(tester.element(find.text('tela de pessoas'))).pop();
    await tester.pumpAndSettle();
    expect(focado(tester, busca), isFalse);
  });

  testWidgets('B18 SsChoiceField: fechar a folha não devolve o foco ao campo de texto anterior', (tester) async {
    String? escolha;
    await tester.pumpWidget(
      app(
        Scaffold(
          body: StatefulBuilder(
            builder: (context, set) => Column(
              children: [
                const SsTextField(label: 'Título'),
                SsChoiceField<String>(
                  label: 'Responsável',
                  value: escolha,
                  options: const {'a': 'Ana', 'b': 'Bia'},
                  onChanged: (v) => set(() => escolha = v),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final titulo = find.byType(SsTextField);
    await tester.tap(titulo);
    await tester.pump();
    expect(focado(tester, titulo), isTrue);
    await tester.tap(find.text(SsStrings.pt.choose));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bia').last);
    await tester.pumpAndSettle();
    expect(escolha, 'b');
    expect(focado(tester, titulo), isFalse);
  });

  testWidgets('B16 SsButton é um nó próprio de botão no leitor de tela, mesmo dentro de um cartão', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      app(
        Scaffold(
          body: Semantics(
            container: true,
            child: SsCard(
              child: Column(
                children: [
                  const Text('Quer uma segunda opinião?'),
                  SsButton(label: 'Explicar com IA', expand: false, onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.bySemanticsLabel('Explicar com IA')),
      matchesSemantics(
        label: 'Explicar com IA',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });

  group('B16 SsAiInsightCard', () {
    testWidgets('pensando: espera dentro do cartão, segundos depois de 5 s, Cancelar, nada cobre a tela', (
      tester,
    ) async {
      var cancelou = false;
      var tocouFora = false;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: Column(
              children: [
                SsAiInsightCard(
                  thinking: true,
                  thinkingText: 'A IA está lendo a sugestão.',
                  onCancel: () => cancelou = true,
                ),
                SsButton(label: 'Outra coisa', onPressed: () => tocouFora = true),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('A IA está lendo a sugestão.'), findsOneWidget);
      expect(find.text(SsStrings.pt.aiThinkingHint), findsOneWidget);
      expect(find.byType(ModalBarrier), findsOneWidget, reason: 'só a do Scaffold/rota, nenhuma a mais');
      await tester.pump(const Duration(seconds: 6));
      expect(find.text('A IA está lendo a sugestão. (6 s)'), findsOneWidget);
      await tester.tap(find.text('Outra coisa'));
      expect(tocouFora, isTrue);
      await tester.tap(find.text('Cancelar'));
      expect(cancelou, isTrue);
    });

    testWidgets('pronto: selo, confiança, título, texto, fontes e ações; textos em inglês', (tester) async {
      var aplicou = false;
      await tester.pumpWidget(
        app(
          Scaffold(
            body: SsAiInsightCard(
              title: 'Spending up 18%',
              text: 'Groceries drove it.',
              confidence: 'high',
              sources: const ['42 entries'],
              onApply: () => aplicou = true,
              onDismiss: () {},
            ),
          ),
          locale: const Locale('en'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('AI'), findsOneWidget);
      expect(find.text('Spending up 18%'), findsOneWidget);
      expect(find.text('Where this comes from'), findsOneWidget);
      expect(find.text('Ignore'), findsOneWidget);
      await tester.tap(find.text('Apply'));
      expect(aplicou, isTrue);
    });
  });

  testWidgets('U08 safeListPadding(fab: true) reserva a folga do botão flutuante', (tester) async {
    late EdgeInsets sem;
    late EdgeInsets com;
    late double folga;
    await tester.pumpWidget(
      app(
        Builder(
          builder: (context) {
            sem = safeListPadding(context);
            com = safeListPadding(context, fab: true);
            folga = SsFab.clearance(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(folga, greaterThanOrEqualTo(80));
    expect(com.bottom - sem.bottom, folga);
  });
}
