import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

// v1.9 · paridade web: o paridade.yml (Flutter ↔ Rails) e a UX transversal (barra que some ao rolar,
// busca do menu lateral com Ctrl+K, sincronização completa, toque longo e deslizar no item, ssA11yAudit).

// ── O paridade.yml ────────────────────────────────────────────────────

/// Uma entrada do yml: os alvos e se está pendente da onda v1.9.
typedef ParEntrada = ({List<String> alvos, bool pendente});

/// Leitor do subconjunto de YAML que o paridade.yml usa: seções no topo e `  Chave: valor`, com valor
/// "texto", ["a", "b"] ou { rails: "x", pendente_v19: true }.
Map<String, Map<String, ParEntrada>> lerParidade(String texto) {
  final out = <String, Map<String, ParEntrada>>{};
  Map<String, ParEntrada>? atual;
  List<String> aspas(String s) => [for (final m in RegExp(r'"((?:[^"\\]|\\.)*)"').allMatches(s)) m.group(1)!];
  for (final linha in texto.split('\n')) {
    if (linha.trim().isEmpty || linha.trimLeft().startsWith('#')) continue;
    final secao = RegExp(r'^(\w+):\s*$').firstMatch(linha);
    if (secao != null) {
      atual = out[secao.group(1)!] = {};
      continue;
    }
    final e = RegExp(r'^  (\S+): (.+)$').firstMatch(linha);
    if (e == null || atual == null) throw FormatException('linha fora do formato: $linha');
    final v = e.group(2)!.trim();
    if (v.startsWith('{')) {
      atual[e.group(1)!] = (alvos: aspas(v), pendente: RegExp(r'pendente_v19:\s*true').hasMatch(v));
    } else {
      atual[e.group(1)!] = (alvos: aspas(v), pendente: false);
    }
  }
  return out;
}

const _classe = r'^(?:abstract |final |base |sealed |interface )*class (\w+)(?:<[^>{]*>)?(?:\s+extends\s+(\w+))?';
const _bases = {
  'StatelessWidget', 'StatefulWidget', 'InheritedWidget', 'SingleChildRenderObjectWidget', 'InheritedNotifier', //
  'InheritedTheme', 'LeafRenderObjectWidget', 'MultiChildRenderObjectWidget', 'ProxyWidget', //
  'ImplicitlyAnimatedWidget', 'AnimatedWidget', 'Widget', 'InheritedModel',
};

/// O que o pacote exporta (seguindo os `export` de lib/componentes_ui.dart, com show/hide): os widgets Ss* e
/// todos os nomes públicos de topo (classes e funções).
({Set<String> widgets, Set<String> nomes}) exportados() {
  final supers = <String, String?>{};
  for (final f in Directory(
    'lib/src',
  ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
    for (final m in RegExp(_classe, multiLine: true).allMatches(f.readAsStringSync())) {
      supers[m.group(1)!] = m.group(2);
    }
  }
  final nomes = <String>{};
  final classes = <String>{};
  void anda(String caminho, Set<String>? show, Set<String>? hide) {
    final src = File(caminho).readAsStringSync();
    bool vale(String n) => !n.startsWith('_') && (show == null || show.contains(n)) && !(hide?.contains(n) ?? false);
    for (final m in RegExp(_classe, multiLine: true).allMatches(src)) {
      if (vale(m.group(1)!)) {
        nomes.add(m.group(1)!);
        classes.add(m.group(1)!);
      }
    }
    for (final m in RegExp(
      r'^(?:Future<[^\n]*?>|void|[A-Z]\w*(?:<[^\n]*?>)?\??|String|bool|int|double) (\w+)(?:<[^>]*>)?\(',
      multiLine: true,
    ).allMatches(src)) {
      if (vale(m.group(1)!)) nomes.add(m.group(1)!);
    }
    for (final m in RegExp(r"^export '([^']+)'(?:\s+(show|hide)\s+([^;]+))?;", multiLine: true).allMatches(src)) {
      final alvo = File(caminho).parent.uri.resolve(m.group(1)!).toFilePath();
      final lista = m.group(3)?.split(',').map((s) => s.trim()).toSet();
      var s = m.group(2) == 'show' ? lista : null;
      if (show != null) s = (s ?? show).intersection(show);
      anda(alvo, s, m.group(2) == 'hide' ? lista : null);
    }
  }

  anda('lib/componentes_ui.dart', null, null);
  bool widget(String n, [int d = 0]) {
    final s = supers[n];
    return d < 20 && s != null && (_bases.contains(s) || widget(s, d + 1));
  }

  return (
    widgets: {
      for (final n in classes)
        if (n.startsWith('Ss') && widget(n)) n,
    },
    nomes: nomes,
  );
}

// ── Montagem dos testes de UX ─────────────────────────────────────────

const _abas = [
  SsNavItem(Icons.home_outlined, 'Início'),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos'),
  SsNavItem(Icons.menu, 'Mais'),
];

Widget _lista() =>
    ListView.builder(itemCount: 80, itemBuilder: (_, i) => SizedBox(height: 56, child: Text('Linha $i')));

/// Altura que a barra ocupa agora (a caixa que encolhe ao esconder).
double _alturaBarra(WidgetTester t) => t.getSize(find.byType(SsNavBar)).height;
double _alturaVisivel(WidgetTester t) {
  final box = find.ancestor(of: find.byType(SsNavBar), matching: find.byType(ClipRect));
  return box.evaluate().isEmpty ? _alturaBarra(t) : t.getSize(box.first).height;
}

void main() {
  group('paridade.yml', () {
    final yml = lerParidade(File('../paridade.yml').readAsStringSync());
    final exp = exportados();

    test('as seções e os motivos', () {
      expect(yml.keys.toSet(), {'pares', 'apis', 'so_app', 'so_web', 'divida', 'divida_app'});
      for (final s in ['so_app', 'so_web', 'divida', 'divida_app']) {
        for (final e in yml[s]!.entries) {
          expect(e.value.alvos.single.trim().length, greaterThan(10), reason: '$s.${e.key} sem motivo');
        }
      }
      expect(yml['pares']!.keys.toSet().intersection(yml['so_app']!.keys.toSet()), isEmpty);
    });

    test('todo widget Ss* exportado tem par ou exceção (peça num lado só falha aqui)', () {
      final registrados = {...yml['pares']!.keys, ...yml['so_app']!.keys, ...yml['divida']!.keys};
      final faltam = exp.widgets.difference(registrados).toList()..sort();
      expect(faltam, isEmpty, reason: 'widget sem par web nem exceção no paridade.yml: ${faltam.join(', ')}');
    });

    test('todo SsX do yml existe e é exportado pelo pacote (pendentes da v1.9 à parte)', () {
      final erros = <String>[];
      for (final s in ['pares', 'so_app', 'divida']) {
        for (final e in yml[s]!.entries) {
          if (e.value.pendente) continue;
          if (!exp.widgets.contains(e.key)) erros.add('$s.${e.key}');
        }
      }
      for (final n in yml['apis']!.keys) {
        if (!exp.nomes.contains(n)) erros.add('apis.$n');
      }
      expect(erros, isEmpty, reason: 'no yml mas não exportado: ${erros.join(', ')}');
    });

    test('todo par aponta para um alvo web no formato certo', () {
      final formato = RegExp(r'^(Ss::\w+Component|helper:ss_\w+|form:ss_\w+|css:\.ss-[a-z0-9-]+|js:ss-[a-z0-9-]+)$');
      for (final s in ['pares', 'apis']) {
        for (final e in yml[s]!.entries) {
          expect(e.value.alvos, isNotEmpty, reason: e.key);
          for (final a in e.value.alvos) {
            expect(formato.hasMatch(a), isTrue, reason: '${e.key} → $a');
          }
        }
      }
    });

    test('os pares que a v1.9 criou no web', () {
      expect(yml['pares']!['SsSwipeToConfirm']!.alvos, ['Ss::SwipeToConfirmComponent']);
      expect(yml['pares']!['SsOdometer']!.alvos, ['Ss::OdometerComponent']);
      expect(yml['pares']!['SsSyncStatus']!.alvos, ['Ss::SyncStatusComponent']);
      expect(yml['pares']!['SsGantt']!.pendente, isTrue);
      expect(yml['so_app']!.containsKey('SsSyncPanel'), isTrue);
    });

    test('o leitor do yml', () {
      final y = lerParidade(
        'pares:\n  SsA: "Ss::AComponent"\n  SsB: ["css:.ss-b", "helper:ss_b"]\n'
        '  SsC: { rails: "Ss::CComponent", pendente_v19: true }\n# nota\nso_app:\n  SsD: "um motivo qualquer"\n',
      );
      expect(y['pares']!['SsB']!.alvos, ['css:.ss-b', 'helper:ss_b']);
      expect(y['pares']!['SsC']!.pendente, isTrue);
      expect(y['so_app']!['SsD']!.alvos.single, 'um motivo qualquer');
      expect(() => lerParidade('pares:\nSsA: x\n'), throwsFormatException);
    });
  });

  group('SsNavBar(hideOnScroll:) e SsNavScaffold(hideNavOnScroll:)', () {
    testWidgets('a barra some ao rolar para baixo e volta ao rolar para cima', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: _lista(),
            bottomNavigationBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}, hideOnScroll: true),
          ),
        ),
      );
      final cheia = _alturaVisivel(t);
      expect(cheia, greaterThan(60));
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(_alturaVisivel(t), lessThan(1));
      await t.drag(find.byType(ListView), const Offset(0, 120));
      await t.pumpAndSettle();
      expect(_alturaVisivel(t), cheia);
    });

    testWidgets('sem hideOnScroll fica parada', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: _lista(),
            bottomNavigationBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
          ),
        ),
      );
      final h = _alturaVisivel(t);
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(_alturaVisivel(t), h);
    });

    testWidgets('com leitor de tela ligado não some', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(accessibleNavigation: true, size: Size(400, 800)),
            child: Scaffold(
              body: _lista(),
              bottomNavigationBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}, hideOnScroll: true),
            ),
          ),
        ),
      );
      final h = _alturaVisivel(t);
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(_alturaVisivel(t), h);
    });

    testWidgets('reduzir movimento: some sem animar', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true, size: Size(400, 800)),
            child: Scaffold(
              body: _lista(),
              bottomNavigationBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}, hideOnScroll: true),
            ),
          ),
        ),
      );
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pump();
      expect(_alturaVisivel(t), lessThan(1));
    });

    testWidgets('no SsNavScaffold o corpo ganha a altura da barra e trocar de aba mostra de novo', (t) async {
      var aba = 0;
      late StateSetter set;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: StatefulBuilder(
            builder: (context, s) {
              set = s;
              return SsNavScaffold(
                peek: false,
                hideNavOnScroll: true,
                navBar: SsNavBar(items: _abas, currentIndex: aba, onTap: (i) => s(() => aba = i)),
                body: _lista(),
              );
            },
          ),
        ),
      );
      final antes = t.getSize(find.byType(ListView)).height;
      await t.drag(find.byType(ListView), const Offset(0, -300));
      await t.pumpAndSettle();
      expect(_alturaVisivel(t), lessThan(1));
      expect(t.getSize(find.byType(ListView)).height, greaterThan(antes + 50));
      set(() => aba = 1);
      await t.pumpAndSettle();
      expect(_alturaVisivel(t), greaterThan(60));
    });
  });

  group('SsSideMenu(search:) e a paleta com registros', () {
    final telas = [
      SsCommand(Icons.receipt_long_outlined, 'Pedidos', group: 'Telas', onRun: () {}),
      SsCommand(Icons.people_outline, 'Clientes', group: 'Telas', onRun: () {}),
    ];
    Future<List<SsCommand>> registros(String q) async => [
      SsCommand(Icons.person_outline, 'Mercado $q', group: 'Clientes', onRun: () {}),
    ];
    Widget app() => MaterialApp(
      theme: AppTheme.light,
      home: SsNavScaffold(
        peek: false,
        navBar: SsNavBar(items: _abas, currentIndex: 0, onTap: (_) {}),
        sideMenu: SsSideMenu(
          title: 'Meu App',
          search: SsSideMenuSearch(commands: telas, records: registros),
        ),
        body: const SizedBox.expand(),
      ),
    );

    testWidgets('a linha Buscar no topo do menu abre a paleta e os registros chegam depois', (t) async {
      await t.pumpWidget(app());
      t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).open();
      await t.pumpAndSettle();
      expect(find.bySemanticsLabel('Buscar'), findsOneWidget);
      await t.tap(find.text('Buscar'));
      await t.pumpAndSettle();
      expect(find.byType(SsCommandPalette), findsOneWidget);
      expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).isOpen, isFalse);
      await t.enterText(find.byType(TextField), 'bom');
      await t.pump();
      expect(find.text('Mercado bom'), findsNothing); // ainda no intervalo da digitação
      await t.pump(const Duration(milliseconds: 300));
      await t.pump();
      expect(find.text('Mercado bom'), findsOneWidget);
      expect(find.byType(SsGroupHeader), findsOneWidget); // o grupo do registro
    });

    testWidgets('Ctrl+K abre a paleta com o menu fechado; com ela aberta não abre outra', (t) async {
      await t.pumpWidget(app());
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(find.byType(SsCommandPalette), findsOneWidget);
      await t.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await t.sendKeyEvent(LogicalKeyboardKey.keyK);
      await t.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await t.pumpAndSettle();
      expect(find.byType(SsCommandPalette), findsOneWidget);
    });

    test('o atalho mostrado por plataforma', () {
      expect(SsSideMenuSearch.shortcutLabel(TargetPlatform.windows), 'Ctrl K');
      expect(SsSideMenuSearch.shortcutLabel(TargetPlatform.macOS), '⌘K');
      expect(SsSideMenuSearch.shortcutLabel(TargetPlatform.android), isNull);
    });

    testWidgets('a busca que falha conta como nada achado', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SsCommandPalette(
              commands: telas,
              onSelected: (_) {},
              search: (q) async => throw Exception('sem rede'),
            ),
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'zzz');
      await t.pump(const Duration(milliseconds: 300));
      await t.pump();
      expect(find.textContaining('zzz'), findsWidgets);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });
  });

  group('SsSyncStatus completo e SsSyncPanel', () {
    test('resolve: a regra do minhas-vendas-app', () {
      expect(SsSyncStatus.resolve(syncing: true, failed: 2, pending: 3), SsSyncState.sending);
      expect(SsSyncStatus.resolve(failed: 1, offline: true), SsSyncState.failed);
      expect(SsSyncStatus.resolve(offline: true, pending: 2), SsSyncState.offline);
      expect(SsSyncStatus.resolve(pending: 2), SsSyncState.pending);
      expect(SsSyncStatus.resolve(), SsSyncState.synced);
    });

    test('rótulos: com erro, a última sincronização e os idiomas', () {
      expect(SsSyncStatus.label(SsSyncState.failed, 0, SsStrings.pt, 2), '2 com erro');
      expect(SsSyncStatus.label(SsSyncState.failed, 0), 'Falhou · Tentar de novo');
      final agora = DateTime(2026, 11, 24, 18);
      expect(
        SsSyncStatus.lastSyncedLabel(DateTime(2026, 11, 24, 14, 32), SsStrings.pt, agora),
        'Sincronizado às 14:32',
      );
      expect(SsSyncStatus.lastSyncedLabel(DateTime(2026, 11, 12, 9), SsStrings.pt, agora), 'Sincronizado em 12/11');
      expect(SsSyncStatus.lastSyncedLabel(null, SsStrings.en), 'Never synced');
      expect(SsSyncStatus.label(SsSyncState.failed, 0, SsStrings.es, 1), '1 con error');
    });

    testWidgets('a pílula leva a última sincronização ao leitor de tela', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Center(
              child: SsSyncStatus(state: SsSyncState.pending, pendingCount: 3, lastSyncedAt: DateTime.now()),
            ),
          ),
        ),
      );
      expect(find.bySemanticsLabel(RegExp(r'^3 a enviar, Sincronizado às \d\d:\d\d$')), findsOneWidget);
      h.dispose();
    });

    testWidgets('o painel: título, erro, a pílula e Sincronizar agora (carregando ao enviar)', (t) async {
      var cliques = 0;
      Widget painel(SsSyncState s) => MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SsSyncPanel(
            state: s,
            pendingCount: 2,
            failedCount: 1,
            lastSyncedAt: DateTime(2026, 11, 24, 14, 32),
            now: DateTime(2026, 11, 24, 18),
            error: 'Sem conexão: usando os dados do aparelho.',
            details: '120 clientes no aparelho',
            onSyncNow: () => cliques++,
          ),
        ),
      );
      await t.pumpWidget(painel(SsSyncState.failed));
      expect(find.text('Sincronizado às 14:32'), findsOneWidget);
      expect(find.text('1 com erro'), findsOneWidget);
      expect(find.text('Sem conexão: usando os dados do aparelho.'), findsOneWidget);
      await t.tap(find.text('Sincronizar agora'));
      expect(cliques, 1);
      await t.pumpWidget(painel(SsSyncState.sending));
      await t.pump();
      expect(find.text('Enviando…'), findsWidgets);
      await t.tap(find.byType(SsButton), warnIfMissed: false);
      expect(cliques, 1);
    });
  });

  group('SsListItem(contextActions:, swipeStart:, swipeEnd:)', () {
    testWidgets('toque longo abre o menu de contexto; o leitor de tela recebe as ações', (t) async {
      var editou = 0;
      final h = t.ensureSemantics();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SsListItem(
              title: 'Pedido 12',
              onTap: () {},
              contextActions: [SsContextAction(Icons.edit_outlined, 'Editar', () => editou++)],
            ),
          ),
        ),
      );
      final node = t.getSemantics(find.text('Pedido 12'));
      expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      await t.longPress(find.text('Pedido 12'));
      await t.pumpAndSettle();
      await t.tap(find.text('Editar'));
      await t.pumpAndSettle();
      expect(editou, 1);
      h.dispose();
    });

    testWidgets('deslizar para a esquerda dispara o swipeEnd', (t) async {
      var arquivou = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: SsListItem(
              title: 'Pedido 13',
              swipeEnd: SsSwipeSide(
                icon: Icons.archive_outlined,
                label: 'Arquivar',
                color: AppColors.danger,
                onTrigger: () => arquivou++,
              ),
            ),
          ),
        ),
      );
      await t.drag(find.text('Pedido 13'), const Offset(-500, 0));
      await t.pumpAndSettle();
      expect(arquivou, 1);
    });
  });

  group('ssA11yAudit', () {
    testWidgets('tela boa passa', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ListView(
              children: [
                SsListItem(title: 'Pedido 12', subtitle: 'Mercado Bom Preço', value: 'R\$ 120,00', onTap: () {}),
                SsButton(label: 'Salvar', onPressed: () {}),
              ],
            ),
          ),
        ),
      );
      await ssA11yAudit(t);
    });

    testWidgets('acusa alvo pequeno, botão sem rótulo e texto que estoura', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(40), // longe da borda: a regra do Flutter pula o que encosta nela
                  child: GestureDetector(onTap: () {}, child: const SizedBox(width: 20, height: 20)),
                ),
                // Cabe em 1×; com o texto em 1,6× a coluna estoura.
                const SizedBox(
                  height: 20,
                  child: Column(children: [Text('A', style: TextStyle(fontSize: 14, height: 1))]),
                ),
              ],
            ),
          ),
        ),
      );
      Object? erro;
      try {
        await ssA11yAudit(t);
      } on TestFailure catch (e) {
        erro = e;
      }
      expect('$erro', contains('48 × 48'));
      expect('$erro', contains('rótulo'));
      expect('$erro', contains('1.6x'));
      expect(t.platformDispatcher.textScaleFactor, 1.0); // devolveu o texto normal
    });
  });
}
