import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget w) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: w),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('ssBoldSpans: negrito em pares e ** sem par fica como texto', () {
    final s = ssBoldSpans('Foram **R\$ 10** hoje');
    expect(s.map((e) => e.text), ['Foram ', 'R\$ 10', ' hoje']);
    expect(s[1].style?.fontWeight, FontWeight.w800);
    expect(s[0].style, isNull);
    expect(ssBoldSpans('a ** b').single.text, 'a ** b');
  });

  test('SsSyncStatus.label', () {
    expect(SsSyncStatus.label(SsSyncState.pending, 1), '1 a enviar');
    expect(SsSyncStatus.label(SsSyncState.pending, 3), '3 a enviar');
    expect(SsSyncStatus.label(SsSyncState.offline, 0), 'Sem conexão');
    expect(SsSyncStatus.label(SsSyncState.offline, 2), 'Sem conexão · 2 a enviar');
  });

  testWidgets('SsQuota: texto e limite', (t) async {
    await t.pumpWidget(_app(const Column(children: [SsQuota(used: 2, limit: 3), SsQuota(used: 3, limit: 3)])));
    expect(find.text('2 de 3 este mês'), findsOneWidget);
    expect(find.text('3 de 3 este mês'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.byIcon(Icons.block_rounded), findsOneWidget);
  });

  testWidgets('SsOnboarding: Continuar avança, última vira Começar, Pular chama onDone', (t) async {
    var feito = 0;
    const pages = [SsOnboardingPage(title: 'Um', text: 'a'), SsOnboardingPage(title: 'Dois', text: 'b')];
    await t.pumpWidget(_app(SsOnboarding(pages: pages, onDone: () => feito++)));
    await t.tap(find.text('Continuar'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 500));
    expect(find.text('Começar'), findsOneWidget);
    expect(find.text('Pular'), findsNothing);
    await t.tap(find.text('Começar'));
    expect(feito, 1);

    await t.pumpWidget(_app(SsOnboarding(key: UniqueKey(), pages: pages, onDone: () => feito++)));
    await t.tap(find.text('Pular'));
    expect(feito, 2);
  });

  testWidgets('SsChecklistCard: contador, toque e "Tudo pronto" ao completar', (t) async {
    var tocou = 0;
    var fechou = 0;
    Widget card(bool b) => _app(
      SsChecklistCard(
        items: [
          const SsChecklistItem('A', done: true),
          SsChecklistItem('B', done: b, onTap: () => tocou++),
        ],
        onDismiss: () => fechou++,
      ),
    );
    await t.pumpWidget(card(false));
    expect(find.text('1 de 2'), findsOneWidget);
    await t.tap(find.text('B'));
    expect(tocou, 1);
    expect(find.text('Tudo pronto!'), findsNothing);
    await t.pumpWidget(card(true));
    await t.pump(const Duration(milliseconds: 1500)); // confete termina
    expect(find.text('2 de 2'), findsOneWidget);
    await t.tap(find.text('Fechar'));
    expect(fechou, 1);
  });

  testWidgets('SsTip: × anima e depois chama onDismiss', (t) async {
    var fechou = 0;
    await t.pumpWidget(_app(SsTip(text: 'Dica', onDismiss: () => fechou++)));
    await t.pumpAndSettle();
    await t.tap(find.byTooltip('Dispensar dica'));
    await t.pump(const Duration(milliseconds: 100));
    expect(fechou, 0);
    await t.pumpAndSettle();
    expect(fechou, 1);
  });

  testWidgets('SsChatInput: envia só com texto, aparado, e não durante sending', (t) async {
    final enviados = <String>[];
    final ctrl = TextEditingController();
    Widget campo(bool sending) => _app(SsChatInput(controller: ctrl, onSend: enviados.add, sending: sending));
    await t.pumpWidget(campo(false));
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(enviados, isEmpty);
    await t.enterText(find.byType(TextField), '  oi  ');
    await t.pump();
    await t.tap(find.byIcon(Icons.arrow_upward_rounded));
    expect(enviados, ['oi']);
    await t.pumpWidget(campo(true));
    await t.testTextInput.receiveAction(TextInputAction.send);
    expect(enviados, ['oi']);
  });

  testWidgets('SsOverflowMenu: uma ação vira ícone; várias abrem menu', (t) async {
    var editou = 0;
    var excluiu = 0;
    await t.pumpWidget(_app(SsOverflowMenu(items: [SsMenuAction(Icons.edit, 'Editar', () => editou++)])));
    await t.tap(find.byTooltip('Editar'));
    expect(editou, 1);

    await t.pumpWidget(
      _app(
        SsOverflowMenu(
          items: [
            SsMenuAction(Icons.edit, 'Editar', () => editou++),
            SsMenuAction(Icons.delete, 'Excluir', () => excluiu++, destructive: true),
          ],
        ),
      ),
    );
    await t.tap(find.byTooltip('Mais opções'));
    await t.pumpAndSettle();
    await t.tap(find.text('Excluir'));
    await t.pumpAndSettle();
    expect(excluiu, 1);
    expect(editou, 1);
  });

  testWidgets('SsSyncDot: ✓ aparece ao sincronizar e some', (t) async {
    await t.pumpWidget(_app(const SsSyncDot(SsSyncState.sending)));
    await t.pumpWidget(_app(const SsSyncDot(SsSyncState.synced)));
    await t.pump(const Duration(milliseconds: 300));
    final op = t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity));
    expect(op.opacity, 1);
    await t.pump(const Duration(milliseconds: 1500));
    expect(t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity, 0);
  });

  testWidgets('SsShareController.capture devolve PNG', (t) async {
    final ctrl = SsShareController();
    await t.pumpWidget(_app(SsShareable(controller: ctrl, child: const SizedBox(width: 50, height: 30))));
    final png = (await t.runAsync(() => ctrl.capture(pixelRatio: 1)))!;
    expect(png.sublist(1, 4), 'PNG'.codeUnits);
  });

  testWidgets('SsScreenHeader: título grande some e pequeno aparece ao rolar', (t) async {
    final ctrl = ScrollController();
    await t.pumpWidget(
      _app(
        SsScreenHeader(
          title: 'Título',
          controller: ctrl,
          slivers: [SliverList.builder(itemCount: 50, itemBuilder: (_, i) => SizedBox(height: 50, child: Text('$i')))],
        ),
      ),
    );
    double opac(int i) => t
        .widgetList<Opacity>(find.ancestor(of: find.text('Título'), matching: find.byType(Opacity)))
        .elementAt(i)
        .opacity;
    // 0: grande, 1: pequeno (ordem do Stack).
    expect(opac(0), 1);
    expect(opac(1), 0);
    ctrl.jumpTo(300);
    await t.pump();
    expect(opac(0), 0);
    expect(opac(1), 1);
  });

  testWidgets('SsReveal/SsDrawIn mostram o filho; reduceMotion não anima', (t) async {
    await t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: const Column(
            children: [
              SsReveal(child: Text('a')),
              SsDrawIn(child: Text('b')),
            ],
          ),
        ),
      ),
    );
    expect(find.byType(TweenAnimationBuilder<double>), findsNothing);
    expect(find.text('a'), findsOneWidget);
  });
}
