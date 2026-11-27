// v1.13.0 "confiança na IA e suíte": o valor falado (SsSpeech contra docs/v1130/fala.json, os mesmos casos do Ruby e do
// JS), o estado no link (SsHandoff contra docs/v1130/handoff.json), os textos pt/en/es e as peças SsExplain,
// SsAiActionPreview, SsSinceLastVisit, SsContinueOn, SsSuiteSwitcher, SsConflictResolver, SsMoneyField(onVoice:),
// SsPrivacyScope(auto:), SsChatActionCard(onReview:) e SsSyncPanel(conflictCount:), com o ssA11yAudit.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _fala = jsonDecode(File('../docs/v1130/fala.json').readAsStringSync()) as Map<String, dynamic>;
final _handoff = jsonDecode(File('../docs/v1130/handoff.json').readAsStringSync()) as Map<String, dynamic>;

Widget _app(Widget child, {SsDensity density = SsDensity.standard, Locale locale = const Locale('pt', 'BR')}) =>
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.build(Brightness.light, density: density),
      locale: locale,
      supportedLocales: SsStrings.supportedLocales,
      localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
      home: Scaffold(
        body: SingleChildScrollView(padding: const EdgeInsets.all(16), child: child),
      ),
    );

Future<void> _pump(WidgetTester t, Widget w, {SsDensity density = SsDensity.standard, Locale? locale}) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(_app(w, density: density, locale: locale ?? const Locale('pt', 'BR')));
  await t.pump();
}

String? _clip;
void _mockClipboard(WidgetTester t) {
  _clip = null;
  t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') _clip = (call.arguments as Map)['text'] as String;
    if (call.method == 'Clipboard.getData') return {'text': _clip};
    return null;
  });
}

final _agora = DateTime(2026, 11, 27, 10);

const _mudancas = [
  SsAiChange(
    id: 'l1',
    title: 'Mercado Bom Preço',
    subtitle: 'Lançamento de 26/11',
    fields: [
      SsFieldDiff('Categoria', before: 'Outros', after: 'Mercado'),
      SsFieldDiff('Etiqueta', after: 'Casa'),
      SsFieldDiff('Valor', before: r'R$ 214,90', after: r'R$ 214,90'),
    ],
  ),
  SsAiChange(
    id: 'l2',
    title: 'Posto Avenida',
    fields: [SsFieldDiff('Observação', before: 'duplicado?')],
  ),
  SsAiChange(
    id: 'l3',
    title: 'Farmácia',
    fields: [SsFieldDiff('Categoria', before: 'Outros', after: 'Saúde')],
    selected: false,
  ),
];

void main() {
  group('valor falado', () {
    final casos = (_fala['casos'] as List).cast<List>();

    test('os ${casos.length} casos de docs/v1130/fala.json (os mesmos do Ruby e do JS)', () {
      expect(casos.length, greaterThanOrEqualTo(80));
      final erros = <String>[];
      for (final c in casos) {
        final got = SsSpeech.parseAmountPtBr(c[0] as String);
        if (got != c[1]) erros.add('"${c[0]}": esperado ${c[1]}, veio $got');
      }
      expect(erros, isEmpty, reason: erros.join('\n'));
    });

    test('os casos do pedido, um a um', () {
      expect(SsSpeech.parseAmountPtBr('cento e vinte e três e cinquenta'), 12350);
      expect(SsSpeech.parseAmountPtBr('mil e duzentos reais'), 120000);
      expect(SsSpeech.parseAmountPtBr('dois mil e quinhentos e noventa centavos'), 250090);
      expect(SsSpeech.parseAmountPtBr(r'R$ 12,50'), 1250);
      expect(SsSpeech.parseAmountPtBr('doze e meio'), 1250);
      expect(SsSpeech.parseAmountPtBr(null), isNull);
      expect(SsSpeech.words, containsAll(['cento', 'mil', 'cinquenta', 'dezenove']));
    });
  });

  group('estado no link', () {
    test('o vetor de docs/v1130/handoff.json, ida e volta', () {
      final state = (_handoff['state'] as Map).cast<String, Object?>();
      expect(SsHandoff.encode(state), _handoff['encoded']);
      expect(SsHandoff.decode(_handoff['encoded'] as String), state);
      expect(SsHandoff.link(_handoff['base'] as String, state), _handoff['link']);
      expect(SsHandoff.link('https://x.com/a', state), startsWith('https://x.com/a?s='));
      expect(SsHandoff.link('https://x.com/a', null), 'https://x.com/a');
      expect(SsHandoff.decode('não é base64'), isNull);
      expect(SsHandoff.decode(base64Url.encode(utf8.encode('[1,2]'))), isNull);
    });
  });

  group('textos', () {
    test('pt, en e es com os mesmos moldes %{x}', () {
      List<String> moldes(SsTrustStrings s) => [
        s.explainMore,
        s.previewSelected,
        s.previewApplied,
        s.previewInclude,
        s.sinceToday,
        s.sinceYesterday,
        s.sinceWeekday,
        s.sinceDate,
        s.suiteUsed,
        s.suiteBadge,
        s.conflictBy,
        s.conflictSame,
        s.conflictCount,
        s.voiceHeard,
        s.voiceNotUnderstood,
      ];
      Set<String> chaves(String m) => {for (final x in RegExp(r'%\{(\w+)\}').allMatches(m)) x.group(1)!};
      final pt = moldes(SsTrustStrings.pt);
      for (final outro in [SsTrustStrings.en, SsTrustStrings.es]) {
        final o = moldes(outro);
        for (var i = 0; i < pt.length; i++) {
          expect(chaves(o[i]), chaves(pt[i]), reason: o[i]);
        }
        expect(outro.privacyReasons.keys.toSet(), SsTrustStrings.pt.privacyReasons.keys.toSet());
      }
      expect(SsTrustStrings.forLocale(const Locale('es')).sinceGotIt, 'Entendido');
    });

    test('relógio e "desde" por idioma', () {
      final d = DateTime(2026, 11, 26, 18);
      expect(SsTrustStrings.pt.clock(d), '18h');
      expect(SsTrustStrings.pt.clock(DateTime(2026, 11, 26, 9, 30)), '9h30');
      expect(SsTrustStrings.en.clock(d), '6 PM');
      expect(SsTrustStrings.es.clock(d), '18:00');
      expect(SsSinceLastVisit.label(d, now: _agora), 'Desde ontem às 18h');
      expect(SsSinceLastVisit.label(DateTime(2026, 11, 27, 8), now: _agora), 'Desde hoje às 8h');
      expect(SsSinceLastVisit.label(DateTime(2026, 11, 23, 9, 30), now: _agora), 'Desde segunda às 9h30');
      expect(SsSinceLastVisit.label(DateTime(2026, 11, 12, 9), now: _agora), 'Desde 12/11');
      expect(SsSinceLastVisit.label(d, now: _agora, t: SsTrustStrings.en, s: SsStrings.en), 'Since yesterday at 6 PM');
    });

    test('nenhuma duração solta nas peças da v1.13 (SsMotion)', () {
      for (final f in Directory('lib/src/v1130').listSync().whereType<File>()) {
        expect(f.readAsStringSync(), isNot(contains('milliseconds:')), reason: f.path);
      }
    });
  });

  group('SsExplain', () {
    testWidgets('toque longo abre a folha com o valor, a fórmula e o que compõe', (t) async {
      var abriu = 0;
      await _pump(
        t,
        SsExplain(
          value: r'R$ 1.240,00',
          title: 'Gastos de novembro',
          formula: 'Soma dos 23 lançamentos de nov',
          items: [SsExplainItem('Mercado Bom Preço', r'R$ 214,90', onTap: () => abriu++)],
          more: 22,
          onMore: () {},
          child: const Text(r'R$ 1.240,00'),
        ),
      );
      await t.longPress(find.text(r'R$ 1.240,00'));
      await t.pumpAndSettle();
      expect(find.text('Gastos de novembro'), findsOneWidget);
      expect(find.text('Soma dos 23 lançamentos de nov'), findsOneWidget);
      expect(find.text('e mais 22'), findsOneWidget);
      expect(find.text('Ver todos'), findsOneWidget);
      await t.tap(find.text('Mercado Bom Preço'));
      expect(abriu, 1);
    });

    testWidgets('leitor de tela: a dica e a ação "Ver de onde vem este valor"', (t) async {
      final h = t.ensureSemantics();
      await _pump(t, const SsExplain(value: '72%', child: Text('72%')));
      final node = t.getSemantics(find.text('72%'));
      expect(node.getSemanticsData().hint, contains('Toque e segure'));
      expect(node.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      h.dispose();
    });

    testWidgets('Explicar com IA: pensando com Cancelar, resposta, erro e tentar de novo', (t) async {
      var pedidos = 0;
      var cancelou = 0;
      late Completer<String> c;
      await _pump(
        t,
        SsExplainPanel(
          value: r'R$ 1.240,00',
          onAskAi: () {
            pedidos++;
            c = Completer<String>();
            return c.future;
          },
          onCancelAi: () => cancelou++,
        ),
      );
      await t.tap(find.text('Explicar com IA'));
      await t.pump();
      expect(find.byType(SsThinking), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pump();
      expect(cancelou, 1);
      c.complete('tarde demais');
      await t.pump();
      expect(find.text('tarde demais'), findsNothing);
      expect(find.text('Explicar com IA'), findsOneWidget);

      await t.tap(find.text('Explicar com IA'));
      await t.pump();
      c.complete('Mercado subiu 18% por causa de duas compras grandes.');
      await t.pumpAndSettle();
      expect(find.textContaining('Mercado subiu 18%'), findsOneWidget);
      expect(find.textContaining('Explicação da IA'), findsOneWidget);
      expect(pedidos, 2);
    });

    testWidgets('erro da IA com tentar de novo; ssA11yAudit', (t) async {
      await _pump(
        t,
        SsExplainPanel(
          value: '72%',
          formula: 'Meta do mês',
          items: [SsExplainItem('Pedidos', '18', onTap: () {})],
          onAskAi: () async => throw Exception('rede'),
        ),
      );
      await t.tap(find.text('Explicar com IA'));
      await t.pumpAndSettle();
      expect(find.text('Não deu para explicar agora.'), findsOneWidget);
      expect(find.text('Tentar de novo'), findsOneWidget);
      await ssA11yAudit(t);
    });
  });

  group('SsAiActionPreview', () {
    test('o que aconteceu com o campo', () {
      expect(SsAiActionPreview.kindOf(null, 'x'), SsDiffKind.added);
      expect(SsAiActionPreview.kindOf('x', ''), SsDiffKind.removed);
      expect(SsAiActionPreview.kindOf('x', 'y'), SsDiffKind.changed);
      expect(SsAiActionPreview.kindOf(' x', 'x '), SsDiffKind.same);
    });

    testWidgets('antes e depois, marcar e desmarcar, aplicar as marcadas e desfazer', (t) async {
      List<SsAiChange>? aplicadas, desfeitas;
      await _pump(
        t,
        SsAiActionPreview(
          changes: _mudancas,
          onApply: (s) async => aplicadas = s,
          onUndo: (s) => desfeitas = s,
          onAdjust: () {},
          onCancel: () {},
        ),
      );
      expect(find.text('2 de 3 marcadas'), findsOneWidget);
      expect(find.text('Outros'), findsNWidgets(2));
      expect(find.text('Mercado'), findsOneWidget);
      expect(find.text('NOVO'), findsOneWidget);
      expect(find.text('REMOVIDO'), findsOneWidget);
      expect(find.text('ALTERADO'), findsNWidgets(2));
      expect(find.text('Valor'), findsNothing, reason: 'campo igual não aparece');
      await t.tap(find.text('Posto Avenida'));
      await t.pump();
      expect(find.text('1 de 3 marcadas'), findsOneWidget);
      await t.tap(find.text('Aplicar (1)'));
      await t.pump();
      expect(aplicadas!.map((c) => c.id), ['l1']);
      await t.pump(SsMotion.long);
      expect(find.text('1 alteração aplicada'), findsOneWidget);
      await t.tap(find.text('Desfazer'));
      await t.pumpAndSettle();
      expect(desfeitas!.map((c) => c.id), ['l1']);
    });

    testWidgets('nenhuma marcada: Aplicar desligado e o aviso', (t) async {
      var aplicou = false;
      await _pump(t, SsAiActionPreview(changes: _mudancas, onApply: (_) async => aplicou = true));
      await t.tap(find.text('Marcar todas'));
      await t.pump();
      expect(find.text('3 de 3 marcadas'), findsOneWidget);
      await t.tap(find.text('Desmarcar todas'));
      await t.pump();
      expect(find.text('Marque ao menos uma alteração para aplicar.'), findsOneWidget);
      await t.tap(find.text('Aplicar'), warnIfMissed: false);
      expect(aplicou, isFalse);
    });

    testWidgets('leitor de tela: a caixa de cada alteração e o campo falado; ssA11yAudit', (t) async {
      final h = t.ensureSemantics();
      await _pump(t, SsAiActionPreview(changes: _mudancas, onApply: (_) async {}, onCancel: () {}));
      expect(find.bySemanticsLabel('Incluir Mercado Bom Preço'), findsOneWidget);
      expect(find.bySemanticsLabel('Categoria. Alterado. Antes: Outros. Depois: Mercado'), findsOneWidget);
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('na folha, com o SsChatActionCard(onReview:)', (t) async {
      List<SsAiChange>? r;
      await _pump(
        t,
        Builder(
          builder: (ctx) => SsChatActionCard(
            title: 'Recategorizar 3 lançamentos',
            onConfirm: () {},
            onCancel: () {},
            onReview: () async => r = await showSsAiActionPreview(ctx, changes: _mudancas),
          ),
        ),
      );
      await t.tap(find.text('Ver alterações'));
      await t.pumpAndSettle();
      expect(find.text('Antes de aplicar'), findsOneWidget);
      await t.tap(find.text('Aplicar (2)'));
      await t.pumpAndSettle();
      expect(r!.length, 2);
    });
  });

  group('SsSinceLastVisit', () {
    final itens = [
      SsSinceItem(value: '3', label: 'pedidos novos', icon: Icons.receipt_long_outlined, onTap: () {}),
      const SsSinceItem(value: r'R$ 1.240,00', label: 'recebidos', tone: SsTone.success),
      const SsSinceItem(value: '1', label: 'tarefa atrasada', tone: SsTone.warning),
    ];

    testWidgets('título, itens com odômetro, Entendi grava a visita e some', (t) async {
      final guardado = <String, String>{};
      final store = SsLastVisit(read: (k) async => guardado[k], write: (k, v) async => guardado[k] = v);
      var saiu = 0;
      await _pump(
        t,
        SsSinceLastVisit(
          since: DateTime(2026, 11, 26, 18),
          now: _agora,
          items: itens,
          store: store,
          onDismiss: () => saiu++,
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Desde ontem às 18h'), findsOneWidget);
      expect(find.text('pedidos novos'), findsOneWidget);
      expect(find.byType(SsOdometer), findsNWidgets(3));
      await t.tap(find.text('Entendi'));
      await t.pumpAndSettle();
      expect(find.text('pedidos novos'), findsNothing);
      expect(saiu, 1);
      expect(await store.load(), _agora.toUtc());
    });

    testWidgets('some sozinho; com o leitor de tela, não', (t) async {
      await _pump(
        t,
        SsSinceLastVisit(
          since: DateTime(2026, 11, 26),
          now: _agora,
          items: itens,
          autoHide: const Duration(seconds: 3),
        ),
      );
      await t.pump(const Duration(seconds: 4));
      await t.pumpAndSettle();
      expect(find.text('recebidos'), findsNothing);

      await t.pumpWidget(const SizedBox());
      await t.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: _app(
            SsSinceLastVisit(
              since: DateTime(2026, 11, 26),
              now: _agora,
              items: itens,
              autoHide: const Duration(seconds: 3),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 4));
      await t.pumpAndSettle();
      expect(find.text('recebidos'), findsOneWidget);
    });

    testWidgets('sem itens não desenha; ssA11yAudit no padrão e no compacto', (t) async {
      await _pump(t, SsSinceLastVisit(since: _agora, items: const []));
      expect(find.byType(SsCard), findsNothing);
      for (final d in [SsDensity.standard, SsDensity.compact]) {
        await _pump(
          t,
          SsSinceLastVisit(since: DateTime(2026, 11, 20), now: _agora, items: itens),
          density: d,
        );
        await t.pumpAndSettle();
        await ssA11yAudit(t);
      }
    });
  });

  group('SsContinueOn', () {
    const url = 'https://vendas.exemplo.com.br/pedidos?s=eyJ0ZWxhIjoicGVkaWRvcyJ9';

    testWidgets('link, QR com nome e copiar com retorno', (t) async {
      _mockClipboard(t);
      final h = t.ensureSemantics();
      await _pump(t, const SsContinueOn(url: url));
      expect(find.byType(SsQrImage), findsOneWidget);
      expect(find.bySemanticsLabel('QR Code para abrir no outro aparelho'), findsOneWidget);
      expect(find.textContaining('navegador do computador'), findsOneWidget);
      await t.tap(find.text('Copiar link'));
      await t.pump();
      expect(_clip, url);
      expect(find.text('Link copiado'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      expect(find.text('Copiar link'), findsOneWidget);
      h.dispose();
    });

    testWidgets('link longo avisa; celular põe o QR primeiro; ssA11yAudit', (t) async {
      await _pump(t, SsContinueOn(url: '$url${'x' * 300}', target: SsContinueTarget.phone, onShare: () {}));
      expect(find.text('O endereço é longo. Se o código não ler, use o link.'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
      expect(t.getTopLeft(find.byType(SsQrImage)).dy, lessThan(t.getTopLeft(find.byType(SelectableText)).dy));
      await ssA11yAudit(t);
    });
  });

  group('SsSuiteSwitcher', () {
    final produtos = [
      SsSuiteProduct(id: 'vendas', name: 'Minhas Vendas', icon: Icons.storefront_outlined, current: true),
      SsSuiteProduct(
        id: 'fin',
        name: 'Meu Financeiro',
        icon: Icons.account_balance_wallet_outlined,
        lastUsedAt: DateTime(2026, 11, 24, 10),
        badge: 3,
        onOpen: () {},
      ),
      SsSuiteProduct(id: 'gestor', name: 'Meu Gestor', icon: Icons.insights_outlined, onOpen: () {}),
      SsSuiteProduct(
        id: 'cultivo',
        name: 'Meu Cultivo',
        icon: Icons.eco_outlined,
        active: false,
        description: 'Plantas e jardim',
        onDiscover: () {},
      ),
    ];

    testWidgets('seus apps, último acesso, selo e conheça também', (t) async {
      final h = t.ensureSemantics();
      await _pump(t, SsSuiteSwitcher(products: produtos, now: _agora));
      expect(find.text('SEUS APPS'), findsOneWidget);
      expect(find.text('Você está aqui'), findsOneWidget);
      expect(find.textContaining('Usado há 3'), findsOneWidget);
      expect(find.text('Ainda não usado'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('3 avisos')), findsOneWidget);
      expect(find.text('CONHEÇA TAMBÉM'), findsOneWidget);
      expect(find.text('Conhecer'), findsOneWidget);
      h.dispose();
      await ssA11yAudit(t);
    });

    testWidgets('a seção do menu lateral', (t) async {
      late SsSideMenuSection sec;
      await _pump(
        t,
        Builder(
          builder: (ctx) {
            sec = SsSuiteSwitcher.section(ctx, products: produtos, onDiscover: () {}, now: _agora);
            return const SizedBox();
          },
        ),
      );
      expect(sec.title, 'Apps da suíte');
      expect(sec.items.map((i) => i.label), ['Meu Financeiro', 'Meu Gestor', 'Conheça também']);
      expect(sec.items.first.badge, 3);
    });
  });

  group('SsConflictResolver', () {
    const campos = [
      SsConflictField(key: 'qtd', label: 'Quantidade', mine: '12', theirs: '10'),
      SsConflictField(key: 'obs', label: 'Observação', mine: 'Entregar de manhã', theirs: ''),
      SsConflictField(key: 'cliente', label: 'Cliente', mine: 'Loja Centro', theirs: 'Loja Centro'),
    ];

    testWidgets('só os diferentes, escolher por campo e ficar com a do servidor', (t) async {
      Map<String, SsConflictSide>? r;
      await _pump(
        t,
        SsConflictResolver(
          title: 'Pedido 1042',
          fields: campos,
          theirsBy: 'Ana',
          theirsAt: DateTime(2026, 11, 27, 9),
          now: _agora,
          onResolve: (m) => r = m,
        ),
      );
      expect(find.text('Quantidade'), findsOneWidget);
      expect(find.text('Cliente'), findsNothing);
      expect(find.text('1 campo igual nas duas versões'), findsOneWidget);
      expect(find.text('(vazio)'), findsOneWidget);
      expect(find.textContaining('por Ana'), findsNWidgets(2));
      await t.tap(find.text('10'));
      await t.pump();
      await t.tap(find.text('Salvar escolha'));
      expect(r, {'qtd': SsConflictSide.theirs, 'obs': SsConflictSide.mine, 'cliente': SsConflictSide.mine});
      await t.tap(find.text('Ficar com a do servidor'));
      await t.pump();
      await t.tap(find.text('Salvar escolha'));
      expect(r!.values.toSet(), {SsConflictSide.theirs});
    });

    testWidgets('leitor de tela e ssA11yAudit; SsSyncPanel com os conflitos', (t) async {
      final h = t.ensureSemantics();
      await _pump(t, SsConflictResolver(fields: campos, onResolve: (_) {}, onCancel: () {}));
      expect(find.bySemanticsLabel('Sua versão: 12'), findsOneWidget);
      h.dispose();
      await ssA11yAudit(t);
      var abriu = 0;
      await _pump(
        t,
        SsSyncPanel(state: SsSyncState.pending, pendingCount: 2, conflictCount: 2, onResolveConflicts: () => abriu++),
      );
      expect(find.text('2 registros em conflito'), findsOneWidget);
      await t.tap(find.text('Resolver'));
      expect(abriu, 1);
    });
  });

  group('SsMoneyField(onVoice:)', () {
    testWidgets('o microfone escuta, converte e mostra o que ouviu', (t) async {
      int? cents;
      final fala = Completer<String?>();
      await _pump(t, SsMoneyField(label: 'Valor', onChanged: (v) => cents = v, onVoice: () => fala.future));
      await t.tap(find.byTooltip('Falar o valor'));
      await t.pump();
      expect(find.text('Ouvindo…'), findsOneWidget);
      fala.complete('cento e vinte e três e cinquenta');
      await t.pump();
      expect(cents, 12350);
      expect(find.text('123,50'), findsOneWidget);
      expect(find.textContaining('Ouvi “cento e vinte e três e cinquenta”'), findsOneWidget);
    });

    testWidgets('não entendeu: o aviso e o valor fica como estava', (t) async {
      int? cents = 500;
      await _pump(
        t,
        SsMoneyField(label: 'Valor', cents: 500, onChanged: (v) => cents = v, onVoice: () async => 'banana'),
      );
      await t.tap(find.byTooltip('Falar o valor'));
      await t.pump();
      await t.pump();
      expect(find.textContaining('Não entendi o valor em “banana”'), findsOneWidget);
      expect(cents, 500);
      await ssA11yAudit(t);
    });

    testWidgets('sem onVoice, sem microfone', (t) async {
      await _pump(t, SsMoneyField(label: 'Valor', onChanged: (_) {}));
      expect(find.byTooltip('Falar o valor'), findsNothing);
    });
  });

  group('SsPrivacyScope(auto:)', () {
    testWidgets('um sinal do app esconde; ao desligar, volta', (t) async {
      final virado = SsPrivacySignal('face_down');
      late Set<String> motivos;
      await _pump(
        t,
        SsPrivacyScope(
          hidden: false,
          auto: SsPrivacyAuto(signals: [virado]),
          child: Builder(
            builder: (ctx) {
              motivos = SsPrivacyScope.autoReasonsOf(ctx);
              return const SsAmount(r'R$ 1.234,56');
            },
          ),
        ),
      );
      expect(find.textContaining('•••'), findsNothing);
      virado.value = true;
      await t.pump();
      expect(find.textContaining('•••'), findsOneWidget);
      expect(motivos, {'face_down'});
      virado.value = false;
      await t.pump();
      expect(find.textContaining('•••'), findsNothing);
    });

    testWidgets('app fora da frente: esconde e desfoca a miniatura', (t) async {
      await _pump(t, const SsPrivacyScope(hidden: false, auto: SsPrivacyAuto(), child: SsAmount(r'R$ 1.234,56')));
      expect(find.byType(BackdropFilter), findsNothing);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      await t.pump();
      expect(find.textContaining('•••'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsOneWidget);
      t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await t.pump();
      expect(find.textContaining('•••'), findsNothing);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('sem auto, como antes', (t) async {
      await _pump(t, const SsPrivacyScope(hidden: true, child: SsAmount(r'R$ 1.234,56')));
      expect(find.textContaining('•••'), findsOneWidget);
    });
  });
}
