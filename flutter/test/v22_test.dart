// v0.22: tela de entrada "Folhinha" (SsAuthLayout.folhinha), fonte de exibição e authPartOf.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

Widget _app(Widget child, {Size size = const Size(420, 1000), Locale? locale}) => MediaQuery(
  data: MediaQueryData(size: size),
  child: MaterialApp(
    theme: AppTheme.light,
    locale: locale ?? const Locale('pt'),
    supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
    localizationsDelegates: const [
      SsStrings.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: Scaffold(body: child),
  ),
);

Widget _folhinha({SsAuthVariant variant = SsAuthVariant.sheet, DateTime? date, String? note}) => SsAuthLayout.folhinha(
  product: 'Meu Gestor',
  tagline: 'A loja em dia.',
  title: 'Entrar',
  subtitle: 'no Meu Gestor',
  variant: variant,
  date: date ?? DateTime(2026, 11, 13),
  note: note,
  footer: const [Text('Termos')],
  children: const [Text('formulário', key: ValueKey('form'))],
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  Future<void> grande(WidgetTester t, Size s) async {
    t.view.physicalSize = s;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
  }

  testWidgets('sheet: marca, mês, dia, dia da semana, título, conteúdo do app e faixa', (t) async {
    await grande(t, const Size(420, 1000));
    await t.pumpWidget(_app(_folhinha(note: 'bom dia')));
    await t.pumpAndSettle();
    expect(find.text('Novembro'), findsOneWidget);
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('13'), findsOneWidget);
    expect(find.text('Sexta-feira'), findsOneWidget);
    expect(find.text('bom dia'), findsOneWidget);
    expect(find.text('Entrar'), findsOneWidget);
    expect(find.text('no Meu Gestor'), findsOneWidget);
    expect(find.byKey(const ValueKey('form')), findsOneWidget);
    expect(find.text('Meu Gestor'), findsOneWidget);
    expect(find.text('A loja em dia.'), findsOneWidget);
    expect(find.text('Termos'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('domingo sai na cor de perigo', (t) async {
    await grande(t, const Size(420, 1000));
    await t.pumpWidget(_app(_folhinha(date: DateTime(2026, 11, 15))));
    await t.pumpAndSettle();
    final ctx = t.element(find.text('15'));
    expect(t.widget<Text>(find.text('15')).style?.color, SsColors.of(ctx).danger);
  });

  testWidgets('wall larga: folhinha fora do leitor de tela e "Parte da MinhaSuite"', (t) async {
    await grande(t, const Size(1200, 800));
    await t.pumpWidget(_app(_folhinha(variant: SsAuthVariant.wall), size: const Size(1200, 800)));
    await t.pumpAndSettle();
    expect(find.text('Parte da MinhaSuite'), findsOneWidget);
    expect(find.byType(Row), findsWidgets);
    expect(find.ancestor(of: find.text('13'), matching: find.byType(ExcludeSemantics)), findsWidgets);
    expect(t.takeException(), isNull);
  });

  testWidgets('wall estreita empilha sem estourar', (t) async {
    await grande(t, const Size(390, 1100));
    await t.pumpWidget(_app(_folhinha(variant: SsAuthVariant.wall), size: const Size(390, 1100)));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('form')), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('pad: hoje na folha e amanhã por baixo (virada de mês)', (t) async {
    await grande(t, const Size(420, 1000));
    await t.pumpWidget(_app(_folhinha(variant: SsAuthVariant.pad, date: DateTime(2026, 11, 30))));
    await t.pumpAndSettle();
    expect(find.text('30'), findsOneWidget);
    expect(find.text('Segunda-feira, Novembro'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Terça-feira'), findsOneWidget);
  });

  testWidgets('inglês e espanhol', (t) async {
    await grande(t, const Size(1200, 800));
    await t.pumpWidget(
      _app(
        _folhinha(variant: SsAuthVariant.wall),
        size: const Size(1200, 800),
        locale: const Locale('en'),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('November'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Part of MinhaSuite'), findsOneWidget);
    await t.pumpWidget(_app(_folhinha(), locale: const Locale('es')));
    await t.pumpAndSettle();
    expect(find.text('Viernes'), findsOneWidget);
  });

  test('authPartOf nos três idiomas e no copyWith', () {
    expect(SsStrings.pt.authPartOf('MinhaSuite'), 'Parte da MinhaSuite');
    expect(SsStrings.en.authPartOf('X'), 'Part of X');
    expect(SsStrings.es.authPartOf('X'), 'Parte de X');
    expect(SsStrings.pt.copyWith(authPartOf: (b) => 'De $b').authPartOf('Y'), 'De Y');
  });
}
