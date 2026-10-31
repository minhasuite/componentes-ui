import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: Padding(padding: const EdgeInsets.all(16), child: child),
  ),
);

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;

  test('foldAccents tira acento e caixa', () {
    expect(foldAccents('Ação São JOÃO Ñ'), 'acao sao joao n');
  });

  test('validadores em pt-BR', () {
    expect(SsValidators.required(''), 'Campo obrigatório');
    expect(SsValidators.required(null), 'Campo obrigatório');
    expect(SsValidators.required('x'), isNull);
    expect(SsValidators.money(0), 'Informe um valor');
    expect(SsValidators.money(5), isNull);
    final r = SsValidators.intRange(1, 10);
    expect(r('abc'), 'Informe um número');
    expect(r('11'), 'Use um número de 1 a 10');
    expect(r('10'), isNull);
  });

  test('atalhos de data: Sex na semana, Seg quando amanhã é sexta ou fim de semana', () {
    String nomes(DateTime d) => SsDateField.shortcuts(d).map((a) => '${a.$1}=${date(a.$2)}').join(' ');
    // Quarta 28/10/2026
    expect(nomes(DateTime(2026, 10, 28, 15)), 'Hoje=28/10/2026 Amanhã=29/10/2026 Sex 30/10=30/10/2026');
    // Quinta: amanhã já é sexta
    expect(SsDateField.shortcuts(DateTime(2026, 10, 29))[2].$1, 'Seg 02/11');
    // Sábado 31/10: vira o mês
    expect(nomes(DateTime(2026, 10, 31)), 'Hoje=31/10/2026 Amanhã=01/11/2026 Seg 02/11=02/11/2026');
    // Domingo: amanhã é segunda
    expect(SsDateField.shortcuts(DateTime(2026, 11, 1))[2].$1, 'Sex 06/11');
  });

  test('stepper arredonda e prende no limite', () {
    expect(SsStepper.fit(10.5, max: 10), 10);
    expect(SsStepper.fit(-1), 0);
    expect(SsStepper.fit(1.25, decimals: 1, max: 5), 1.3);
    expect(SsStepper.fit(2, decimals: 0), isA<int>());
    expect(SsStepper.format(2.5, 1), '2,5');
  });

  testWidgets('stepper: + soma, desabilita no máximo e segurar repete', (tester) async {
    num v = 8;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => SsStepper(value: v, max: 10, onChanged: (n) => set(() => v = n)),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(v, 9);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(v, 10);
    await tester.tap(find.byIcon(Icons.add_rounded));
    await tester.pumpAndSettle();
    expect(v, 10);

    // Segurar o − repete até soltar.
    final g = await tester.startGesture(tester.getCenter(find.byIcon(Icons.remove_rounded)));
    await tester.pump(const Duration(milliseconds: 600)); // long press
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await g.up();
    await tester.pumpAndSettle();
    expect(v, lessThan(9));
  });

  testWidgets('stepper: tocar no número permite digitar', (tester) async {
    num v = 2;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => SsStepper(value: v, max: 50, onChanged: (n) => set(() => v = n)),
        ),
      ),
    );
    await tester.tap(find.text('2'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), '77');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(v, 50);
  });

  testWidgets('dinheiro cresce da direita e devolve centavos', (tester) async {
    int? v;
    await tester.pumpWidget(_app(SsMoneyField(label: 'Valor', cents: null, onChanged: (c) => v = c)));
    await tester.enterText(find.byType(TextField), '5');
    expect(v, 5);
    expect(find.text('0,05'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    expect(v, 123456);
    expect(find.text('1.234,56'), findsOneWidget);
  });

  testWidgets('teclado de valor: dígitos, 00, apagar e confirmar', (tester) async {
    int? v;
    await tester.pumpWidget(_app(SsAmountKeypad(onConfirm: (c) => v = c)));
    for (final k in ['1', '2', '00']) {
      await tester.tap(find.text(k));
    }
    await tester.tap(find.byIcon(Icons.backspace_outlined));
    await tester.tap(find.text('Confirmar'));
    expect(v, 120);
  });

  testWidgets('texto: valida no envio e de novo a cada digitação', (tester) async {
    final form = GlobalKey<FormState>();
    await tester.pumpWidget(
      _app(
        Form(
          key: form,
          child: const SsTextField(label: 'Nome', validator: SsValidators.required),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Campo obrigatório'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Ana');
    await tester.pumpAndSettle();
    expect(find.text('Campo obrigatório'), findsNothing);
  });

  testWidgets('escolha: abre a folha, marca e devolve; valida no Form', (tester) async {
    final form = GlobalKey<FormState>();
    String? v;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => Form(
            key: form,
            child: SsChoiceField<String>(
              label: 'Estado',
              value: v,
              options: const {'SP': 'São Paulo', 'PR': 'Paraná'},
              validator: SsValidators.required,
              onChanged: (n) => set(() => v = n),
            ),
          ),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Campo obrigatório'), findsOneWidget);
    await tester.tap(find.text('Escolher'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paraná'));
    await tester.pumpAndSettle();
    expect(v, 'PR');
    expect(form.currentState!.validate(), isTrue);
  });

  testWidgets('escolha: busca aparece com mais de 8 opções e ignora acento', (tester) async {
    final opts = {for (var i = 0; i < 9; i++) i: 'Opção $i'}..[9] = 'Ceará';
    await tester.pumpWidget(_app(SsChoiceList<int>(options: opts, onSelect: (_) {})));
    expect(find.byType(SsSearchField), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'ceara');
    await tester.pump();
    expect(find.text('Ceará'), findsOneWidget);
    expect(find.text('Opção 1'), findsNothing);
  });

  testWidgets('linha de switch: tocar no título alterna', (tester) async {
    var v = false;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, set) => SsSwitchRow(title: 'Lembrar', value: v, onChanged: (n) => set(() => v = n)),
        ),
      ),
    );
    await tester.tap(find.text('Lembrar'));
    await tester.pump();
    expect(v, isTrue);
  });

  testWidgets('picker local filtra sem acento e devolve o item', (tester) async {
    String? r;
    await tester.pumpWidget(
      _app(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                r = await showSsPicker<String>(context, title: 'Cliente', items: const ['Açougue', 'Padaria']),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'acou');
    await tester.pump();
    expect(find.text('Padaria'), findsNothing);
    await tester.tap(find.text('Açougue'));
    await tester.pumpAndSettle();
    expect(r, 'Açougue');
  });

  testWidgets('picker remoto espera 300 ms para buscar', (tester) async {
    final buscas = <String>[];
    await tester.pumpWidget(
      _app(
        SsPickerSheet<String>(
          title: 'Cliente',
          onSelect: (_) {},
          load: (q) async {
            buscas.add(q);
            return ['$q 1'];
          },
        ),
      ),
    );
    await tester.pump();
    expect(buscas, ['']);
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pump(const Duration(milliseconds: 200));
    expect(buscas, ['']);
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump();
    expect(buscas, ['', 'ana']);
    expect(find.text('ana 1'), findsOneWidget);
  });
}
