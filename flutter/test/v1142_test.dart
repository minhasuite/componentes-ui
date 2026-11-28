// v1.14.2: o desfazer do arquivar dentro da SsNotificationCenter (unarchive:) e a aba Arquivadas
// (loadArchived:), pares do Ss::NotificationCenterComponent(archive_undo:, archived_url:, unarchive_href:).
import 'dart:io';

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

SsNotificationItem _n(String id, {bool read = false}) => SsNotificationItem(
  id: id,
  title: 'Aviso $id',
  body: 'Corpo $id',
  createdAt: DateTime(2026, 11, 24, 10),
  read: read,
);

/// Fonte falsa com caixa de entrada e arquivadas de verdade (arquivar move de uma para a outra).
class _Fonte {
  _Fonte(this.caixa, [List<SsNotificationItem>? arq]) : arq = arq ?? [];
  final List<SsNotificationItem> caixa;
  final List<SsNotificationItem> arq;
  final chamadas = <String>[];
  var falhaDesarquivar = false;

  Future<SsNotificationPage> load(int p) async => SsNotificationPage(List.of(caixa));
  Future<SsNotificationPage> loadArchived(int p) async {
    chamadas.add('arquivadas:$p');
    return SsNotificationPage(List.of(arq));
  }

  Future<void> archive(String id) async {
    chamadas.add('arquivar:$id');
    final i = caixa.indexWhere((n) => n.id == id);
    arq.insert(0, caixa.removeAt(i));
  }

  Future<void> unarchive(String id) async {
    chamadas.add('desarquivar:$id');
    if (falhaDesarquivar) throw Exception('rede');
    final i = arq.indexWhere((n) => n.id == id);
    caixa.insert(0, arq.removeAt(i));
  }
}

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('desfazer do arquivar (unarchive:)', () {
    testWidgets('o aviso ganha "Desfazer": desfaz, chama o unarchive e o item volta ao lugar', (t) async {
      final f = _Fonte([_n('1'), _n('2'), _n('3')]);
      final ctl = SsNotificationCenterController();
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            load: f.load,
            archive: f.archive,
            unarchive: f.unarchive,
            controller: ctl,
            now: () => _agora,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(ctl.unreadCount, 3);
      await t.drag(find.text('Aviso 2'), const Offset(-300, 0));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(f.chamadas, ['arquivar:2']);
      expect(find.text('Aviso 2'), findsNothing);
      expect(ctl.unreadCount, 2);
      expect(find.text('Notificação arquivada'), findsOneWidget);
      expect(find.text('Desfazer'), findsOneWidget);

      await t.tap(find.text('Desfazer'));
      await t.pump();
      // Volta crescendo: no meio da animação já está na árvore, na posição de antes.
      await t.pump(const Duration(milliseconds: 100));
      expect(find.text('Aviso 2'), findsOneWidget);
      await t.pumpAndSettle();
      expect(f.chamadas, ['arquivar:2', 'desarquivar:2']);
      expect(ctl.items.map((n) => n.id), ['1', '2', '3']);
      expect(ctl.unreadCount, 3);
      final y1 = t.getTopLeft(find.text('Aviso 1')).dy;
      final y2 = t.getTopLeft(find.text('Aviso 2')).dy;
      final y3 = t.getTopLeft(find.text('Aviso 3')).dy;
      expect(y1 < y2 && y2 < y3, isTrue);
    });

    testWidgets('desfazer que falha no servidor tira o item de novo e avisa', (t) async {
      final f = _Fonte([_n('1'), _n('2')])..falhaDesarquivar = true;
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            load: f.load,
            archive: f.archive,
            unarchive: f.unarchive,
            errorText: (_) => 'Sem internet',
            now: () => _agora,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.drag(find.text('Aviso 1'), const Offset(-300, 0));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      await t.tap(find.text('Desfazer'));
      await t.pumpAndSettle();
      expect(find.text('Aviso 1'), findsNothing);
      expect(find.text('Sem internet'), findsOneWidget);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
    });

    testWidgets('sem unarchive:, o aviso fica como antes (sem Desfazer)', (t) async {
      final f = _Fonte([_n('1'), _n('2')]);
      await t.pumpWidget(_app(SsNotificationCenter(load: f.load, archive: f.archive, now: () => _agora)));
      await t.pumpAndSettle();
      await t.drag(find.text('Aviso 1'), const Offset(-300, 0));
      for (var i = 0; i < 20; i++) {
        await t.pump(const Duration(milliseconds: 50));
      }
      expect(find.text('Notificação arquivada'), findsOneWidget);
      expect(find.text('Desfazer'), findsNothing);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();
    });
  });

  group('aba Arquivadas (loadArchived:)', () {
    testWidgets('sem loadArchived não há abas', (t) async {
      final f = _Fonte([_n('1')]);
      await t.pumpWidget(_app(SsNotificationCenter(load: f.load, now: () => _agora)));
      await t.pumpAndSettle();
      expect(find.text('Arquivadas'), findsNothing);
      expect(find.byType(SsSegmented<SsNotificationView>), findsNothing);
    });

    testWidgets('Caixa de entrada | Arquivadas: a aba relê, não conta no sino e desarquiva', (t) async {
      final f = _Fonte([_n('1'), _n('2')], [_n('9'), _n('8', read: true)]);
      final ctl = SsNotificationCenterController();
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            load: f.load,
            loadArchived: f.loadArchived,
            archive: f.archive,
            unarchive: f.unarchive,
            markAllRead: () async {},
            controller: ctl,
            now: () => _agora,
          ),
        ),
      );
      await t.pumpAndSettle();
      expect(find.text('Caixa de entrada'), findsOneWidget);
      expect(find.text('Arquivadas'), findsOneWidget);
      expect(find.text('2 não lidas'), findsOneWidget);
      expect(f.chamadas, isEmpty); // as arquivadas só carregam ao abrir a aba

      await t.tap(find.text('Arquivadas'));
      await t.pumpAndSettle();
      expect(ctl.view, SsNotificationView.archived);
      expect(f.chamadas, ['arquivadas:1']);
      expect(find.text('Aviso 9'), findsOneWidget);
      expect(find.text('Aviso 1'), findsNothing);
      // Sem a faixa de não lidas e sem o sino contar a arquivada não lida.
      expect(find.textContaining('não lida'), findsNothing);
      expect(ctl.unreadCount, 2);

      // Desarquivar (deslizar para a esquerda): sai da aba, volta à caixa e o sino conta.
      final h = t.ensureSemantics();
      final sem = t.getSemantics(find.bySemanticsLabel(RegExp('^Aviso 9')));
      expect(sem.getSemanticsData().customSemanticsActionIds, isNotEmpty);
      h.dispose();
      await t.drag(find.text('Aviso 9'), const Offset(-300, 0));
      await t.pumpAndSettle();
      expect(f.chamadas.last, 'desarquivar:9');
      expect(find.text('Aviso 9'), findsNothing);
      expect(find.text('Notificação de volta à caixa de entrada'), findsOneWidget);
      expect(ctl.unreadCount, 3);
      await t.pump(const Duration(seconds: 5));
      await t.pumpAndSettle();

      await ctl.show(SsNotificationView.inbox);
      await t.pumpAndSettle();
      expect(find.text('Aviso 9'), findsOneWidget);
      expect(find.text('3 não lidas'), findsOneWidget);
    });

    testWidgets('initialView: archived abre nas arquivadas; vazio próprio', (t) async {
      final f = _Fonte([_n('1')]);
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            load: f.load,
            loadArchived: f.loadArchived,
            initialView: SsNotificationView.archived,
            now: () => _agora,
          ),
        ),
      );
      await t.pump(const Duration(seconds: 1));
      expect(find.text('Nenhuma notificação arquivada'), findsOneWidget);
      expect(find.text('O que você arquivar fica aqui, fora da caixa de entrada.'), findsOneWidget);
    });

    testWidgets('arquivar na caixa e abrir a aba: o arquivado aparece lá', (t) async {
      final f = _Fonte([_n('1'), _n('2')]);
      await t.pumpWidget(
        _app(
          SsNotificationCenter(
            load: f.load,
            loadArchived: f.loadArchived,
            archive: f.archive,
            unarchive: f.unarchive,
            now: () => _agora,
          ),
        ),
      );
      await t.pumpAndSettle();
      await t.drag(find.text('Aviso 1'), const Offset(-300, 0));
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      await t.tap(find.text('Arquivadas'));
      await t.pumpAndSettle();
      expect(find.text('Aviso 1'), findsOneWidget);
      expect(find.text('Aviso 2'), findsNothing);
    });

    for (final (loc, caixa, arq, desarq) in [
      (const Locale('en'), 'Inbox', 'Archived', 'Unarchive'),
      (const Locale('es'), 'Bandeja de entrada', 'Archivadas', 'Desarchivar'),
    ]) {
      testWidgets('textos em ${loc.languageCode}', (t) async {
        final f = _Fonte([_n('1')], [_n('9')]);
        await t.pumpWidget(
          _app(
            SsNotificationCenter(load: f.load, loadArchived: f.loadArchived, unarchive: f.unarchive, now: () => _agora),
            locale: loc,
          ),
        );
        await t.pumpAndSettle();
        expect(find.text(caixa), findsOneWidget);
        expect(find.text(arq), findsOneWidget);
        final s = loc.languageCode == 'en' ? SsStrings.en : SsStrings.es;
        expect(s.notifUnarchive, desarq);
      });
    }
  });

  test('SsAppleButton: o glifo continua o do Simple Icons e a origem está escrita', () {
    final src = File('lib/src/v1110/apple_button.dart').readAsStringSync().replaceAll(RegExp(r'\n\s*///'), '');
    expect(src, contains('Simple Icons'));
    expect(src, contains('Apple Design Resources License'));
  });
}
