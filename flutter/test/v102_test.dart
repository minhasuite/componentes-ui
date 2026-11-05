// v0.10.2: o que faltava para o minha-automacao (app) ficar 100% no pacote.
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {ThemeData? theme, double scale = 1, bool disableAnimations = false}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: MediaQuery(
    data: MediaQueryData(
      textScaler: TextScaler.linear(scale),
      disableAnimations: disableAnimations,
      size: const Size(390, 844),
    ),
    child: Scaffold(body: child),
  ),
);

void main() {
  group('SsAgendaList (coluna da hora)', () {
    final hoje = DateTime(2026, 11, 5);

    testWidgets('15:00–16:00 numa linha e "Dia todo" sem cortar: a coluna cresce até caber', (t) async {
      await t.pumpWidget(
        _app(
          SsAgendaList(
            days: [
              SsAgendaDay(
                hoje,
                events: const [
                  SsAgendaItem(time: '15:00–16:00', title: 'Reunião'),
                  SsAgendaItem(allDay: true, title: 'Feriado'),
                  SsAgendaItem(time: '09:30', title: 'Dentista'),
                ],
              ),
            ],
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      final faixa = find.text('15:00–16:00');
      expect(faixa, findsOneWidget);
      expect(find.text('Dia todo'), findsOneWidget);
      // Uma linha só: a altura do texto é a de uma linha de DM Mono 13.
      expect(t.getSize(faixa).height, lessThan(20));
      expect(t.getSize(find.text('Dia todo')).height, lessThan(20));
      // Mesma coluna para todos: os títulos começam no mesmo x.
      expect(t.getTopLeft(find.text('Reunião')).dx, t.getTopLeft(find.text('Dentista')).dx);
    });

    testWidgets('end: vai embaixo da hora e entra no nome lido', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          SsAgendaList(
            days: [
              SsAgendaDay(
                hoje,
                events: const [SsAgendaItem(time: '15:00', end: '16:00', title: 'Reunião')],
              ),
            ],
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.getTopLeft(find.text('16:00')).dy, greaterThan(t.getTopLeft(find.text('15:00')).dy));
      expect(find.bySemanticsLabel(RegExp(r'15:00 – 16:00, Reunião')), findsOneWidget);
      h.dispose();
    });

    testWidgets('allDay com idioma: All day; timeWidth fixa a coluna', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: SsStringsScope(
            strings: SsStrings.en,
            child: Scaffold(
              body: SsAgendaList(
                timeWidth: 90,
                days: [
                  SsAgendaDay(hoje, events: const [SsAgendaItem(allDay: true, title: 'Holiday')]),
                ],
              ),
            ),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('All day'), findsOneWidget);
      final col = find.ancestor(of: find.text('All day'), matching: find.byType(Container)).first;
      expect(t.getSize(col).width, 90);
    });

    testWidgets('fonte grande (1,6×) não estoura', (t) async {
      await t.pumpWidget(
        _app(
          scale: 1.6,
          SsAgendaList(
            days: [
              SsAgendaDay(
                hoje,
                events: const [
                  SsAgendaItem(time: '15:00–16:00', title: 'Reunião longa com o fornecedor', detail: 'Sala 3'),
                ],
              ),
            ],
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
    });
  });

  group('SsTopBar', () {
    testWidgets('título, ações e voltar automático numa tela empurrada', (t) async {
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: nav,
          home: const Scaffold(body: Text('início')),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: SsTopBar(
              title: 'Editar painel',
              subtitle: 'Casa',
              actions: [SsButton.text(label: 'Rascunho', onPressed: () {})],
            ),
            body: const SizedBox(),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Editar painel'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Rascunho'), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsOneWidget);
      await t.tap(find.byTooltip('Voltar'));
      await t.pumpAndSettle();
      expect(find.text('início'), findsOneWidget);
    });

    testWidgets('overlay: transparente com véu e texto claro; dark: fundo escuro', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            extendBodyBehindAppBar: true,
            appBar: const SsTopBar(title: 'Mapa', style: SsTopBarStyle.overlay),
            body: const ColoredBox(color: Colors.green),
          ),
        ),
      );
      var bar = t.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, Colors.transparent);
      expect(bar.flexibleSpace, isNotNull);
      expect(bar.foregroundColor, AppColors.onDark);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            appBar: SsTopBar(title: 'Câmera', style: SsTopBarStyle.dark),
          ),
        ),
      );
      bar = t.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, AppColors.headerDarkBg);
      expect(bar.leading, isNull); // tela raiz: sem voltar
    });

    testWidgets('onBack troca o pop', (t) async {
      var voltou = 0;
      await t.pumpWidget(_app(SsTopBar(title: 'X', onBack: () => voltou++)));
      await t.tap(find.byTooltip('Voltar'));
      expect(voltou, 1);
    });
  });

  group('SsIconButton e SsFab', () {
    testWidgets('dica vira nome; sem onPressed fica apagado; badge', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          Row(
            children: [
              SsIconButton(icon: Icons.delete_outline_rounded, tooltip: 'Excluir', onPressed: () => n++),
              const SsIconButton(icon: Icons.edit, tooltip: 'Editar', badge: '3'),
            ],
          ),
        ),
      );
      await t.tap(find.byTooltip('Excluir'));
      expect(n, 1);
      expect(find.text('3'), findsOneWidget);
      expect(t.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.edit)).onPressed, isNull);
      expect(t.getSize(find.byType(IconButton).first).width, greaterThanOrEqualTo(48));
    });

    testWidgets('SsFab estendido e só ícone com dica', (t) async {
      var n = 0;
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Scaffold(
            body: const SizedBox(),
            floatingActionButton: SsFab(icon: Icons.add_rounded, label: 'Seção', onPressed: () => n++),
          ),
        ),
      );
      await t.tap(find.text('Seção'));
      await t.pump(const Duration(milliseconds: 500));
      expect(n, 1);
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            floatingActionButton: SsFab(icon: Icons.add_rounded, tooltip: 'Novo', onPressed: () {}),
          ),
        ),
      );
      expect(find.byTooltip('Novo'), findsOneWidget);
    });
  });

  group('SsSpinner e SsSplash', () {
    testWidgets('spinner gira e para com reduzir movimento', (t) async {
      await t.pumpWidget(_app(const Center(child: SsSpinner())));
      final rot = t.widget<RotationTransition>(
        find.descendant(of: find.byType(SsSpinner), matching: find.byType(RotationTransition)),
      );
      final antes = rot.turns.value;
      await t.pump(const Duration(milliseconds: 200));
      expect(rot.turns.value, isNot(antes));
      await t.pumpWidget(_app(const Center(child: SsSpinner()), disableAnimations: true));
      final parado = t
          .widget<RotationTransition>(
            find.descendant(of: find.byType(SsSpinner), matching: find.byType(RotationTransition)),
          )
          .turns
          .value;
      await t.pump(const Duration(milliseconds: 300));
      expect(
        t
            .widget<RotationTransition>(
              find.descendant(of: find.byType(SsSpinner), matching: find.byType(RotationTransition)),
            )
            .turns
            .value,
        parado,
      );
      expect(find.bySemanticsLabel('Carregando'), findsOneWidget);
    });

    testWidgets('splash: título na hora, spinner e mensagem depois do atraso', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: const SsSplash(title: 'Minha Automação', message: 'Conectando…'),
        ),
      );
      expect(find.text('Minha Automação'), findsOneWidget);
      AnimatedOpacity op() => t.widget<AnimatedOpacity>(find.byType(AnimatedOpacity).first);
      expect(op().opacity, 0);
      await t.pump(const Duration(milliseconds: 350));
      expect(op().opacity, 1);
      expect(find.text('Conectando…'), findsOneWidget);
      await t.pump(const Duration(seconds: 1));
    });
  });

  group('SsReorderableList', () {
    testWidgets('arrasta pela alça e devolve (de, para) ajustado', (t) async {
      final itens = ['Sala', 'Cozinha', 'Quarto'];
      (int, int)? movido;
      await t.pumpWidget(
        _app(
          StatefulBuilder(
            builder: (context, set) => SsReorderableList(
              itemCount: itens.length,
              spacing: 8,
              onReorder: (from, to) => set(() {
                movido = (from, to);
                itens.insert(to, itens.removeAt(from));
              }),
              itemBuilder: (context, i) => SsCard(
                key: ValueKey(itens[i]),
                child: Row(
                  children: [
                    SsDragHandle(index: i),
                    Text(itens[i]),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Arrastar para reordenar'), findsNWidgets(3));
      final alca = find.byType(SsDragHandle).first;
      final g = await t.startGesture(t.getCenter(alca));
      await t.pump(const Duration(milliseconds: 100));
      await g.moveBy(const Offset(0, 200));
      await t.pump(const Duration(milliseconds: 300));
      await g.up();
      await t.pumpAndSettle();
      expect(movido, isNotNull);
      expect(movido!.$1, 0);
      expect(itens.first, isNot('Sala'));
    });
  });

  group('peças de linha', () {
    testWidgets('SsRows põe um fio entre as linhas (não antes da 1ª)', (t) async {
      await t.pumpWidget(_app(const SsRows(children: [Text('a'), Text('b'), Text('c')])));
      expect(find.byType(Divider), findsNWidgets(2));
      expect(find.byType(SsCard), findsOneWidget);
    });

    testWidgets('SsDangerZone com título padrão no idioma', (t) async {
      await t.pumpWidget(
        _app(
          SsDangerZone(
            message: 'Apaga o local e os aparelhos.',
            child: SsButton(label: 'Excluir local', variant: SsButtonVariant.danger, onPressed: () {}),
          ),
        ),
      );
      expect(find.text('Zona de perigo'), findsOneWidget);
      expect(find.text('Excluir local'), findsOneWidget);
    });

    testWidgets('SsCallout: tom, título, mensagem e ações; perigo é liveRegion', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(
          SsCallout(
            tone: SsTone.danger,
            title: 'Faltam campos',
            message: 'Escolha o aparelho.',
            actions: [SsButton.text(label: 'Ver', onPressed: () {})],
          ),
        ),
      );
      expect(find.text('Faltam campos'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline_rounded), findsOneWidget);
      final sem = t.getSemantics(find.byType(SsCallout));
      expect(sem.flagsCollection.isLiveRegion, isTrue);
      h.dispose();
    });

    testWidgets('SsCodeBlock copia e mostra o ✓', (t) async {
      String? copiado;
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copiado = (call.arguments as Map)['text'] as String;
        return null;
      });
      await t.pumpWidget(_app(const SsCodeBlock('token: abc123', terminal: true)));
      await t.tap(find.byTooltip('Copiar'));
      await t.pump();
      expect(copiado, 'token: abc123');
      expect(find.byTooltip('Copiado'), findsOneWidget);
      await t.pump(const Duration(seconds: 3));
      expect(find.byTooltip('Copiar'), findsOneWidget);
    });

    testWidgets('SsButtonGroup manda o comando de cada botão; sem ação fica apagado', (t) async {
      final feitos = <String>[];
      await t.pumpWidget(
        _app(
          SsButtonGroup(
            label: 'Cortina',
            buttons: [
              SsGroupButton(icon: Icons.arrow_upward, tooltip: 'Abrir', onPressed: () => feitos.add('abrir')),
              SsGroupButton(icon: Icons.stop, tooltip: 'Parar', onPressed: () => feitos.add('parar')),
              const SsGroupButton(icon: Icons.arrow_downward, tooltip: 'Fechar'),
            ],
          ),
        ),
      );
      await t.tap(find.byTooltip('Parar'));
      await t.tap(find.byTooltip('Fechar'));
      expect(feitos, ['parar']);
      expect(t.getSize(find.byType(InkWell).first).width, 48);
    });

    testWidgets('SsStepHeading: número, ✓ quando feito, lido como cabeçalho', (t) async {
      final h = t.ensureSemantics();
      await t.pumpWidget(
        _app(const Column(children: [SsStepHeading(1, 'Quando'), SsStepHeading(2, 'Então', done: true)])),
      );
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsNothing);
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.bySemanticsLabel('1. Quando'), findsOneWidget);
      h.dispose();
    });

    testWidgets('SsDivider com texto', (t) async {
      await t.pumpWidget(_app(const SsDivider(label: 'ou')));
      expect(find.text('ou'), findsOneWidget);
      expect(find.byType(Divider), findsNWidgets(2));
    });
  });

  group('parâmetros novos', () {
    testWidgets('SsFilterChip(solid:) marcado fica na cor sólida com texto branco', (t) async {
      await t.pumpWidget(_app(SsFilterChip('Luzes', selected: true, solid: true, count: 4, onTap: () {})));
      await t.pump(const Duration(milliseconds: 500));
      final texto = t.widget<Text>(find.text('Luzes'));
      expect(texto.style!.color, AppColors.onDark);
      final ctx = t.element(find.text('Luzes'));
      final caixas = t.widgetList<AnimatedContainer>(find.byType(AnimatedContainer));
      expect(
        caixas.any(
          (a) =>
              a.decoration is BoxDecoration && (a.decoration! as BoxDecoration).color == SsColors.of(ctx).accentSolid,
        ),
        isTrue,
      );
    });

    testWidgets('SsChipBar(fade:) esmaece o fim; wrapAbove quebra no largo', (t) async {
      final chips = [for (var i = 0; i < 12; i++) SsFilterChip('Filtro $i', selected: i == 0, onTap: () {})];
      await t.pumpWidget(_app(SsChipBar(fade: true, children: chips)));
      expect(find.byType(ShaderMask), findsOneWidget);
      await t.pumpWidget(_app(SsChipBar(wrapAbove: 300, children: chips)));
      expect(find.byType(Wrap), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsNothing);
    });

    testWidgets('SsBadge(dot:) e SsBadgeVariant.muted; SsIconTile(gradient:)', (t) async {
      await t.pumpWidget(
        _app(
          const Row(
            children: [
              SsBadge('Online', variant: SsBadgeVariant.success, dot: true),
              SsBadge('Rascunho', variant: SsBadgeVariant.muted),
              SsIconTile(Icons.lightbulb, gradient: true),
            ],
          ),
        ),
      );
      expect(find.text('Online'), findsOneWidget);
      expect(find.text('Rascunho'), findsOneWidget);
      final tile = t.widget<Container>(
        find.ancestor(of: find.byIcon(Icons.lightbulb), matching: find.byType(Container)).first,
      );
      expect((tile.decoration! as BoxDecoration).gradient, isNotNull);
    });

    test('textos novos nos três idiomas', () {
      for (final s in [SsStrings.pt, SsStrings.en, SsStrings.es]) {
        for (final v in [s.allDay, s.copy, s.copied, s.dangerZone]) {
          expect(v, isNotEmpty);
        }
      }
      expect(SsStrings.en.allDay, 'All day');
      expect(SsStrings.es.dangerZone, 'Zona de peligro');
    });
  });
}
