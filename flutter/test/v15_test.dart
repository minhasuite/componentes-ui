// v0.15: fase 0 do meu-financeiro (ícones por nome, barras, dinheiro com conta,
// privacidade, linha de progresso e cartão de ação do chat).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/src/v15/bar_chart.dart' show ssBarRange;

// Sem locale: o SsStrings cai no pt (sem delegate). Com locale (en/es), o delegate da suíte.
Widget _app(Widget child, {Locale? locale}) => MaterialApp(
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: locale == null ? const [Locale('en', 'US')] : [locale],
  localizationsDelegates: locale == null ? null : const [SsStrings.delegate],
  home: Scaffold(body: SizedBox(width: 390, child: child)),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('ssEvalAmount (a mesma conta do AmountExpression)', () {
    test('contas e números', () {
      expect(ssEvalAmount('45+12'), 5700);
      expect(ssEvalAmount('45+12,50-3'), 5450);
      expect(ssEvalAmount('3*19,90'), 5970);
      expect(ssEvalAmount('3×19,90'), 5970);
      expect(ssEvalAmount('1.500'), 150000);
      expect(ssEvalAmount(r'R$ 1.234,56'), 123456);
      expect(ssEvalAmount('12.5'), 1250);
      expect(ssEvalAmount('(10+5)/3'), 500);
      expect(ssEvalAmount('-3'), -300);
      expect(ssEvalAmount('10−2'), 800);
      expect(ssEvalAmount('0,1+0,2'), 30);
      expect(ssEvalAmount('1,234.50', SsFormats.usd), 123450);
    });

    test('o que não fecha é nulo', () {
      for (final t in ['', '45+', '1/0', '1,500', 'abc', '(1+2', '2**3']) {
        expect(ssEvalAmount(t), isNull, reason: t);
      }
      expect(ssIsAmountExpression('45+12'), isTrue);
      expect(ssIsAmountExpression('-45'), isFalse);
    });
  });

  group('SsIcons (mesmos nomes da gem)', () {
    test('v1, apelido da v2, cheio e reserva', () {
      expect(SsIcons.named('credit-card'), Icons.credit_card_rounded);
      expect(SsIcons.resolve('magnifying-glass'), 'search');
      expect(SsIcons.named('magnifying-glass'), SsIcons.named('search'));
      expect(SsIcons.named('star', solid: true), Icons.star_rounded);
      expect(SsIcons.named('nao-existe'), SsIcons.fallback);
      expect(SsIcons.named(null), SsIcons.fallback);
      expect(SsIcons.has('arrow-trending-up'), isTrue);
    });

    test('todo ícone da gem tem par no app', () {
      final dir = Directory('../rails/icones/outline');
      if (!dir.existsSync()) return; // fora do repo inteiro
      final gem = dir.listSync().map((f) => f.uri.pathSegments.last.replaceAll('.svg', '')).toSet();
      expect(SsIcons.names.toSet(), gem);
      for (final n in gem) {
        expect(SsIcons.has(n), isTrue, reason: n);
      }
    });
  });

  testWidgets('SsBarChart: faixa com o zero, legenda e balão ao tocar', (t) async {
    expect(
      ssBarRange(
        [
          const SsSeries([2]),
          const SsSeries([3]),
        ],
        1,
        stacked: true,
      ).$1,
      0,
    );
    final (lo, hi) = ssBarRange(
      [
        const SsSeries([100, -250]),
      ],
      2,
      line: const SsSeries([20, -300]),
    );
    expect(lo, lessThan(-300));
    expect(hi, greaterThan(100));
    await t.pumpWidget(
      _app(
        const SsBarChart(
          labels: ['jan', 'fev'],
          stacked: true,
          series: [
            SsSeries([100, 200], name: 'Receitas'),
            SsSeries([-80, -250], name: 'Despesas'),
          ],
          line: SsSeries([20, -50], name: 'Saldo'),
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Receitas'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget);
    final box = t.getRect(find.byType(CustomPaint).last);
    await t.tapAt(Offset(box.left + box.width * .75, box.center.dy));
    await t.pump();
    expect(find.text('fev'), findsOneWidget);
    expect(find.text('-250'), findsOneWidget);
  });

  testWidgets('SsBarChart(projection:): faixa, legenda tracejada, balão e leitor de tela', (t) async {
    // A projeção entra na faixa só a partir de projectionFrom.
    final (lo, hi) = ssBarRange(
      [
        const SsSeries([10, 10, 10]),
      ],
      3,
      projection: const SsSeries([-999, 50, 80]),
      projectionFrom: 1,
    );
    expect(lo, 0);
    expect(hi, greaterThan(80));
    final sem = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        const SsBarChart(
          labels: ['1', '2', '3'],
          series: [
            SsSeries([100, 0, 0], name: 'Receitas'),
          ],
          line: SsSeries([100, 90], name: 'Saldo'),
          projection: SsSeries([0, 90, 40], name: 'Projeção'),
          projectionFrom: 1,
        ),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Projeção'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp(r'3: 0 / Projeção 40')), findsOneWidget);
    final box = t.getRect(find.byType(CustomPaint).last);
    await t.tapAt(Offset(box.left + box.width * .9, box.center.dy));
    await t.pump();
    // Balão do 3º dia: receitas e a projeção (a linha real parou no 2º).
    expect(find.text('40'), findsOneWidget);
    expect(find.text('Saldo'), findsOneWidget); // só a legenda
    sem.dispose();
  });

  testWidgets('SsMoneyField(expression:) mostra o resultado e valida', (t) async {
    int? valor = -1;
    final form = GlobalKey<FormState>();
    await t.pumpWidget(
      _app(
        Form(
          key: form,
          child: SsMoneyField(label: 'Valor', cents: null, expression: true, onChanged: (v) => valor = v),
        ),
      ),
    );
    await t.enterText(find.byType(TextField), '45+12,50');
    await t.pump();
    expect(valor, 5750);
    expect(find.text('= R\$\u00A057,50'), findsOneWidget);
    await t.enterText(find.byType(TextField), '45+');
    await t.pump();
    expect(valor, isNull);
    expect(form.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Conta ou valor inválido'), findsOneWidget);
  });

  testWidgets('SsMoneyField(signed:) aceita o menos; sem ele, não', (t) async {
    int? a, b;
    await t.pumpWidget(
      _app(
        Column(
          children: [
            SsMoneyField(key: const Key('a'), cents: null, signed: true, onChanged: (v) => a = v),
            SsMoneyField(key: const Key('b'), cents: null, onChanged: (v) => b = v),
          ],
        ),
      ),
    );
    await t.enterText(find.descendant(of: find.byKey(const Key('a')), matching: find.byType(TextField)), '-1250');
    await t.enterText(find.descendant(of: find.byKey(const Key('b')), matching: find.byType(TextField)), '-1250');
    expect(a, -1250);
    expect(b, 1250);
  });

  testWidgets('SsMoneyField(formats:) usa a moeda da conta', (t) async {
    await t.pumpWidget(_app(SsMoneyField(cents: 9990, formats: SsFormats.usd, onChanged: (_) {})));
    expect(find.text('99.90'), findsOneWidget);
  });

  testWidgets('SsAmountKeypad(expression:) faz a conta e devolve os centavos', (t) async {
    int? ok;
    await t.pumpWidget(_app(SsAmountKeypad(expression: true, onConfirm: (v) => ok = v)));
    for (final k in ['4', '5', '+', '1', '2']) {
      await t.tap(find.text(k).last);
      await t.pump();
    }
    expect(find.text('= R\$\u00A057,00'), findsOneWidget);
    await t.tap(find.text('Confirmar'));
    expect(ok, 5700);
  });

  testWidgets('SsAmountKeypad(signed:) troca o sinal', (t) async {
    int? ok;
    await t.pumpWidget(_app(SsAmountKeypad(initial: 1000, signed: true, onConfirm: (v) => ok = v)));
    await t.tap(find.text('±'));
    await t.pump();
    await t.tap(find.text('Confirmar'));
    expect(ok, -1000);
  });

  testWidgets('SsPrivacyScope esconde o SsAmount e borra o SsPrivate', (t) async {
    expect(ssPrivacyMask(r'R$ 1.234,56'), r'R$ •••');
    expect(ssPrivacyMask(r'-R$ 12,00'), r'R$ •••');
    expect(ssPrivacyMask('1.234,56 €'), '••• €');
    expect(ssPrivacyMask('72%'), '•••%');
    await t.pumpWidget(
      _app(
        SsPrivacyScope(
          hidden: true,
          child: Column(
            children: [
              SsAmount(money(123456)),
              const SsPrivate(child: Text('gráfico')),
              SsPrivacyToggle(hidden: true, onChanged: (_) {}),
            ],
          ),
        ),
      ),
    );
    expect(find.textContaining('1.234'), findsNothing);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.bySemanticsLabel('Valor oculto'), findsWidgets);
    expect(find.byTooltip('Mostrar valores'), findsOneWidget);
    await t.pumpWidget(_app(SsAmount(money(123456))));
    expect(find.textContaining('1.234'), findsOneWidget);
  });

  testWidgets('SsProgressRow: tons e textos de limite e meta', (t) async {
    const rows = [
      SsProgressRow(label: 'Mercado', value: 500, limit: 1000),
      SsProgressRow(label: 'Lazer', value: 850, limit: 1000),
      SsProgressRow(label: 'Bar', value: 1200, limit: 1000),
      SsProgressRow(label: 'Viagem', value: 3000, limit: 3000, kind: SsProgressKind.goal),
      SsProgressRow(label: 'Carro', value: 1000, limit: 4000, kind: SsProgressKind.goal),
    ];
    expect(rows.map((r) => r.tone).toList(), [
      SsProgressTone.ok,
      SsProgressTone.warn,
      SsProgressTone.over,
      SsProgressTone.done,
      SsProgressTone.ok,
    ]);
    await t.pumpWidget(_app(const Column(children: rows)));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('Restam 500'), findsOneWidget);
    expect(find.text('200 acima'), findsOneWidget);
    expect(find.text('Meta batida'), findsOneWidget);
    expect(find.text('Faltam 3000'), findsOneWidget);
    expect(find.text('120%'), findsOneWidget);
    await t.pumpWidget(_app(const SsProgressRow(label: 'Bar', value: 1200, limit: 1000), locale: const Locale('en')));
    await t.pump(const Duration(seconds: 1));
    expect(find.text('200 over'), findsOneWidget);
  });

  testWidgets('SsChatActionCard: confirma, trava ocupado e mostra o resultado', (t) async {
    var sim = 0, nao = 0;
    await t.pumpWidget(
      _app(
        SsChatActionCard(
          title: 'Lançar despesa',
          rows: const [('Valor', r'R$ 45,00')],
          onConfirm: () => sim++,
          onCancel: () => nao++,
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('AÇÃO PROPOSTA'), findsOneWidget);
    expect(find.text(r'R$ 45,00'), findsOneWidget);
    await t.tap(find.text('Confirmar'));
    await t.tap(find.text('Cancelar'));
    expect((sim, nao), (1, 1));
    await t.pumpWidget(_app(SsChatActionCard(title: 'x', busy: true, onConfirm: () => sim++, onCancel: () => nao++)));
    await t.pump(const Duration(milliseconds: 400));
    await t.tap(find.text('Cancelar'), warnIfMissed: false);
    expect(nao, 1);
    await t.pumpWidget(_app(const SsChatActionCard(title: 'x', state: SsChatActionState.confirmed)));
    await t.pump(const Duration(milliseconds: 400));
    expect(find.text('Feito'), findsOneWidget);
    expect(find.text('Confirmar'), findsNothing);
  });
}
