// v1.11.0 "adaptativa": cada peça adaptativa nas duas plataformas (Android e iOS, pelo ThemeData.platform ou
// pelo debugDefaultTargetPlatformOverride), a saída (adaptive: false e SsPlatformScope), a alça do menu
// lateral que cede ao voltar do iOS só em rota empilhada, o voltar/fechar visível nas telas empilhadas, a
// área segura de cima (ilha dinâmica) e de baixo (home indicator) e o botão de entrar com a Apple.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:componentes_ui/testing.dart';
import 'package:cupertino_ui/cupertino_ui.dart'
    show
        CupertinoActionSheet,
        CupertinoAlertDialog,
        CupertinoDatePicker,
        CupertinoDialogAction,
        CupertinoPageTransitionsBuilder,
        CupertinoSliverRefreshControl,
        CupertinoSwitch;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

final _ios = AppTheme.light.copyWith(platform: TargetPlatform.iOS);
final _android = AppTheme.light.copyWith(platform: TargetPlatform.android);

Widget _app(Widget home, {ThemeData? theme, MediaQueryData? mq, bool scopeOff = false}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  // Sem a animação do tema: senão o 1º quadro depois de trocar de tema ainda tem a plataforma antiga.
  themeAnimationDuration: Duration.zero,
  theme: theme ?? _ios,
  locale: const Locale('pt', 'BR'),
  supportedLocales: SsStrings.supportedLocales,
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  builder: (context, child) {
    Widget w = child!;
    if (scopeOff) w = SsPlatformScope(adaptive: false, child: w);
    return mq == null ? w : MediaQuery(data: mq, child: w);
  },
  home: home,
);

/// Monta [w] do zero (o pumpWidget reaproveita o Navigator da montagem anterior).
Future<void> _pump(WidgetTester t, Widget w) async {
  await t.pumpWidget(const SizedBox());
  await t.pumpWidget(w);
}

/// Um botão que chama [f] com o contexto da tela.
Widget _botao(String rotulo, void Function(BuildContext) f) => Scaffold(
  body: Center(
    child: Builder(
      builder: (context) => TextButton(onPressed: () => f(context), child: Text(rotulo)),
    ),
  ),
);

/// A física da rolagem tem [tipo] em algum ponto da corrente de pais?
bool _temFisica<T extends ScrollPhysics>(ScrollPhysics? p) {
  for (var f = p; f != null; f = f.parent) {
    if (f is T) return true;
  }
  return false;
}

const _menu = SsSideMenu(
  sections: [
    SsSideMenuSection([SsSideMenuItem(Icons.settings_outlined, 'Configurações')]),
  ],
);

void main() {
  group('SsPlatform e a saída', () {
    testWidgets('lê a plataforma do tema; adaptive e SsPlatformScope desligam', (t) async {
      late BuildContext ctx;
      await _pump(t, _app(Builder(builder: (c) => (ctx = c, const SizedBox()).$2)));
      expect(SsPlatform.of(ctx), TargetPlatform.iOS);
      expect(SsPlatform.isApple(ctx), isTrue);
      expect(SsPlatform.cupertino(ctx), isTrue);
      expect(SsPlatform.cupertino(ctx, adaptive: false), isFalse);
      expect(SsPlatform.backIcon(ctx), Icons.arrow_back_ios_new_rounded);

      await _pump(t, _app(Builder(builder: (c) => (ctx = c, const SizedBox()).$2), theme: _android));
      expect(SsPlatform.cupertino(ctx), isFalse);
      expect(SsPlatform.backIcon(ctx), Icons.arrow_back_rounded);

      await _pump(t, _app(Builder(builder: (c) => (ctx = c, const SizedBox()).$2), scopeOff: true));
      expect(SsPlatform.isApple(ctx), isTrue);
      expect(SsPlatform.cupertino(ctx), isFalse);
    });

    testWidgets('o tema usa a transição do iOS (voltar de arrastar) e a do Android segue a preditiva', (t) async {
      final b = AppTheme.light.pageTransitionsTheme.builders;
      expect(b[TargetPlatform.iOS], isA<CupertinoPageTransitionsBuilder>());
      expect(b[TargetPlatform.macOS], isA<CupertinoPageTransitionsBuilder>());
      expect(b[TargetPlatform.android], isA<SsPredictiveBackPageTransitionsBuilder>());
    });

    testWidgets('rolagem com elástico nas listas do pacote no iOS e presa no Android e com a saída', (t) async {
      Future<ScrollPhysics?> fisica(ThemeData tema, {bool off = false}) async {
        await _pump(
          t,
          _app(
            Scaffold(
              body: SsPagedList<int>(
                key: UniqueKey(),
                items: List.generate(30, (i) => i),
                hasMore: false,
                onLoadMore: () async {},
                itemBuilder: (_, i) => SizedBox(height: 48, child: Text('Linha $i')),
              ),
            ),
            theme: tema,
            scopeOff: off,
          ),
        );
        await t.pumpAndSettle();
        return t.state<ScrollableState>(find.byType(Scrollable).first).position.physics;
      }

      expect(_temFisica<BouncingScrollPhysics>(await fisica(_ios)), isTrue);
      expect(_temFisica<BouncingScrollPhysics>(await fisica(_android)), isFalse);
      expect(_temFisica<ClampingScrollPhysics>(await fisica(_ios, off: true)), isTrue);
    });
  });

  group('SsSwitch e SsSwitchRow', () {
    for (final ios in [false, true]) {
      testWidgets('${ios ? 'iOS: CupertinoSwitch' : 'Android: a chave da suíte'}, alterna com o toque', (t) async {
        var v = false;
        await _pump(
          t,
          _app(
            Scaffold(
              body: StatefulBuilder(
                builder: (_, set) => SsSwitchRow(title: 'Lembrete', value: v, onChanged: (x) => set(() => v = x)),
              ),
            ),
            theme: ios ? _ios : _android,
          ),
        );
        expect(find.byType(CupertinoSwitch), ios ? findsOneWidget : findsNothing);
        await t.tap(find.text('Lembrete'));
        await t.pumpAndSettle();
        expect(v, isTrue);
        if (ios) {
          await t.tap(find.byType(CupertinoSwitch));
          await t.pumpAndSettle();
          expect(v, isFalse);
        }
        final alvo = t.getSize(find.byType(SsSwitch));
        expect(alvo.height, greaterThanOrEqualTo(48));
      });
    }

    testWidgets('adaptive: false fica com a chave da suíte no iOS', (t) async {
      await _pump(t, _app(Scaffold(body: SsSwitch(value: true, onChanged: (_) {}, adaptive: false))));
      expect(find.byType(CupertinoSwitch), findsNothing);
    });
  });

  group('data e hora', () {
    testWidgets('iOS: showSsDatePicker é a roda numa folha; Confirmar devolve o dia', (t) async {
      DateTime? r = DateTime(1999);
      await _pump(
        t,
        _app(
          _botao('abrir', (c) async {
            r = await showSsDatePicker(c, initialDate: DateTime(2026, 11, 27), firstDate: DateTime(2026));
          }),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsOneWidget);
      expect(find.text('Escolher data'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('ss-wheel-confirm')));
      await t.pumpAndSettle();
      expect(r, DateTime(2026, 11, 27));
    });

    testWidgets('iOS: Cancelar devolve nulo; Android segue o calendário da suíte', (t) async {
      DateTime? r = DateTime(1999);
      await _pump(
        t,
        _app(_botao('abrir', (c) async => r = await showSsDatePicker(c, initialDate: DateTime(2026, 11, 27)))),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(r, isNull);

      await _pump(
        t,
        _app(_botao('abrir', (c) => showSsDatePicker(c, initialDate: DateTime(2026, 11, 27))), theme: _android),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsNothing);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });

    testWidgets('iOS: SsTimeField abre a roda de hora; Confirmar devolve a hora', (t) async {
      TimeOfDay? v;
      await _pump(
        t,
        _app(
          Scaffold(
            body: StatefulBuilder(
              builder: (_, set) => SsTimeField(
                label: 'Horário',
                value: v ?? const TimeOfDay(hour: 7, minute: 30),
                onChanged: (x) => set(() => v = x),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('07:30'));
      await t.pumpAndSettle();
      final roda = t.widget<CupertinoDatePicker>(find.byType(CupertinoDatePicker));
      expect(roda.use24hFormat, isTrue);
      expect(find.text('Escolher hora'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('ss-wheel-confirm')));
      await t.pumpAndSettle();
      expect(v, const TimeOfDay(hour: 7, minute: 30));
    });

    testWidgets('SsDateField(adaptive: false) fica no calendário mesmo no iOS', (t) async {
      await _pump(
        t,
        _app(
          Scaffold(
            body: SsDateField(label: 'Vence', value: null, onChanged: (_) {}, showShortcuts: false, adaptive: false),
          ),
        ),
      );
      await t.tap(find.text('Escolher data'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoDatePicker), findsNothing);
      expect(find.byType(DatePickerDialog), findsOneWidget);
    });
  });

  group('folha de ação', () {
    testWidgets('iOS: showSsPicker curto vira folha de ação; longo, com busca ou livre segue a folha de busca', (
      t,
    ) async {
      String? r;
      await _pump(
        t,
        _app(
          _botao('curto', (c) async {
            r = await showSsPicker<String>(c, title: 'Unidade', items: const ['kg', 'un', 'L']);
          }),
        ),
      );
      await t.tap(find.text('curto'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      expect(find.text('Unidade'), findsOneWidget);
      await t.tap(find.text('un'));
      await t.pumpAndSettle();
      expect(r, 'un');

      await _pump(
        t,
        _app(
          _botao('longo', (c) {
            showSsPicker<String>(c, title: 'Cidade', items: [for (var i = 0; i < 12; i++) 'Cidade $i']);
          }),
        ),
      );
      await t.tap(find.text('longo'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.byType(SsPickerSheet<String>), findsOneWidget);
    });

    testWidgets('Android: showSsPicker curto segue a folha de busca', (t) async {
      await _pump(
        t,
        _app(
          _botao('curto', (c) => showSsPicker<String>(c, title: 'Unidade', items: const ['kg', 'un'])),
          theme: _android,
        ),
      );
      await t.tap(find.text('curto'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsNothing);
      expect(find.byType(SsPickerSheet<String>), findsOneWidget);
    });

    for (final ios in [false, true]) {
      testWidgets('SsOverflowMenu ${ios ? 'iOS: folha de ação com ⋯' : 'Android: menu ancorado com ⋮'}', (t) async {
        var feitos = <String>[];
        await _pump(
          t,
          _app(
            Scaffold(
              body: Center(
                child: SsOverflowMenu(
                  items: [
                    SsMenuAction(Icons.edit_outlined, 'Editar', () => feitos.add('editar')),
                    SsMenuAction(Icons.delete_outline, 'Excluir', () => feitos.add('excluir'), destructive: true),
                  ],
                ),
              ),
            ),
            theme: ios ? _ios : _android,
          ),
        );
        expect(find.byIcon(ios ? Icons.more_horiz_rounded : Icons.more_vert_rounded), findsOneWidget);
        await t.tap(find.ssTooltip('Mais opções'));
        await t.pumpAndSettle();
        expect(find.byType(CupertinoActionSheet), ios ? findsOneWidget : findsNothing);
        if (ios) expect(find.text('Cancelar'), findsOneWidget);
        await t.tap(find.text('Excluir'));
        await t.pumpAndSettle();
        expect(feitos, ['excluir']);
        feitos = [];
      });
    }

    testWidgets('SsContextMenu no iOS: toque longo abre a folha de ação; Cancelar não faz nada', (t) async {
      final feitos = <String>[];
      await _pump(
        t,
        _app(
          Scaffold(
            body: Center(
              child: SsContextMenu(
                actions: [
                  SsContextAction(Icons.share_outlined, 'Compartilhar', () => feitos.add('compartilhar')),
                  SsContextAction(Icons.delete_outline, 'Excluir', () => feitos.add('excluir'), destructive: true),
                ],
                child: const SizedBox(width: 200, height: 60, child: Text('Pedido 42')),
              ),
            ),
          ),
        ),
      );
      await t.longPress(find.text('Pedido 42'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoActionSheet), findsOneWidget);
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(feitos, isEmpty);
      await t.longPress(find.text('Pedido 42'));
      await t.pumpAndSettle();
      await t.tap(find.text('Compartilhar'));
      await t.pumpAndSettle();
      expect(feitos, ['compartilhar']);
    });
  });

  group('showSsConfirm', () {
    testWidgets('iOS: CupertinoAlertDialog com a destrutiva em vermelho; devolve true', (t) async {
      bool? r;
      await _pump(
        t,
        _app(
          _botao('abrir', (c) async {
            r = await showSsConfirm(c, title: 'Excluir pedido?', message: 'Não dá para desfazer.', danger: true);
          }),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.byType(CupertinoAlertDialog), findsOneWidget);
      expect(find.byType(SsConfirmDialog), findsNothing);
      final ok = t.widget<CupertinoDialogAction>(find.byKey(const ValueKey('ss-confirm-ok')));
      expect(ok.isDestructiveAction, isTrue);
      await t.tap(find.byKey(const ValueKey('ss-confirm-ok')));
      await t.pumpAndSettle();
      expect(r, isTrue);
    });

    testWidgets('Android e adaptive: false: o diálogo da suíte', (t) async {
      await _pump(t, _app(_botao('abrir', (c) => showSsConfirm(c, title: 'Sair?')), theme: _android));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.byType(SsConfirmDialog), findsOneWidget);
      expect(find.byType(CupertinoAlertDialog), findsNothing);

      await _pump(t, _app(_botao('abrir2', (c) => showSsConfirm(c, title: 'Sair?', adaptive: false))));
      await t.tap(find.text('abrir2'));
      await t.pumpAndSettle();
      expect(find.byType(SsConfirmDialog), findsOneWidget);
    });
  });

  group('SsPullToRefresh', () {
    Widget lista() => ListView(children: [for (var i = 0; i < 5; i++) ListTile(title: Text('Item $i'))]);

    testWidgets('iOS: o controle do iOS dispara o onRefresh ao puxar', (t) async {
      var vezes = 0;
      await _pump(
        t,
        _app(
          Scaffold(
            body: SsPullToRefresh(onRefresh: () async => vezes++, child: lista()),
          ),
        ),
      );
      expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsNothing);
      expect(find.text('Item 0'), findsOneWidget);
      await t.drag(find.text('Item 0'), const Offset(0, 260), touchSlopY: 0);
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      await t.pumpAndSettle();
      expect(vezes, 1);
    });

    testWidgets('Android: o indicador da suíte; conteúdo solto também vira rolável no iOS', (t) async {
      await _pump(
        t,
        _app(
          Scaffold(
            body: SsPullToRefresh(onRefresh: () async {}, child: lista()),
          ),
          theme: _android,
        ),
      );
      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), findsNothing);

      await _pump(
        t,
        _app(
          Scaffold(
            body: SsPullToRefresh(onRefresh: () async {}, child: const Text('Nada aqui')),
          ),
        ),
      );
      expect(find.byType(CupertinoSliverRefreshControl, skipOffstage: false), findsOneWidget);
    });

    testWidgets('iOS: o SsScreenHeader(onRefresh:) põe o controle embaixo do cabeçalho', (t) async {
      await _pump(
        t,
        _app(
          Scaffold(
            body: SsScreenHeader(
              title: 'Pedidos',
              onRefresh: () async {},
              slivers: const [SliverToBoxAdapter(child: Text('Pedido 1'))],
            ),
          ),
        ),
      );
      final slivers = t.widget<CustomScrollView>(find.byType(CustomScrollView)).slivers;
      expect(slivers[0], isA<SsSliverHeader>());
      expect(slivers[1], isA<CupertinoSliverRefreshControl>());
    });
  });

  group('SsHaptics', () {
    Future<List<String>> toques(WidgetTester t, TargetPlatform p) async {
      final feitos = <String>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'HapticFeedback.vibrate') feitos.add(call.arguments as String);
        return null;
      });
      debugDefaultTargetPlatformOverride = p;
      try {
        await SsHaptics.selection();
        // O sucesso do Android espera 90 ms entre os dois toques: o relógio do teste precisa andar.
        final sucesso = SsHaptics.success();
        await t.pump(const Duration(milliseconds: 200));
        await sucesso;
        await SsHaptics.warning();
        await SsHaptics.error();
      } finally {
        debugDefaultTargetPlatformOverride = null;
        t.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
      }
      return feitos;
    }

    testWidgets('iOS: seleção, e sucesso/aviso/erro nas notificações do iOS', (t) async {
      expect(await toques(t, TargetPlatform.iOS), [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.successNotification',
        'HapticFeedbackType.warningNotification',
        'HapticFeedbackType.errorNotification',
      ]);
    });

    testWidgets('Android: os impactos de sempre (sucesso são dois leves)', (t) async {
      expect(await toques(t, TargetPlatform.android), [
        'HapticFeedbackType.selectionClick',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.lightImpact',
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    });

    testWidgets('SsHaptics.adaptive = false usa o mapa do Android no iOS', (t) async {
      SsHaptics.adaptive = false;
      addTearDown(() => SsHaptics.adaptive = true);
      expect((await toques(t, TargetPlatform.iOS))[1], 'HapticFeedbackType.lightImpact');
    });
  });

  group('SsSideMenuHost: voltar do iOS', () {
    final alca = GlobalKey();

    Widget host({bool adaptive = true, Widget? child}) => SsSideMenuHost(
      menu: _menu,
      peek: false,
      handleKey: alca,
      adaptive: adaptive,
      child: child ?? const Scaffold(body: Center(child: Text('Início'))),
    );

    testWidgets('iOS, tela principal: a alça e a faixa ficam', (t) async {
      await _pump(t, _app(host()));
      expect(find.byKey(alca), findsOneWidget);
      expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).yieldsToBack, isFalse);
    });

    testWidgets('iOS, a tela do host empilhada: a alça some; Android: fica', (t) async {
      for (final ios in [true, false]) {
        await _pump(
          t,
          _app(
            _botao('ir', (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => host()))),
            theme: ios ? _ios : _android,
          ),
        );
        await t.tap(find.text('ir'));
        await t.pumpAndSettle();
        expect(find.byKey(alca), ios ? findsNothing : findsOneWidget, reason: ios ? 'iOS' : 'Android');
      }
    });

    testWidgets('iOS, Navigator de dentro com tela aberta: a alça some e volta ao voltar', (t) async {
      final nav = GlobalKey<NavigatorState>();
      await _pump(
        t,
        _app(
          host(
            child: Navigator(
              key: nav,
              onGenerateRoute: (_) => MaterialPageRoute<void>(
                builder: (_) => const Scaffold(body: Center(child: Text('Raiz'))),
              ),
            ),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byKey(alca), findsOneWidget);
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const Scaffold(body: Center(child: Text('Detalhe'))),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Detalhe'), findsOneWidget);
      expect(find.byKey(alca), findsNothing);
      expect(t.state<SsSideMenuHostState>(find.byType(SsSideMenuHost)).yieldsToBack, isTrue);
      nav.currentState!.pop();
      await t.pumpAndSettle();
      expect(find.byKey(alca), findsOneWidget);
    });

    testWidgets('iOS, adaptive: false: a alça fica mesmo empilhada', (t) async {
      await _pump(
        t,
        _app(_botao('ir', (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => host(adaptive: false))))),
      );
      await t.tap(find.text('ir'));
      await t.pumpAndSettle();
      expect(find.byKey(alca), findsOneWidget);
    });

    testWidgets('iOS: a página empilhada usa a transição do iOS e arrastar da borda volta', (t) async {
      await _pump(
        t,
        _app(
          _botao(
            'ir',
            (c) => Navigator.of(c).push(
              MaterialPageRoute<void>(
                builder: (_) => const Scaffold(
                  appBar: SsTopBar(title: 'Detalhe'),
                  body: SizedBox.expand(),
                ),
              ),
            ),
          ),
        ),
      );
      await t.tap(find.text('ir'));
      await t.pumpAndSettle();
      expect(find.text('Detalhe'), findsOneWidget);
      expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);
      final g = await t.startGesture(const Offset(4, 300));
      for (var i = 0; i < 10; i++) {
        await g.moveBy(const Offset(70, 0));
        await t.pump(const Duration(milliseconds: 16));
      }
      await g.up();
      await t.pumpAndSettle();
      expect(find.text('Detalhe'), findsNothing);
      expect(find.text('ir'), findsOneWidget);
    });
  });

  group('telas empilhadas: voltar ou fechar visível, ilha dinâmica e texto grande', () {
    const ilha = MediaQueryData(
      size: Size(393, 852),
      padding: EdgeInsets.only(top: 59, bottom: 34),
      viewPadding: EdgeInsets.only(top: 59, bottom: 34),
      textScaler: TextScaler.linear(1.6),
    );

    testWidgets('SsScreenHeader e SsTopBar empilhados têm o voltar abaixo da ilha', (t) async {
      for (final tela in <Widget>[
        const Scaffold(
          body: SsScreenHeader(title: 'Pedido', slivers: []),
        ),
        const Scaffold(
          appBar: SsTopBar(title: 'Pedido'),
          body: SizedBox(),
        ),
      ]) {
        await _pump(
          t,
          _app(_botao('ir', (c) => Navigator.of(c).push(MaterialPageRoute<void>(builder: (_) => tela))), mq: ilha),
        );
        await t.tap(find.text('ir'));
        await t.pumpAndSettle();
        final voltar = find.ssTooltip('Voltar');
        expect(voltar, findsOneWidget);
        expect(t.getTopLeft(voltar).dy, greaterThanOrEqualTo(59));
        expect(t.takeException(), isNull);
      }
    });

    testWidgets('SsFullscreenPage: o × abaixo da ilha, com texto 1,6×', (t) async {
      await _pump(
        t,
        _app(
          _botao(
            'abrir',
            (c) => showSsFullscreen<void>(
              c,
              title: 'Embarque',
              child: const Center(child: Text('QR')),
            ),
          ),
          mq: ilha,
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      final fechar = find.ssTooltip('Fechar');
      expect(fechar, findsOneWidget);
      expect(t.getTopLeft(fechar).dy, greaterThanOrEqualTo(59));
      await t.tap(fechar);
      await t.pumpAndSettle();
      expect(find.text('QR'), findsNothing);
    });

    testWidgets('SsSheet: no iOS ganha o × (e não passa da ilha); no Android, só a alça', (t) async {
      for (final ios in [true, false]) {
        await _pump(
          t,
          _app(
            _botao(
              'abrir',
              (c) => showSsSheet<void>(
                c,
                title: 'Filtros',
                child: Column(children: [for (var i = 0; i < 30; i++) Text('Linha $i')]),
              ),
            ),
            theme: ios ? _ios : _android,
            mq: ilha,
          ),
        );
        await t.tap(find.text('abrir'));
        await t.pumpAndSettle();
        final x = find.byKey(const ValueKey('ss-sheet-close'));
        expect(x, ios ? findsOneWidget : findsNothing);
        expect(t.getTopLeft(find.byType(SsSheet)).dy, greaterThanOrEqualTo(59));
        if (ios) {
          await t.tap(x);
          await t.pumpAndSettle();
          expect(find.byType(SsSheet), findsNothing);
        }
        expect(t.takeException(), isNull);
      }
    });

    testWidgets('SsNavBar respeita o home indicator (34) nas duas plataformas', (t) async {
      for (final tema in [_ios, _android]) {
        await _pump(
          t,
          _app(
            Scaffold(
              body: const SizedBox.expand(),
              bottomNavigationBar: SsNavBar(
                items: const [SsNavItem(Icons.home_outlined, 'Início'), SsNavItem(Icons.list, 'Pedidos')],
                currentIndex: 0,
                onTap: (_) {},
              ),
            ),
            theme: tema,
            mq: ilha.copyWith(textScaler: TextScaler.noScaling),
          ),
        );
        expect(t.getSize(find.byType(SsNavBar)).height, SsNavBar.rise + SsNavBar.barHeight + 34);
        expect(t.getBottomLeft(find.text('Início')).dy, lessThanOrEqualTo(852 - 34));
      }
    });
  });

  group('SsAppleButton', () {
    testWidgets('as três aparências, o texto do idioma e o toque', (t) async {
      var toques = 0;
      await _pump(
        t,
        _app(
          Scaffold(
            body: Column(
              children: [
                SsAppleButton(onPressed: () => toques++),
                SsAppleButton(style: SsAppleButtonStyle.white, label: SsAppleButtonLabel.signIn, onPressed: () {}),
                SsAppleButton(style: SsAppleButtonStyle.outline, onPressed: null),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Continuar com a Apple'), findsNWidgets(2));
      expect(find.text('Entrar com a Apple'), findsOneWidget);
      await t.tap(find.text('Continuar com a Apple').first);
      expect(toques, 1);
      await t.tap(find.text('Continuar com a Apple').last);
      expect(toques, 1, reason: 'desligado');
      for (final b in t.widgetList<SsAppleButton>(find.byType(SsAppleButton))) {
        expect(t.getSize(find.byWidget(b)).height, greaterThanOrEqualTo(SsAppleButton.height));
      }
      await ssA11yAudit(t);
    });

    testWidgets('sem style: preto no claro e branco no escuro; ícone ao lado do Google no SsAuthLayout', (t) async {
      late SsAppleButtonStyle claro, escuro;
      await _pump(
        t,
        _app(Builder(builder: (c) => (claro = SsAppleButton(onPressed: () {}).effectiveStyle(c), const SizedBox()).$2)),
      );
      await _pump(
        t,
        _app(
          Builder(builder: (c) => (escuro = SsAppleButton(onPressed: () {}).effectiveStyle(c), const SizedBox()).$2),
          theme: AppTheme.dark,
        ),
      );
      expect(claro, SsAppleButtonStyle.black);
      expect(escuro, SsAppleButtonStyle.white);

      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        if ('${d.exception}'.contains('Unable to load asset')) return;
        original?.call(d);
      };
      addTearDown(() => FlutterError.onError = original);
      await _pump(
        t,
        _app(
          Scaffold(
            body: SsAuthLayout(
              title: 'Meu Financeiro',
              subtitle: 'Entre na sua conta',
              halo: (AppColors.danger, AppColors.danger),
              providers: [
                SsGoogleButton(onTap: () {}),
                SsAppleButton.icon(onPressed: () {}),
              ],
              children: const [Text('formulário')],
            ),
          ),
        ),
      );
      await t.pump();
      expect(find.byType(SsAuthProviders), findsOneWidget);
      final g = t.getCenter(find.byType(SsGoogleButton));
      final a = t.getCenter(find.byType(SsAppleButton));
      expect(g.dy, moreOrLessEquals(a.dy, epsilon: 1), reason: 'lado a lado');
      expect(t.getSize(find.byType(SsAppleButton)), const Size(50, 50));
      expect(find.ssTooltip('Continuar com a Apple'), findsOneWidget);
    });

    testWidgets('inglês e espanhol', (t) async {
      for (final (loc, texto) in [
        (const Locale('en'), 'Sign in with Apple'),
        (const Locale('es'), 'Iniciar sesión con Apple'),
      ]) {
        await _pump(
          t,
          MaterialApp(
            theme: AppTheme.light,
            locale: loc,
            supportedLocales: SsStrings.supportedLocales,
            localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
            home: Scaffold(
              body: SsAppleButton(label: SsAppleButtonLabel.signIn, onPressed: () {}),
            ),
          ),
        );
        expect(find.text(texto), findsOneWidget);
      }
    });
  });
}
