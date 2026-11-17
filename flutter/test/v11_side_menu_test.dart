import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'dart:io';

// v1.1 · menu lateral: sem o sublinhado amarelo, versões no pé, botão de menu automático no cabeçalho.
const _abas = [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.receipt_long_outlined, 'Pedidos')];

Widget _app({Widget? body}) => MaterialApp(
  theme: AppTheme.light,
  home: SsNavScaffold(
    peek: false,
    navBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
    sideMenu: const SsSideMenu(
      title: 'Meu App',
      subtitle: 'ana@exemplo.com',
      icon: Icons.storefront_rounded,
      version: '1.4.0 (123)',
    ),
    body: body ?? const SizedBox.expand(),
  ),
);

void main() {
  testWidgets('cabeçalho do painel sem o sublinhado amarelo de depuração (há um Material acima)', (t) async {
    await t.pumpWidget(_app());
    t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).open();
    await t.pumpAndSettle();
    for (final texto in ['Meu App', 'ana@exemplo.com']) {
      final estilo = DefaultTextStyle.of(t.element(find.text(texto)));
      // O DefaultTextStyle de fallback (fora de um Material) tem o sublinhado amarelo duplo.
      expect(estilo.style.decoration, isNot(TextDecoration.underline), reason: texto);
      expect(Material.maybeOf(t.element(find.text(texto))), isNotNull, reason: texto);
    }
  });

  testWidgets('pé do painel: versão do app e do componentes_ui', (t) async {
    await t.pumpWidget(_app());
    t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).open();
    await t.pumpAndSettle();
    expect(find.text('Meu App 1.4.0 (123) · componentes_ui $ssComponentesUiVersion'), findsOneWidget);
  });

  testWidgets('tela principal com SsScreenHeader dentro do menu ganha o botão que o abre', (t) async {
    await t.pumpWidget(
      _app(
        body: const Scaffold(
          body: SsScreenHeader(title: 'Início', slivers: []),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.ssTooltip('Abrir o menu'), findsWidgets);
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).isOpen, isTrue);
  });

  testWidgets('SsTopBar na tela principal também ganha o botão do menu', (t) async {
    await t.pumpWidget(
      _app(
        body: const Scaffold(appBar: SsTopBar(title: 'Início')),
      ),
    );
    await t.pumpAndSettle();
    await t.tap(find.byIcon(Icons.menu_rounded));
    await t.pumpAndSettle();
    expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).isOpen, isTrue);
  });

  test('ssComponentesUiVersion igual ao version do pubspec', () {
    final v = RegExp(
      r'^version:\s*(\S+)',
      multiLine: true,
    ).firstMatch(File('pubspec.yaml').readAsStringSync())!.group(1);
    expect(ssComponentesUiVersion, v);
  });
}
