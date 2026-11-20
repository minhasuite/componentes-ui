// v1.8: cartão de conquista (SsAchievementCard), par do Ss::AchievementCardComponent.
// Com CONQUISTA_SAIDA=<pasta> grava as capturas (360 em 2 colunas; claro, escuro, OLED; texto 1,6×).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(
  Widget child, {
  ThemeData? theme,
  Locale locale = const Locale('pt'),
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  themeAnimationDuration: Duration.zero,
  theme: theme ?? AppTheme.light,
  locale: locale,
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: RepaintBoundary(
        key: const Key('shot'),
        child: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  ),
);

/// A grade de 2 colunas do celular: uma conquistada, uma em andamento, uma sem progresso e uma com toque.
Widget _grade({VoidCallback? onTap}) => Padding(
  padding: const EdgeInsets.all(16),
  child: Column(
    children: [
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(
              child: SsAchievementCard(
                title: 'Primeiro turno coberto',
                description: 'Cobriu um turno aberto da escala.',
                earned: true,
                caption: 'em 12/11',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SsAchievementCard(
                title: '30 dias seguidos',
                description: 'Sequência de 30 dias escalados com tudo feito.',
                icon: SsIcons.named('fire'),
                progress: 12 / 30,
                progressLabel: '12 de 30 dias',
                onTap: onTap,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: SsAchievementCard(
              title: '100 checklists no prazo',
              description: 'Conclua 100 checklists antes do prazo.',
            ),
          ),
          SizedBox(width: 12),
          Expanded(child: SizedBox()),
        ],
      ),
    ],
  ),
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    final f = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
    }
  });
  final saida = Platform.environment['CONQUISTA_SAIDA'];

  Future<void> tela(WidgetTester t, Size s) async {
    t.view.physicalSize = s * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  Future<void> capturar(WidgetTester t, String nome) async {
    await t.runAsync(GoogleFonts.pendingFonts);
    await t.pump(const Duration(seconds: 2));
    if (saida == null) return;
    final b = t.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
    await t.runAsync(() async {
      final img = await b.toImage(pixelRatio: 2);
      final png = await img.toByteData(format: ui.ImageByteFormat.png);
      File('$saida/$nome.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }

  testWidgets('conquistada: selo "Conquistada" com a data; em andamento: barra e o que falta', (t) async {
    await tela(t, const Size(360, 640));
    await t.pumpWidget(_app(_grade()));
    await t.pumpAndSettle();
    expect(find.textContaining('Conquistada', findRichText: true), findsOneWidget);
    expect(find.text('em 12/11'), findsOneWidget);
    expect(find.text('12 de 30 dias'), findsOneWidget);
    expect(find.byType(SsProgress), findsOneWidget);
    // Sem progresso: nem barra nem selo.
    final sem = find.ancestor(of: find.text('100 checklists no prazo'), matching: find.byType(SsAchievementCard));
    expect(find.descendant(of: sem, matching: find.byType(SsProgress)), findsNothing);
    expect(find.descendant(of: sem, matching: find.textContaining('Conquistada', findRichText: true)), findsNothing);
    expect(t.takeException(), isNull);
    await capturar(t, 'conquista-claro');
  });

  testWidgets('leitor de tela: um nó só por cartão, botão quando há toque', (t) async {
    var toques = 0;
    await tela(t, const Size(360, 640));
    final h = t.ensureSemantics();
    await t.pumpWidget(_app(_grade(onTap: () => toques++)));
    await t.pumpAndSettle();
    expect(
      find.bySemanticsLabel(
        'Conquista: Primeiro turno coberto. Conquistada em 12/11. Cobriu um turno aberto da escala.',
      ),
      findsOneWidget,
    );
    final andamento = find.bySemanticsLabel(
      'Conquista: 30 dias seguidos. Falta: 12 de 30 dias. Sequência de 30 dias escalados com tudo feito.',
    );
    expect(andamento, findsOneWidget);
    expect(t.getSemantics(andamento), isSemantics(isButton: true, hasTapAction: true));
    expect(
      find.bySemanticsLabel('Conquista: 100 checklists no prazo. Conclua 100 checklists antes do prazo.'),
      findsOneWidget,
    );
    await t.tap(find.text('30 dias seguidos'));
    expect(toques, 1);
    h.dispose();
  });

  testWidgets('inglês e espanhol', (t) async {
    await tela(t, const Size(360, 640));
    await t.pumpWidget(_app(_grade(), locale: const Locale('en')));
    await t.pumpAndSettle();
    expect(find.textContaining('Earned', findRichText: true), findsOneWidget);
    await t.pumpWidget(_app(_grade(), locale: const Locale('es')));
    await t.pumpAndSettle();
    expect(find.textContaining('Conseguido', findRichText: true), findsOneWidget);
  });

  for (final (nome, tema) in [
    ('escuro', AppTheme.build(Brightness.dark)),
    ('oled', AppTheme.build(Brightness.dark, oled: true)),
  ]) {
    testWidgets('tema $nome sem erro', (t) async {
      await tela(t, const Size(360, 640));
      await t.pumpWidget(_app(_grade(), theme: tema));
      await t.pumpAndSettle();
      expect(t.takeException(), isNull);
      await capturar(t, 'conquista-$nome');
    });
  }

  testWidgets('texto 1,6× em 2 colunas de 360: nada transborda, o texto quebra', (t) async {
    await tela(t, const Size(360, 900));
    await t.pumpWidget(_app(_grade(), textScaler: const TextScaler.linear(1.6)));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
    expect(find.text('Sequência de 30 dias escalados com tudo feito.'), findsOneWidget);
    await capturar(t, 'conquista-texto-1.6');
  });
}
