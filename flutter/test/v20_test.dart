// v0.20: o que o minhas-vendas e o meu-gestor acharam ao migrar para 100% de
// componentização (pares do web): rótulo escondido, máscara, rádio, botão
// discreto de perigo, tons no item/KPI/cabeçalho, tabela (coluna parada,
// cabeçalho montado, total, sem card, linha apagada), ação ao lado da busca do
// seletor, barra fixa com resumo, linhas repetíveis, contagem na aba, link no
// texto, termos e valor editável.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {ThemeData? theme, SsStrings? strings}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  localizationsDelegates: const [SsStrings.delegate],
  home: SsStringsScope(
    strings: strings ?? SsStrings.pt,
    child: Scaffold(
      body: Center(
        child: Padding(padding: const EdgeInsets.all(16), child: child),
      ),
    ),
  ),
);

TextEditingValue _digita(TextInputFormatter f, String texto) => f.formatEditUpdate(
  TextEditingValue.empty,
  TextEditingValue(
    text: texto,
    selection: TextSelection.collapsed(offset: texto.length),
  ),
);

void main() {
  group('SsMask', () {
    test('CPF parcial e completo, CNPJ numérico e alfanumérico', () {
      expect(SsMask.document.format('1234'), '123.4');
      expect(SsMask.document.format('12345678901'), '123.456.789-01');
      expect(SsMask.document.format('11222333000181'), '11.222.333/0001-81');
      expect(SsMask.document.format('12abc34501de35'), '12.ABC.345/01DE-35');
      expect(SsMask.document.format('123.456.789-0123'), '12.345.678/9012-3');
      expect(SsMask.document.unmask('11.222.333/0001-81'), '11222333000181');
    });

    test('telefone fixo e celular, CEP', () {
      expect(SsMask.phone.format('8'), '(8');
      expect(SsMask.phone.format('8532'), '(85) 32');
      expect(SsMask.phone.format('8532345678'), '(85) 3234-5678');
      expect(SsMask.phone.format('85987654321'), '(85) 98765-4321');
      expect(SsMask.phone.format('859876543219'), '(85) 98765-4321');
      expect(SsMask.cep.format('60125'), '60125');
      expect(SsMask.cep.format('60125100'), '60125-100');
      expect(SsMask.cep.format('60a1251009'), '60125-100');
      expect(SsMask.cep.maxLength, 9);
    });

    test('como formatador: texto e cursor no fim', () {
      final v = _digita(SsMask.document, '12345678901');
      expect(v.text, '123.456.789-01');
      expect(v.selection.baseOffset, v.text.length);
    });

    testWidgets('SsTextField(mask:) formata enquanto digita e põe o teclado numérico', (t) async {
      await t.pumpWidget(_app(const SsTextField(label: 'CEP', mask: SsMask.cep)));
      await t.enterText(find.byType(TextField), '60125100');
      await t.pump();
      expect(find.text('60125-100'), findsOneWidget);
      expect(t.widget<TextField>(find.byType(TextField)).keyboardType, TextInputType.number);
    });
  });

  group('SsTextField(hideLabel:)', () {
    testWidgets('o rótulo some da vista e fica para o leitor de tela', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(const SsTextField(label: 'Buscar produto', hideLabel: true)));
      expect(find.byType(SsFieldLabel), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Buscar produto')), findsWidgets);
      await t.pumpWidget(_app(const SsTextField(label: 'Nome')));
      expect(find.byType(SsFieldLabel), findsOneWidget);
      h.dispose();
    });
  });

  group('SsRadioGroup', () {
    testWidgets('marca o value, troca no toque e é lido como rádio', (t) async {
      final h = t.ensureSemantics();
      String? tipo = 'pj';
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsRadioGroup<String>(
              label: 'Tipo',
              value: tipo,
              options: const {'pf': 'Pessoa física', 'pj': 'Empresa'},
              onChanged: (v) => set(() => tipo = v),
            ),
          ),
        ),
      );
      expect(find.text('Tipo'), findsOneWidget);
      final pj = t.getSemantics(find.bySemanticsLabel('Empresa'));
      expect(pj, isSemantics(isChecked: true, isInMutuallyExclusiveGroup: true, hasCheckedState: true));
      await t.tap(find.text('Pessoa física'));
      await t.pumpAndSettle();
      expect(tipo, 'pf');
      expect(t.getSemantics(find.bySemanticsLabel('Pessoa física')), isSemantics(isChecked: true));
      h.dispose();
    });

    testWidgets('validator dentro de Form e onChanged nulo desabilita', (t) async {
      final form = GlobalKey<FormState>();
      await t.pumpWidget(
        _app(
          Form(
            key: form,
            child: SsRadioGroup<int>(
              label: 'Plano',
              value: null,
              options: const {1: 'Mensal', 2: 'Anual'},
              onChanged: null,
              validator: (v) => v == null ? 'Escolha um plano' : null,
              inline: false,
            ),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Escolha um plano'), findsOneWidget);
    });
  });

  group('SsButton.ghost(tone:)', () {
    testWidgets('texto no tom do perigo, fundo de campo; sem tom igual ao ghost', (t) async {
      await t.pumpWidget(
        _app(
          Column(
            children: [
              SsButton.ghost(label: 'Excluir', tone: SsTone.danger, onPressed: () {}),
              SsButton(label: 'Cancelar', variant: SsButtonVariant.ghost, onPressed: () {}),
            ],
          ),
        ),
      );
      final ctx = t.element(find.text('Excluir'));
      expect(t.widget<Text>(find.text('Excluir')).style?.color, SsTone.danger.colors(ctx).text);
      expect(t.widget<Text>(find.text('Cancelar')).style?.color, SsColors.of(ctx).ink2);
    });
  });

  group('tons no texto', () {
    testWidgets('SsListItem(subtitleTone:, valueTone:), SsKpiCard(valueTone:), SsCardHeader(eyebrow:)', (t) async {
      await t.pumpWidget(
        _app(
          const Column(
            children: [
              SsListItem(
                title: 'Boleto',
                subtitle: 'Vence hoje',
                subtitleTone: SsTone.danger,
                value: '10',
                valueTone: SsTone.success,
              ),
              SsCardHeader(title: 'Ruptura', eyebrow: 'Estoque', eyebrowTone: SsTone.warning),
            ],
          ),
        ),
      );
      final ctx = t.element(find.text('Boleto'));
      expect(t.widget<Text>(find.text('Vence hoje')).style?.color, SsTone.danger.colors(ctx).text);
      expect(t.widget<Text>(find.text('10')).style?.color, SsTone.success.colors(ctx).text);
      expect(t.widget<Text>(find.text('ESTOQUE')).style?.color, SsTone.warning.colors(ctx).text);
      await t.pumpWidget(_app(const SsKpiCard(label: 'Saldo', value: 'R\$ 10', valueTone: SsTone.danger)));
      await t.pump(const Duration(seconds: 2));
      expect(
        t.widget<SsAmount>(find.byType(SsAmount)).color,
        SsTone.danger.colors(t.element(find.byType(SsAmount))).text,
      );
    });
  });

  group('SsDataTable v0.20', () {
    final cols = [
      const SsDataColumn('Cliente', header: Icon(Icons.person, key: Key('cab'))),
      const SsDataColumn('Total', numeric: true),
      const SsDataColumn('Cidade'),
      const SsDataColumn('Vendedor'),
    ];
    List<SsDataRow> linhas() => [
      SsDataRow.text(['Ana', '10', 'Fortaleza', 'João']),
      SsDataRow.text(['Bia', '5', 'Sobral', 'Maria'], dimmed: true),
    ];

    testWidgets('cabeçalho montado, total, linha apagada e sem card', (t) async {
      t.view.physicalSize = const Size(900, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _app(SsDataTable(columns: cols, rows: linhas(), flat: true, footer: const [Text('Total'), Text('15')])),
      );
      await t.pumpAndSettle();
      expect(find.byKey(const Key('cab')), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
      final o = t.widget<Opacity>(find.ancestor(of: find.text('Bia'), matching: find.byType(Opacity)).first);
      expect(o.opacity, .5);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('1ª coluna parada ao rolar de lado quando não cabe', (t) async {
      t.view.physicalSize = const Size(700, 600);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(
        _app(SsDataTable(columns: cols, rows: linhas(), stickyFirstColumn: true, minColumnWidth: 220, stackBelow: 300)),
      );
      await t.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final antes = t.getTopLeft(find.text('Ana').last);
      final cidade = t.getTopLeft(find.text('Fortaleza'));
      await t.drag(find.byType(SingleChildScrollView), const Offset(-200, 0));
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.text('Ana').last).dx, closeTo(antes.dx, 1));
      expect(t.getTopLeft(find.text('Fortaleza')).dx, lessThan(cidade.dx - 100));
    });

    testWidgets('no celular o total vira bloco no fim', (t) async {
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 320,
            child: SingleChildScrollView(
              child: SsDataTable(columns: cols, rows: linhas(), footer: const [Text('Total'), Text('15')]),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('15'), findsOneWidget);
    });
  });

  group('showSsPicker(actions:)', () {
    testWidgets('a ação ao lado da busca fecha devolvendo o item', (t) async {
      String? r;
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => SsButton(
              label: 'Abrir',
              onPressed: () async => r = await showSsPicker<String>(
                context,
                title: 'Produto',
                items: const ['Arroz', 'Feijão'],
                actions: [SsPickerAction(icon: Icons.qr_code_scanner, tooltip: 'Ler código', onPressed: (_) => 'Café')],
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      expect(find.byTooltip('Ler código'), findsOneWidget);
      await t.tap(find.byIcon(Icons.qr_code_scanner));
      await t.pumpAndSettle();
      expect(r, 'Café');
      expect(find.text('Arroz'), findsNothing);
    });

    testWidgets('ação que devolve nulo deixa aberto', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => SsButton(
              label: 'Abrir',
              onPressed: () => showSsPicker<String>(
                context,
                title: 'Produto',
                items: const ['Arroz'],
                actions: [
                  SsPickerAction(
                    icon: Icons.add,
                    tooltip: 'Novo',
                    onPressed: (_) {
                      n++;
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      await t.tap(find.byIcon(Icons.add));
      await t.pumpAndSettle();
      expect(n, 1);
      expect(find.text('Arroz'), findsOneWidget);
    });
  });

  group('SsStickyActionBar', () {
    testWidgets('resumo à esquerda, ações à direita; invisível não recebe toque', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          SsStickyActionBar(
            summary: const Text('3 itens'),
            actions: [SsButton(label: 'Fechar', expand: false, onPressed: () => n++)],
          ),
        ),
      );
      expect(find.text('3 itens'), findsOneWidget);
      expect(t.getTopLeft(find.text('3 itens')).dx, lessThan(t.getTopLeft(find.text('Fechar')).dx));
      await t.tap(find.text('Fechar'));
      expect(n, 1);
      await t.pumpWidget(
        _app(
          SsStickyActionBar(
            message: 'Alterações não salvas',
            visible: false,
            actions: [SsButton(label: 'Salvar', expand: false, onPressed: () => n++)],
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Salvar'), warnIfMissed: false);
      expect(n, 1);
    });
  });

  group('SsRepeater', () {
    testWidgets('adiciona, tira e respeita o mínimo', (t) async {
      final itens = <String>['a'];
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsRepeater(
              itemCount: itens.length,
              minItems: 1,
              itemBuilder: (_, i) => Text('linha ${itens[i]}'),
              onAdd: () => set(() => itens.add('b')),
              onRemove: (i) => set(() => itens.removeAt(i)),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Remover linha 1'), findsNothing);
      await t.tap(find.text('Adicionar'));
      await t.pump();
      expect(find.text('linha b'), findsOneWidget);
      await t.tap(find.byTooltip('Remover linha 2'));
      await t.pump();
      expect(find.text('linha b'), findsNothing);
    });
  });

  group('SsNavItem(badge:)', () {
    testWidgets('contagem no ícone e no leitor de tela; 0 some', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: const [SsStrings.delegate],
          home: SsStringsScope(
            strings: SsStrings.pt,
            child: Scaffold(
              bottomNavigationBar: SsNavBar(
                currentIndex: 0,
                onTap: (_) {},
                items: const [
                  SsNavItem(Icons.home_outlined, 'Início'),
                  SsNavItem(Icons.inbox_outlined, 'Cards', badge: 3),
                  SsNavItem(Icons.person_outline, 'Conta', badge: 0),
                  SsNavItem(Icons.list, 'Pedidos', badge: 120),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('0'), findsNothing);
      expect(find.bySemanticsLabel(RegExp(r'Cards: 3 novas')), findsOneWidget);
      h.dispose();
    });
  });

  group('link no texto, termos e valor editável', () {
    testWidgets('SsLinkText: toque no link chama onTap', (t) async {
      var n = 0;
      await t.pumpWidget(_app(SsLinkText(['Li os ', SsTextLink('termos', onTap: () => n++), '.'])));
      await t.tapOnText(find.textRange.ofSubstring('termos'));
      expect(n, 1);
    });

    testWidgets('SsTermsNotice em pt/en/es abre as URLs', (t) async {
      final abertas = <String>[];
      await t.pumpWidget(_app(SsTermsNotice(termsUrl: '/t', privacyUrl: '/p', onOpen: abertas.add)));
      expect(
        find.textContaining('Ao continuar, você concorda com os Termos de uso (abre fora do app) e a Política'),
        findsOneWidget,
      );
      await t.tapOnText(find.textRange.ofSubstring('Política de privacidade'));
      await t.tapOnText(find.textRange.ofSubstring('Termos de uso'));
      expect(abertas, ['/p', '/t']);
      await t.pumpWidget(
        _app(
          SsTermsNotice(termsUrl: '/t', privacyUrl: '/p', onOpen: abertas.add),
          strings: SsStrings.en,
        ),
      );
      expect(find.textContaining('By continuing, you agree to the Terms of Use'), findsOneWidget);
      expect(SsStrings.es.termsNotice, contains('{privacy}'));
      expect(SsStrings.es.addRow, 'Agregar');
      expect(SsStrings.en.removeRow, 'Remove row');
      expect(SsStrings.pt.editValue, 'Editar');
    });

    testWidgets('SsEditableValue: rótulo, valor em mono, editar e leitura única', (t) async {
      final h = t.ensureSemantics();
      var n = 0;
      await t.pumpWidget(_app(SsEditableValue(label: 'novo', value: r'R$ 12,90', onEdit: () => n++)));
      expect(find.text('editar'), findsOneWidget);
      expect(find.bySemanticsLabel(r'novo: R$ 12,90, Editar'), findsOneWidget);
      await t.tap(find.byType(SsEditableValue));
      expect(n, 1);
      h.dispose();
    });
  });

  // v0.20.1: sem expand, o botão não estica dentro de Wrap/Align.
  testWidgets('SsButton(expand: false) no Wrap fica do tamanho do texto', (t) async {
    await t.pumpWidget(
      _app(
        SizedBox(
          width: 360,
          child: Wrap(
            spacing: 8,
            children: [
              SsButton(label: 'Ver card', expand: false, onPressed: () {}),
              SsButton(label: 'Dispensar', expand: false, onPressed: () {}),
            ],
          ),
        ),
      ),
    );
    final a = t.getRect(find.widgetWithText(SsButton, 'Ver card'));
    final b = t.getRect(find.widgetWithText(SsButton, 'Dispensar'));
    expect(a.width, lessThan(200));
    expect(b.top, a.top); // lado a lado, não um por linha
  });

  group('SsRepeater(header:, flex:) v0.20.3', () {
    testWidgets('cabeçalho uma vez, colunas alinhadas às da linha, × no meio', (t) async {
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 360,
            child: SsRepeater(
              itemCount: 2,
              header: const ['Produto', 'Qtd'],
              flex: const [3, 1],
              itemBuilder: (_, i) => SsRepeater.cells(
                [
                  SsTextField(label: 'Produto', hideLabel: true, initialValue: 'Arroz $i'),
                  const SsTextField(label: 'Qtd', hideLabel: true, initialValue: '1'),
                ],
                flex: const [3, 1],
              ),
              onRemove: (_) {},
            ),
          ),
        ),
      );
      expect(find.text('PRODUTO'), findsOneWidget);
      expect(find.text('QTD'), findsOneWidget);
      expect(find.byType(SsFieldLabel), findsNothing);
      final cab = t.getTopLeft(find.text('QTD')).dx;
      final campo = t.getTopLeft(find.byType(SsTextField).at(1)).dx;
      expect(cab, closeTo(campo, 1));
      final x = t.getCenter(find.byTooltip('Remover linha 1')).dy;
      final linha = t.getCenter(find.byType(SsTextField).first).dy;
      expect(x, closeTo(linha, 1));
    });
  });

  group('SsDataTable(stack: false) v0.20.4', () {
    testWidgets('no celular continua tabela e rola de lado com a 1ª coluna parada', (t) async {
      final cols = [
        for (final n in ['Pessoa', for (var d = 1; d <= 14; d++) '$d']) SsDataColumn(n),
      ];
      List<SsDataRow> linhas() => [
        SsDataRow.text(['Ana', for (var d = 1; d <= 14; d++) d.isEven ? 'M' : 'T']),
      ];
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 340,
            child: SsDataTable(
              columns: cols,
              rows: linhas(),
              stack: false,
              stickyFirstColumn: true,
              minColumnWidth: 60,
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('PESSOA'), findsWidgets);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final ana = t.getTopLeft(find.text('Ana').last).dx;
      await t.drag(find.byType(SingleChildScrollView), const Offset(-300, 0));
      await t.pumpAndSettle();
      expect(t.getTopLeft(find.text('Ana').last).dx, closeTo(ana, 1));
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 340,
            child: SsDataTable(columns: cols, rows: linhas(), stack: false, minColumnWidth: 60),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      expect(find.text('Ana'), findsOneWidget);
      await t.pumpWidget(
        _app(
          SizedBox(
            width: 340,
            child: SsDataTable(columns: cols, rows: linhas()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('PESSOA'), findsNothing);
    });
  });
}
