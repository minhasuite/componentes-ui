// v1.9 · produto: SsNotificationCenter, SsAssistantView e SsCaptureHub (pares do
// Ss::NotificationCenterComponent, Ss::AssistantComponent e Ss::CaptureHubComponent).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Locale locale = const Locale('pt')}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: AppTheme.light,
  locale: locale,
  supportedLocales: const [Locale('pt'), Locale('en'), Locale('es')],
  localizationsDelegates: const [SsStrings.delegate, ...GlobalMaterialLocalizations.delegates],
  home: Scaffold(body: child),
);

final _agora = DateTime(2026, 11, 24, 15);

SsNotificationItem _n(String id, {int diasAtras = 0, bool read = false, int hora = 10}) => SsNotificationItem(
  id: id,
  title: 'Aviso $id',
  body: 'Corpo $id',
  createdAt: DateTime(2026, 11, 24 - diasAtras, hora, 5),
  read: read,
);

/// Fonte de dados falsa: guarda o que foi chamado.
class _Fonte {
  _Fonte(this.paginas, {this.unread});
  final List<List<SsNotificationItem>> paginas;
  final int? unread;
  final pedidas = <int>[];
  final lidas = <String>[];
  final arquivadas = <String>[];
  var todas = 0;
  var falhaTodas = false;

  Future<SsNotificationPage> load(int p) async {
    pedidas.add(p);
    return SsNotificationPage(paginas[p - 1], hasMore: p < paginas.length, unreadCount: unread);
  }

  Future<void> markRead(String id) async => lidas.add(id);
  Future<void> archive(String id) async => arquivadas.add(id);
  Future<void> markAll() async {
    todas++;
    if (falhaTodas) throw Exception('rede');
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsNotificationCenter', () {
    test('rótulo do dia: Hoje, Ontem, dia da semana e data de outro ano', () {
      final s = SsStrings.pt;
      expect(SsNotificationCenter.dayLabel(DateTime(2026, 11, 24, 1), _agora, s), 'Hoje');
      expect(SsNotificationCenter.dayLabel(DateTime(2026, 11, 23, 23), _agora, s), 'Ontem');
      expect(SsNotificationCenter.dayLabel(DateTime(2026, 10, 5), _agora, s), 'segunda, 5 de outubro');
      expect(SsNotificationCenter.dayLabel(DateTime(2025, 12, 31), _agora, s), '31/12/2025');
      expect(SsNotificationCenter.dayLabel(DateTime(2026, 11, 23), _agora, SsStrings.en), 'Yesterday');
    });

    testWidgets('agrupa por dia, mostra não lidas e toca: marca lida e abre', (t) async {
      final f = _Fonte([
        [_n('1'), _n('2', diasAtras: 1, read: true), _n('3', diasAtras: 1)],
      ]);
      SsNotificationItem? aberta;
      final ctl = SsNotificationCenterController();
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            load: f.load,
            markRead: f.markRead,
            markAllRead: f.markAll,
            onOpen: (n) => aberta = n,
            controller: ctl,
            now: () => _agora,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('HOJE'), findsOneWidget);
      expect(find.text('ONTEM'), findsOneWidget);
      expect(find.text('2 não lidas'), findsOneWidget);
      expect(ctl.unreadCount, 2);
      expect(find.bySemanticsLabel(RegExp(r'^Aviso 1\. Corpo 1\. 10:05\. não lida$')), findsOneWidget);

      await t.tap(find.text('Aviso 1'));
      await t.pumpAndSettle();
      expect(f.lidas, ['1']);
      expect(aberta?.id, '1');
      expect(aberta?.read, isTrue);
      expect(ctl.unreadCount, 1);
      expect(find.text('1 não lida'), findsOneWidget);

      // Lida não chama markRead de novo, mas abre.
      await t.tap(find.text('Aviso 2'));
      await t.pumpAndSettle();
      expect(f.lidas, ['1']);
      expect(aberta?.id, '2');
    });

    testWidgets('marcar todas: otimista e volta se falhar', (t) async {
      final f = _Fonte([
        [_n('1'), _n('2')],
      ])..falhaTodas = true;
      await t.pumpWidget(_app(SsNotificationCenter(load: f.load, markAllRead: f.markAll, now: () => _agora)));
      await t.pumpAndSettle();
      await t.tap(find.text('Marcar todas como lidas'));
      await t.pump();
      expect(f.todas, 1);
      await t.pump(const Duration(milliseconds: 50));
      // Falhou: voltaram as não lidas.
      expect(find.text('2 não lidas'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();

      f.falhaTodas = false;
      await t.tap(find.text('Marcar todas como lidas'));
      await t.pumpAndSettle();
      expect(find.text('Marcar todas como lidas'), findsNothing);
    });

    testWidgets('contagem do servidor vale mais que a dos itens carregados', (t) async {
      final f = _Fonte([
        [_n('1')],
      ], unread: 12);
      int? ultimo;
      await t.pumpWidget(
        _app(SsNotificationCenter(load: f.load, markRead: f.markRead, onUnreadChanged: (n) => ultimo = n)),
      );
      await t.pumpAndSettle();
      expect(find.text('12 não lidas'), findsOneWidget);
      await t.tap(find.text('Aviso 1'));
      await t.pumpAndSettle();
      expect(ultimo, 11);
    });

    testWidgets('pagina sozinha sem repetir e mostra o fim', (t) async {
      final f = _Fonte([
        [for (var i = 0; i < 12; i++) _n('a$i', hora: 12 - i % 10)],
        [_n('a11'), _n('b1', diasAtras: 3)],
      ]);
      await t.pumpWidget(_app(SsNotificationCenter(load: f.load, now: () => _agora)));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView), const Offset(0, -3000));
      await t.pumpAndSettle();
      await t.drag(find.byType(ListView), const Offset(0, -3000));
      await t.pumpAndSettle();
      expect(f.pedidas, [1, 2]);
      expect(find.text('Aviso a11'), findsOneWidget);
      expect(find.text('Sem mais notificações'), findsOneWidget);
    });

    testWidgets('deslizar: direita marca lida, esquerda arquiva', (t) async {
      final f = _Fonte([
        [_n('1'), _n('2')],
      ]);
      await t.pumpWidget(
        _app(SsNotificationCenter(load: f.load, markRead: f.markRead, archive: f.archive, now: () => _agora)),
      );
      await t.pumpAndSettle();
      await t.drag(find.text('Aviso 1'), const Offset(300, 0));
      await t.pumpAndSettle();
      expect(f.lidas, ['1']);
      await t.drag(find.text('Aviso 2'), const Offset(-300, 0));
      await t.pumpAndSettle();
      expect(f.arquivadas, ['2']);
      expect(find.text('Aviso 2'), findsNothing);
      expect(find.text('Notificação arquivada'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
    });

    testWidgets('vazio e erro com tentar de novo', (t) async {
      await t.pumpWidget(_app(SsNotificationCenter(load: (_) async => const SsNotificationPage([]))));
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Nenhuma notificação'), findsOneWidget);

      var tentativas = 0;
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            key: const ValueKey('erro'),
            load: (_) async {
              tentativas++;
              throw Exception('x');
            },
            errorText: (_) => 'Sem internet',
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Sem internet'), findsOneWidget);
      await t.tap(find.text('Tentar de novo'));
      await t.pump(const Duration(seconds: 1));
      expect(tentativas, 2);
    });
  });

  group('SsAssistantView', () {
    testWidgets('vazio com atalhos; tocar no atalho chama onShortcut', (t) async {
      SsAssistantShortcut? usado;
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [],
            onSend: (_) {},
            emptyText: 'Pergunte sobre o seu treino.',
            shortcuts: const [SsAssistantShortcut('Resumo da semana', value: 'weekly')],
            onShortcut: (a) => usado = a,
          ),
        ),
      );
      expect(find.text('Como posso ajudar?'), findsOneWidget);
      await t.tap(find.text('Resumo da semana'));
      expect(usado?.value, 'weekly');
    });

    testWidgets('histórico, pendente vira pensando, ação sugerida e envio limpa o campo', (t) async {
      final enviados = <String>[];
      var montou = false;
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: [
              const SsAssistantMessage(id: '1', text: 'Monte um treino', fromMe: true),
              SsAssistantMessage(
                id: '2',
                text: 'Posso montar 4 dias.',
                action: SsAssistantAction(
                  title: 'Montar treino',
                  confirmLabel: 'Montar',
                  onConfirm: () => montou = true,
                ),
              ),
              const SsAssistantMessage(id: '3', status: SsAssistantStatus.pending),
            ],
            onSend: enviados.add,
            shortcuts: const [SsAssistantShortcut('Metas')],
            onShortcut: (_) {},
            quotaUsed: 3,
            quotaLimit: 10,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Monte um treino'), findsOneWidget);
      expect(find.byType(SsThinking), findsOneWidget);
      expect(find.byType(SsQuota), findsOneWidget);
      expect(find.text('Metas'), findsOneWidget);
      await t.tap(find.text('Montar'));
      expect(montou, isTrue);

      // Com pendente, o envio fica travado.
      await t.enterText(find.byType(TextField), 'Obrigado');
      await t.testTextInput.receiveAction(TextInputAction.send);
      expect(enviados, isEmpty);

      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [SsAssistantMessage(id: '1', text: 'Oi', fromMe: true)],
            onSend: enviados.add,
          ),
        ),
      );
      await t.enterText(find.byType(TextField), 'Obrigado');
      await t.testTextInput.receiveAction(TextInputAction.send);
      await t.pump();
      expect(enviados, ['Obrigado']);
      expect(find.text('Obrigado'), findsNothing);
    });

    testWidgets('falha com tentar de novo e plano sem direito sem campo', (t) async {
      SsAssistantMessage? tentou;
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [SsAssistantMessage(id: '9', status: SsAssistantStatus.failed)],
            onSend: (_) {},
            onRetryMessage: (m) => tentou = m,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      expect(find.text('Não deu para responder agora.'), findsOneWidget);
      await t.tap(find.text('Tentar de novo'));
      expect(tentou?.id, '9');

      var viu = false;
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [],
            onSend: (_) {},
            locked: SsAssistantLock(
              feature: 'Assistente com IA',
              text: 'Nos planos Pro e Max.',
              onUpgrade: () => viu = true,
            ),
          ),
        ),
      );
      expect(find.byType(SsPlanLocked), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      await t.tap(find.text('Ver planos'));
      expect(viu, isTrue);
    });

    testWidgets('cota esgotada trava o campo com o aviso', (t) async {
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [SsAssistantMessage(id: '1', text: 'Oi')],
            onSend: (_) {},
            inputEnabled: false,
            quotaUsed: 10,
            quotaLimit: 10,
          ),
        ),
      );
      await t.pump(const Duration(milliseconds: 600));
      final campo = t.widget<TextField>(find.byType(TextField));
      expect(campo.enabled, isFalse);
      expect(campo.decoration?.hintText, 'Mensagens do mês esgotadas');
    });

    testWidgets('tela larga: conversas ao lado; abrir, nova e apagar com confirmação', (t) async {
      t.view.physicalSize = const Size(1200, 800);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      String? aberta;
      var nova = 0;
      String? apagada;
      await t.pumpWidget(
        _app(
          SsAssistantView(
            messages: const [],
            onSend: (_) {},
            conversations: const [
              SsAssistantConversation(id: 'a', title: 'Treino de perna'),
              SsAssistantConversation(id: 'b'),
            ],
            currentConversationId: 'a',
            onOpenConversation: (c) => aberta = c.id,
            onNewConversation: () => nova++,
            onDeleteConversation: (c) => apagada = c.id,
          ),
        ),
      );
      expect(find.text('Conversas'), findsOneWidget);
      expect(find.text('ABERTA'), findsOneWidget);
      expect(find.text('Conversa'), findsOneWidget); // sem título
      await t.tap(find.text('Conversa'));
      expect(aberta, 'b');
      await t.tap(find.byTooltip('Nova conversa'));
      expect(nova, 1);
      await t.tap(find.byTooltip('Apagar conversa').first);
      await t.pumpAndSettle();
      expect(find.text('Apagar esta conversa?'), findsOneWidget);
      await t.tap(find.widgetWithText(SsButton, 'Apagar conversa'));
      await t.pumpAndSettle();
      expect(apagada, 'a');
    });

    testWidgets('folha de conversas no celular fecha ao abrir', (t) async {
      String? aberta;
      await t.pumpWidget(
        _app(
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showSsAssistantConversations(
                ctx,
                conversations: const [SsAssistantConversation(id: 'x', title: 'Metas')],
                onOpen: (c) => aberta = c.id,
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Metas'));
      await t.pumpAndSettle();
      expect(aberta, 'x');
      expect(find.text('Metas'), findsNothing);
    });
  });

  group('SsCaptureHub', () {
    testWidgets('destaque, padrões por tipo, indisponível com motivo e grupos', (t) async {
      final tocados = <String>[];
      await t.pumpWidget(
        _app(
          SingleChildScrollView(
            child: SsCaptureHub(
              options: [
                SsCaptureOption(
                  kind: SsCaptureKind.camera,
                  title: 'Foto do cupom',
                  highlighted: true,
                  onTap: () => tocados.add('foto'),
                ),
                SsCaptureOption(kind: SsCaptureKind.paste, group: 'Compra', onTap: () => tocados.add('colar')),
                SsCaptureOption(kind: SsCaptureKind.barcode, group: 'Produto', onTap: () => tocados.add('barras')),
                const SsCaptureOption(kind: SsCaptureKind.file, group: 'Produto', disabledReason: 'No plano Pro'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('RECOMENDADO'), findsOneWidget);
      expect(find.text('Colar texto'), findsOneWidget);
      expect(find.text('Cole o texto que você copiou'), findsOneWidget);
      expect(find.text('COMPRA'), findsOneWidget);
      expect(find.text('PRODUTO'), findsOneWidget);
      expect(find.text('No plano Pro'), findsOneWidget);
      expect(find.bySemanticsLabel('Enviar arquivo. No plano Pro. Indisponível'), findsOneWidget);
      await t.tap(find.text('Foto do cupom'));
      await t.tap(find.text('Colar texto'));
      await t.tap(find.text('Enviar arquivo'));
      expect(tocados, ['foto', 'colar']);
    });

    testWidgets('em inglês e na folha: fecha antes de chamar', (t) async {
      var leu = false;
      await t.pumpWidget(
        _app(
          locale: const Locale('en'),
          Builder(
            builder: (ctx) => TextButton(
              onPressed: () => showSsCaptureHub(
                ctx,
                title: 'Add',
                options: [SsCaptureOption(kind: SsCaptureKind.barcode, onTap: () => leu = true)],
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await t.tap(find.text('open'));
      await t.pumpAndSettle();
      expect(find.text('Point at the code'), findsOneWidget);
      await t.tap(find.text('Barcode'));
      await t.pumpAndSettle();
      expect(leu, isTrue);
      expect(find.text('Barcode'), findsNothing);
    });

    testWidgets('texto grande vira uma coluna', (t) async {
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(360, 800), textScaler: TextScaler.linear(1.6)),
            child: Scaffold(
              body: SingleChildScrollView(
                child: SsCaptureHub(
                  options: [
                    SsCaptureOption(kind: SsCaptureKind.camera, onTap: () {}),
                    SsCaptureOption(kind: SsCaptureKind.gallery, onTap: () {}),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final a = t.getTopLeft(find.text('Tirar foto'));
      final b = t.getTopLeft(find.text('Da galeria'));
      expect(b.dy, greaterThan(a.dy));
      expect(b.dx, a.dx);
    });
  });
}
