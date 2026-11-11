// v0.13: seção com ícone, cabeçalho de bloco, mosaico em colunas, coluna
// lateral, pílulas do mosaico, card de foto e marca a partir de duas cores.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {double width = 390, ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(size: Size(width, 844)),
    child: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: width,
          child: SingleChildScrollView(child: child),
        ),
      ),
    ),
  ),
);

Widget _box(String k, double h) => SizedBox(key: ValueKey(k), height: h);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  test('ssMix e SsBrand.fromColors', () {
    const a = Color(0xFF0284C7);
    const b = Color(0xFF14B8A6);
    expect(ssMix(a, b, 0), a);
    expect(ssMix(a, b, 1), b);
    expect(ssMix(a, b, 2), b);
    final brand = SsBrand.fromColors(a, b);
    expect(brand.accentLight, a);
    expect(brand.brandTo, b);
    expect(brand.accentHoverLight, Color.lerp(a, AppColors.scrim, .14));
    expect(brand.accentDark, Color.lerp(a, AppColors.surfaceLight, .28));
    expect(brand.brandDeep, Color.lerp(a, AppColors.scrim, .35));
    expect(SsBrand.fromColors(a).brandTo, a);
  });

  testWidgets('SsSection e SsSectionHeader com ícone', (t) async {
    await t.pumpWidget(
      _app(
        const Column(
          children: [
            SsSection('Sala', icon: Icons.weekend_outlined),
            SsSectionHeader('Andar de cima', subtitle: '3 cômodos', icon: Icons.home_outlined),
          ],
        ),
      ),
    );
    expect(find.byIcon(Icons.weekend_outlined), findsOneWidget);
    expect(find.text('SALA'), findsOneWidget);
    expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    expect(find.text('3 cômodos'), findsOneWidget);
  });

  test('SsMasonry: colunas pela largura', () {
    expect(SsMasonry.columnsFor(390), 1);
    expect(SsMasonry.columnsFor(700), 2);
    expect(SsMasonry.columnsFor(1200), 3);
    expect(SsMasonry.columnsFor(1600), 4);
    expect(SsMasonry.columnsFor(1600, max: 2), 2);
  });

  testWidgets('SsMasonry distribui um por coluna, na ordem', (t) async {
    await t.pumpWidget(
      _app(SsMasonry(spacing: 10, children: [_box('a', 100), _box('b', 40), _box('c', 30)]), width: 700),
    );
    final a = t.getTopLeft(find.byKey(const ValueKey('a')));
    final b = t.getTopLeft(find.byKey(const ValueKey('b')));
    final c = t.getTopLeft(find.byKey(const ValueKey('c')));
    expect(a.dy, b.dy);
    expect(b.dx, greaterThan(a.dx));
    expect(c.dx, a.dx);
    expect(c.dy, a.dy + 110);
  });

  testWidgets('SsAsideLayout: lado a lado no largo, empilhado no estreito', (t) async {
    final w = SsAsideLayout(main: _box('m', 50), aside: _box('s', 50), asideLabel: 'Resumo', breakpoint: 700);
    await t.pumpWidget(_app(w, width: 760));
    expect(t.getTopLeft(find.byKey(const ValueKey('s'))).dy, t.getTopLeft(find.byKey(const ValueKey('m'))).dy);
    expect(
      t.getSize(find.byKey(const ValueKey('m'))).width,
      greaterThan(t.getSize(find.byKey(const ValueKey('s'))).width),
    );
    await t.pumpWidget(_app(w));
    expect(
      t.getTopLeft(find.byKey(const ValueKey('s'))).dy,
      greaterThan(t.getTopLeft(find.byKey(const ValueKey('m'))).dy),
    );
  });

  testWidgets('SsMosaicTile(facts:) mostra as pílulas no lugar da legenda', (t) async {
    await t.pumpWidget(
      _app(
        const SsMosaicTile(
          title: 'Sala',
          caption: 'escondida',
          height: 150,
          facts: [
            SsMosaicFact('2 ligados', icon: Icons.lightbulb_outline),
            SsMosaicFact('87 W'),
          ],
        ),
      ),
    );
    expect(find.text('2 ligados'), findsOneWidget);
    expect(find.text('87 W'), findsOneWidget);
    expect(find.text('ESCONDIDA'), findsNothing);
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
  });

  testWidgets('SsMosaicFact(onTap:) é um toque à parte e ganha do bloco', (t) async {
    var bloco = 0, pilula = 0;
    await t.pumpWidget(
      _app(
        SsMosaicTile(
          title: 'Contas',
          height: 150,
          onTap: () => bloco++,
          facts: [
            const SsMosaicFact('12 em dia'),
            SsMosaicFact('3 atrasadas', tone: SsTone.warning, semanticLabel: 'Ver 3 atrasadas', onTap: () => pilula++),
          ],
        ),
      ),
    );
    await t.tap(find.text('3 atrasadas'));
    await t.pumpAndSettle();
    expect(pilula, 1);
    expect(bloco, 0);
    await t.tap(find.text('Contas'));
    await t.pumpAndSettle();
    expect(bloco, 1);
    expect(pilula, 1);
    // A pílula com toque é um botão próprio; a frase do bloco fica com o resto.
    expect(find.bySemanticsLabel('Ver 3 atrasadas'), findsOneWidget);
    expect(t.getSemantics(find.bySemanticsLabel('Ver 3 atrasadas')).flagsCollection.isButton, isTrue);
    expect(find.bySemanticsLabel('Contas, 12 em dia'), findsOneWidget);
  });

  testWidgets('SsMosaicFact(tone:) pinta a pílula no tom', (t) async {
    await t.pumpWidget(
      _app(
        const SsMosaicTile(
          title: 'Contas',
          height: 150,
          facts: [
            SsMosaicFact('1 vencida', tone: SsTone.danger),
            SsMosaicFact('neutra'),
          ],
        ),
      ),
    );
    final ctx = t.element(find.text('1 vencida'));
    final esperado = SsTone.danger.colors(ctx).text;
    expect(t.widget<Text>(find.text('1 vencida')).style!.color, esperado);
    expect(t.widget<Text>(find.text('neutra')).style!.color, AppColors.onDark);
    // Sem pílula com toque, o leitor de tela continua lendo tudo numa frase.
    expect(find.bySemanticsLabel('Contas, 1 vencida, neutra'), findsOneWidget);
  });

  testWidgets('SsPhotoCard: título, selo, apagada e toque', (t) async {
    var toques = 0;
    await t.pumpWidget(
      _app(
        SsPhotoCard(
          image: const ColoredBox(color: AppColors.success),
          title: 'Varanda',
          badge: 'Ligada',
          dimmed: true,
          aspectRatio: 2,
          onTap: () => toques++,
        ),
      ),
    );
    expect(find.text('Varanda'), findsOneWidget);
    expect(find.text('Ligada'), findsOneWidget);
    expect(find.byType(ColorFiltered), findsOneWidget);
    expect(t.getSize(find.byType(AspectRatio)).width / t.getSize(find.byType(AspectRatio)).height, closeTo(2, .01));
    await t.tap(find.text('Varanda'));
    await t.pumpAndSettle();
    expect(toques, 1);
  });

  testWidgets('SsProse.paragraphs, SsIntro e SsFieldGroup', (t) async {
    final sem = t.ensureSemantics();
    await t.pumpWidget(
      _app(
        Column(
          children: [
            const SsIntro('Abertura'),
            SsProse.paragraphs('Primeiro.\n\n- um\n- dois\n\nÚltimo.'),
            const SsFieldGroup(label: 'Horário', helperText: 'Todos os dias', children: [Text('a'), Text('b')]),
          ],
        ),
      ),
    );
    expect(find.text('Abertura'), findsOneWidget);
    expect(find.text('Primeiro.'), findsOneWidget);
    expect(find.text('um'), findsOneWidget);
    expect(find.text('dois'), findsOneWidget);
    expect(find.text('Último.'), findsOneWidget);
    expect(find.bySemanticsLabel('Horário. Todos os dias'), findsOneWidget);
    sem.dispose();
  });
}
