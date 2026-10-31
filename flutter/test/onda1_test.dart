import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:componentes_ui/componentes_ui.dart';

Widget _app(Widget body) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: body),
);

/// Botão que chama [acao] com um context dentro do Navigator.
Widget _botao(Future<void> Function(BuildContext) acao) => _app(
  Builder(
    builder: (ctx) => TextButton(onPressed: () => acao(ctx), child: const Text('abrir')),
  ),
);

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('SsAsyncBody', () {
    Widget corpo(AsyncValue<List<int>> v, {VoidCallback? retry, bool Function(Object)? offline}) => _app(
      SsAsyncBody<List<int>>(
        value: v,
        onRetry: retry,
        isOffline: offline,
        isEmpty: (l) => l.isEmpty,
        empty: const Text('vazio'),
        data: (l) => Text('itens ${l.length}'),
      ),
    );

    testWidgets('carregando, erro com retry, offline, vazio, dado', (t) async {
      await t.pumpWidget(corpo(const AsyncLoading()));
      expect(find.byType(SkeletonList), findsOneWidget);

      var tentou = 0;
      await t.pumpWidget(corpo(AsyncError(Exception('x'), StackTrace.empty), retry: () => tentou++));
      expect(find.text('Algo deu errado. Tente de novo.'), findsOneWidget);
      await t.tap(find.text('Tentar de novo'));
      expect(tentou, 1);

      await t.pumpWidget(corpo(AsyncError(Exception('x'), StackTrace.empty), offline: (_) => true));
      expect(find.textContaining('Sem conexão'), findsOneWidget);

      await t.pumpWidget(corpo(const AsyncData([])));
      expect(find.text('vazio'), findsOneWidget);

      await t.pumpWidget(corpo(const AsyncData([1, 2])));
      expect(find.text('itens 2'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('revalidando mantém o dado e mostra o fio', (t) async {
      await t.pumpWidget(corpo(const AsyncLoading<List<int>>().copyWithPrevious(const AsyncData([1]))));
      expect(find.text('itens 1'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  testWidgets('SsInlineAsync: erro compacto com retry', (t) async {
    var tentou = 0;
    await t.pumpWidget(
      _app(
        ListView(
          children: [
            SsInlineAsync<int>(
              value: AsyncError(Exception('x'), StackTrace.empty),
              onRetry: () => tentou++,
              data: (v) => Text('$v'),
            ),
          ],
        ),
      ),
    );
    await t.tap(find.text('Tentar de novo'));
    expect(tentou, 1);
  });

  testWidgets('SsPullToRefresh atualiza com lista curta', (t) async {
    var n = 0;
    await t.pumpWidget(
      _app(
        SsPullToRefresh(
          onRefresh: () async => n++,
          child: ListView(children: const [Text('um')]),
        ),
      ),
    );
    await t.fling(find.text('um'), const Offset(0, 400), 1000);
    await t.pumpAndSettle();
    expect(n, 1);
  });

  testWidgets('SsPagedList: carregar mais e fim da lista', (t) async {
    var pediu = 0;
    Widget lista(bool mais) => _app(
      SsPagedList<String>(
        items: const ['a', 'b'],
        hasMore: mais,
        onLoadMore: () async => pediu++,
        itemBuilder: (_, s) => Text(s),
      ),
    );
    await t.pumpWidget(lista(true));
    await t.tap(find.text('Carregar mais'));
    await t.pump();
    expect(pediu, 1);
    await t.pumpWidget(lista(false));
    expect(find.text('Fim da lista'), findsOneWidget);
  });

  group('diálogos', () {
    testWidgets('showSsConfirm devolve true/false', (t) async {
      bool? r;
      await t.pumpWidget(_botao((ctx) async => r = await showSsConfirm(ctx, title: 'Ok?', confirmLabel: 'Sim')));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Sim'));
      await t.pumpAndSettle();
      expect(r, isTrue);
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Cancelar'));
      await t.pumpAndSettle();
      expect(r, isFalse);
    });

    testWidgets('irreversível só libera com a palavra', (t) async {
      bool? r;
      await t.pumpWidget(
        _botao((ctx) async => r = await showSsConfirmIrreversible(ctx, title: 'Zerar?', word: 'APAGAR')),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.tap(find.text('Confirmar'));
      await t.pump();
      expect(r, isNull);
      await t.enterText(find.byType(TextField), 'apagar');
      await t.pump();
      await t.tap(find.text('Confirmar'));
      await t.pumpAndSettle();
      expect(r, isTrue);
    });

    testWidgets('showSsPrompt valida e devolve aparado', (t) async {
      String? r = 'nada';
      await t.pumpWidget(
        _botao(
          (ctx) async => r = await showSsPrompt(ctx, title: 'Nome', validator: (v) => v.length < 3 ? 'Curto' : null),
        ),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      await t.enterText(find.byType(TextFormField), 'ab');
      await t.tap(find.text('Salvar'));
      await t.pump();
      expect(find.text('Curto'), findsOneWidget);
      await t.enterText(find.byType(TextFormField), '  Feira  ');
      await t.tap(find.text('Salvar'));
      await t.pumpAndSettle();
      expect(r, 'Feira');
    });

    testWidgets('ssRunBlocking devolve, repassa o erro e sempre fecha', (t) async {
      int? r;
      Object? erro;
      await t.pumpWidget(
        _botao((ctx) async {
          r = await ssRunBlocking(ctx, () async => 7);
          try {
            await ssRunBlocking<void>(ctx, () async => throw StateError('falhou'));
          } catch (e) {
            erro = e;
          }
        }),
      );
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(r, 7);
      expect(erro, isA<StateError>());
      expect(find.byType(SsBlockingIndicator), findsNothing);
    });

    testWidgets('SsUnsavedGuard pergunta antes de sair', (t) async {
      final nav = GlobalKey<NavigatorState>();
      await t.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          navigatorKey: nav,
          home: const Scaffold(body: Text('inicio')),
        ),
      );
      nav.currentState!.push(
        MaterialPageRoute<void>(
          builder: (_) => const SsUnsavedGuard(dirty: true, child: Scaffold(body: Text('form'))),
        ),
      );
      await t.pumpAndSettle();
      nav.currentState!.maybePop();
      await t.pumpAndSettle();
      expect(find.text('Descartar as alterações?'), findsOneWidget);
      await t.tap(find.text('Descartar'));
      await t.pumpAndSettle();
      expect(find.text('inicio'), findsOneWidget);
      expect(find.text('form'), findsNothing);
    });

    testWidgets('showSsImageSource devolve a escolha', (t) async {
      SsImageSource? r;
      await t.pumpWidget(_botao((ctx) async => r = await showSsImageSource(ctx, allowRemove: true)));
      await t.tap(find.text('abrir'));
      await t.pumpAndSettle();
      expect(find.text('Remover foto'), findsOneWidget);
      await t.tap(find.text('Escolher da galeria'));
      await t.pumpAndSettle();
      expect(r, SsImageSource.gallery);
    });
  });

  testWidgets('SsOfflineBanner: sem conexão, de volta online e some', (t) async {
    Widget b(bool off) => _app(SsOfflineBanner(offline: off, child: const Text('tela')));
    await t.pumpWidget(b(false));
    expect(find.textContaining('Sem conexão'), findsNothing);
    await t.pumpWidget(b(true));
    await t.pumpAndSettle();
    expect(find.textContaining('Sem conexão'), findsOneWidget);
    await t.pumpWidget(b(false));
    await t.pump();
    expect(find.text('De volta online'), findsOneWidget);
    await t.pump(const Duration(seconds: 3));
    await t.pumpAndSettle();
    expect(find.text('De volta online'), findsNothing);
    expect(find.text('tela'), findsOneWidget);
  });

  group('showSsUndo', () {
    testWidgets('tocar em Desfazer devolve true', (t) async {
      bool? r;
      await t.pumpWidget(_botao((ctx) async => r = await showSsUndo(ctx, 'Pedido excluído')));
      await t.tap(find.text('abrir'));
      await t.pump();
      await t.pump(const Duration(milliseconds: 500));
      await t.tap(find.text('Desfazer'));
      await t.pump();
      expect(r, isTrue);
    });

    testWidgets('esgotar o tempo devolve false', (t) async {
      bool? r;
      await t.pumpWidget(_botao((ctx) async => r = await showSsUndo(ctx, 'Pedido excluído')));
      await t.tap(find.text('abrir'));
      await t.pump(const Duration(seconds: 6));
      await t.pumpAndSettle();
      expect(r, isFalse);
      expect(find.text('Pedido excluído'), findsNothing);
    });
  });
}
