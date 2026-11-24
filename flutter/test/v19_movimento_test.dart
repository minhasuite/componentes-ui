// v1.9 · movimento: SsPagedList(onRefresh:) com altura, cores do sistema na aparência, tokens
// SsMotion, mapa de vibração (SsHaptics), skeleton que vira conteúdo e remoção com desfazer.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget body, {bool reduce = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: const Locale('pt'),
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Builder(
    builder: (context) => MediaQuery(
      data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
      child: Scaffold(body: body),
    ),
  ),
);

/// Grava as vibrações pedidas ao sistema.
List<String> _vibracoes(WidgetTester t) {
  final l = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') l.add('${call.arguments}');
    return null;
  });
  return l;
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => SsHaptics.enabled = true);

  group('SsPagedList', () {
    testWidgets('onRefresh: não quebra o layout (a lista tem altura) e puxa para atualizar', (t) async {
      var atualizou = 0;
      await t.pumpWidget(
        _app(
          SsPagedList<int>(
            items: List.generate(30, (i) => i),
            itemBuilder: (_, i) => SizedBox(height: 48, child: Text('item $i')),
            onLoadMore: () async {},
            hasMore: false,
            onRefresh: () async => atualizou++,
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('item 0'), findsOneWidget);
      await t.fling(find.text('item 0'), const Offset(0, 400), 1000);
      await t.pumpAndSettle();
      expect(atualizou, 1);
    });
  });

  group('cores do sistema', () {
    SsAppearanceController ctl({Color? cor, String? guardado}) => SsAppearanceController(
      brand: SsBrand.violeta,
      read: () async => guardado,
      write: (_) async {},
      systemColor: cor,
    );

    test('o JSON guarda "sistema" e lê de volta', () {
      const a = SsAppearance(paleta: SsAppearance.sistema);
      expect(a.toJson(), contains('"paleta":"sistema"'));
      expect(SsAppearance.fromJson(a.toJson()).paleta, 'sistema');
      expect(SsAppearance.fromJson('{"paleta":"nao-existe"}').paleta, isNull);
    });

    test('a marca sai da cor do sistema; sem ela, fica a do app', () async {
      final c = ctl(cor: const Color(0xFF3366CC), guardado: '{"paleta":"sistema"}');
      await c.load();
      expect(c.value.paleta, 'sistema');
      expect(identical(c.effectiveBrand, c.systemBrand), isTrue);
      expect(c.effectiveBrand.accentLight, const Color(0xFF3366CC));
      final sem = ctl(guardado: '{"paleta":"sistema"}');
      await sem.load();
      expect(sem.systemBrand, isNull);
      expect(identical(sem.effectiveBrand, SsBrand.violeta), isTrue);
    });

    test('cor clara do sistema é escurecida até o texto branco passar 4,5:1', () {
      final c = ctl(cor: const Color(0xFFFFE082));
      expect(ssContrast(c.systemBrand!.accentLight, AppColors.surfaceLight), greaterThanOrEqualTo(4.5));
    });

    test('trocar a cor do sistema avisa e refaz o tema', () {
      final c = ctl(cor: const Color(0xFF3366CC), guardado: null);
      c.set(const SsAppearance(paleta: SsAppearance.sistema));
      final antes = c.theme(Brightness.light);
      var avisos = 0;
      c.addListener(() => avisos++);
      c.systemColor = const Color(0xFF2E7D32);
      expect(avisos, 1);
      expect(identical(c.theme(Brightness.light), antes), isFalse);
      expect(c.effectiveBrand.accentLight, const Color(0xFF2E7D32));
    });

    testWidgets('o painel mostra "Cores do sistema" só com a cor e escolhe', (t) async {
      final sem = ctl();
      await t.pumpWidget(_app(SingleChildScrollView(child: SsAppearancePanel(controller: sem))));
      expect(find.text('Cores do sistema'), findsNothing);

      final c = ctl(cor: const Color(0xFF3366CC));
      await t.pumpWidget(_app(SingleChildScrollView(child: SsAppearancePanel(controller: c))));
      await t.pump();
      expect(find.text('Cores do sistema'), findsOneWidget);
      await t.tap(find.text('Cores do sistema'));
      await t.pumpAndSettle();
      expect(c.value.paleta, SsAppearance.sistema);
      expect(find.bySemanticsLabel('Cores do sistema'), findsOneWidget);
    });
  });

  group('SsMotion', () {
    test('a tabela única (e os nomes antigos iguais)', () {
      expect(SsMotion.short, const Duration(milliseconds: 180));
      expect(SsMotion.medium, const Duration(milliseconds: 280));
      expect(SsMotion.long, const Duration(milliseconds: 400));
      expect(SsMotion.fast, SsMotion.short);
      expect(SsMotion.base, SsMotion.medium);
      expect(SsMotion.slow, SsMotion.long);
      expect(SsMotion.standard, const Cubic(.2, 0, 0, 1));
      expect(SsMotion.enter, Curves.easeOutCubic);
      expect(SsMotion.exit, Curves.easeInCubic);
      expect(SsMotion.spring, Curves.easeOutBack);
      expect([SsMotion.distSmall, SsMotion.distMedium, SsMotion.distLarge], [4, 12, 24]);
    });
  });

  group('SsHaptics', () {
    testWidgets('cada nome tem a sua vibração e enabled desliga', (t) async {
      final v = _vibracoes(t);
      await SsHaptics.selection();
      await SsHaptics.limit();
      await SsHaptics.warning();
      await SsHaptics.error();
      expect(v, [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
      v.clear();
      SsHaptics.enabled = false;
      await SsHaptics.selection();
      await SsHaptics.success();
      expect(v, isEmpty);
    });

    testWidgets('segmentado e chave: seleção', (t) async {
      final v = _vibracoes(t);
      var valor = 0;
      var liga = false;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (_, set) => Column(
              children: [
                SsSegmented<int>(
                  segments: const [(0, 'Dia'), (1, 'Mês')],
                  value: valor,
                  onChanged: (n) => set(() => valor = n),
                ),
                SsSwitch(value: liga, onChanged: (n) => set(() => liga = n)),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('Mês'));
      await t.pumpAndSettle();
      await t.tap(find.byType(SsSwitch));
      await t.pumpAndSettle();
      expect(v, ['HapticFeedbackType.selectionClick', 'HapticFeedbackType.selectionClick']);
    });

    testWidgets('confirmação perigosa: atenção; toast de erro: erro', (t) async {
      final v = _vibracoes(t);
      await t.pumpWidget(
        _app(
          Builder(
            builder: (context) => Column(
              children: [
                TextButton(
                  onPressed: () => showSsConfirm(context, title: 'Excluir?', danger: true, confirmLabel: 'Excluir'),
                  child: const Text('abrir'),
                ),
                TextButton(
                  onPressed: () => showSsToast(context, 'Falhou', tone: AppColors.danger),
                  child: const Text('erro'),
                ),
              ],
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Excluir'));
      await t.pumpAndSettle();
      expect(v, ['HapticFeedbackType.mediumImpact']);
      await t.tap(find.text('erro'));
      await t.pump();
      expect(v.last, 'HapticFeedbackType.heavyImpact');
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
    });

    testWidgets('slider no limite: batida leve; no meio: seleção', (t) async {
      final v = _vibracoes(t);
      var x = 50.0;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (_, set) => Padding(
              padding: const EdgeInsets.all(24),
              child: SsSlider(value: x, min: 0, max: 100, step: 10, onChanged: (n) => set(() => x = n)),
            ),
          ),
        ),
      );
      final r = t.getRect(find.byType(SsSlider));
      await t.tapAt(Offset(r.right - 1, r.center.dy));
      await t.pumpAndSettle();
      expect(x, 100);
      expect(v.last, 'HapticFeedbackType.lightImpact');
      await t.tapAt(r.center);
      await t.pumpAndSettle();
      expect(v.last, 'HapticFeedbackType.selectionClick');
    });
  });

  group('skeleton que vira conteúdo', () {
    Widget corpo(AsyncValue<String> v, {bool reduce = false}) => _app(
      SsAsyncBody<String>(value: v, data: (s) => Text(s)),
      reduce: reduce,
    );

    testWidgets('SsAsyncBody: crossfade e subida do skeleton para o dado', (t) async {
      await t.pumpWidget(corpo(const AsyncValue.loading()));
      expect(find.byType(SkeletonList), findsOneWidget);
      await t.pumpWidget(corpo(const AsyncValue.data('Pronto')));
      await t.pump(const Duration(milliseconds: 100));
      // No meio: os dois na tela, o dado ainda transparente e abaixo do lugar.
      expect(find.byType(SkeletonList), findsOneWidget);
      final fade = t.widget<FadeTransition>(
        find.ancestor(of: find.text('Pronto'), matching: find.byType(FadeTransition)).first,
      );
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      final sobe = t.widget<Transform>(find.ancestor(of: find.text('Pronto'), matching: find.byType(Transform)).first);
      expect(sobe.transform.getTranslation().y, greaterThan(0));
      await t.pumpAndSettle();
      expect(find.byType(SkeletonList), findsNothing);
      expect(find.text('Pronto'), findsOneWidget);
    });

    testWidgets('revalidar com o dado na tela não anima', (t) async {
      await t.pumpWidget(corpo(const AsyncValue.data('A')));
      await t.pumpWidget(corpo(const AsyncValue.data('B')));
      await t.pump();
      expect(find.text('A'), findsNothing);
      expect(find.text('B'), findsOneWidget);
      expect(t.hasRunningAnimations, isFalse);
    });

    testWidgets('com menos movimento troca direto', (t) async {
      await t.pumpWidget(corpo(const AsyncValue.loading(), reduce: true));
      await t.pumpWidget(corpo(const AsyncValue.data('Pronto'), reduce: true));
      await t.pump();
      expect(find.byType(SkeletonList), findsNothing);
      expect(find.text('Pronto'), findsOneWidget);
    });

    testWidgets('SsAsyncSliver: a lista entra esmaecendo depois do skeleton', (t) async {
      Widget tela(AsyncValue<List<String>> v) => _app(
        CustomScrollView(
          slivers: [
            SsAsyncSliver<List<String>>(value: v, data: (l) => [for (final s in l) Text(s)]),
          ],
        ),
      );
      await t.pumpWidget(tela(const AsyncValue.loading()));
      await t.pumpWidget(tela(const AsyncValue.data(['um', 'dois'])));
      await t.pump(const Duration(milliseconds: 100));
      final fade = t.widget<SliverFadeTransition>(find.byType(SliverFadeTransition));
      expect(fade.opacity.value, inExclusiveRange(0, 1));
      await t.pumpAndSettle();
      expect(t.widget<SliverFadeTransition>(find.byType(SliverFadeTransition)).opacity.value, 1);
      expect(find.text('dois'), findsOneWidget);
    });

    testWidgets('SsAsyncSliver com o dado já pronto não anima', (t) async {
      await t.pumpWidget(
        _app(
          CustomScrollView(
            slivers: [
              SsAsyncSliver<List<String>>(
                value: const AsyncValue.data(['um']),
                data: (l) => [for (final s in l) Text(s)],
              ),
            ],
          ),
        ),
      );
      expect(t.widget<SliverFadeTransition>(find.byType(SliverFadeTransition)).opacity.value, 1);
    });
  });

  group('SsUndoableRemoval', () {
    Future<(List<String>, List<String>)> monta(WidgetTester t, {Future<void> Function()? commit}) async {
      final itens = ['Arroz', 'Feijão', 'Café'];
      final feitos = <String>[];
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (_, set) => ListView(
              children: [
                for (final i in itens)
                  SsUndoableRemoval(
                    key: ValueKey(i),
                    message: '$i removido',
                    onCommit: commit ?? () async => feitos.add(i),
                    onRemoved: () => set(() => itens.remove(i)),
                    builder: (_, remove) => ListTile(
                      title: Text(i),
                      trailing: IconButton(tooltip: 'Remover $i', icon: const Icon(Icons.close), onPressed: remove),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
      return (itens, feitos);
    }

    double altura(WidgetTester t, String i) => t.getSize(find.byKey(ValueKey(i))).height;

    testWidgets('sai encolhendo e o desfazer traz de volta no mesmo lugar', (t) async {
      final v = _vibracoes(t);
      final (itens, feitos) = await monta(t);
      final cheio = altura(t, 'Feijão');
      await t.tap(find.byTooltip('Remover Feijão'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 100));
      expect(altura(t, 'Feijão'), inExclusiveRange(0, cheio));
      await t.pump(const Duration(milliseconds: 400));
      expect(altura(t, 'Feijão'), 0);
      expect(find.text('Feijão removido'), findsOneWidget);
      expect(v.first, 'HapticFeedbackType.mediumImpact');
      await t.tap(find.text('Desfazer'));
      await t.pumpAndSettle();
      expect(altura(t, 'Feijão'), cheio);
      expect(t.getTopLeft(find.text('Feijão')).dy, greaterThan(t.getTopLeft(find.text('Arroz')).dy));
      expect(t.getTopLeft(find.text('Feijão')).dy, lessThan(t.getTopLeft(find.text('Café')).dy));
      expect(feitos, isEmpty);
      expect(itens, hasLength(3));
    });

    testWidgets('sem desfazer: executa e tira da lista', (t) async {
      final (itens, feitos) = await monta(t);
      await t.tap(find.byTooltip('Remover Arroz'));
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      expect(feitos, ['Arroz']);
      expect(itens, ['Feijão', 'Café']);
      expect(find.text('Arroz'), findsNothing);
    });

    testWidgets('a exclusão falhou: volta e avisa o erro', (t) async {
      final v = _vibracoes(t);
      final (itens, _) = await monta(t, commit: () async => throw Exception('rede'));
      final cheio = altura(t, 'Café');
      await t.tap(find.byTooltip('Remover Café'));
      await t.pump();
      await t.pump(const Duration(seconds: 6));
      for (var i = 0; i < 10; i++) {
        await t.pump(const Duration(milliseconds: 100));
      }
      expect(altura(t, 'Café'), cheio);
      expect(itens, hasLength(3));
      expect(find.text(SsStrings.pt.genericError), findsOneWidget);
      expect(v.last, 'HapticFeedbackType.heavyImpact');
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
    });
  });
}
