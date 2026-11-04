// v0.10 (dados): renderiza cada estado do catálogo em claro, escuro e OLED
// (com CATALOGO_SAIDA=<pasta> grava os PNG, como o catalogo_test) e testa o
// comportamento do gráfico no tempo, das faixas, do logbook e da tabela.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo_v10_dados.dart';

const _dpr = 2.0;

Future<void> _fonte(String familia, List<String> arquivos) async {
  final l = FontLoader(familia);
  for (final f in arquivos) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

Widget _app(Widget child, {Size size = const Size(400, 800), bool semAnimacao = true}) => MaterialApp(
  theme: AppTheme.light,
  themeAnimationDuration: Duration.zero,
  home: MediaQuery(
    data: MediaQueryData(size: size, disableAnimations: semAnimacao),
    child: Scaffold(body: child),
  ),
);

void main() {
  final saida = Platform.environment['CATALOGO_SAIDA'];

  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    final root = Platform.environment['FLUTTER_ROOT'] ?? '/sdk/flutter';
    await _fonte('MaterialIcons', ['$root/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf']);
  });

  group('catálogo v0.10 dados', () {
    for (final c in catalogoV10Dados) {
      testWidgets(c.nome, (tester) async {
        for (final e in c.estados) {
          for (final tema in ['claro', 'escuro', 'oled']) {
            tester.view.physicalSize = e.tamanho * _dpr;
            tester.view.devicePixelRatio = _dpr;
            await tester.pumpWidget(
              MaterialApp(
                debugShowCheckedModeBanner: false,
                themeAnimationDuration: Duration.zero,
                theme: switch (tema) {
                  'claro' => AppTheme.light,
                  'escuro' => AppTheme.dark,
                  _ => AppTheme.build(Brightness.dark, oled: true),
                },
                home: RepaintBoundary(
                  key: const Key('shot'),
                  child: Scaffold(
                    key: ValueKey('${c.slug}/${e.slug}/$tema'),
                    body: Builder(builder: e.build),
                  ),
                ),
              ),
            );
            await tester.pump();
            await tester.pump(Duration(milliseconds: e.aguarde));
            await tester.runAsync(GoogleFonts.pendingFonts);
            expect(tester.takeException(), isNull, reason: '${c.slug}/${e.slug}/$tema');
            if (saida == null || tema == 'oled') continue;
            final b = tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('shot')));
            await tester.runAsync(() async {
              final img = await b.toImage(pixelRatio: _dpr);
              final png = await img.toByteData(format: ui.ImageByteFormat.png);
              File('$saida/${c.slug}/${e.slug}-$tema.png')
                ..createSync(recursive: true)
                ..writeAsBytesSync(png!.buffer.asUint8List());
            });
          }
        }
        // Deixa terminar o que ainda anima (mola, cascata, logbook de mentira).
        await tester.pump(const Duration(seconds: 2));
        tester.view.reset();
      });
    }
  });

  group('formato pelo idioma', () {
    test('número: pt, en e es', () {
      final pt = SsTimeFormat(const Locale('pt', 'BR'));
      final en = SsTimeFormat(const Locale('en', 'US'));
      final es = SsTimeFormat(const Locale('es'));
      expect(pt.number(1234.5, decimals: 1), '1.234,5');
      expect(en.number(1234.5, decimals: 1), '1,234.5');
      expect(es.number(1234.5, decimals: 1), '1234,5');
      expect(es.number(12345.6, decimals: 1), '12.345,6');
      expect(pt.number(21.0, decimals: 1), '21');
      expect(pt.number(-0.004), '0');
      expect(pt.number(3.14159), '3,14');
      expect(pt.value(48, unit: '%'), '48%');
      expect(pt.value(21.46, unit: '°C', decimals: 1), '21,5 °C');
      expect(pt.value(null), '—');
      expect(SsTimeFormat(const Locale('de')).lang, 'en');
    });

    test('hora, data e duração', () {
      final t = DateTime(2026, 11, 4, 15, 5);
      expect(SsTimeFormat(const Locale('pt')).hm(t), '15:05');
      expect(SsTimeFormat(const Locale('en')).hm(t), '3:05 PM');
      expect(SsTimeFormat(const Locale('en')).hm(DateTime(2026, 1, 1, 0, 30)), '12:30 AM');
      expect(SsTimeFormat(const Locale('pt')).dm(t), '04/11');
      expect(SsTimeFormat(const Locale('en')).dm(t), '11/04');
      expect(SsTimeFormat(const Locale('pt')).when(t), '04/11 15:05');
      expect(SsTimeFormat(const Locale('pt')).day(t, now: t), 'qua, 04/11');
      expect(SsTimeFormat(const Locale('es')).day(t, now: DateTime(2027)), 'mié, 04/11/2026');
      final pt = SsTimeFormat(const Locale('pt'));
      expect(pt.duration(const Duration(minutes: 150)), '2 h 30 min');
      expect(pt.duration(const Duration(minutes: 45)), '45 min');
      expect(pt.duration(const Duration(hours: 52)), '2 d 4 h');
      expect(SsTimeFormat(const Locale('en')).duration(const Duration(minutes: 150)), '2h 30m');
    });

    test('marcas do tempo: horas num dia, dias numa semana, meses num ano', () {
      final f = SsTimeFormat(const Locale('pt'));
      final dia = f.ticks(DateTime(2026, 11, 3, 14, 10), DateTime(2026, 11, 4, 14, 10), maxTicks: 5);
      expect(dia.length, inInclusiveRange(3, 5));
      expect(dia.first.at, DateTime(2026, 11, 3, 18));
      // A meia-noite vira a data, em negrito.
      final meia = dia.firstWhere((t) => t.major);
      expect(meia.at, DateTime(2026, 11, 4));
      expect(meia.label, '04/11');
      expect(dia.where((t) => !t.major).every((t) => RegExp(r'^\d\d:00$').hasMatch(t.label)), isTrue);

      final semana = f.ticks(DateTime(2026, 11, 1, 9), DateTime(2026, 11, 8, 9), maxTicks: 8);
      expect(semana.first.at, DateTime(2026, 11, 2));
      expect(semana.first.label, 'seg. 2');

      final ano = f.ticks(DateTime(2026, 1, 10), DateTime(2026, 12, 20), maxTicks: 6);
      expect(ano.map((t) => t.label), ['abr.', 'jul.', 'out.']);

      final virada = f.ticks(DateTime(2026, 10, 1), DateTime(2027, 9, 1), maxTicks: 5);
      expect(virada.any((t) => t.label == '2027' && t.major), isTrue);

      // Poucos minutos: passo de minutos.
      final curto = f.ticks(DateTime(2026, 11, 4, 10, 1), DateTime(2026, 11, 4, 10, 9), maxTicks: 5);
      expect(curto.first.label, '10:02');
    });

    test('escala Y redonda', () {
      final r = ssNiceRange(18.3, 26.7, count: 4);
      expect(r.step, 2.5);
      expect(r.lo, 17.5);
      expect(r.hi, 27.5);
      final plano = ssNiceRange(5, 5);
      expect(plano.lo, lessThan(5));
      expect(plano.hi, greaterThan(5));
    });
  });

  group('gráfico no tempo', () {
    final t0 = DateTime(2026, 11, 4, 10);
    final s = SsTimeSeries(
      name: 'Sala',
      unit: '°C',
      points: [
        SsTimePoint(t0, 20),
        SsTimePoint(t0.add(const Duration(minutes: 10)), 22),
        SsTimePoint(t0.add(const Duration(minutes: 20)), null),
        SsTimePoint(t0.add(const Duration(minutes: 40)), 25),
      ],
    );

    test('valor no instante: degrau, linha, buraco, antes e depois', () {
      final meio = t0.add(const Duration(minutes: 5));
      expect(s.valueAt(meio, SsTimeChartMode.step), 20);
      expect(s.valueAt(meio, SsTimeChartMode.line), 21);
      expect(s.valueAt(t0.add(const Duration(minutes: 30)), SsTimeChartMode.line), isNull);
      expect(s.valueAt(t0.subtract(const Duration(minutes: 1)), SsTimeChartMode.line), isNull);
      expect(s.valueAt(t0.add(const Duration(hours: 3)), SsTimeChartMode.line), 25);
    });

    testWidgets('arrastar mostra o balão com o horário e os valores; soltar esconde', (t) async {
      final cursores = <DateTime?>[];
      await t.pumpWidget(
        _app(
          SsTimeChart(
            locale: const Locale('pt'),
            from: t0,
            to: t0.add(const Duration(minutes: 40)),
            series: [s],
            onScrub: cursores.add,
          ),
        ),
      );
      await t.pumpAndSettle();
      final area = find.descendant(of: find.byType(SsTimeChart), matching: find.byType(CustomPaint)).first;
      final g = await t.startGesture(t.getTopLeft(area) + const Offset(50, 60));
      await g.moveBy(const Offset(50, 0));
      await t.pump();
      expect(cursores.last, isNotNull);
      expect(find.textContaining(RegExp(r'^04/11 10:')), findsOneWidget);
      expect(find.textContaining('°C'), findsWidgets);
      await g.up();
      await t.pump();
      expect(cursores.last, isNull);
      expect(find.textContaining(RegExp(r'^04/11 10:')), findsNothing);
      // Deixa vencer o tempo do toque duplo.
      await t.pump(const Duration(seconds: 1));
    });

    testWidgets('legenda liga e desliga a série', (t) async {
      await t.pumpWidget(_app(SsTimeChart(locale: const Locale('pt'), series: seriesClima())));
      await t.pumpAndSettle();
      final quarto = find.bySemanticsLabel('Quarto, °C');
      expect(t.getSemantics(quarto), isSemantics(isButton: true, hasToggledState: true, isToggled: true));
      await t.tap(find.text('Quarto'));
      await t.pumpAndSettle();
      expect(t.getSemantics(quarto), isSemantics(hasToggledState: true, isToggled: false));
      final texto = t.widget<Text>(find.text('Quarto'));
      expect(texto.style?.decoration, TextDecoration.lineThrough);
    });

    testWidgets('toque duplo aproxima; "Ver tudo" volta e avisa o app', (t) async {
      final janelas = <(DateTime, DateTime)>[];
      await t.pumpWidget(
        _app(
          SsTimeChart(locale: const Locale('pt'), series: [seriesClima().first], onZoom: (a, b) => janelas.add((a, b))),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Ver tudo'), findsNothing);
      final centro = t.getCenter(
        find.descendant(of: find.byType(SsTimeChart), matching: find.byType(CustomPaint)).first,
      );
      await t.tapAt(centro);
      await t.pump(const Duration(milliseconds: 60));
      await t.tapAt(centro);
      await t.pumpAndSettle();
      expect(janelas, hasLength(1));
      expect(janelas.single.$2.difference(janelas.single.$1).inHours, inInclusiveRange(23, 24));
      expect(find.text('Ver tudo'), findsOneWidget);
      await t.tap(find.text('Ver tudo'));
      await t.pumpAndSettle();
      expect(find.text('Ver tudo'), findsNothing);
      expect(janelas.last.$2.difference(janelas.last.$1).inHours, greaterThanOrEqualTo(47));
    });

    testWidgets('carregando, vazio e resumo para o leitor de tela', (t) async {
      await t.pumpWidget(_app(const SsTimeChart(series: [], loading: true)));
      expect(find.byType(SkeletonBox), findsWidgets);
      await t.pumpWidget(
        _app(
          const SsTimeChart(
            series: [SsTimeSeries(name: 'x', points: [])],
          ),
        ),
      );
      expect(find.text('Sem leituras neste período'), findsOneWidget);
      await t.pumpWidget(_app(SsTimeChart(title: 'Sala', locale: const Locale('pt'), series: [s])));
      await t.pumpAndSettle();
      expect(
        find.bySemanticsLabel(
          RegExp(r'^Sala, 04/11 10:00 a 04/11 10:40\. Sala: mínimo 20 °C, máximo 25 °C, último 25 °C'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('duas unidades: um eixo de cada lado', (t) async {
      await t.pumpWidget(_app(SsTimeChart(locale: const Locale('pt'), series: seriesClima())));
      await t.pumpAndSettle();
      // Os rótulos são pintados; confere que o gráfico montou com a legenda das 3 séries.
      expect(find.text('Umidade da sala'), findsOneWidget);
      expect(t.takeException(), isNull);
    });
  });

  group('faixas de estado', () {
    test('tom pelo estado', () {
      expect(ssStateTone('on'), SsTone.accent);
      expect(ssStateTone('closed'), SsTone.neutral);
      expect(ssStateTone('error'), SsTone.danger);
      expect(ssStateTone('cleaning'), isNull);
      expect(ssStateTone('cleaning', {'cleaning': SsTone.success}), SsTone.success);
    });

    testWidgets('tocar no trecho abre o balão com estado, horário e duração', (t) async {
      final a = DateTime(2026, 11, 4, 8), b = DateTime(2026, 11, 4, 10, 30), c = DateTime(2026, 11, 4, 12);
      await t.pumpWidget(
        _app(
          SsStateBands(
            locale: const Locale('pt'),
            rows: [
              SsStateRow('Luz', [
                SsStateSegment(a, b, 'on', label: 'Ligada'),
                SsStateSegment(b, c, 'off', label: 'Desligada'),
              ]),
            ],
          ),
        ),
      );
      await t.pumpAndSettle();
      final barra = find.descendant(of: find.byType(SsStateBandRow), matching: find.byType(CustomPaint)).first;
      await t.tapAt(t.getTopLeft(barra) + const Offset(20, 10));
      await t.pump();
      expect(find.text('Ligada'), findsOneWidget);
      expect(find.text('04/11 08:00 – 10:30 · 2 h 30 min'), findsOneWidget);
      // Tocar de novo fecha.
      await t.tapAt(t.getTopLeft(barra) + const Offset(20, 10));
      await t.pump();
      expect(find.text('Ligada'), findsNothing);
      expect(find.bySemanticsLabel(RegExp('Luz: Ligada 2 h 30 min, Desligada 1 h 30 min')), findsOneWidget);
    });

    testWidgets('vazio e linha sem leituras', (t) async {
      await t.pumpWidget(_app(const SsStateBands(rows: [])));
      expect(find.text('Nenhuma mudança neste período'), findsOneWidget);
      await t.pumpWidget(
        _app(SsStateBands(from: DateTime(2026), to: DateTime(2026, 1, 2), rows: const [SsStateRow('Porta', [])])),
      );
      expect(find.text('sem leituras'), findsOneWidget);
    });
  });

  group('logbook', () {
    testWidgets('agrupa em Hoje, Ontem e a data; gruda o cabeçalho', (t) async {
      await t.pumpWidget(_app(SsLogbook(entries: eventosDemo(porDia: 2), now: agoraDemo, locale: const Locale('pt'))));
      await t.pumpAndSettle();
      expect(find.text('HOJE'), findsOneWidget);
      expect(find.text('ONTEM'), findsOneWidget);
      expect(find.text('SEG, 02/11'), findsOneWidget);
      expect(find.text('13:47'), findsWidgets);
      expect(find.text('Início do registro'), findsOneWidget);
      expect(SsLogbook.groupByDay(eventosDemo(porDia: 2)).map((g) => g.$2.length), [2, 2, 2]);
    });

    testWidgets('carregar mais: botão chama, rolar até o fim chama sozinho uma vez', (t) async {
      var chamadas = 0;
      await t.pumpWidget(
        _app(
          SsLogbook(
            entries: eventosDemo(dias: 1, porDia: 2),
            now: agoraDemo,
            hasMore: true,
            onLoadMore: () => chamadas++,
            autoLoad: false,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.tap(find.text('Carregar mais'));
      expect(chamadas, 1);

      var auto = 0;
      await t.pumpWidget(
        _app(
          SsLogbook(entries: eventosDemo(dias: 3, porDia: 6), now: agoraDemo, hasMore: true, onLoadMore: () => auto++),
        ),
      );
      await t.pumpAndSettle();
      await t.drag(find.byType(CustomScrollView), const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(auto, 1);
    });

    testWidgets('carregando, vazio, erro e erro no rodapé', (t) async {
      await t.pumpWidget(_app(const SsLogbook(entries: [], loading: true)));
      expect(find.byType(SkeletonBox), findsWidgets);
      await t.pumpWidget(_app(const SsLogbook(entries: [])));
      expect(find.text('Nada registrado ainda'), findsOneWidget);
      var tentou = 0;
      await t.pumpWidget(_app(SsLogbook(entries: const [], error: 'Falhou', onRetry: () => tentou++)));
      await t.tap(find.text('Tentar de novo'));
      expect(tentou, 1);
      await t.pumpWidget(
        _app(
          SsLogbook(
            entries: eventosDemo(dias: 1, porDia: 1),
            now: agoraDemo,
            hasMore: true,
            error: 'Sem rede',
            onRetry: () {},
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Sem rede'), findsOneWidget);
      expect(find.text('Carregar mais'), findsNothing);
      await t.pumpWidget(
        _app(SsLogbook(entries: eventosDemo(dias: 1, porDia: 1), now: agoraDemo, hasMore: true, loadingMore: true)),
      );
      await t.pump();
      expect(find.text('Carregando…'), findsOneWidget);
    });
  });

  group('tabela de dados', () {
    testWidgets('larga: cabeçalho ordena e alterna o sentido', (t) async {
      final pedidos = <(int, bool)>[];
      Widget tabela(int? col, bool asc) => _app(
        SsDataTable(
          sortColumn: col,
          sortAscending: asc,
          columns: [
            SsDataColumn('Nome', onSort: (a) => pedidos.add((0, a))),
            SsDataColumn('Valor', numeric: true, onSort: (a) => pedidos.add((1, a))),
            const SsDataColumn('Obs'),
          ],
          rows: [
            SsDataRow.text(['Ana', '10', 'x']),
            SsDataRow.text(['Bia', '20', 'y']),
          ],
        ),
        size: const Size(800, 600),
      );
      await t.pumpWidget(tabela(null, true));
      expect(find.text('NOME'), findsOneWidget);
      await t.tap(find.text('VALOR'));
      expect(pedidos.last, (1, true));
      await t.pumpWidget(tabela(1, true));
      await t.tap(find.text('VALOR'));
      expect(pedidos.last, (1, false));
      expect(find.bySemanticsLabel('Valor, crescente'), findsOneWidget);
      // Coluna sem onSort não é botão.
      await t.tap(find.text('OBS'));
      expect(pedidos, hasLength(2));
    });

    testWidgets('celular: cartões com rótulo e fichas de ordenar', (t) async {
      final pedidos = <(int, bool)>[];
      t.view.physicalSize = const Size(360, 700) * 2;
      t.view.devicePixelRatio = 2;
      await t.pumpWidget(
        _app(
          SsDataTable(
            sortColumn: 1,
            sortAscending: false,
            columns: [
              const SsDataColumn('Nome'),
              SsDataColumn('Valor', numeric: true, onSort: (a) => pedidos.add((1, a))),
            ],
            rows: [
              SsDataRow.text(['Ana', '10']),
            ],
          ),
          size: const Size(360, 700),
        ),
      );
      expect(find.text('Ordenar por'), findsOneWidget);
      expect(find.text('VALOR'), findsOneWidget); // rótulo dentro do cartão
      expect(find.text('Ana'), findsOneWidget);
      await t.tap(find.text('Valor'));
      expect(pedidos.single, (1, true));
      t.view.reset();
    });

    testWidgets('vazia e carregando', (t) async {
      await t.pumpWidget(_app(const SsDataTable(columns: [SsDataColumn('A')], rows: [])));
      expect(find.text('Nada por aqui ainda.'), findsOneWidget);
      await t.pumpWidget(_app(const SsDataTable(columns: [SsDataColumn('A')], rows: [], loading: true)));
      expect(find.byType(SkeletonBox), findsWidgets);
    });
  });
}
