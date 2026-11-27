// v1.14.0 "interface e animação": o arrastar dos gráficos (SsScrubDetector e o scrub:/onScrub: dos quatro), o
// SsPeriodCompare, a SsExpandableRow, a folha com alturas (showSsSheet(detents:)), o ícone animado da barra, o
// SsMeshBackground (contraste em toda paleta), o odômetro no KPI, o cabeçalho que ganha cor, o SsSuccessCheck (com
// o gancho do som), o SsTiltCard, a troca de aba (SsSharedAxisTransition/SsTabHero) e o SsSkeleton.of, com os
// textos pt/en/es (as mesmas chaves do componentes_ui.interface.* da gem) e o ssA11yAudit.
import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {bool reduce = false, bool scroll = true, Locale locale = const Locale('pt', 'BR')}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      locale: locale,
      supportedLocales: SsStrings.supportedLocales,
      localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduce),
        child: child!,
      ),
      home: Scaffold(
        body: scroll ? SingleChildScrollView(padding: const EdgeInsets.all(16), child: child) : child,
      ),
    );

Future<void> _pump(WidgetTester t, Widget w, {bool reduce = false, bool scroll = true}) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(_app(w, reduce: reduce, scroll: scroll));
  await t.pump();
}

/// Conta as vibrações (HapticFeedback.vibrate pelo canal da plataforma).
List<String> _vibra(WidgetTester t) {
  final v = <String>[];
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') v.add('${call.arguments}');
    return null;
  });
  return v;
}

const _dias = ['01/11', '05/11', '10/11', '15/11', '20/11', '25/11', '30/11'];
const _nov = <double>[320.0, 540, 410, 880, 760, 1020, 940];
const _out = <double>[280.0, 460, 520, 610, 700, 760, 820];

/// As chaves de `componentes_ui.interface` num locale da gem (o bloco indentado logo abaixo de `interface:`).
Set<String> _chavesGem(String locale) {
  final f = File('../rails/config/locales/componentes_ui.$locale.yml');
  if (!f.existsSync()) return {};
  final linhas = f.readAsLinesSync();
  final i = linhas.indexWhere((l) => RegExp(r'^\s+interface:\s*$').hasMatch(l));
  if (i < 0) return {};
  final recuo = linhas[i].indexOf('interface');
  final out = <String>{};
  for (final l in linhas.skip(i + 1)) {
    if (l.trim().isEmpty) continue;
    final r = l.length - l.trimLeft().length;
    if (r <= recuo) break;
    final m = RegExp(r'^\s+(\w+):').firstMatch(l);
    if (m != null && r == recuo + 2) out.add(m.group(1)!);
  }
  return out;
}

String _snake(String k) => k.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m.group(0)!.toLowerCase()}');

void main() {
  setUp(() {
    SsHaptics.enabled = true;
    SsSounds.player = null;
    SsSounds.enabled = true;
  });

  group('textos e tokens', () {
    test('pt, en e es com as mesmas chaves e os mesmos moldes %{x}', () {
      Set<String> moldes(String s) => {for (final m in RegExp(r'%\{(\w+)\}').allMatches(s)) m.group(1)!};
      final pt = SsInterfaceStrings.pt.all;
      for (final o in [SsInterfaceStrings.en.all, SsInterfaceStrings.es.all]) {
        expect(o.keys, pt.keys);
        for (final k in pt.keys) {
          expect(moldes(o[k]!), moldes(pt[k]!), reason: k);
          expect(o[k], isNotEmpty);
        }
      }
      expect(SsInterfaceStrings.forLocale(const Locale('es')).expandSave, 'Guardar');
      expect(SsInterfaceStrings.fill(SsInterfaceStrings.pt.sheetSize, {'percent': 50}), '50% da tela');
    });

    test('as mesmas chaves no componentes_ui.interface.* da gem (pt-BR, en, es)', () {
      final esperadas = {for (final k in SsInterfaceStrings.pt.all.keys) _snake(k)};
      for (final l in ['pt-BR', 'en', 'es']) {
        final gem = _chavesGem(l);
        if (gem.isEmpty) continue; // gem sem o bloco ainda: o teste do Rails cobre
        expect(gem.containsAll(esperadas), isTrue, reason: '$l: faltam ${esperadas.difference(gem)}');
      }
    });

    test('nenhuma duração solta nas peças da v1.14 (SsMotion)', () {
      for (final f in Directory('lib/src/v1140').listSync().whereType<File>()) {
        expect(f.readAsStringSync(), isNot(contains('milliseconds:')), reason: f.path);
      }
      expect(SsMotion.pulse, const Duration(milliseconds: 1100));
      expect(SsMotion.ambient.inSeconds, 24);
    });
  });

  group('scrub dos gráficos', () {
    test('SsScrubDetector.indexAt: pontos e vagas', () {
      expect(SsScrubDetector.indexAt(0, 300, 7), 0);
      expect(SsScrubDetector.indexAt(300, 300, 7), 6);
      expect(SsScrubDetector.indexAt(150, 300, 7), 3);
      expect(SsScrubDetector.indexAt(-40, 300, 7), 0);
      expect(SsScrubDetector.indexAt(10, 300, 3, slots: true), 0);
      expect(SsScrubDetector.indexAt(299, 300, 3, slots: true), 2);
      expect(SsScrubDetector.indexAt(5, 0, 3), 0);
    });

    testWidgets('SsLineChart: arrastar avisa cada ponto, vibra a cada um e solta com nulo', (t) async {
      final v = _vibra(t);
      final vistos = <int?>[];
      await _pump(
        t,
        SsLineChart(
          labels: _dias,
          series: const [SsSeries(_nov, name: 'Gastos')],
          onScrub: vistos.add,
        ),
      );
      final r = t.getRect(find.byType(SsLineChart));
      final g = await t.startGesture(Offset(r.left + 6, r.center.dy));
      for (var x = 6.0; x < r.width - 6; x += 20) {
        await g.moveTo(Offset(r.left + x, r.center.dy));
        await t.pump();
      }
      await g.up();
      await t.pump();
      expect(vistos.whereType<int>().toSet().length, greaterThanOrEqualTo(5));
      expect(vistos.last, isNull);
      expect(v.where((x) => x.contains('selectionClick')).length, greaterThanOrEqualTo(5));
    });

    testWidgets('SsLineChart: o mouse mostra o balão e sai com nulo; scrub: false fica parado', (t) async {
      final vistos = <int?>[];
      await _pump(
        t,
        SsLineChart(
          labels: _dias,
          series: const [SsSeries(_nov, name: 'Gastos')],
          onScrub: vistos.add,
        ),
      );
      final r = t.getRect(find.byType(SsLineChart));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset(r.left - 20, r.top - 20));
      await mouse.moveTo(r.center);
      await t.pump();
      expect(vistos.last, 3);
      expect(find.text('15/11'), findsWidgets); // o rótulo no balão
      await mouse.moveTo(Offset(r.right + 40, r.bottom + 40));
      await t.pump();
      expect(vistos.last, isNull);
      await mouse.removePointer();

      vistos.clear();
      await _pump(t, SsLineChart(labels: _dias, series: const [SsSeries(_nov)], scrub: false, onScrub: vistos.add));
      await t.drag(find.byType(SsLineChart), const Offset(120, 0));
      await t.pump();
      expect(vistos, isEmpty);
    });

    testWidgets('SsBarChart, SsAreaChart e SsTimeChart: o índice/instante sob o dedo', (t) async {
      final barras = <int?>[];
      await _pump(t, SsBarChart(labels: _dias, series: const [SsSeries(_nov)], onScrub: barras.add));
      await t.tapAt(t.getRect(find.byType(SsBarChart)).centerLeft + const Offset(10, -20));
      await t.pump();
      expect(barras, [0]);

      final area = <int?>[];
      await _pump(t, SsAreaChart(values: _nov, labels: _dias, onScrub: area.add));
      final r = t.getRect(find.byType(SsAreaChart));
      final g = await t.startGesture(r.centerLeft + const Offset(14, 0));
      await g.moveTo(r.centerRight - const Offset(14, 0));
      await t.pump();
      expect(find.textContaining('30/11 ·'), findsNothing); // pintado no canvas: só o índice conta
      await g.up();
      await t.pump();
      expect(area.whereType<int>(), contains(6));
      expect(area.last, isNull);

      final tempo = <DateTime?>[];
      final ini = DateTime(2026, 11, 27);
      await _pump(
        t,
        SsTimeChart(
          series: [
            SsTimeSeries(
              name: 'Sala',
              unit: '°C',
              points: [for (var i = 0; i < 6; i++) SsTimePoint(ini.add(Duration(hours: i)), 20.0 + i)],
            ),
          ],
          onScrub: tempo.add,
        ),
      );
      await t.pump(const Duration(seconds: 1));
      final rt = t.getRect(find.byType(SsTimeChart));
      final mouse = await t.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: rt.topLeft - const Offset(10, 10));
      await mouse.moveTo(rt.topLeft + Offset(rt.width / 2, 40));
      await t.pump();
      expect(tempo.last, isNotNull);
      await mouse.moveTo(rt.bottomRight + const Offset(40, 40));
      await t.pump();
      expect(tempo.last, isNull);
      await mouse.removePointer();
    });
  });

  group('SsPeriodCompare', () {
    testWidgets('total, diferença, legenda, troca de período e o ponto sob o dedo', (t) async {
      final h = t.ensureSemantics();
      var periodo = -1;
      final pontos = <int?>[];
      await _pump(
        t,
        SsPeriodCompare(
          title: 'Gastos do mês',
          labels: _dias,
          current: _nov,
          previous: _out,
          currentLabel: 'Novembro',
          previousLabel: 'Outubro',
          higherIsBetter: false,
          format: (v) => money((v * 100).round()),
          periods: const ['Semana', 'Mês', 'Ano'],
          period: 1,
          onPeriodChanged: (i) => periodo = i,
          onScrub: pontos.add,
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Gastos do mês'), findsOneWidget);
      expect(find.text('Novembro'), findsOneWidget);
      expect(find.text('Outubro'), findsOneWidget);
      // 4870 × 4150 → +17,3%, despesa subindo: ruim.
      expect(find.text('17%'), findsOneWidget);
      final delta = t.widget<SsDelta>(find.byType(SsDelta));
      expect(delta.up, isTrue);
      expect(delta.good, isFalse);
      expect(find.bySemanticsLabel(RegExp(r'neste período, .* no anterior')), findsOneWidget);
      await t.tap(find.text('Ano'));
      await t.pump();
      expect(periodo, 2);
      await t.tapAt(t.getRect(find.byType(SsLineChart)).centerRight - const Offset(6, 0));
      await t.pump();
      expect(pontos.last, 6);
      expect(find.text('30/11 · em relação ao período anterior'), findsOneWidget);
      expect(SsPeriodCompare.change(110, 100), closeTo(10, .001));
      expect(SsPeriodCompare.change(5, 0), isNull);
      await ssA11yAudit(t);
      h.dispose();
    });
  });

  group('SsExpandableRow', () {
    testWidgets('abre no lugar com o foco no 1º campo; Esc cancela; salvar false fica, true fecha', (t) async {
      var resposta = false;
      var cancelou = 0;
      final v = _vibra(t);
      await _pump(
        t,
        SsExpandableRow(
          title: 'Mercado Bom Preço',
          subtitle: '26/11',
          value: r'R$ 214,90',
          onCancel: () => cancelou++,
          onSave: () async => resposta,
          editor: (_) => Column(
            children: [
              SsTextField(key: const Key('valor'), label: 'Valor', onChanged: (_) {}),
              SsTextField(label: 'Observação', onChanged: (_) {}),
            ],
          ),
        ),
      );
      expect(find.byKey(const Key('valor')), findsNothing);
      await t.tap(find.text('Mercado Bom Preço'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('valor')), findsOneWidget);
      final campo = find.descendant(of: find.byKey(const Key('valor')), matching: find.byType(EditableText));
      expect(t.widget<EditableText>(campo).focusNode.hasFocus, isTrue);
      await ssA11yAudit(t);

      await t.sendKeyEvent(LogicalKeyboardKey.escape);
      await t.pumpAndSettle();
      expect(cancelou, 1);
      expect(find.byKey(const Key('valor')), findsNothing);

      await t.tap(find.text('Mercado Bom Preço'));
      await t.pumpAndSettle();
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('valor')), findsOneWidget);
      resposta = true;
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(find.byKey(const Key('valor')), findsNothing);
      expect(v, isNotEmpty);
    });

    testWidgets('em inglês e com reduzir movimento', (t) async {
      await t.pumpWidget(
        _app(
          SsExpandableRow(title: 'Item', expanded: true, onSave: () => true, editor: (_) => const Text('x')),
          locale: const Locale('en'),
          reduce: true,
        ),
      );
      await t.pump();
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('folha com alturas', () {
    test('SsDetentSheet.target: a mais perto de onde o gesto levaria; abaixo da menor, fecha', () {
      const ds = [.33, .5, 1.0];
      expect(SsDetentSheet.target(ds, .52, 0), 1);
      expect(SsDetentSheet.target(ds, .52, 4), 2); // jogou para cima
      expect(SsDetentSheet.target(ds, .4, -1), 0);
      expect(SsDetentSheet.target(ds, .2, -1), isNull);
      expect(SsDetentSheet.target(ds, .2, -1, dismissible: false), 0);
    });

    testWidgets('showSsSheet(detents:): abre na inicial, arrasta, a alça no leitor de tela', (t) async {
      final h = t.ensureSemantics();
      final v = _vibra(t);
      await _pump(
        t,
        Builder(
          builder: (context) => SsButton(
            label: 'Abrir',
            onPressed: () => showSsSheet<void>(
              context,
              title: 'Filtros',
              detents: const [.33, .5, 1],
              initialDetent: 1,
              child: const Text('Conteúdo'),
            ),
          ),
        ),
      );
      await t.tap(find.text('Abrir'));
      await t.pumpAndSettle();
      final tela = t.view.physicalSize.height / t.view.devicePixelRatio;
      double altura() => t.getSize(find.byType(SsDetentSheet)).height;
      expect(altura(), lessThan(tela * .6));
      expect(find.bySemanticsLabel('Alça da folha'), findsOneWidget);
      expect(t.getSemantics(find.bySemanticsLabel('Alça da folha')).value, '50% da tela');
      await t.drag(find.bySemanticsLabel('Alça da folha'), Offset(0, -tela * .4));
      await t.pumpAndSettle();
      expect(altura(), greaterThan(tela * .8));
      expect(v, isNotEmpty);
      // Tocar na alça, na maior, volta à menor.
      await t.tap(find.bySemanticsLabel('Alça da folha'));
      await t.pumpAndSettle();
      expect(altura(), lessThan(tela * .4));
      await ssA11yAudit(t);
      // Arrastar bem para baixo fecha.
      await t.drag(find.bySemanticsLabel('Alça da folha'), Offset(0, tela * .3));
      await t.pumpAndSettle();
      expect(find.text('Conteúdo'), findsNothing);
      h.dispose();
    });
  });

  group('barra e cabeçalho', () {
    testWidgets('SsNavItem(animatedIcon:): no meio do pulo os dois ícones cruzam; no fim, só o cheio', (t) async {
      var aba = 0;
      Widget barra() => SsNavBar(
        currentIndex: aba,
        onTap: (i) {},
        items: const [
          SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
          SsNavItem(Icons.receipt_long_outlined, 'Pedidos', activeIcon: Icons.receipt_long_rounded),
        ],
      );
      await t.pumpWidget(_app(barra(), scroll: false));
      await t.pumpAndSettle();
      aba = 1;
      await t.pumpWidget(_app(barra(), scroll: false));
      await t.pump(SsMotion.indicator * .7);
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
      expect(find.byType(Transform), findsWidgets);
      await t.pumpAndSettle();
      expect(find.byIcon(Icons.receipt_long_rounded), findsOneWidget);
    });

    testWidgets('SsScreenHeader(collapseTint:): transparente aberto, superfície ao rolar', (t) async {
      await t.pumpWidget(
        _app(
          SsScreenHeader(
            title: 'Pedidos',
            collapseTint: true,
            slivers: [
              SliverList.list(children: [for (var i = 0; i < 30; i++) SsListItem(title: 'Pedido $i')]),
            ],
          ),
          scroll: false,
        ),
      );
      await t.pump();
      Color fundo() => t
          .widget<Material>(find.descendant(of: find.byType(SsSliverHeader), matching: find.byType(Material)).first)
          .color!;
      expect(fundo().a, 0);
      await t.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await t.pump();
      expect(fundo(), SsColors.forDark(false).surface);
    });
  });

  group('SsMeshBackground', () {
    test('o texto claro passa de 4,5:1 sobre a mancha mais clara, em toda paleta, claro e escuro', () {
      for (final p in SsPaleta.todas) {
        for (final dark in [false, true]) {
          final c = SsColors.forDark(dark, p.brand);
          final cores = [c.brandFrom, c.brandTo, c.accentBright, c.accent];
          final veu = SsMeshBackground.veilFor(c.brandDeep, cores);
          for (final x in cores) {
            expect(
              SsMeshBackground.contrastOnDark(SsMeshBackground.worst(c.brandDeep, x, veu)),
              greaterThanOrEqualTo(4.5),
              reason: '${p.slug} ${dark ? 'escuro' : 'claro'}',
            );
          }
        }
      }
    });

    testWidgets('anda (uma animação contínua) e para com reduzir movimento', (t) async {
      await _pump(t, const SsHeroCard(mesh: true, label: 'Saldo', value: r'R$ 4.870,00'));
      expect(t.binding.hasScheduledFrame, isTrue);
      expect(find.text(r'R$ 4.870,00'), findsOneWidget);
      await _pump(t, const SsHeroCard(mesh: true, label: 'Saldo', value: r'R$ 4.870,00'), reduce: true);
      await t.pumpAndSettle(); // parado: termina
      await _pump(t, SsHeroCard.custom(mesh: true, child: const Text('Olá')));
      expect(find.text('Olá'), findsOneWidget);
      await ssA11yAudit(t);
    });
  });

  group('odômetro e check', () {
    testWidgets('SsKpiCard rola por padrão (o leitor ouve o valor); animate: false é texto', (t) async {
      final h = t.ensureSemantics();
      await _pump(t, const SsKpiCard(label: 'Vendas', value: r'R$ 8.240,50'));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(SsOdometer), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(r'8\.240,50')), findsWidgets);
      await _pump(t, const SsKpiCard(label: 'Vendas', value: r'R$ 8.240,50', animate: false));
      await t.pump(const Duration(seconds: 2));
      expect(find.byType(SsOdometer), findsNothing);
      await _pump(t, const SsAmount(r'R$ 12,50', animate: true));
      expect(find.byType(SsOdometer), findsOneWidget);
      await _pump(t, const SsStatCard(label: 'Pedidos', value: '42'));
      expect(find.byType(SsOdometer), findsOneWidget);
      h.dispose();
    });

    testWidgets('SsSuccessCheck: vibra, chama o som do app só com sound:, lido como Concluído', (t) async {
      final h = t.ensureSemantics();
      final v = _vibra(t);
      final sons = <SsSound>[];
      SsSounds.player = sons.add;
      await _pump(t, const SsSuccessCheck());
      await t.pumpAndSettle();
      expect(v, isNotEmpty);
      expect(sons, isEmpty);
      expect(find.bySemanticsLabel('Concluído'), findsOneWidget);
      await _pump(t, const SsSuccessCheck(sound: true, haptic: false, label: 'Pago'));
      await t.pumpAndSettle();
      expect(sons, [SsSound.success]);
      expect(find.bySemanticsLabel('Pago'), findsOneWidget);
      SsSounds.enabled = false;
      await _pump(t, const SsSuccessCheck(sound: true, haptic: false));
      await t.pumpAndSettle();
      expect(sons.length, 1);
      // play: false espera; ao ligar, desenha.
      var fim = 0;
      await _pump(t, SsSuccessCheck(play: false, haptic: false, onDone: () => fim++));
      await t.pumpAndSettle();
      expect(fim, 0);
      await t.pumpWidget(_app(SsSuccessCheck(haptic: false, onDone: () => fim++)));
      await t.pumpAndSettle();
      expect(fim, 1);
      h.dispose();
    });

    testWidgets('o ✓ no fim do SsMorphButton e do SsSwipeToConfirm', (t) async {
      await _pump(t, SsMorphButton(label: 'Enviar', onPressed: () async {}));
      await t.tap(find.text('Enviar'));
      await t.pump();
      await t.pump(SsMotion.long);
      expect(find.byType(SsSuccessCheck), findsOneWidget);
      await t.pumpAndSettle();
      await _pump(t, const SsSwipeToConfirm(label: 'Pagar', onConfirm: null, done: true));
      expect(find.byType(SsSuccessCheck), findsOneWidget);
    });
  });

  group('SsTiltCard', () {
    testWidgets('inclina sob o dedo e volta; desligado com reduzir movimento e enabled: false', (t) async {
      Matrix4? matriz() {
        final f = find.descendant(of: find.byType(SsTiltCard), matching: find.byType(Transform));
        return f.evaluate().isEmpty ? null : t.widget<Transform>(f.first).transform;
      }

      await _pump(t, const SsTiltCard(child: SizedBox(height: 120, width: 300, child: Text('Plano Pro'))));
      final r = t.getRect(find.byType(SsTiltCard));
      final g = await t.startGesture(r.topLeft + const Offset(10, 10));
      await t.pump();
      expect(matriz(), isNot(Matrix4.identity()));
      await g.up();
      await t.pumpAndSettle();
      expect(matriz()!.storage[8].abs(), lessThan(1e-6));
      await _pump(t, const SsTiltCard(child: Text('Plano Pro')), reduce: true);
      expect(matriz(), isNull);
      await _pump(t, const SsTiltCard(enabled: false, child: Text('Plano Pro')));
      expect(matriz(), isNull);
    });
  });

  group('entre abas', () {
    testWidgets('SsNavScaffold: a aba nova entra esmaecendo e o SsTabHero voa; null troca seco', (t) async {
      var aba = 0;
      late StateSetter set;
      Widget tela(int i) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (i == 1) const SizedBox(height: 200),
            const SsTabHero(
              tag: 'saldo',
              child: SizedBox(width: 120, height: 40, child: Text('Saldo')),
            ),
          ],
        ),
      );
      Widget app(SsSharedAxis? tr) => MaterialApp(
        theme: AppTheme.light,
        localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
        home: StatefulBuilder(
          builder: (context, s) {
            set = s;
            return SsNavScaffold(
              tabTransition: tr,
              peek: false,
              body: IndexedStack(index: aba, children: [tela(0), tela(1)]),
              navBar: SsNavBar(
                currentIndex: aba,
                onTap: (i) => set(() => aba = i),
                items: const [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.list_alt_outlined, 'Extrato')],
              ),
            );
          },
        ),
      );
      await t.pumpWidget(app(SsSharedAxis.fadeThrough));
      await t.pumpAndSettle();
      set(() => aba = 1);
      await t.pump();
      await t.pump(SsMotion.short * .5);
      final op = find.ancestor(of: find.byType(IndexedStack), matching: find.byType(Opacity));
      expect(op, findsWidgets);
      expect(t.widget<Opacity>(op.first).opacity, lessThan(1));
      // O voo: uma cópia do "Saldo" no Overlay (com a de destino escondida).
      expect(find.text('Saldo', skipOffstage: false), findsNWidgets(3));
      await t.pumpAndSettle();
      expect(find.text('Saldo', skipOffstage: false), findsNWidgets(2));

      await t.pumpWidget(app(null));
      await t.pumpAndSettle();
      set(() => aba = 0);
      await t.pump();
      expect(find.ancestor(of: find.byType(IndexedStack), matching: find.byType(SsSharedAxisTransition)), findsNothing);
    });
  });

  group('SsSkeleton.of', () {
    testWidgets('blocos no lugar do texto, fora do leitor de tela e do toque', (t) async {
      final h = t.ensureSemantics();
      var tocou = 0;
      await _pump(
        t,
        SsSkeleton.of(
          SsListItem(title: 'Mercado Bom Preço', subtitle: '26/11', value: r'R$ 214,90', onTap: () => tocou++),
        ),
      );
      await t.pump(const Duration(milliseconds: 500));
      expect(find.bySemanticsLabel('Carregando…'), findsOneWidget);
      expect(find.bySemanticsLabel('Mercado Bom Preço'), findsNothing);
      await t.tap(find.byType(SsSkeleton), warnIfMissed: false);
      expect(tocou, 0);
      await ssA11yAudit(t);
      h.dispose();
      // Parado com reduzir movimento (o pumpAndSettle termina).
      await _pump(t, SsSkeleton.of(const Text('Olá')), reduce: true);
      await t.pumpAndSettle();
    });
  });
}
