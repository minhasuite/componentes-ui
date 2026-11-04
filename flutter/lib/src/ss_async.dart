import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'safe_list_padding.dart';
import 'skeleton.dart';
import 'ss_aurora.dart';
import 'ss_error_view.dart';
import 'ss_strings.dart';

String _mensagem(
  BuildContext context,
  Object e,
  bool Function(Object)? isOffline,
  String Function(Object)? errorMessage,
) {
  final s = SsStrings.of(context);
  return (isOffline?.call(e) ?? false) ? s.offlineError : (errorMessage?.call(e) ?? s.genericError);
}

/// Fio de 2 px no topo enquanto revalida com o dado anterior na tela.
Widget _fio() => const Positioned(
  top: 0,
  left: 0,
  right: 0,
  child: LinearProgressIndicator(minHeight: 2, backgroundColor: Colors.transparent),
);

/// Corpo de tela a partir de um `AsyncValue` (Riverpod):
/// carregando = [loading] ou [SkeletonList]; erro = [SsErrorView] com "Tentar
/// de novo" ([onRetry]), com texto de sem conexão quando [isOffline] diz que
/// é erro de rede; [isEmpty] + [empty] mostram o estado vazio (ex.
/// [SsEmptyState]). Revalidar com dado anterior não pisca: o dado fica e um
/// fio de progresso aparece no topo (erro com dado velho também mantém o dado).
///
/// `SsAsyncBody(value: ref.watch(pedidos), data: (l) => Lista(l), onRetry: () => ref.invalidate(pedidos))`
class SsAsyncBody<T> extends StatelessWidget {
  const SsAsyncBody({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loading,
    this.isEmpty,
    this.empty,
    this.isOffline,
    this.errorMessage,
    this.showRefreshing = true,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  /// Falso em tela que se atualiza sozinha (a cada poucos segundos): sem o fio.
  final bool showRefreshing;
  final VoidCallback? onRetry;
  final Widget? loading;
  final bool Function(T data)? isEmpty;
  final Widget? empty;

  /// Diz se o erro é de rede (o app sabe o tipo da exceção dele).
  final bool Function(Object error)? isOffline;

  /// Texto do erro; sem ele, uma mensagem genérica.
  final String Function(Object error)? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final v = value.requireValue;
      final vazio = empty != null && (isEmpty?.call(v) ?? false);
      return Stack(
        children: [
          Positioned.fill(child: vazio ? empty! : data(v)),
          if (value.isLoading && showRefreshing) _fio(),
        ],
      );
    }
    if (value.hasError) {
      return SsErrorView(message: _mensagem(context, value.error!, isOffline, errorMessage), onRetry: onRetry);
    }
    return loading ?? const SkeletonList();
  }
}

/// O mesmo que [SsAsyncBody] para uma seção dentro de uma lista que já rola:
/// compacto e sem `Expanded`. Carregando = [SkeletonBox] de [loadingHeight];
/// erro = uma linha com o texto e "Tentar de novo"; vazio = [empty] (ou nada).
class SsInlineAsync<T> extends StatelessWidget {
  const SsInlineAsync({
    super.key,
    required this.value,
    required this.data,
    this.onRetry,
    this.loadingHeight = 72,
    this.isEmpty,
    this.empty,
    this.isOffline,
    this.errorMessage,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;
  final double loadingHeight;
  final bool Function(T data)? isEmpty;
  final Widget? empty;
  final bool Function(Object error)? isOffline;
  final String Function(Object error)? errorMessage;

  @override
  Widget build(BuildContext context) {
    if (value.hasValue) {
      final v = value.requireValue;
      final Widget corpo = (isEmpty?.call(v) ?? false) ? (empty ?? const SizedBox.shrink()) : data(v);
      return Stack(children: [corpo, if (value.isLoading) _fio()]);
    }
    if (value.hasError) {
      final c = SsColors.of(context);
      final offline = isOffline?.call(value.error!) ?? false;
      return Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(offline ? Icons.cloud_off_rounded : Icons.error_outline, size: 20, color: c.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _mensagem(context, value.error!, isOffline, errorMessage),
                  style: TextStyle(color: c.ink2, fontSize: AppType.sub),
                ),
              ),
              if (onRetry != null) TextButton(onPressed: onRetry, child: Text(SsStrings.of(context).retry)),
            ],
          ),
        ),
      );
    }
    return SkeletonBox(height: loadingHeight);
  }
}

/// Marca uma peça que monta a própria rolagem (um `CustomScrollView` por
/// dentro): o [SsPullToRefresh] a usa como está, sem embrulhar num
/// `SingleChildScrollView` (que a deixaria sem altura limitada).
abstract interface class SsSelfScrolling {}

/// Puxar para atualizar que funciona com lista curta (força rolagem sempre,
/// inclusive em `ListView` sem `physics`), na cor da marca e com haptic ao
/// disparar. Enquanto puxa, um brilho de aurora acende no topo na medida do
/// arraste e pulsa leve enquanto atualiza (parado com menos movimento).
/// [child] pode ser uma lista ou qualquer widget (vira rolável).
///
/// O que já rola por dentro vai direto, sem embrulho: `ScrollView`
/// (ListView, CustomScrollView, GridView), `SingleChildScrollView`,
/// `NestedScrollView`, `Scrollable`, `PageView` e as peças marcadas com
/// [SsSelfScrolling] ([SsLogbook], [SsPagedList], [SsScreenHeader],
/// [SsMenuView]). Para um widget próprio que monta a sua rolagem (e precisa
/// de altura limitada), passe [scrollable] `true`; `false` força o embrulho.
class SsPullToRefresh extends StatefulWidget {
  const SsPullToRefresh({super.key, required this.onRefresh, required this.child, this.scrollable});

  final Future<void> Function() onRefresh;
  final Widget child;

  /// O [child] já rola sozinho? Nulo = descobre pelo tipo (ver acima).
  final bool? scrollable;

  /// O [child] já rola por dentro (não precisa de `SingleChildScrollView`).
  static bool selfScrolling(Widget child) =>
      child is ScrollView ||
      child is SingleChildScrollView ||
      child is NestedScrollView ||
      child is Scrollable ||
      child is PageView ||
      child is SsSelfScrolling;

  @override
  State<SsPullToRefresh> createState() => _SsPullToRefreshState();
}

class _SsPullToRefreshState extends State<SsPullToRefresh> with SingleTickerProviderStateMixin {
  static const _curso = 110.0; // arraste que acende o brilho por inteiro
  final _puxado = ValueNotifier<double>(0);
  late final _pulso = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
  bool _atualizando = false;

  @override
  void dispose() {
    _puxado.dispose();
    _pulso.dispose();
    super.dispose();
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0 || _atualizando) return false;
    if (n is OverscrollNotification && n.overscroll < 0 && n.dragDetails != null) {
      _puxado.value = math.min(1, _puxado.value - n.overscroll / _curso);
    } else if (n is ScrollUpdateNotification && n.metrics.pixels < n.metrics.minScrollExtent) {
      _puxado.value = math.min(1, (n.metrics.minScrollExtent - n.metrics.pixels) / _curso); // iOS (bounce)
    } else if (n is ScrollUpdateNotification && _puxado.value > 0 && n.metrics.pixels > n.metrics.minScrollExtent) {
      _puxado.value = 0;
    } else if (n is ScrollEndNotification) {
      _puxado.value = 0;
    }
    return false;
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _atualizando = true);
    _puxado.value = 1;
    if (!reduceMotion(context)) _pulso.repeat(reverse: true);
    try {
      await widget.onRefresh();
    } finally {
      if (mounted) {
        _pulso.stop();
        _puxado.value = 0;
        setState(() => _atualizando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final child = widget.scrollable ?? SsPullToRefresh.selfScrolling(widget.child)
        ? widget.child
        : LayoutBuilder(
            builder: (_, box) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: box.maxHeight),
                child: widget.child,
              ),
            ),
          );
    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: Stack(
        children: [
          ScrollConfiguration(
            behavior: _SempreRola(ScrollConfiguration.of(context)),
            child: RefreshIndicator(onRefresh: _refresh, color: c.accent, backgroundColor: c.surface, child: child),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 140,
            child: IgnorePointer(
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _Brilho(Listenable.merge([_puxado, _pulso]), _puxado, _pulso, auroraColors(c), c.isDark),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Repassa tudo ao comportamento de rolagem do app, só força a rolagem sempre.
class _SempreRola extends ScrollBehavior {
  const _SempreRola(this.base);
  final ScrollBehavior base;

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) =>
      AlwaysScrollableScrollPhysics(parent: base.getScrollPhysics(context));

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) =>
      base.buildOverscrollIndicator(context, child, details);

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) =>
      base.buildScrollbar(context, child, details);

  @override
  Set<PointerDeviceKind> get dragDevices => base.dragDevices;
}

class _Brilho extends CustomPainter {
  _Brilho(Listenable repaint, this.puxado, this.pulso, this.cores, this.escuro) : super(repaint: repaint);
  final ValueNotifier<double> puxado;
  final AnimationController pulso;
  final List<Color> cores;
  final bool escuro;

  @override
  void paint(Canvas canvas, Size size) {
    final t = Curves.easeOut.transform(puxado.value) * (1 - .35 * pulso.value);
    if (t <= 0) return;
    final pos = [.18, .55, .9];
    for (var i = 0; i < cores.length; i++) {
      final centro = Offset(size.width * pos[i], 0);
      final r = size.width * .42 * (.7 + .3 * t);
      final cor = cores[i].withValues(alpha: (escuro ? .42 : .30) * t);
      canvas.drawCircle(
        centro,
        r,
        Paint()
          ..shader = RadialGradient(
            colors: [cor, cor.withValues(alpha: 0)],
          ).createShader(Rect.fromCircle(center: centro, radius: r)),
      );
    }
  }

  @override
  bool shouldRepaint(_Brilho old) => old.cores != cores || old.escuro != escuro;
}

/// Rodapé de lista paginada: carregando (spinner), "Carregar mais" (quando
/// [hasMore]) ou "Fim da lista" ([endLabel] troca o texto do fim:
/// "Início do registro", "Sem mais avisos").
class SsLoadMore extends StatelessWidget {
  const SsLoadMore({super.key, required this.hasMore, this.loading = false, this.onLoadMore, this.endLabel});

  final bool hasMore;
  final bool loading;
  final VoidCallback? onLoadMore;

  /// Texto do fim da lista. Padrão: [SsStrings.endOfList].
  final String? endLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final Widget w;
    if (loading) {
      w = Semantics(
        label: SsStrings.of(context).loadingMore,
        child: const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
      );
    } else if (hasMore) {
      w = TextButton.icon(
        onPressed: onLoadMore,
        icon: const Icon(Icons.expand_more_rounded),
        label: Text(SsStrings.of(context).loadMore),
      );
    } else {
      w = Text(
        endLabel ?? SsStrings.of(context).endOfList,
        style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
      );
    }
    return SizedBox(height: 56, child: Center(child: w));
  }
}

/// Lista paginada: pede a próxima página ([onLoadMore]) sozinha quando a
/// rolagem chega perto do fim e mostra o [SsLoadMore] no rodapé. Com
/// [onRefresh], ganha o [SsPullToRefresh]. Se a página falhar, para de pedir
/// sozinha e deixa o "Carregar mais" para tentar de novo.
class SsPagedList<T> extends StatefulWidget implements SsSelfScrolling {
  const SsPagedList({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    required this.hasMore,
    this.onRefresh,
    this.padding,
    this.separator = 10,
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Future<void> Function() onLoadMore;
  final bool hasMore;
  final Future<void> Function()? onRefresh;

  /// Sem ele, [safeListPadding].
  final EdgeInsets? padding;
  final double separator;

  @override
  State<SsPagedList<T>> createState() => _SsPagedListState<T>();
}

class _SsPagedListState<T> extends State<SsPagedList<T>> {
  bool _carregando = false;
  bool _falhou = false;

  Future<void> _mais() async {
    if (_carregando || !widget.hasMore) return;
    setState(() {
      _carregando = true;
      _falhou = false;
    });
    try {
      await widget.onLoadMore();
    } catch (_) {
      _falhou = true; // o app mostra o erro; aqui só não insiste sozinho
    } finally {
      if (mounted) setState(() => _carregando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.items.length;
    Widget lista = NotificationListener<ScrollNotification>(
      onNotification: (s) {
        if (s.depth == 0 && s.metrics.extentAfter < 400 && !_falhou) _mais();
        return false;
      },
      child: ListView.separated(
        padding: widget.padding ?? safeListPadding(context),
        itemCount: n + 1,
        separatorBuilder: (_, _) => SizedBox(height: widget.separator),
        itemBuilder: (context, i) => i < n
            ? widget.itemBuilder(context, widget.items[i])
            : (n == 0 && !widget.hasMore
                  ? const SizedBox.shrink()
                  : SsLoadMore(hasMore: widget.hasMore, loading: _carregando, onLoadMore: _mais)),
      ),
    );
    if (widget.onRefresh != null) lista = SsPullToRefresh(onRefresh: widget.onRefresh!, child: lista);
    return lista;
  }
}
