// v1.7: tela de entrada "Cartaz + papel" (SsAuthLayout.cartaz), par do Ss::AuthLayoutComponent(variant: :cartaz).
// Com CARTAZ_SAIDA=<pasta> grava as capturas (390 e 1440; claro, escuro, OLED e alto contraste; pt/en/es).
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
  Locale? locale,
  bool reduzir = false,
  TextScaler textScaler = TextScaler.noScaling,
}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  themeAnimationDuration: Duration.zero,
  theme: theme ?? AppTheme.light,
  locale: locale ?? const Locale('pt'),
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduzir, textScaler: textScaler),
      child: RepaintBoundary(
        key: const Key('shot'),
        child: Scaffold(body: child),
      ),
    ),
  ),
);

Widget _cartaz({
  String? word,
  List<String> facts = const ['Web', 'Windows', 'Caixa', 'App'],
  String? tagline = 'A venda não para.',
}) => SsAuthLayout.cartaz(
  product: 'Minhas Vendas',
  tagline: tagline,
  word: word,
  facts: facts,
  icon: Icons.bar_chart_rounded,
  title: 'Entrar',
  subtitle: 'no Minhas Vendas',
  footer: const [Text('Termos'), Text('Privacidade')],
  children: [
    const SsTextField(label: 'E-mail', hint: 'voce@exemplo.com'),
    const SizedBox(height: 16),
    const SsTextField(label: 'Senha', obscureText: true),
    const SizedBox(height: 24),
    SsButton(label: 'Entrar', onPressed: () {}, key: const ValueKey('entrar')),
  ],
);

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // Ícones do Material nas capturas (como no catalogo_test).
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    final f = File('$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf');
    if (f.existsSync()) {
      await (FontLoader('MaterialIcons')..addFont(Future.value(ByteData.sublistView(f.readAsBytesSync())))).load();
    }
  });
  final saida = Platform.environment['CARTAZ_SAIDA'];

  Future<void> tela(WidgetTester t, Size s) async {
    t.view.physicalSize = s * 2;
    t.view.devicePixelRatio = 2;
    addTearDown(t.view.reset);
  }

  Future<void> capturar(WidgetTester t, String nome) async {
    await t.runAsync(GoogleFonts.pendingFonts);
    await t.pump();
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

  testWidgets('celular: faixa do cartaz em cima, sem a linha de dados; papel com o formulário', (t) async {
    await tela(t, const Size(390, 844));
    await t.pumpWidget(_app(_cartaz()));
    await t.pumpAndSettle();
    expect(find.text('Minhas Vendas'), findsOneWidget);
    expect(find.text('A venda não para.'), findsOneWidget);
    expect(find.text('vendas'), findsOneWidget);
    expect(find.text('Web'), findsNothing);
    expect(find.text('Parte da MinhaSuite'), findsOneWidget);
    expect(find.text('Entrar'), findsWidgets);
    expect(find.text('no Minhas Vendas'), findsOneWidget);
    expect(find.byKey(const ValueKey('entrar')), findsOneWidget);
    expect(find.text('Termos'), findsOneWidget);
    expect(t.takeException(), isNull);
    // O cartaz fica em cima do papel.
    expect(
      t.getTopLeft(find.text('A venda não para.')).dy,
      lessThan(t.getTopLeft(find.text('Parte da MinhaSuite')).dy),
    );
  });

  testWidgets('computador: cartaz e papel lado a lado, com a linha de dados', (t) async {
    await tela(t, const Size(1440, 900));
    await t.pumpWidget(_app(_cartaz()));
    await t.pumpAndSettle();
    for (final f in ['Web', 'Windows', 'Caixa', 'App']) {
      expect(find.text(f), findsOneWidget);
    }
    final frase = t.getTopLeft(find.text('A venda não para.'));
    final parte = t.getTopLeft(find.text('Parte da MinhaSuite'));
    expect(parte.dx, greaterThan(frase.dx + 600));
    expect(t.takeException(), isNull);
  });

  testWidgets('palavra gigante fora do leitor de tela; título é cabeçalho', (t) async {
    await tela(t, const Size(1440, 900));
    final h = t.ensureSemantics();
    await t.pumpWidget(_app(_cartaz()));
    await t.pumpAndSettle();
    expect(find.ancestor(of: find.text('vendas'), matching: find.byType(ExcludeSemantics)), findsWidgets);
    expect(find.bySemanticsLabel('vendas'), findsNothing);
    expect(t.getSemantics(find.text('Entrar').first), matchesSemantics(label: 'Entrar', isHeader: true));
    h.dispose();
  });

  testWidgets('word: padrão é a última palavra do produto; dada, em minúsculas', (t) async {
    expect(const SsAuthCartaz(product: 'Meu Financeiro', title: 'Entrar', children: []).posterWord, 'financeiro');
    expect(const SsAuthCartaz(product: 'Central', title: 'Entrar', word: 'Venda', children: []).posterWord, 'venda');
  });

  testWidgets('cores: brandDeep no claro, 52% com a página no escuro e no OLED; texto ≥ 7:1 e secundário ≥ 4,5:1', (
    t,
  ) async {
    for (final (tema, nome) in [
      (AppTheme.build(Brightness.light, brand: SsBrand.violeta), 'claro'),
      (AppTheme.build(Brightness.dark, brand: SsBrand.violeta), 'escuro'),
      (AppTheme.build(Brightness.dark, brand: SsBrand.violeta, oled: true), 'oled'),
      (AppTheme.build(Brightness.light, brand: SsBrand.azul), 'azul'),
      (AppTheme.build(Brightness.dark, brand: SsBrand.petroleo), 'petroleo'),
    ]) {
      late SsCartazColors k;
      late SsColors c;
      await t.pumpWidget(
        MaterialApp(
          theme: tema,
          home: Builder(
            builder: (ctx) {
              k = SsCartazColors.of(ctx);
              c = SsColors.of(ctx);
              return const SizedBox();
            },
          ),
        ),
      );
      expect(k.background, c.isDark ? ssMix(c.page, c.brandDeep, .52) : c.brandDeep, reason: nome);
      expect(ssContrast(k.ink, k.background), greaterThanOrEqualTo(7), reason: nome);
      expect(ssContrast(k.ink2, k.background), greaterThanOrEqualTo(4.5), reason: nome);
    }
  });

  testWidgets('reduzir movimento: o cartaz já abre pronto (sem passada)', (t) async {
    await tela(t, const Size(390, 844));
    await t.pumpWidget(_app(_cartaz(), reduzir: true));
    await t.pump();
    expect(find.byType(ClipPath), findsNothing);
    expect(t.hasRunningAnimations, isFalse);
  });

  testWidgets('sem frase e sem dados, nada estoura', (t) async {
    await tela(t, const Size(1440, 900));
    await t.pumpWidget(_app(_cartaz(tagline: null, facts: const [])));
    await t.pumpAndSettle();
    expect(t.takeException(), isNull);
  });

  testWidgets('texto 1,6× no celular sem estourar', (t) async {
    await tela(t, const Size(390, 844));
    await t.pumpWidget(_app(_cartaz(), textScaler: const TextScaler.linear(1.6)));
    await t.pumpAndSettle();
    await capturar(t, 'cartaz-390-texto-1.6');
    expect(t.takeException(), isNull);
  });

  testWidgets('textos em inglês e espanhol', (t) async {
    await tela(t, const Size(390, 844));
    await t.pumpWidget(_app(_cartaz(), locale: const Locale('en')));
    await t.pumpAndSettle();
    expect(find.text('Part of MinhaSuite'), findsOneWidget);
    await t.pumpWidget(_app(_cartaz(), locale: const Locale('es')));
    await t.pumpAndSettle();
    expect(find.text('Parte de MinhaSuite'), findsOneWidget);
  });

  testWidgets('capturas: 390 e 1440 em claro, escuro, OLED e alto contraste', (t) async {
    final temas = {
      'claro': AppTheme.light,
      'escuro': AppTheme.dark,
      'oled': AppTheme.build(Brightness.dark, brand: SsBrand.violeta, oled: true),
      'contraste': AppTheme.build(Brightness.light, brand: SsBrand.violeta, highContrast: true),
      'azul-escuro': AppTheme.build(Brightness.dark, brand: SsBrand.azul),
    };
    for (final s in const [Size(390, 844), Size(1440, 900)]) {
      for (final e in temas.entries) {
        await tela(t, s);
        await t.pumpWidget(_app(_cartaz(), theme: e.value, reduzir: true));
        await t.pumpAndSettle();
        await capturar(t, 'cartaz-${s.width.toInt()}-${e.key}');
        expect(t.takeException(), isNull);
      }
    }
  });
}
