// v0.15.2: o que a migração do minhas-compras e do minhas-viagens pediu
// (SsBadge sem estouro, SsFormats com espaço não separável, litro em
// maiúscula e moeda por código ISO, ssRunBlocking de espera longa, paletas
// Azul e Petróleo).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'catalogo.dart';

Widget _app(Widget child, {SsStrings? strings}) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(
    body: strings == null ? child : SsStringsScope(strings: strings, child: child),
  ),
);

const _nb = ' ';

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsBadge', () {
    testWidgets('rótulo longo num Wrap estreito encolhe com reticências (não estoura)', (t) async {
      await t.pumpWidget(
        _app(
          const Center(
            child: SizedBox(
              width: 90,
              child: Wrap(
                children: [
                  SsBadge('vence em 2 semanas · aberto · estimada', variant: SsBadgeVariant.warning, micro: true),
                  SsBadge('Ligada há 3 horas na sala de estar', dot: true),
                  SsBadge('Mais barato no Atacadão Centro', icon: Icons.local_offer_outlined),
                ],
              ),
            ),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      for (final e in t.widgetList<Text>(find.descendant(of: find.byType(SsBadge), matching: find.byType(Text)))) {
        expect(e.overflow, TextOverflow.ellipsis);
        expect(e.maxLines, 1);
      }
      for (final b in t.widgetList<SsBadge>(find.byType(SsBadge))) {
        expect(t.getSize(find.byWidget(b)).width, lessThanOrEqualTo(90));
      }
      // O leitor de tela lê o rótulo inteiro.
      expect(find.bySemanticsLabel('Ligada há 3 horas na sala de estar'), findsOneWidget);
    });

    testWidgets('rótulo curto continua do tamanho do texto', (t) async {
      await t.pumpWidget(
        _app(
          const Center(
            child: SizedBox(width: 300, child: Wrap(children: [SsBadge('Pago')])),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(SsBadge)).width, lessThan(120));
    });
  });

  group('SsFormats', () {
    test('dinheiro com espaço não separável entre símbolo e valor', () {
      expect(money(123456), 'R\$${_nb}1.234,56');
      expect(money(-5), '-R\$${_nb}0,05');
      expect(SsFormats.brl.prefix, 'R\$$_nb');
      expect(money(123456, SsFormats.eur), '1.234,56$_nb€');
      expect(money(123456, SsFormats.usd), r'$1,234.56');
      expect(parseMoney('R\$${_nb}1.234,56'), 123456);
      expect(ssEvalAmount('R\$${_nb}45+12,50'), 5750);
    });

    test('quantidade com unidade: litro em maiúscula', () {
      expect(SsFormats.brl.qty(1.5, 'l'), '1,5 L');
      expect(SsFormats.brl.qty(2, 'L'), '2 L');
      expect(SsFormats.brl.qty(0.25, 'kg'), '0,25 kg');
      expect(SsFormats.brl.qty(500, 'ml'), '500 ml');
      expect(SsFormats.brl.qty(3), '3');
      expect(SsFormats.brl.qty(null, 'l'), '—');
      expect(SsFormats.usd.qty(1.5, 'l'), '1.5 L');
      expect(qtyUnit(2, 'l'), '2 L');
      expect(qtyUnit(1.5, 'un'), '1,5 un');
      expect(qtyUnit(1.5, null), '1,5');
      expect(qty(0.125), '0,125');
    });

    test('forCurrency: qualquer moeda ISO com o símbolo do mapa da gem', () {
      expect(money(4500, SsFormats.forCurrency('EUR')), '€${_nb}45,00');
      expect(money(1200, SsFormats.forCurrency('usd')), 'US\$${_nb}12,00');
      expect(money(150000, SsFormats.forCurrency('GBP')), '£${_nb}1.500,00');
      expect(money(1000, SsFormats.forCurrency('CHF')), 'CHF${_nb}10,00');
      expect(money(1000, SsFormats.forCurrency('JPY')), '¥${_nb}10,00');
      expect(money(150000, SsFormats.forCurrency('ARS', symbol: 'ARS')), 'ARS${_nb}1.500,00');
      expect(SsFormats.forCurrency('BRL'), SsFormats.brl);
      expect(SsFormats.forCurrency('EUR').currencyCode, 'EUR');
      expect(SsFormats.symbolFor('cad'), r'CA$');
      // Com outra base: separadores e posição dela.
      expect(SsFormats.forCurrency('USD', base: SsFormats.usd), SsFormats.usd);
      expect(money(123456, SsFormats.forCurrency('EUR', base: SsFormats.usd)), r'€1,234.56');
      expect(money(123456, SsFormats.forCurrency('CHF', base: SsFormats.usd)), 'CHF${_nb}1,234.56');
      expect(money(123456, SsFormats.forCurrency('USD', base: SsFormats.eur)), '1.234,56${_nb}US\$');
    });
  });

  group('ssRunBlocking (espera longa)', () {
    Widget botao(Future<Object?> Function(BuildContext) go) => Builder(
      builder: (c) => TextButton(onPressed: () => go(c), child: const Text('ir')),
    );

    testWidgets('arte no lugar do spinner, tempo depois de N s e Cancelar depois de M s', (t) async {
      var cancelou = false;
      await t.pumpWidget(
        _app(
          botao(
            (c) => ssRunBlocking(
              c,
              () => Future<void>.delayed(const Duration(seconds: 30)),
              label: 'Lendo o cupom…',
              art: const Icon(Icons.receipt_long, key: Key('arte')),
              showElapsedAfter: const Duration(seconds: 8),
              cancelAfter: const Duration(seconds: 15),
              onCancel: () => cancelou = true,
            ),
          ),
        ),
      );
      await t.tap(find.text('ir'));
      await t.pump();
      expect(find.byKey(const Key('arte')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.textContaining('ainda trabalhando'), findsNothing);
      expect(find.text('Cancelar'), findsNothing);

      await t.pump(const Duration(seconds: 8));
      expect(find.text('8 s · ainda trabalhando, não feche o app'), findsOneWidget);
      expect(find.text('Cancelar'), findsNothing);

      await t.pump(const Duration(seconds: 7));
      expect(find.text('Cancelar'), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pump();
      expect(cancelou, isTrue);
      expect(find.text('Cancelando…'), findsOneWidget);

      await t.pump(const Duration(seconds: 15));
      await t.pumpAndSettle();
      expect(find.byType(SsBlockingIndicator), findsNothing);
    });

    testWidgets('sem onCancel, Cancelar fecha na hora e o Future termina com SsBlockingCancelled', (t) async {
      Object? erro;
      var terminou = false;
      await t.pumpWidget(
        _app(
          botao((c) async {
            try {
              await ssRunBlocking(
                c,
                () => Future<int>.delayed(const Duration(seconds: 60), () => 1),
                cancelAfter: const Duration(seconds: 2),
              );
            } catch (e) {
              erro = e;
            }
            terminou = true;
            return null;
          }),
        ),
      );
      await t.tap(find.text('ir'));
      await t.pump();
      expect(find.text('Cancelar'), findsNothing);
      await t.pump(const Duration(seconds: 2));
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(terminou, isTrue);
      expect(erro, isA<SsBlockingCancelled>());
      expect(find.byType(SsBlockingIndicator), findsNothing);
      // A tarefa abandonada termina depois sem erro solto.
      await t.pump(const Duration(seconds: 60));
    });

    testWidgets('sem os parâmetros novos, igual à v0.15.1 (spinner, sem relógio)', (t) async {
      late int r;
      await t.pumpWidget(
        _app(
          botao((c) async {
            r = await ssRunBlocking(c, () => Future<int>.delayed(const Duration(seconds: 20), () => 7));
            return r;
          }),
        ),
      );
      await t.tap(find.text('ir'));
      await t.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await t.pump(const Duration(seconds: 12));
      expect(find.textContaining(' s · '), findsNothing);
      expect(find.text('Cancelar'), findsNothing);
      await t.pump(const Duration(seconds: 8));
      await t.pumpAndSettle();
      expect(r, 7);
    });

    testWidgets('tempo decorrido em inglês e espanhol, e texto próprio', (t) async {
      for (final (s, esperado) in [
        (SsStrings.en, "16 s · still working, don't close the app"),
        (SsStrings.es, '16 s · todavía trabajando, no cierres la app'),
      ]) {
        await t.pumpWidget(
          _app(
            SsBlockingIndicator(
              key: ValueKey(s.locale),
              showElapsedAfter: const Duration(seconds: 8),
              elapsed: const Duration(seconds: 16),
            ),
            strings: s,
          ),
        );
        await t.pump();
        expect(find.text(esperado), findsOneWidget);
      }
      await t.pumpWidget(
        _app(
          SsBlockingIndicator(
            key: const Key('proprio'),
            showElapsedAfter: Duration.zero,
            elapsed: const Duration(seconds: 3),
            elapsedLabel: (n) => '${n}s · ainda lendo',
          ),
        ),
      );
      expect(find.text('3s · ainda lendo'), findsOneWidget);
    });
  });

  group('paletas Azul e Petróleo', () {
    test('estão no SsBrand e no SsPaleta.todas (30)', () {
      expect(SsPaleta.todas, hasLength(30));
      expect(SsBrand.azul.accentLight, const Color(0xFF2563EB));
      expect(SsBrand.azul.accentHoverLight, const Color(0xFF1D4ED8));
      expect(SsBrand.azul.accentDark, const Color(0xFF5B8CFF));
      expect(SsBrand.azul.brandDeep, const Color(0xFF1E40AF));
      // #0E7C86 dá 4,34:1 sobre a página clara do Flutter: o accent claro desceu 2,5% (#0E7983).
      expect(SsBrand.petroleo.accentLight, const Color(0xFF0E7983));
      expect(SsBrand.petroleo.brandTo, const Color(0xFF0E7C86));
      expect(SsBrand.petroleo.accentDark, const Color(0xFF1F9CA6));
      final slugs = SsPaleta.todas.map((p) => p.slug);
      expect(slugs, containsAll(['azul', 'petroleo']));
      expect(SsBrand.paletas['Petróleo'], SsBrand.petroleo);
    });
  });

  test('catálogo v0.15.2 soma estados às entradas que existem', () {
    final slugs = {for (final c in catalogo) c.slug: c};
    expect(slugs['ss-badge']!.estados.map((e) => e.slug), contains('longo'));
    expect(slugs['ss-run-blocking']!.estados.map((e) => e.slug), containsAll(['cancelavel', 'longa']));
  });
}
