// v0.19: imagem em tela cheia com zoom, grupo recolhível com subtítulo e os
// tokens de espaçamento de texto (o que sobrava de genérico no meu-financeiro-app).
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

final _png = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

Widget _app(Widget home, {bool reduce = false}) => MaterialApp(
  theme: AppTheme.light,
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: home,
    ),
  ),
);

Widget _abre({String? title, List<Widget> actions = const []}) => Scaffold(
  body: Builder(
    builder: (context) => Center(
      child: SsButton(
        label: 'ver',
        expand: false,
        onPressed: () => showSsImageViewer(context, image: MemoryImage(_png), title: title, actions: actions),
      ),
    ),
  ),
);

void main() {
  group('showSsImageViewer', () {
    testWidgets('abre com título e ações, o × fecha', (t) async {
      await t.pumpWidget(
        _app(
          _abre(
            title: 'cupom.jpg',
            actions: [SsIconButton(icon: Icons.ios_share, tooltip: 'Compartilhar', onPressed: () {})],
          ),
        ),
      );
      await t.tap(find.text('ver'));
      await t.pumpAndSettle();
      expect(find.byType(SsImageViewer), findsOneWidget);
      expect(find.text('cupom.jpg'), findsOneWidget);
      expect(find.byTooltip('Compartilhar'), findsOneWidget);
      await t.tap(find.byTooltip('Fechar'));
      await t.pumpAndSettle();
      expect(find.byType(SsImageViewer), findsNothing);
    });

    testWidgets('toque duplo amplia e volta; leitor lê nome e dica', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(_app(_abre(), reduce: true));
      await t.tap(find.text('ver'));
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Imagem'), findsOneWidget);
      final viewer = t.widget<InteractiveViewer>(find.byType(InteractiveViewer));
      final c = viewer.transformationController!;
      expect(c.value.getMaxScaleOnAxis(), 1);
      final centro = t.getCenter(find.byType(InteractiveViewer));
      await t.tapAt(centro);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(centro);
      await t.pumpAndSettle();
      expect(c.value.getMaxScaleOnAxis(), closeTo(2.5, .01));
      await t.tapAt(centro);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(centro);
      await t.pumpAndSettle();
      expect(c.value.getMaxScaleOnAxis(), 1);
      h.dispose();
    });

    testWidgets('imagem que não carrega vira o ícone', (t) async {
      await t.pumpWidget(_app(SsImageViewer(image: MemoryImage(utf8.encode('não é imagem')))));
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
    });

    testWidgets('em inglês e espanhol', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SsStringsScope(
            strings: SsStrings.es,
            child: SsImageViewer(image: MemoryImage(_png)),
          ),
        ),
      );
      await t.pump();
      expect(find.byTooltip('Cerrar'), findsOneWidget);
      expect(SsStrings.en.image, 'Image');
      expect(SsStrings.es.zoomHint, contains('ampliar'));
    });
  });

  group('SsCollapsible(subtitle:)', () {
    testWidgets('subtítulo à vista fechado; o corpo fica montado e valida', (t) async {
      final form = GlobalKey<FormState>();
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Form(
              key: form,
              child: const SsCollapsible(
                title: 'Mais opções',
                subtitle: 'Pessoa, tags, repetição',
                child: SsTextField(label: 'Nota', validator: SsValidators.required),
              ),
            ),
          ),
        ),
      );
      expect(find.text('Pessoa, tags, repetição'), findsOneWidget);
      expect(find.byKey(const ValueKey('ss-collapsible-subtitle')), findsOneWidget);
      expect(form.currentState!.validate(), isFalse, reason: 'o campo fechado ainda valida');
      await t.tap(find.text('Mais opções'));
      await t.pumpAndSettle();
      expect(find.text('Nota'), findsOneWidget);
    });

    testWidgets('sem subtítulo, igual a antes', (t) async {
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: SsCollapsible(title: 'Sala', count: 6, child: Text('x')),
          ),
        ),
      );
      expect(find.byKey(const ValueKey('ss-collapsible-subtitle')), findsNothing);
      expect(find.text('6'), findsOneWidget);
    });
  });

  test('tokens de espaçamento de texto', () {
    expect(AppType.leading, 1.4);
    expect(AppType.trackingCaps, .8);
    expect(AppType.trackingWide, 1.4);
  });
}
