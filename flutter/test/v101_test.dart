// v0.10.1: o que a migração do minha-automacao-app pediu (parte do pacote
// base: rolagem, campos, menu, aviso, imagem, gráfico e idioma).
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget child, {ThemeData? theme}) => MaterialApp(
  theme: theme ?? AppTheme.light,
  home: Scaffold(body: child),
);

List<SsLogEntry> _eventos(int n, DateTime agora) => [
  for (var i = 0; i < n; i++)
    SsLogEntry(
      at: agora.subtract(Duration(minutes: 37 * i)),
      title: 'Evento $i',
      icon: Icons.bolt_rounded,
    ),
];

void main() {
  final agora = DateTime(2026, 11, 4, 14, 30);

  group('SsLogbook', () {
    testWidgets('.sliver vai nos slivers do SsScreenHeader e carrega mais pela rolagem de fora', (t) async {
      var pedidos = 0;
      await t.pumpWidget(
        _app(
          SsScreenHeader(
            title: 'Histórico',
            slivers: [
              SsLogbook.sliver(entries: _eventos(40, agora), now: agora, hasMore: true, onLoadMore: () => pedidos++),
            ],
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Evento 0'), findsOneWidget);
      expect(pedidos, 0);
      await t.drag(find.byType(CustomScrollView), const Offset(0, -6000));
      await t.pump();
      await t.pump(const Duration(seconds: 1));
      expect(pedidos, 1);
    });

    testWidgets('dentro do SsPullToRefresh vai direto (sem SingleChildScrollView)', (t) async {
      await t.pumpWidget(
        _app(
          SsPullToRefresh(
            onRefresh: () async {},
            child: SsLogbook(entries: _eventos(3, agora), now: agora),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.text('Evento 2'), findsOneWidget);
    });

    testWidgets('endAction e showEnd', (t) async {
      await t.pumpWidget(
        _app(
          SsLogbook(
            entries: _eventos(2, agora),
            now: agora,
            showEnd: false,
            endAction: SsButton.text(label: 'Ver um período maior', onPressed: () {}),
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Ver um período maior'), findsOneWidget);
      expect(find.text(SsStrings.pt.logbookEnd), findsNothing);
    });

    test('groupByDay com utcOffset agrupa no fuso do site', () {
      // 02:00 UTC de 5/11 é 23:00 de 4/11 em UTC−3.
      final e = SsLogEntry(at: DateTime.utc(2026, 11, 5, 2), title: 'x');
      final g = SsLogbook.groupByDay([e], utcOffset: const Duration(hours: -3));
      expect(g.single.$1, DateTime(2026, 11, 4));
    });
  });

  group('SsTimeFormat.utcOffset', () {
    test('hora e marcas no fuso fixo', () {
      final f = SsTimeFormat(const Locale('pt'), utcOffset: const Duration(hours: -3));
      expect(f.hm(DateTime.utc(2026, 11, 4, 15)), '12:00');
      expect(f.when(DateTime.utc(2026, 11, 5, 1, 30)), '04/11 22:30');
      final ticks = f.ticks(DateTime.utc(2026, 11, 4, 0), DateTime.utc(2026, 11, 5, 0), maxTicks: 5);
      // Meia-noite do site (03:00 UTC) é a virada.
      final virada = ticks.firstWhere((k) => k.major);
      expect(virada.at, DateTime.utc(2026, 11, 4, 3));
      expect(virada.label, '04/11');
    });
  });

  group('SsTimeChart', () {
    final serie = SsTimeSeries(
      name: 'Sala',
      unit: '°C',
      decimals: 1,
      points: [SsTimePoint(agora.subtract(const Duration(hours: 2)), 22), SsTimePoint(agora, 23.4)],
    );
    testWidgets('legendAlways + showValues: legenda com o último valor numa série só', (t) async {
      await t.pumpWidget(_app(SsTimeChart(series: [serie], locale: const Locale('pt'))));
      expect(find.text('Sala'), findsNothing);
      await t.pumpWidget(
        _app(SsTimeChart(series: [serie], locale: const Locale('pt'), legendAlways: true, showValues: true)),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Sala'), findsOneWidget);
      expect(find.text('23,4 °C'), findsOneWidget);
    });
  });

  group('SsPullToRefresh', () {
    test('selfScrolling reconhece as peças que já rolam', () {
      expect(SsPullToRefresh.selfScrolling(ListView()), isTrue);
      expect(SsPullToRefresh.selfScrolling(const SingleChildScrollView()), isTrue);
      expect(SsPullToRefresh.selfScrolling(const SsLogbook(entries: [])), isTrue);
      expect(SsPullToRefresh.selfScrolling(const Text('x')), isFalse);
    });
  });

  group('SsNoticeCard', () {
    testWidgets('onTap, unread, image e footer', (t) async {
      var tocou = 0;
      await t.pumpWidget(
        _app(
          SsNoticeCard(
            title: 'Movimento',
            unread: true,
            onTap: () => tocou++,
            image: const ColoredBox(color: Colors.black),
            footer: const Text('Respondido: Sim'),
            actions: [SsNoticeAction('Ver', () {})],
          ),
        ),
      );
      expect(find.text('Respondido: Sim'), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp(SsStrings.pt.unread)), findsOneWidget);
      await t.tap(find.text('Movimento'));
      expect(tocou, 1);
      await t.tap(find.text('Ver'));
      expect(tocou, 1);
    });
  });

  group('SsMenuView', () {
    testWidgets('sem onDeleteAccount não mostra o botão; appearance e SsSegmented no tema', (t) async {
      ThemeMode? modo;
      await t.pumpWidget(
        _app(
          SsMenuView(
            name: 'Ana',
            email: 'ana@exemplo.com',
            sections: const [],
            themeMode: ThemeMode.system,
            onThemeMode: (m) => modo = m,
            onLogout: () {},
            appearanceOpen: true,
            appearance: const [SsMenuCard(child: Text('Paleta'))],
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text(SsStrings.pt.deleteMyAccount), findsNothing);
      expect(find.text('Paleta'), findsOneWidget);
      expect(find.byType(SegmentedButton<ThemeMode>), findsNothing);
      await t.tap(find.text(SsStrings.pt.themeDark));
      expect(modo, ThemeMode.dark);
    });

    testWidgets('SsMenuSwitch com ícone', (t) async {
      await t.pumpWidget(
        _app(SsMenuSwitch(label: 'Sons', icon: Icons.volume_up_outlined, value: false, onChanged: (_) {})),
      );
      expect(find.byIcon(Icons.volume_up_outlined), findsOneWidget);
    });
  });

  group('SsTabsUnderline', () {
    testWidgets('muitas abas rolam e a escolhida aparece', (t) async {
      final abas = [for (var i = 0; i < 10; i++) 'Cômodo comprido $i'];
      await t.pumpWidget(_app(SsTabsUnderline(tabs: abas, index: 8, onChanged: (_) {})));
      await t.pump(const Duration(seconds: 1));
      expect(t.takeException(), isNull);
      expect(find.byType(SingleChildScrollView), findsOneWidget);
      final r = t.getRect(find.text('Cômodo comprido 8'));
      expect(r.left >= 0 && r.right <= 800, isTrue);
    });

    testWidgets('cabendo, divide a largura e mostra os ícones', (t) async {
      await t.pumpWidget(
        _app(
          SsTabsUnderline(
            tabs: const ['A', 'B'],
            icons: const [Icons.home_outlined, null],
            index: 0,
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsNothing);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
    });
  });

  group('SsButton.text', () {
    testWidgets('chama onPressed', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          Center(
            child: SsButton.text(label: 'Ver tudo', onPressed: () => n++),
          ),
        ),
      );
      await t.tap(find.text('Ver tudo'));
      await t.pump(const Duration(milliseconds: 400));
      expect(n, 1);
    });
  });

  group('SsScreenHeader', () {
    testWidgets('titleLeading e titleWidget', (t) async {
      await t.pumpWidget(
        _app(
          const SsScreenHeader(
            title: 'Casa',
            titleLeading: Icon(Icons.cottage_rounded),
            slivers: [SliverToBoxAdapter(child: SizedBox(height: 100))],
          ),
        ),
      );
      expect(find.byIcon(Icons.cottage_rounded), findsOneWidget);
      await t.pumpWidget(
        _app(
          const SsScreenHeader(
            title: 'Casa',
            titleWidget: Text('Herói'),
            slivers: [SliverToBoxAdapter(child: SizedBox(height: 100))],
          ),
        ),
      );
      expect(find.text('Herói'), findsOneWidget);
    });
  });

  group('SsNetImage', () {
    testWidgets('sem altura numa Column não estoura (4:3 pela largura)', (t) async {
      await t.pumpWidget(
        _app(
          const SizedBox(
            width: 200,
            child: Column(children: [SsNetImage(null, name: 'Foto')]),
          ),
        ),
      );
      expect(t.takeException(), isNull);
      expect(t.getSize(find.byType(SsNetImage)).height, closeTo(150, .01));
    });

    test('SsBytesImage compara pelo cacheKey', () {
      Future<Uint8List> a() async => Uint8List(0);
      Future<Uint8List> b() async => Uint8List(1);
      expect(SsBytesImage(a, cacheKey: 'k'), SsBytesImage(b, cacheKey: 'k'));
      expect(SsBytesImage(a, cacheKey: 'k') == SsBytesImage(a, cacheKey: 'j'), isFalse);
    });
  });

  group('Campos', () {
    testWidgets('helperText em escolha, data, hora e slider', (t) async {
      await t.pumpWidget(
        _app(
          ListView(
            children: [
              SsChoiceField<int>(value: null, options: const {1: 'Um'}, onChanged: (_) {}, helperText: 'dica escolha'),
              SsDateField(value: null, onChanged: (_) {}, helperText: 'dica data'),
              SsDateTimeField(value: null, onChanged: (_) {}, helperText: 'dica data e hora'),
              SsTimeField(value: null, onChanged: (_) {}, helperText: 'dica hora'),
              SsSlider(
                value: 21.5,
                onChanged: (_) {},
                helperText: 'dica slider',
                decimals: 1,
                unit: '°C',
                showValue: true,
              ),
            ],
          ),
        ),
      );
      for (final d in ['dica escolha', 'dica data', 'dica data e hora', 'dica hora', 'dica slider']) {
        expect(find.text(d), findsOneWidget);
      }
      expect(find.text('21,5 °C'), findsWidgets);
    });

    testWidgets('SsTimeField com validator mostra o erro no Form', (t) async {
      final form = GlobalKey<FormState>();
      await t.pumpWidget(
        _app(
          Form(
            key: form,
            child: SsTimeField(value: null, onChanged: (_) {}, validator: (v) => v == null ? 'Escolha' : null),
          ),
        ),
      );
      expect(form.currentState!.validate(), isFalse);
      await t.pump();
      expect(find.text('Escolha'), findsOneWidget);
    });

    testWidgets('SsTextField repassa autocorrect e enableSuggestions', (t) async {
      await t.pumpWidget(_app(const SsTextField(autocorrect: false, enableSuggestions: false)));
      final f = t.widget<TextField>(find.byType(TextField));
      expect(f.autocorrect, isFalse);
      expect(f.enableSuggestions, isFalse);
    });
  });

  group('Diálogo, chat, lista e faixa', () {
    testWidgets('SsPromptDialog com ícone, autofill e capitalização', (t) async {
      await t.pumpWidget(
        _app(
          const SsPromptDialog(
            title: 'E-mail',
            icon: Icons.alternate_email_rounded,
            autofillHints: [AutofillHints.email],
            textCapitalization: TextCapitalization.none,
          ),
        ),
      );
      final f = t.widget<TextField>(find.byType(TextField));
      expect(f.textCapitalization, TextCapitalization.none);
      expect(f.autofillHints, [AutofillHints.email]);
      expect(find.byIcon(Icons.alternate_email_rounded), findsOneWidget);
    });

    testWidgets('SsChatInput: maxLength e dica do botão', (t) async {
      final c = TextEditingController();
      await t.pumpWidget(_app(SsChatInput(controller: c, onSend: (_) {}, maxLength: 10, sendTooltip: 'Mandar')));
      await t.enterText(find.byType(TextField), 'abcdefghijklmn');
      await t.pump();
      expect(c.text.length, 10);
      expect(find.text('10/10'), findsOneWidget);
      expect(find.byTooltip('Mandar'), findsOneWidget);
    });

    testWidgets('SsLoadMore(endLabel:)', (t) async {
      await t.pumpWidget(_app(const SsLoadMore(hasMore: false, endLabel: 'Sem mais avisos')));
      expect(find.text('Sem mais avisos'), findsOneWidget);
    });

    testWidgets('SsOfflineBanner: message e ação', (t) async {
      var n = 0;
      await t.pumpWidget(
        _app(
          SsOfflineBanner(offline: true, message: 'Último painel salvo', onAction: () => n++, child: const SizedBox()),
        ),
      );
      expect(find.text('Último painel salvo'), findsOneWidget);
      await t.tap(find.text(SsStrings.pt.retry));
      expect(n, 1);
    });

    testWidgets('SsLinearLoader para com menos movimento', (t) async {
      await t.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(body: SsLinearLoader()),
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.byType(SsLinearLoader), findsOneWidget);
    });
  });

  group('Escolhas', () {
    testWidgets('SsLocalePicker: "Seguir o sistema" marcada com value nulo', (t) async {
      var sistema = 0;
      await t.pumpWidget(
        _app(SsLocalePicker(value: null, onChanged: (_) {}, systemOption: true, onSystem: () => sistema++)),
      );
      expect(find.text(SsStrings.pt.localeSystem), findsOneWidget);
      await t.tap(find.text(SsStrings.pt.localeSystem));
      expect(sistema, 1);
    });

    testWidgets('SsIconPicker: o rótulo vai na dica e acha na busca', (t) async {
      await t.pumpWidget(
        _app(
          SsIconPicker(
            icons: const [('lightbulb', Icons.lightbulb_outline), ('fan', Icons.air)],
            labels: const {'lightbulb': 'Lâmpada'},
            value: null,
            onChanged: (_) {},
            initialQuery: 'lampada',
          ),
        ),
      );
      expect(find.byTooltip('Lâmpada'), findsOneWidget);
      expect(find.byIcon(Icons.air), findsNothing);
    });

    testWidgets('SsColorPicker: ficha escolhe e hex lê', (t) async {
      Color? cor;
      await t.pumpWidget(
        _app(
          SsColorPicker(
            colors: const [Color(0xFFFFB74D), Color(0xFF64B5F6)],
            names: const ['Âmbar', 'Azul'],
            value: null,
            onChanged: (c) => cor = c,
            free: true,
          ),
        ),
      );
      await t.tap(find.byTooltip('Azul'));
      await t.pump(const Duration(milliseconds: 400));
      expect(cor, const Color(0xFF64B5F6));
      expect(find.byTooltip(SsStrings.pt.colorCustom), findsOneWidget);
      expect(SsColorPicker.parseHex('#fb4'), const Color(0xFFFFBB44));
      expect(SsColorPicker.parseHex('xyz'), isNull);
      expect(SsColorPicker.hex(const Color(0xFF2EC4B6)), '#2ec4b6');
    });

    testWidgets('SsBlockList: duplicable falso e deleteConfirm', (t) async {
      var apagou = 0;
      await t.pumpWidget(
        _app(
          SsBlockList(
            blocks: const [SsBlock(id: 'a', title: 'Gatilho', duplicable: false)],
            onDuplicate: (_) {},
            onDelete: (_) => apagou++,
            deleteConfirm: 'Excluir este bloco?',
          ),
        ),
      );
      // Só "Excluir" sobra no menu (sem "Duplicar"): vira botão direto.
      await t.tap(find.byType(SsOverflowMenu).first);
      await t.pumpAndSettle();
      expect(find.text(SsStrings.pt.duplicate), findsNothing);
      expect(find.text('Excluir este bloco?'), findsOneWidget);
      expect(apagou, 0);
    });
  });
}
