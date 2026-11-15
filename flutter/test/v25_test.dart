import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.25 · auditoria de UX de novembro, rodada 5 (meu-gestor-app: barra de abas).
// Cada teste reproduz o achado: falha na v0.24.0 e passa com a correção.
void main() {
  const abas = [
    SsNavItem(Icons.today_outlined, 'Hoje', activeIcon: Icons.today),
    SsNavItem(Icons.view_kanban_outlined, 'Cards'),
    SsNavItem(Icons.menu, 'Mais'),
  ];

  Widget app(ThemeData tema, {int atual = 0}) => MaterialApp(
    theme: tema,
    home: MediaQuery(
      data: const MediaQueryData(size: Size(390, 844)),
      child: Scaffold(
        bottomNavigationBar: SsNavBar(items: abas, currentIndex: atual, onTap: (_) {}),
      ),
    ),
  );

  /// Opacidade efetiva de um widget (o produto das Opacity/FadeTransition acima dele).
  double opacidade(WidgetTester t, Finder f) {
    var o = 1.0;
    for (final e in t.element(f).debugGetDiagnosticChain()) {
      final w = e.widget;
      if (w is Opacity) o *= w.opacity;
      if (w is FadeTransition) o *= w.opacity.value;
    }
    return o;
  }

  BoxDecoration circulo(WidgetTester t) =>
      t
              .widget<Container>(
                find.byWidgetPredicate(
                  (w) =>
                      w is Container &&
                      w.decoration is BoxDecoration &&
                      (w.decoration! as BoxDecoration).shape == BoxShape.circle,
                ),
              )
              .decoration!
          as BoxDecoration;

  // Antes o `excludeSemantics` engolia o toque do InkResponse: nenhuma aba tinha a ação de tocar
  // no leitor de tela (o TalkBack só acertava pelo toque simulado no centro).
  group('SsNavBar: a aba ativa mostra o rótulo', () {
    testWidgets('o rótulo da aba atual fica visível, na cor da marca, embaixo do círculo', (t) async {
      await t.pumpWidget(app(AppTheme.light, atual: 1));
      await t.pumpAndSettle();
      final rotulo = find.text('Cards');
      expect(rotulo, findsOneWidget);
      expect(opacidade(t, rotulo), 1, reason: 'antes a aba atual inteira ficava com opacidade 0');
      final c = SsColors.of(t.element(rotulo));
      expect(t.widget<Text>(rotulo).style?.color ?? DefaultTextStyle.of(t.element(rotulo)).style.color, c.accentText);
      // Embaixo do círculo, sem encostar nele.
      final circ = t.getRect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).shape == BoxShape.circle,
        ),
      );
      expect(t.getRect(rotulo).top, greaterThanOrEqualTo(circ.bottom));
      // O ícone contornado da aba atual some da barra (ele está no círculo).
      // (Cards não tem activeIcon: o mesmo ícone aparece na barra, 1º, e no círculo, 2º.)
      expect(opacidade(t, find.byIcon(Icons.view_kanban_outlined).first), 0);
      expect(opacidade(t, find.byIcon(Icons.view_kanban_outlined).last), 1);
      // As outras abas seguem com ícone e rótulo.
      expect(opacidade(t, find.text('Hoje')), 1);
      expect(opacidade(t, find.byIcon(Icons.today_outlined)), 1);
    });

    testWidgets('leitor de tela: nome da aba, "aba X de N" e selecionada', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(app(AppTheme.light, atual: 1));
      await t.pumpAndSettle();
      expect(
        t.getSemantics(find.bySemanticsLabel('Cards, aba 2 de 3')),
        isSemantics(label: 'Cards, aba 2 de 3', isButton: true, isSelected: true, hasTapAction: true),
      );
      expect(
        t.getSemantics(find.bySemanticsLabel('Hoje, aba 1 de 3')),
        isSemantics(isButton: true, isSelected: false, hasTapAction: true),
      );
      // O rótulo visível não vira um segundo nó (o leitor não lê "Cards" duas vezes).
      expect(find.bySemanticsLabel('Cards'), findsNothing);
      h.dispose();
    });
  });

  testWidgets('aba atual com contagem: o ícone fica no centro do círculo', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          bottomNavigationBar: SsNavBar(
            currentIndex: 1,
            onTap: (_) {},
            items: const [
              SsNavItem(Icons.today_outlined, 'Hoje'),
              SsNavItem(Icons.view_kanban_outlined, 'Cards', activeIcon: Icons.view_kanban, badge: 3),
            ],
          ),
        ),
      ),
    );
    await t.pumpAndSettle();
    final circ = t.getCenter(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).shape == BoxShape.circle,
      ),
    );
    final icone = t.getCenter(find.byIcon(Icons.view_kanban));
    expect((icone - circ).distance, lessThan(1), reason: 'antes o Badge prendia o ícone no canto de cima do círculo');
  });

  group('SsNavBar: o círculo da aba ativa aparece no escuro', () {
    final temas = {
      'claro': (AppTheme.light, false),
      'escuro': (AppTheme.dark, true),
      'OLED': (AppTheme.build(Brightness.dark, oled: true), true),
      'alto contraste escuro': (AppTheme.build(Brightness.dark, highContrast: true), true),
    };
    for (final MapEntry(key: nome, value: (tema, escuro)) in temas.entries) {
      testWidgets('$nome: anel do círculo com 3:1 sobre a barra e a página', (t) async {
        await t.pumpWidget(app(tema));
        await t.pumpAndSettle();
        final c = SsColors.of(t.element(find.byType(SsNavBar)));
        final d = circulo(t);
        final borda = (d.border as Border?)?.top;
        expect(borda, isNotNull, reason: 'antes o círculo era só surface sobre surface');
        expect(borda!.width, greaterThanOrEqualTo(1.5));
        expect(ssContrast(borda.color, c.surface), greaterThanOrEqualTo(3), reason: 'anel × barra');
        expect(ssContrast(borda.color, c.page), greaterThanOrEqualTo(3), reason: 'anel × página no recorte');
        // No escuro o miolo sobe um degrau (field) para não sumir na barra.
        expect(d.color, escuro ? c.field : c.surface);
      });
    }

    test('anel com 3:1 em todas as paletas (claro, escuro e OLED)', () {
      for (final MapEntry(key: nome, value: brand) in SsBrand.paletas.entries) {
        for (final (escuro, oled) in [(false, false), (true, false), (true, true)]) {
          final c = SsColors.forDark(escuro, brand, oled);
          final anel = SsNavBar.ringColor(c);
          expect(
            ssContrast(anel, c.surface),
            greaterThanOrEqualTo(3),
            reason: '$nome escuro=$escuro oled=$oled × barra',
          );
          expect(ssContrast(anel, c.page), greaterThanOrEqualTo(3), reason: '$nome escuro=$escuro oled=$oled × página');
        }
      }
    });
  });

  testWidgets('SsCollapsible: título longo quebra em até 2 linhas (par do .ss-collapse-title do web)', (t) async {
    t.view.physicalSize = const Size(390, 844);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    const longo = 'Avançado: kit, margem e vencimento do lote que não vai vender a tempo';
    await t.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Padding(
            padding: EdgeInsets.all(16),
            child: SsCollapsible(title: longo, count: 3, label: '2 vencendo', child: SizedBox()),
          ),
        ),
      ),
    );
    final texto = t.widget<Text>(find.text(longo));
    expect(texto.maxLines, 2, reason: 'antes era uma linha só, cortada no celular');
    expect(texto.overflow, TextOverflow.ellipsis);
    expect(t.takeException(), isNull);
  });
}
