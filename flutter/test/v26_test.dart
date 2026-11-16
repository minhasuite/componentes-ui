import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// v0.26 · conversa entre pessoas (minhas-vendas: atendimento do WhatsApp, cliente e atendente).
void main() {
  Widget app(Widget child, {ThemeData? tema}) => MaterialApp(
    theme: tema ?? AppTheme.light,
    home: Scaffold(body: ListView(children: [child])),
  );

  testWidgets('SsChatBubble: sem aiMark a bolha da outra pessoa não tem o ✦', (t) async {
    await t.pumpWidget(app(const SsChatBubble(text: 'Chegou?', fromMe: false, aiMark: false, time: '14:02')));
    await t.pumpAndSettle();
    expect(find.byType(SsAiMark), findsNothing);
    expect(find.text('Chegou?'), findsOneWidget);
    expect(find.text('14:02'), findsOneWidget);

    // Padrão continua o da IA (com o ✦).
    await t.pumpWidget(app(const SsChatBubble(text: 'Posso lançar?', fromMe: false)));
    await t.pumpAndSettle();
    expect(find.byType(SsAiMark), findsOneWidget);
  });

  testWidgets('SsChatBubble: author aparece no alto, dentro da bolha', (t) async {
    await t.pumpWidget(
      app(const SsChatBubble(text: 'Saiu hoje cedo.', fromMe: true, author: 'Ana · pelo celular', time: '09:12')),
    );
    await t.pumpAndSettle();
    final autor = find.text('Ana · pelo celular');
    expect(autor, findsOneWidget);
    // Acima do texto e dentro do mesmo Container da bolha.
    expect(t.getTopLeft(autor).dy, lessThan(t.getTopLeft(find.text('Saiu hoje cedo.')).dy));
    final bolha = find.ancestor(of: find.text('Saiu hoje cedo.'), matching: find.byType(Container)).first;
    expect(find.descendant(of: bolha, matching: autor), findsOneWidget);
  });

  testWidgets('SsChatStatus: entregue e lida com o nome no leitor de tela (pt, en e es)', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(
      app(
        const Column(
          children: [
            SsChatBubble(text: 'a', fromMe: true, status: SsChatStatus.delivered),
            SsChatBubble(text: 'b', fromMe: true, status: SsChatStatus.read),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    // O idioma vem do app (aqui o padrão do MaterialApp); os textos de cada idioma estão embaixo.
    final s = SsStrings.of(t.element(find.text('a')));
    expect(find.byIcon(Icons.done_all_rounded), findsNWidgets(2));
    // O ✓✓ é lido pelo nome (junto com o texto da bolha, no nó dela).
    expect(t.getSemantics(find.byIcon(Icons.done_all_rounded).at(0)).label, contains(s.chatDelivered));
    expect(t.getSemantics(find.byIcon(Icons.done_all_rounded).at(1)).label, contains(s.chatRead));
    expect(s.chatDelivered, 'Entregue');
    // Lida fica na tinta da marca; entregue, apagada.
    final c = SsColors.of(t.element(find.text('a')));
    final icones = t.widgetList<Icon>(find.byIcon(Icons.done_all_rounded)).toList();
    expect(icones[0].color, c.muted);
    expect(icones[1].color, c.accentText);
    sem.dispose();

    expect(SsStrings.pt.chatDelivered, 'Entregue');
    expect(SsStrings.pt.chatRead, 'Lida');
    expect(SsStrings.en.chatDelivered, 'Delivered');
    expect(SsStrings.en.chatRead, 'Read');
    expect(SsStrings.es.chatDelivered, 'Entregado');
    expect(SsStrings.es.chatRead, 'Leído');
  });

  testWidgets('SsChatDivider: rótulo centrado e lido como um nó só', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(app(const SsChatDivider(label: 'Hoje')));
    expect(find.text('Hoje'), findsOneWidget);
    expect(find.bySemanticsLabel('Hoje'), findsOneWidget);
    final centro = t.getCenter(find.text('Hoje')).dx;
    expect(centro, closeTo(t.getCenter(find.byType(SsChatDivider)).dx, 1));
    sem.dispose();
  });

  testWidgets('conversa entre pessoas no escuro e no OLED renderiza sem erro', (t) async {
    for (final tema in [AppTheme.dark, AppTheme.build(Brightness.dark, oled: true)]) {
      await t.pumpWidget(
        app(
          const Column(
            children: [
              SsChatDivider(label: 'Hoje'),
              SsChatBubble(text: 'Oi', fromMe: false, aiMark: false, author: 'Cliente'),
              SsChatBubble(text: 'Olá', fromMe: true, author: 'Ana', status: SsChatStatus.read),
            ],
          ),
          tema: tema,
        ),
      );
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
    }
  });
}
