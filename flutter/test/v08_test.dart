import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('catálogo v0.8 soma estados às entradas que existem', () {
    final slugs = {for (final c in catalogo) c.slug: c};
    expect(slugs['ss-progress']!.estados.map((e) => e.slug), contains('indeterminado'));
    expect(slugs['ss-run-blocking']!.estados.map((e) => e.slug), contains('cancelavel'));
  });

  test('mmss', () {
    expect(SsCountdownRing.mmss(90), '1:30');
    expect(SsCountdownRing.mmss(5), '0:05');
  });

  testWidgets('SsSearchField com debounce só avisa quando para de digitar', (t) async {
    final ditos = <String>[];
    await t.pumpWidget(_app(SsSearchField(debounce: const Duration(milliseconds: 300), onChanged: ditos.add)));
    await t.enterText(find.byType(TextField), 'ar');
    await t.pump(const Duration(milliseconds: 100));
    await t.enterText(find.byType(TextField), 'arroz');
    expect(ditos, isEmpty);
    await t.pump(const Duration(milliseconds: 300));
    expect(ditos, ['arroz']);
    await t.tap(find.byTooltip('Limpar'));
    expect(ditos, ['arroz', '']);
  });

  testWidgets('SsSegmented ignora a opção desabilitada', (t) async {
    final escolhas = <int>[];
    await t.pumpWidget(
      _app(
        SsSegmented<int>(
          segments: const [(0, 'A'), (1, 'B')],
          icons: const [Icons.list, null],
          disabled: const {1},
          value: 0,
          onChanged: escolhas.add,
        ),
      ),
    );
    await t.tap(find.text('B'));
    expect(escolhas, isEmpty);
  });

  testWidgets('showSsPrompt com allowEmpty devolve vazio', (t) async {
    String? r = 'x';
    await t.pumpWidget(
      _app(
        Builder(
          builder: (c) => TextButton(
            onPressed: () async =>
                r = await showSsPrompt(c, title: 'Nota', initial: 'a', allowEmpty: true, maxLines: 3),
            child: const Text('abrir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('abrir'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextFormField), '');
    await t.tap(find.text('Salvar'));
    await t.pumpAndSettle();
    expect(r, '');
  });

  testWidgets('SsUnsavedGuard(isDirty:) pergunta só quando a função diz que mudou', (t) async {
    var mudou = false;
    final nav = GlobalKey<NavigatorState>();
    await t.pumpWidget(
      MaterialApp(
        navigatorKey: nav,
        theme: AppTheme.light,
        home: const Scaffold(body: Text('início')),
      ),
    );
    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => SsUnsavedGuard(
          isDirty: () => mudou,
          child: const Scaffold(body: Text('form')),
        ),
      ),
    );
    await t.pumpAndSettle();
    await nav.currentState!.maybePop();
    await t.pumpAndSettle();
    expect(find.text('início'), findsOneWidget);

    nav.currentState!.push(
      MaterialPageRoute<void>(
        builder: (_) => SsUnsavedGuard(
          isDirty: () => mudou,
          child: const Scaffold(body: Text('form')),
        ),
      ),
    );
    await t.pumpAndSettle();
    mudou = true;
    await nav.currentState!.maybePop();
    await t.pumpAndSettle();
    expect(find.text('Descartar as alterações?'), findsOneWidget);
  });

  testWidgets('ssRunBlocking(onCancel:) mostra Cancelar e chama o app', (t) async {
    var cancelou = false;
    await t.pumpWidget(
      _app(
        Builder(
          builder: (c) => TextButton(
            onPressed: () => ssRunBlocking(
              c,
              () => Future<void>.delayed(const Duration(seconds: 1)),
              onCancel: () => cancelou = true,
            ),
            child: const Text('ir'),
          ),
        ),
      ),
    );
    await t.tap(find.text('ir'));
    await t.pump();
    await t.tap(find.text('Cancelar'));
    await t.pump();
    expect(cancelou, isTrue);
    expect(find.text('Cancelando…'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    await t.pumpAndSettle();
    expect(find.text('Cancelando…'), findsNothing);
  });

  testWidgets('SsDateField(validator:) mostra o erro no Form', (t) async {
    final form = GlobalKey<FormState>();
    await t.pumpWidget(
      _app(
        Form(
          key: form,
          child: SsDateField(value: null, onChanged: (_) {}, validator: (v) => v == null ? 'Informe a data' : null),
        ),
      ),
    );
    expect(form.currentState!.validate(), isFalse);
    await t.pump();
    expect(find.text('Informe a data'), findsOneWidget);
  });
}
