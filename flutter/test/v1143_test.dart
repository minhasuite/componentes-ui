// v1.14.3: folhas e balões pelo Navigator raiz (por cima da barra de abas do SsNavScaffold, quando a tela de aba
// tem Navigator próprio, como no StatefulShellRoute) e a chave do SsDeviceTile com nó de 48 no leitor de tela.
import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

const _abas = [
  SsNavItem(Icons.home_outlined, 'Início'),
  SsNavItem(Icons.bar_chart_outlined, 'Relatórios'),
  SsNavItem(Icons.person_outline, 'Conta'),
];

final _raiz = GlobalKey<NavigatorState>();
final _aba = GlobalKey<NavigatorState>();
final _ancora = GlobalKey();

/// App com a casca das abas e um Navigator dentro do corpo (o do `StatefulShellRoute` do go_router).
Widget _app(Widget tela) => MaterialApp(
  debugShowCheckedModeBanner: false,
  navigatorKey: _raiz,
  theme: AppTheme.light,
  locale: const Locale('pt'),
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: SsNavScaffold(
    peek: false,
    tabTransition: null,
    navBar: SsNavBar(items: _abas, currentIndex: 1, onTap: (_) {}),
    body: Navigator(
      key: _aba,
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => tela),
    ),
  ),
);

/// A tela de aba: um botão (âncora do balão) e o número que se explica no toque longo.
Widget _tela() => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      SizedBox(key: _ancora, width: 80, height: 40),
      const SsExplain(
        value: 'R\$ 1.240,00',
        items: [SsExplainItem('Pedido 120', 'R\$ 1.240,00')],
        child: Text('R\$ 1.240,00'),
      ),
    ],
  ),
);

BuildContext _ctxAba(WidgetTester t) => t.element(find.byKey(_ancora));

/// A folha (ou o balão) que achou [alvo] está no Navigator raiz e passa por cima da barra de abas.
Future<void> _porCimaDaBarra(WidgetTester t, Finder alvo, {bool cobreBarra = true}) async {
  await t.pumpAndSettle();
  expect(alvo, findsWidgets);
  final el = t.element(alvo.first);
  expect(Navigator.of(el), same(_raiz.currentState), reason: 'abriu no Navigator da aba, atrás da barra');
  final rota = ModalRoute.of(el)!;
  expect(rota.isCurrent, isTrue);
  if (cobreBarra) {
    // O toque no meio da barra cai na folha, não na SsNavBar.
    final barra = t.getRect(find.byType(SsNavBar));
    final caiu = t.hitTestOnBinding(barra.center);
    final naBarra = caiu.path.any((e) => e.target == t.renderObject(find.byType(SsNavBar)));
    expect(naBarra, isFalse, reason: 'a barra de abas ficou na frente da folha');
  }
  _raiz.currentState!.pop();
  await t.pumpAndSettle();
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('versão 1.14.3', () {
    expect(ssComponentesUiVersion, '1.14.3');
    final pub = File('pubspec.yaml').readAsStringSync();
    expect(pub, contains('version: 1.14.3'));
  });

  group('por cima da barra de abas (useRootNavigator)', () {
    testWidgets('SsExplain no toque longo, numa tela de aba', (t) async {
      await t.pumpWidget(_app(_tela()));
      await t.longPress(find.text('R\$ 1.240,00'));
      await _porCimaDaBarra(t, find.byType(SsExplainPanel));
    });

    testWidgets('showSsSheet e showSsSheet(detents:)', (t) async {
      await t.pumpWidget(_app(_tela()));
      showSsSheet<void>(
        _ctxAba(t),
        title: 'Folha',
        child: const SizedBox(height: 600, child: Text('corpo')),
      );
      await _porCimaDaBarra(t, find.text('corpo'));
      showSsSheet<void>(_ctxAba(t), title: 'Alturas', detents: const [.5, 1], child: const Text('alturas'));
      await _porCimaDaBarra(t, find.text('alturas'));
    });

    testWidgets('showSsSheet(useRootNavigator: false) volta ao Navigator da aba', (t) async {
      await t.pumpWidget(_app(_tela()));
      showSsSheet<void>(_ctxAba(t), useRootNavigator: false, child: const Text('na aba'));
      await t.pumpAndSettle();
      expect(Navigator.of(t.element(find.text('na aba'))), same(_aba.currentState));
    });

    testWidgets('showSsFilterSheet', (t) async {
      await t.pumpWidget(_app(_tela()));
      showSsFilterSheet(
        _ctxAba(t),
        filters: const [
          SsFilterGroup(
            param: 'status',
            label: 'Situação',
            options: [SsFilterOption('Aberto', 'aberto'), SsFilterOption('Pago', 'pago')],
          ),
        ],
      );
      await _porCimaDaBarra(t, find.byType(SsFilterSheet));
    });

    testWidgets('showSsCaptureHub', (t) async {
      await t.pumpWidget(_app(_tela()));
      showSsCaptureHub(
        _ctxAba(t),
        title: 'Adicionar',
        options: [SsCaptureOption(title: 'Digitar', onTap: () {})],
      );
      await _porCimaDaBarra(t, find.byType(SsCaptureHub));
    });

    testWidgets('showSsAiActionPreview e showSsSinceLastVisit', (t) async {
      await t.pumpWidget(_app(_tela()));
      showSsAiActionPreview(
        _ctxAba(t),
        changes: const [SsAiChange(id: '1', title: 'Baixar o preço')],
      );
      await _porCimaDaBarra(t, find.text('Baixar o preço'));
      showSsSinceLastVisit(
        _ctxAba(t),
        since: DateTime(2026, 11, 20),
        now: DateTime(2026, 11, 28),
        items: const [SsSinceItem(value: '3', label: 'pedidos novos')],
      );
      await _porCimaDaBarra(t, find.text('pedidos novos'));
    });

    testWidgets('showSsPopover (o balão fica no Navigator raiz, ancorado no botão)', (t) async {
      await t.pumpWidget(_app(_tela()));
      showSsPopover<void>(_ctxAba(t), title: 'Como calculamos', child: const Text('balão'));
      await t.pumpAndSettle();
      final el = t.element(find.text('balão'));
      expect(Navigator.of(el), same(_raiz.currentState));
      // Continua ancorado: abre logo abaixo do botão.
      expect(t.getRect(find.text('balão')).top, greaterThan(t.getRect(find.byKey(_ancora)).bottom));
      _raiz.currentState!.pop();
      await t.pumpAndSettle();
    });
  });

  group('SsDeviceTile: a chave com alvo de 48', () {
    Widget tile({SsDensity density = SsDensity.standard}) => MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, density: density),
      localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 200,
            child: SsDeviceTile(icon: Icons.lightbulb_outline, name: 'Luz da sala', on: true, onToggle: (_) {}),
          ),
        ),
      ),
    );

    for (final d in [SsDensity.standard, SsDensity.compact]) {
      testWidgets('passa no ssA11yAudit (${d.name}) sem mudar o desenho', (t) async {
        await t.pumpWidget(tile(density: d));
        await t.pumpAndSettle();
        // O desenho continua o quadrado de antes (iconTile + 2).
        final quadrado = t.getSize(
          find.descendant(of: find.byType(InkWell), matching: find.byType(AnimatedContainer)).first,
        );
        expect(quadrado.width, d.iconTile + 2);
        final no = t.getSemantics(find.bySemanticsLabel('Luz da sala'));
        expect(no.rect.width, greaterThanOrEqualTo(48));
        expect(no.rect.height, greaterThanOrEqualTo(48));
        await ssA11yAudit(t);
      });
    }
  });
}
