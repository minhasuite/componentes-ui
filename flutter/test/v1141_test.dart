// v1.14.1: o subtítulo do SsCommand (paleta e busca do SsSideMenu), o textAlign: do SsTextField e do SsMoneyField
// e a saída dos testes de produto que a v1.14.0 deixou frágeis (find.ssValue no odômetro do KPI e o
// tabTransition: null também no SsAdaptiveScaffold).
import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('pt', 'BR'),
  supportedLocales: SsStrings.supportedLocales,
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Scaffold(
    body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
  ),
);

void _nada() {}

final _aparelhos = [
  SsCommand(Icons.lightbulb_outline_rounded, 'Luz do teto', subtitle: 'Sala', group: 'Aparelhos', onRun: _nada),
  SsCommand(Icons.lightbulb_outline_rounded, 'Luz do teto', subtitle: 'Quarto', group: 'Aparelhos', onRun: _nada),
  SsCommand(Icons.ac_unit_rounded, 'Ar-condicionado', subtitle: 'Quarto', group: 'Aparelhos', onRun: _nada),
  SsCommand(Icons.tune_rounded, 'Configurações', group: 'Telas', onRun: _nada),
];

TextField _campo(WidgetTester t) => t.widget<TextField>(find.byType(TextField));

void main() {
  group('SsCommand(subtitle:)', () {
    testWidgets('a 2ª linha aparece, entra na busca e no leitor de tela', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(SsCommandPalette(commands: _aparelhos, initialQuery: 'quarto', onSelected: (_) {})));
      await t.pump();
      // "quarto" só está no subtítulo: acha os dois do quarto e não o da sala.
      expect(find.text('Quarto', findRichText: true), findsNWidgets(2));
      expect(find.text('Sala', findRichText: true), findsNothing);
      expect(find.text('Configurações', findRichText: true), findsNothing);
      expect(find.bySemanticsLabel('Luz do teto, Quarto'), findsOneWidget);
      expect(find.bySemanticsLabel('Ar-condicionado, Quarto'), findsOneWidget);
      await ssA11yAudit(t);
      h.dispose();
    });

    testWidgets('vários termos: rótulo + subtítulo; o rótulo casado vem antes', (t) async {
      SsCommand? escolhido;
      await t.pumpWidget(
        _app(SsCommandPalette(commands: _aparelhos, initialQuery: 'luz sala', onSelected: (c) => escolhido = c)),
      );
      await t.pump();
      expect(find.text('Sala', findRichText: true), findsOneWidget);
      expect(find.text('Quarto', findRichText: true), findsNothing);
      await t.testTextInput.receiveAction(TextInputAction.go);
      expect(escolhido?.subtitle, 'Sala');
    });

    testWidgets('sem subtítulo, a linha é a de sempre (o rótulo é o nome no leitor)', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(SsCommandPalette(commands: _aparelhos, initialQuery: 'config', onSelected: (_) {})));
      await t.pump();
      expect(find.bySemanticsLabel('Configurações'), findsOneWidget);
      h.dispose();
    });

    testWidgets('a busca do SsSideMenu (search:) mostra o subtítulo', (t) async {
      late BuildContext ctx;
      await t.pumpWidget(
        _app(
          Builder(
            builder: (c) {
              ctx = c;
              return const SizedBox();
            },
          ),
        ),
      );
      final busca = SsSideMenuSearch(commands: _aparelhos);
      busca.open(ctx, initialQuery: 'sala');
      await t.pumpAndSettle();
      expect(find.text('Sala', findRichText: true), findsOneWidget);
      expect(find.text('Luz do teto', findRichText: true), findsOneWidget);
    });
  });

  group('textAlign:', () {
    testWidgets('SsTextField: start por padrão, end para número', (t) async {
      await t.pumpWidget(_app(const SsTextField(label: 'Nome')));
      expect(_campo(t).textAlign, TextAlign.start);
      await t.pumpWidget(_app(const SsTextField(label: 'Quantidade', initialValue: '12', textAlign: TextAlign.end)));
      expect(_campo(t).textAlign, TextAlign.end);
    });

    testWidgets('SsMoneyField: à direita por padrão (como o .ss-money do web), também no modo conta', (t) async {
      await t.pumpWidget(_app(SsMoneyField(label: 'Valor', cents: 1990, onChanged: (_) {})));
      expect(_campo(t).textAlign, TextAlign.end);
      await t.pumpWidget(_app(SsMoneyField(label: 'Valor', expression: true, onChanged: (_) {})));
      expect(_campo(t).textAlign, TextAlign.end);
      await t.pumpWidget(
        _app(SsMoneyField(label: 'Valor', cents: 1990, onChanged: (_) {}, textAlign: TextAlign.start)),
      );
      expect(_campo(t).textAlign, TextAlign.start);
    });

    test('o web tem o par (f.ss_*(align: :end) → .ss-input-end)', () {
      final css = File('../rails/app/assets/tailwind/componentes_ui/v1141_web.css');
      if (!css.existsSync()) return;
      expect(css.readAsStringSync(), contains('.ss-input.ss-input-end { text-align: end; }'));
    });
  });

  group('saída dos testes de produto (v1.14.0)', () {
    testWidgets('KPI com odômetro: find.ssValue e o bySemanticsLabel com RegExp; animate: false volta ao find.text', (
      t,
    ) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(const SsKpiCard(label: 'Receita', value: r'R$ 4.870,00')));
      await t.pumpAndSettle();
      // O odômetro desenha cada dígito numa coluna: o find.text deixa de achar.
      expect(find.text(r'R$ 4.870,00', findRichText: true), findsNothing);
      expect(find.ssValue(r'R$ 4.870,00'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'R\$ 4\.870,00')), findsWidgets);
      // O texto exato não: o nó do card junta rótulo e valor ("Receita, R$ 4.870,00").
      expect(find.bySemanticsLabel(r'R$ 4.870,00'), findsNothing);

      await t.pumpWidget(_app(const SsKpiCard(label: 'Receita', value: r'R$ 4.870,00', animate: false)));
      await t.pumpAndSettle();
      expect(find.text(r'R$ 4.870,00', findRichText: true), findsOneWidget);
      expect(find.ssValue(r'R$ 4.870,00'), findsOneWidget);

      await t.pumpWidget(_app(const SsStatCard(label: 'Saldo', value: r'R$ 1.234,56')));
      await t.pumpAndSettle();
      expect(find.ssValue(r'R$ 1.234,56'), findsOneWidget);
      expect(find.ssValue(RegExp(r'1\.234')), findsOneWidget);
      h.dispose();
    });

    testWidgets('SsAdaptiveScaffold(tabTransition: null) troca de aba seco, como o SsNavScaffold', (t) async {
      Widget app(SsSharedAxis? tr) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
        home: SsAdaptiveScaffold(
          tabTransition: tr,
          currentIndex: 0,
          onTap: (_) {},
          body: const Text('Início'),
          items: const [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.list_alt_outlined, 'Extrato')],
        ),
      );
      await t.binding.setSurfaceSize(const Size(400, 800));
      addTearDown(() => t.binding.setSurfaceSize(null));
      await t.pumpWidget(app(SsSharedAxis.fadeThrough));
      await t.pumpAndSettle();
      expect(find.byType(SsSharedAxisTransition), findsOneWidget);
      await t.pumpWidget(app(null));
      await t.pumpAndSettle();
      expect(find.byType(SsSharedAxisTransition), findsNothing);
    });
  });

  test('versão 1.14.1', () {
    expect(ssComponentesUiVersion, '1.14.1');
  });
}
