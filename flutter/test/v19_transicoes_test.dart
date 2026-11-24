// v1.9 · transições: lista → detalhe (SsOpenContainer/SsOpenRoute/SsOpenPage), voltar preditivo
// (página, folha, diálogo), troca de dados nos gráficos, ilustrações dos estados vazios e a regra
// de comemoração (SsCelebrationGate).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget home, {bool reduce = false, Locale locale = const Locale('pt')}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  themeAnimationDuration: Duration.zero,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
    child: child!,
  ),
  home: home,
);

/// Manda um evento do gesto de voltar como o Android manda (canal flutter/backgesture).
Future<void> _gesto(WidgetTester t, String metodo, [double progress = 0]) async {
  final args = metodo == 'startBackGesture' || metodo == 'updateBackGestureProgress'
      ? <String, Object?>{
          'touchOffset': <double>[4, 300],
          'progress': progress,
          'swipeEdge': 0,
        }
      : null;
  await t.binding.defaultBinaryMessenger.handlePlatformMessage(
    SystemChannels.backGesture.name,
    SystemChannels.backGesture.codec.encodeMethodCall(MethodCall(metodo, args)),
    (_) {},
  );
  await t.pump();
}

class _Lista extends StatelessWidget {
  const _Lista({this.onClosed});
  final ValueChanged<String?>? onClosed;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SsOpenContainer<String>(
        onClosed: onClosed,
        closedBuilder: (context, open) => InkWell(
          onTap: open,
          child: const SizedBox(width: 200, height: 80, child: Text('card')),
        ),
        openBuilder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Pedido 12')),
          body: TextButton(onPressed: () => Navigator.pop(context, 'ok'), child: const Text('detalhe')),
        ),
      ),
    ),
  );
}

double _escala(WidgetTester t, Finder f) {
  final m = t.widget<Transform>(f).transform;
  return m.entry(0, 0);
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('lista → detalhe', () {
    testWidgets('o cartão cresce até a tela, some da lista enquanto aberto e volta com o resultado', (t) async {
      String? volta;
      await t.pumpWidget(_app(_Lista(onClosed: (r) => volta = r)));
      await t.tap(find.text('card'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 200));
      // No meio: o retângulo está entre o cartão e a tela.
      final meio = t.getRect(find.byType(Positioned).last);
      expect(meio.width, greaterThan(200));
      expect(meio.width, lessThan(800));
      await t.pumpAndSettle();
      expect(find.text('detalhe'), findsOneWidget);
      // O cartão da lista fica invisível (é ele que voou).
      final op = t.widget<Opacity>(
        find.ancestor(of: find.text('card', skipOffstage: false), matching: find.byType(Opacity)).first,
      );
      expect(op.opacity, 0);
      await t.tap(find.text('detalhe'));
      await t.pumpAndSettle();
      expect(volta, 'ok');
      expect(find.text('detalhe'), findsNothing);
      expect(t.widget<Opacity>(find.ancestor(of: find.text('card'), matching: find.byType(Opacity)).first).opacity, 1);
    });

    testWidgets('go_router: SsOpenPage com o mesmo tag sai do cartão; sem origem, sobe e aparece', (t) async {
      await t.pumpWidget(
        _app(
          Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: SsOpenCard(
                  tag: 'pedido-12',
                  onOpen: () => Navigator.of(context).push(
                    const SsOpenPage<void>(
                      tag: 'pedido-12',
                      child: Scaffold(body: Text('detalhe')),
                    ).createRoute(context),
                  ),
                  closed: const SizedBox(width: 200, height: 80, child: Text('card')),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('card'));
      await t.pumpAndSettle();
      expect(find.text('detalhe'), findsOneWidget);
      Navigator.of(t.element(find.text('detalhe'))).pop();
      await t.pumpAndSettle();
      expect(find.text('card'), findsOneWidget);

      // Sem cartão de origem na tela (link direto): abre mesmo assim.
      Navigator.of(t.element(find.text('card'))).push(
        SsOpenRoute<void>(
          tag: 'nao-existe',
          builder: (_) => const Scaffold(body: Text('direto')),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('direto'), findsOneWidget);
    });

    testWidgets('reduzir movimento: a tela só aparece', (t) async {
      await t.pumpWidget(_app(const _Lista(), reduce: true));
      await t.tap(find.text('card'));
      await t.pump();
      expect(find.byType(FadeTransition), findsWidgets);
      await t.pump(const Duration(milliseconds: 220));
      expect(find.text('detalhe'), findsOneWidget);
    });
  });

  group('voltar preditivo', () {
    testWidgets('o AppTheme liga o builder no Android e o iOS segue igual', (t) async {
      final b = AppTheme.light.pageTransitionsTheme.builders;
      expect(b[TargetPlatform.android], isA<SsPredictiveBackPageTransitionsBuilder>());
      expect(b[TargetPlatform.iOS], isA<FadeUpwardsPageTransitionsBuilder>());
    });

    testWidgets('página: o gesto encolhe a tela, desistir volta e soltar fecha', (t) async {
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('segunda'))),
                ),
                child: const Text('primeira'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('primeira'));
      await t.pumpAndSettle();
      await _gesto(t, 'startBackGesture');
      await _gesto(t, 'updateBackGestureProgress', .5);
      expect(find.byType(SsBackShrink), findsOneWidget);
      // A anterior aparece por trás.
      expect(find.text('primeira'), findsOneWidget);
      await _gesto(t, 'cancelBackGesture');
      await t.pumpAndSettle();
      expect(find.byType(SsBackShrink), findsNothing);
      expect(find.text('segunda'), findsOneWidget);

      await _gesto(t, 'startBackGesture');
      await _gesto(t, 'updateBackGestureProgress', .4);
      await _gesto(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('segunda'), findsNothing);
      expect(find.text('primeira'), findsOneWidget);
    });

    testWidgets('container transform: o gesto leva a tela de volta ao cartão', (t) async {
      await t.pumpWidget(_app(const _Lista()));
      await t.tap(find.text('card'));
      await t.pumpAndSettle();
      final cheia = t.getRect(find.byType(Positioned).last);
      await _gesto(t, 'startBackGesture');
      await _gesto(t, 'updateBackGestureProgress', .5);
      final meio = t.getRect(find.byType(Positioned).last);
      expect(meio.width, lessThan(cheia.width));
      await _gesto(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('detalhe'), findsNothing);
    });

    testWidgets('folha: desce e encolhe com o dedo e fecha ao soltar', (t) async {
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSsSheet<void>(context, title: 'Filtro', child: const Text('corpo')),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      final escala = find.descendant(of: find.byType(SsPredictiveBackScope), matching: find.byType(Transform)).at(1);
      expect(_escala(t, escala), 1);
      await _gesto(t, 'startBackGesture');
      await _gesto(t, 'updateBackGestureProgress', 1);
      expect(_escala(t, escala), lessThan(1));
      await _gesto(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('corpo'), findsNothing);
    });

    testWidgets('diálogo: encolhe no gesto; reduzir movimento deixa o gesto com o sistema', (t) async {
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showSsConfirm(context, title: 'Excluir?', message: 'Some de vez.'),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.byType(SsPredictiveBackScope), findsOneWidget);
      await _gesto(t, 'startBackGesture');
      await _gesto(t, 'updateBackGestureProgress', 1);
      final f = find.descendant(of: find.byType(SsPredictiveBackScope), matching: find.byType(Transform)).at(1);
      expect(_escala(t, f), closeTo(.9, .01));
      await _gesto(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('Excluir?'), findsNothing);
    });

    testWidgets('reduzir movimento: sem prévia, soltar volta normal', (t) async {
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const Scaffold(body: Text('segunda'))),
                ),
                child: const Text('primeira'),
              ),
            ),
          ),
          reduce: true,
        ),
      );
      await t.tap(find.text('primeira'));
      await t.pumpAndSettle();
      await _gesto(t, 'startBackGesture');
      await _gesto(t, 'updateBackGestureProgress', .5);
      expect(find.byType(SsBackShrink), findsNothing);
      await _gesto(t, 'commitBackGesture');
      await t.pumpAndSettle();
      expect(find.text('segunda'), findsNothing);
    });
  });

  group('gráficos', () {
    Widget area(List<double> v, {bool reduce = false}) => _app(
      Scaffold(
        body: SizedBox(
          width: 320,
          child: SsAreaChart(values: v, labels: const ['a', 'b', 'c']),
        ),
      ),
      reduce: reduce,
    );

    List<List<double>> mostra(WidgetTester t, Type tipo) =>
        (t.state(find.byType(tipo)) as SsChartTransition).chartShown;

    testWidgets('troca de dados: cada ponto vai do anterior ao novo', (t) async {
      await t.pumpWidget(area([10, 20, 30]));
      await t.pumpAndSettle();
      await t.pumpWidget(area([30, 20, 10]));
      await t.pump(const Duration(milliseconds: 260));
      final m = mostra(t, SsAreaChart).first;
      expect(m[0], inExclusiveRange(10, 30));
      expect(m[1], 20);
      expect(m[2], inExclusiveRange(10, 30));
      await t.pumpAndSettle();
      expect(mostra(t, SsAreaChart).first, [30, 20, 10]);
    });

    testWidgets('outro número de pontos troca direto; reduzir movimento também', (t) async {
      await t.pumpWidget(
        _app(
          Scaffold(
            body: SsLineChart(
              labels: const ['a', 'b'],
              series: const [
                SsSeries([1, 2]),
              ],
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.pumpWidget(
        _app(
          Scaffold(
            body: SsLineChart(
              labels: const ['a', 'b', 'c'],
              series: const [
                SsSeries([5, 6, 7]),
              ],
            ),
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 100));
      expect(mostra(t, SsLineChart).first, [5, 6, 7]);

      await t.pumpWidget(area([10, 20, 30], reduce: true));
      await t.pumpAndSettle();
      await t.pumpWidget(area([30, 20, 10], reduce: true));
      await t.pump();
      expect(mostra(t, SsAreaChart).first, [30, 20, 10]);
    });

    testWidgets('barras, rosca e tempo trocam animados', (t) async {
      Widget tela(double k) => _app(
        Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                SsBarChart(
                  labels: const ['jan', 'fev'],
                  series: [
                    SsSeries([10 * k, 20 * k]),
                  ],
                ),
                SsExplodedDonut(slices: [SsDonutSlice('A', 10 * k), const SsDonutSlice('B', 10)]),
                SizedBox(
                  height: 320,
                  child: SsTimeChart(
                    series: [
                      SsTimeSeries(
                        name: 'Temperatura',
                        points: [
                          SsTimePoint(DateTime(2026, 11, 1), 10 * k),
                          SsTimePoint(DateTime(2026, 11, 2), null),
                          SsTimePoint(DateTime(2026, 11, 3), 12),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await t.pumpWidget(tela(1));
      await t.pumpAndSettle();
      await t.pumpWidget(tela(3));
      await t.pump(const Duration(milliseconds: 260));
      expect(mostra(t, SsBarChart).first[0], inExclusiveRange(10, 30));
      expect(mostra(t, SsExplodedDonut).first[0], inExclusiveRange(10, 30));
      final tempo = mostra(t, SsTimeChart).first;
      expect(tempo[0], inExclusiveRange(10, 30));
      expect(tempo[1].isNaN, isTrue);
      await t.pumpAndSettle();
      expect(mostra(t, SsBarChart).first, [30, 60]);
      expect(t.takeException(), isNull);
    });
  });

  group('estados vazios ilustrados', () {
    testWidgets('as cinco ilustrações desenham no SsEmptyState e são decorativas', (t) async {
      for (final i in SsIllustration.values) {
        await t.pumpWidget(
          _app(
            Scaffold(
              body: SsEmptyState(illustration: i, title: 'Título ${i.name}'),
            ),
          ),
        );
        await t.pump(const Duration(milliseconds: 700));
        expect(find.byType(SsIllustrationArt), findsOneWidget);
        expect(find.byIcon(SsIllustrationArt.iconOf(i)), findsOneWidget);
        expect(find.text('Título ${i.name}'), findsOneWidget);
      }
      expect(t.takeException(), isNull);
    });

    testWidgets('reduzir movimento: parada (assenta)', (t) async {
      await t.pumpWidget(
        _app(
          const Scaffold(
            body: SsEmptyState(illustration: SsIllustration.allDone, title: 'Tudo feito'),
          ),
          reduce: true,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Tudo feito'), findsOneWidget);
    });
  });

  group('comemoração', () {
    test('uma por sessão por tipo, com armazenamento injetado e escopo', () {
      final store = SsMemoryCelebrationStore();
      final g = SsCelebrationGate(store: store, scope: 'u1');
      expect(g.claim(SsCelebrationKind.goal), isTrue);
      expect(g.claim(SsCelebrationKind.goal), isFalse);
      expect(g.claim(SsCelebrationKind.streak), isTrue);
      expect(g.canCelebrate(SsCelebrationKind.firstUse), isTrue);
      expect(store.contains('ss-celebrate:u1:goal'), isTrue);
      expect(g.keyOf(SsCelebrationKind.firstUse), 'ss-celebrate:u1:first_use');
      g.reset(SsCelebrationKind.goal);
      expect(g.canCelebrate(SsCelebrationKind.goal), isTrue);
      g.reset();
      expect(g.canCelebrate(SsCelebrationKind.streak), isTrue);
    });

    testWidgets('SsCelebrate(kind:) comemora só a primeira vez na sessão e anuncia', (t) async {
      final g = SsCelebrationGate();
      final anuncios = <String>[];
      t.binding.defaultBinaryMessenger.setMockDecodedMessageHandler<dynamic>(SystemChannels.accessibility, (m) async {
        final data = (m as Map)['data'] as Map?;
        if (data?['message'] != null) anuncios.add('${data!['message']}');
        return null;
      });
      Widget tela(bool ok) => _app(
        Scaffold(
          body: SsCelebrate(achieved: ok, kind: SsCelebrationKind.goal, gate: g, child: const Text('R\$ 500')),
        ),
      );
      await t.pumpWidget(tela(false));
      await t.pumpWidget(tela(true));
      await t.pump();
      expect(g.canCelebrate(SsCelebrationKind.goal), isFalse);
      expect(anuncios, ['Meta batida!']);
      await t.pumpAndSettle(const Duration(milliseconds: 100));
      await t.pumpWidget(tela(false));
      await t.pumpWidget(tela(true));
      await t.pump();
      expect(anuncios, hasLength(1));
      await t.pumpAndSettle(const Duration(milliseconds: 100));
    });

    testWidgets('sequência: estouro em volta, sem confete', (t) async {
      final g = SsCelebrationGate();
      Widget tela(bool ok) => _app(
        Scaffold(
          body: Center(
            child: SsCelebrate(achieved: ok, kind: SsCelebrationKind.streak, gate: g, child: const Text('12 dias')),
          ),
        ),
      );
      await t.pumpWidget(tela(false));
      expect(find.byType(SsBurst), findsOneWidget);
      await t.pumpWidget(tela(true));
      await t.pump(const Duration(milliseconds: 100));
      expect(g.canCelebrate(SsCelebrationKind.streak), isFalse);
      await t.pumpAndSettle();
    });

    test('textos nos três idiomas', () {
      expect(SsCelebrationKind.goal.announcement(SsStrings.pt), 'Meta batida!');
      expect(SsCelebrationKind.streak.announcement(SsStrings.en), 'Streak kept!');
      expect(SsCelebrationKind.firstUse.announcement(SsStrings.es), '¡Primer paso dado!');
      expect(SsStrings.en.copyWith(celebrateGoal: 'Done!').celebrateGoal, 'Done!');
    });
  });
}
