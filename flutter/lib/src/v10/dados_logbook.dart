// v0.10 (dados): logbook (diário de eventos) agrupado por dia, com o
// cabeçalho do dia grudado no topo e o "carregar mais" no fim.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../skeleton.dart';
import '../ss_async.dart' show SsSelfScrolling;
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_empty_state.dart';
import '../ss_strings.dart';
import 'dados_formato.dart';

/// Um evento do [SsLogbook]: quando, o quê ([title]), um [detail] opcional
/// ("pela automação Boa noite · Ana"), o ícone com o tom e, se quiser, o
/// estado novo em pílula ([state]: "Ligada"). [onTap] torna a linha tocável.
class SsLogEntry {
  const SsLogEntry({
    required this.at,
    required this.title,
    this.detail,
    this.icon,
    this.tone = SsTone.neutral,
    this.state,
    this.onTap,
  });

  final DateTime at;
  final String title;
  final String? detail;
  final IconData? icon;
  final SsTone tone;
  final String? state;
  final VoidCallback? onTap;
}

/// Logbook: eventos em ordem (o mais novo primeiro), agrupados por dia sob um
/// cabeçalho que gruda no topo ("Hoje", "Ontem", depois a data). Cada linha
/// tem a hora, o ícone num quadrado tonal, o título e o detalhe.
///
/// - Fim da lista: com [hasMore], chama [onLoadMore] sozinho perto do fim
///   (e mostra o botão "Carregar mais"); [loadingMore] põe o rodapé em
///   carregamento; sem [hasMore], mostra [endLabel].
/// - [loading] (1ª carga): linhas-fantasma. [error]: sem eventos, a tela de
///   erro com [onRetry]; com eventos, o erro vai no rodapé.
/// - As linhas entram em cascata quando aparecem na tela.
///
/// É uma lista rolável (CustomScrollView); [header] vai em cima (filtros).
/// Dentro do [SsPullToRefresh] vai direto (é [SsSelfScrolling]).
///
/// [SsLogbook.sliver] é a mesma peça como sliver, para ir num
/// `CustomScrollView` com outros slivers (ex.: nos `slivers` do
/// [SsScreenHeader], abaixo do [SsSliverHeader]): os dias grudam abaixo do
/// cabeçalho e o "carregar mais" sozinho escuta a rolagem de fora.
///
/// `SsLogbook(entries: eventos, hasMore: true, loadingMore: carregando, onLoadMore: proxima)`
class SsLogbook extends StatefulWidget implements SsSelfScrolling {
  const SsLogbook({
    super.key,
    required this.entries,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
    this.onLoadMore,
    this.onRetry,
    this.header,
    this.now,
    this.locale,
    this.background,
    this.padding = const EdgeInsets.only(bottom: 24),
    this.shrinkWrap = false,
    this.physics,
    this.controller,
    this.autoLoad = true,
    this.todayLabel,
    this.yesterdayLabel,
    this.loadMoreLabel,
    this.loadingMoreLabel,
    this.endLabel,
    this.emptyTitle,
    this.emptySubtitle,
    this.retryLabel,
    this.label,
    this.utcOffset,
    this.endAction,
    this.showEnd = true,
  }) : _sliver = false;

  /// O logbook como sliver (sem rolagem própria): vai num `CustomScrollView`
  /// junto de outros slivers. `SsScreenHeader(title: 'Histórico',
  /// slivers: [SsLogbook.sliver(entries: eventos, hasMore: true, onLoadMore: proxima)])`.
  const SsLogbook.sliver({
    super.key,
    required this.entries,
    this.loading = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.error,
    this.onLoadMore,
    this.onRetry,
    this.header,
    this.now,
    this.locale,
    this.background,
    this.padding = const EdgeInsets.only(bottom: 24),
    this.autoLoad = true,
    this.todayLabel,
    this.yesterdayLabel,
    this.loadMoreLabel,
    this.loadingMoreLabel,
    this.endLabel,
    this.emptyTitle,
    this.emptySubtitle,
    this.retryLabel,
    this.label,
    this.utcOffset,
    this.endAction,
    this.showEnd = true,
  }) : _sliver = true,
       shrinkWrap = false,
       physics = null,
       controller = null;

  final bool _sliver;

  final List<SsLogEntry> entries;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;

  /// Mensagem de erro (da 1ª carga ou da página seguinte).
  final String? error;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;

  /// Vai em cima da lista (filtros, busca).
  final Widget? header;

  /// "Agora" para saber o que é hoje e ontem (padrão: o relógio).
  final DateTime? now;

  /// Idioma da hora e da data (padrão: o do `Localizations`).
  final Locale? locale;

  /// Fundo do cabeçalho do dia que gruda (padrão: o da página).
  final Color? background;
  final EdgeInsets padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  /// Só na forma em caixa (no [SsLogbook.sliver], a rolagem é a de fora).
  final ScrollController? controller;

  /// Pede a próxima página sozinho quando falta pouco para o fim.
  final bool autoLoad;

  final String? todayLabel;
  final String? yesterdayLabel;
  final String? loadMoreLabel;
  final String? loadingMoreLabel;
  final String? endLabel;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String? retryLabel;

  /// Nome da lista para o leitor de tela.
  final String? label;

  /// Fuso fixo da hora e do dia (ex.: `Duration(hours: -3)`, o do site);
  /// nulo = o do aparelho. Ver [SsTimeFormat.utcOffset].
  final Duration? utcOffset;

  /// No fim do registro (sem [hasMore]), abaixo do [endLabel]: um link ou
  /// botão, como `SsButton.text(label: 'Ver um período maior', onPressed: …)`.
  final Widget? endAction;

  /// Falso esconde a marca "Início do registro" do fim (o [endAction], se
  /// houver, continua).
  final bool showEnd;

  /// Agrupa [entries] por dia (do aparelho, ou no [utcOffset]), na ordem
  /// em que vieram.
  static List<(DateTime, List<SsLogEntry>)> groupByDay(List<SsLogEntry> entries, {Duration? utcOffset}) {
    final out = <(DateTime, List<SsLogEntry>)>[];
    final fmt = SsTimeFormat(null, utcOffset: utcOffset);
    for (final e in entries) {
      final d = fmt.dateOf(e.at);
      if (out.isEmpty || out.last.$1 != d) out.add((d, <SsLogEntry>[]));
      out.last.$2.add(e);
    }
    return out;
  }

  @override
  State<SsLogbook> createState() => _SsLogbookState();
}

class _SsLogbookState extends State<SsLogbook> {
  SsStrings get _s => SsStrings.of(context);
  bool _pedido = false;

  // Na forma sliver: a rolagem de fora, escutada para o "carregar mais".
  ScrollPosition? _posicao;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final p = widget._sliver ? Scrollable.maybeOf(context)?.position : null;
    if (p == _posicao) return;
    _posicao?.removeListener(_rolou);
    _posicao = p?..addListener(_rolou);
  }

  @override
  void dispose() {
    _posicao?.removeListener(_rolou);
    super.dispose();
  }

  void _rolou() {
    final p = _posicao;
    if (p == null || !p.hasContentDimensions) return;
    // A rolagem pode avisar no meio do layout: o pedido vai depois do quadro.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      _talvezCarregue(p);
    } else {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && _posicao != null) _talvezCarregue(_posicao!);
      });
    }
  }

  @override
  void didUpdateWidget(SsLogbook old) {
    super.didUpdateWidget(old);
    // Chegou a página (ou mudou o estado): pode pedir de novo.
    if (old.entries.length != widget.entries.length || old.loadingMore != widget.loadingMore) _pedido = false;
  }

  void _talvezCarregue(ScrollMetrics m) {
    if (!widget.autoLoad || !widget.hasMore || widget.loadingMore || widget.error != null || _pedido) return;
    if (m.extentAfter > 320) return;
    _pedido = true;
    widget.onLoadMore?.call();
  }

  String _dia(DateTime d, SsTimeFormat fmt) {
    final agora = fmt.wall(widget.now ?? DateTime.now());
    final hoje = DateTime(agora.year, agora.month, agora.day);
    if (d == hoje) return widget.todayLabel ?? _s.today;
    if (d == DateTime(hoje.year, hoje.month, hoje.day - 1)) return widget.yesterdayLabel ?? _s.yesterday;
    return fmt.day(d, now: agora);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final fmt = SsTimeFormat.of(context, widget.locale, widget.utcOffset);
    final fundo = widget.background ?? c.page;
    final slivers = <Widget>[if (widget.header != null) SliverToBoxAdapter(child: widget.header)];

    if (widget.loading) {
      slivers.add(
        SliverToBoxAdapter(
          child: Semantics(
            label: widget.loadingMoreLabel ?? _s.loadingEllipsis,
            child: Column(children: [for (var i = 0; i < 6; i++) const _LinhaFantasma()]),
          ),
        ),
      );
    } else if (widget.entries.isEmpty && widget.error != null) {
      slivers.add(_preenche(_Erro(widget.error!, widget.onRetry, widget.retryLabel ?? _s.retry)));
    } else if (widget.entries.isEmpty) {
      slivers.add(
        _preenche(
          Center(
            child: SsEmptyState(
              compact: true,
              icon: Icons.history_rounded,
              title: widget.emptyTitle ?? _s.logbookEmpty,
              subtitle: widget.emptySubtitle,
            ),
          ),
        ),
      );
    } else {
      for (final (dia, itens) in SsLogbook.groupByDay(widget.entries, utcOffset: widget.utcOffset)) {
        final titulo = _dia(dia, fmt);
        slivers.add(
          SliverMainAxisGroup(
            slivers: [
              SliverPersistentHeader(pinned: true, delegate: _Cabecalho(titulo, fundo, c.muted)),
              SliverList.builder(
                itemCount: itens.length,
                itemBuilder: (context, i) => SsInViewReveal(
                  index: math.min(i, 8),
                  offset: 10,
                  child: _Linha(itens[i], fmt, last: i == itens.length - 1),
                ),
              ),
            ],
          ),
        );
      }
      slivers.add(SliverToBoxAdapter(child: _rodape(context)));
    }
    slivers.add(SliverPadding(padding: widget.padding));

    // Sliver: sem rolagem própria (o "carregar mais" escuta a de fora).
    if (widget._sliver) return SliverMainAxisGroup(slivers: slivers);

    return Semantics(
      label: widget.label ?? _s.logbookLabel,
      container: true,
      child: NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n.depth == 0) _talvezCarregue(n.metrics);
          return false;
        },
        child: CustomScrollView(
          controller: widget.controller,
          shrinkWrap: widget.shrinkWrap,
          physics: widget.physics,
          slivers: slivers,
        ),
      ),
    );
  }

  // Vazio e erro: ocupam o resto da tela na caixa; no sliver, um bloco com folga.
  Widget _preenche(Widget filho) => widget._sliver
      ? SliverToBoxAdapter(
          child: Padding(padding: const EdgeInsets.symmetric(vertical: 32), child: filho),
        )
      : SliverFillRemaining(hasScrollBody: false, child: filho);

  Widget _rodape(BuildContext context) {
    final c = SsColors.of(context);
    final estilo = TextStyle(color: c.muted, fontSize: AppType.sub);
    final Widget filho;
    if (widget.error != null) {
      filho = Column(
        children: [
          Text(
            widget.error!,
            textAlign: TextAlign.center,
            style: estilo.copyWith(color: c.dangerText),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 8),
            SsButton(
              label: widget.retryLabel ?? _s.retry,
              icon: Icons.refresh_rounded,
              variant: SsButtonVariant.ghost,
              small: true,
              expand: false,
              onPressed: widget.onRetry,
            ),
          ],
        ],
      );
    } else if (widget.loadingMore) {
      filho = Semantics(
        liveRegion: true,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: c.accent)),
            const SizedBox(width: 10),
            Text(widget.loadingMoreLabel ?? _s.loadingEllipsis, style: estilo),
          ],
        ),
      );
    } else if (widget.hasMore) {
      filho = SsButton(
        label: widget.loadMoreLabel ?? _s.loadMore,
        icon: Icons.expand_more_rounded,
        variant: SsButtonVariant.ghost,
        small: true,
        expand: false,
        onPressed: widget.onLoadMore,
      );
    } else {
      final fim = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flag_outlined, size: 16, color: c.muted2),
          const SizedBox(width: 6),
          Text(widget.endLabel ?? _s.logbookEnd, style: estilo),
        ],
      );
      filho = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.showEnd) fim,
          if (widget.showEnd && widget.endAction != null) const SizedBox(height: 6),
          ?widget.endAction,
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: Center(
        child: AnimatedSwitcher(duration: reduceMotion(context) ? Duration.zero : SsMotion.fast, child: filho),
      ),
    );
  }
}

class _Cabecalho extends SliverPersistentHeaderDelegate {
  _Cabecalho(this.titulo, this.fundo, this.cor);

  final String titulo;
  final Color fundo, cor;

  @override
  double get minExtent => 34;
  @override
  double get maxExtent => 34;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) => Semantics(
    header: true,
    child: Container(
      color: fundo,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        titulo.toUpperCase(),
        style: TextStyle(fontSize: AppType.label, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: cor),
      ),
    ),
  );

  @override
  bool shouldRebuild(_Cabecalho old) => old.titulo != titulo || old.fundo != fundo || old.cor != cor;
}

class _Linha extends StatelessWidget {
  const _Linha(this.e, this.fmt, {required this.last});

  final SsLogEntry e;
  final SsTimeFormat fmt;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final tom = e.tone.colors(context);
    final neutro = e.tone == SsTone.neutral;
    final hora = fmt.hm(e.at);
    final corpo = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 52,
            child: Padding(
              padding: const EdgeInsets.only(top: 9),
              child: Text(
                hora,
                textAlign: TextAlign.right,
                style: AppTheme.number(context, size: AppType.meta, color: c.muted),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Ícone com o fio vertical que liga os eventos do dia.
          SizedBox(
            width: 32,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!last) Positioned(top: 32, bottom: 0, child: Container(width: 1, color: c.line)),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: neutro ? c.field : tom.soft,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    e.icon ?? Icons.circle,
                    size: e.icon == null ? 8 : 16,
                    color: neutro ? c.muted : tom.solid,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 5, bottom: last ? 4 : 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        e.title,
                        style: TextStyle(fontSize: AppType.set, fontWeight: FontWeight.w700, color: c.ink),
                      ),
                      if (e.state != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: neutro ? c.field : tom.soft,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            e.state!,
                            style: TextStyle(
                              fontSize: AppType.label,
                              fontWeight: FontWeight.w700,
                              color: neutro ? c.ink2 : tom.text,
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (e.detail != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        e.detail!,
                        style: TextStyle(fontSize: AppType.meta, color: c.muted),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
    final texto = [hora, e.title, ?e.state, ?e.detail].join(', ');
    return Semantics(
      label: texto,
      button: e.onTap != null,
      excludeSemantics: true,
      child: e.onTap == null
          ? Padding(padding: const EdgeInsets.only(top: 4), child: corpo)
          : InkWell(
              onTap: e.onTap,
              child: Padding(padding: const EdgeInsets.only(top: 4), child: corpo),
            ),
    );
  }
}

class _LinhaFantasma extends StatelessWidget {
  const _LinhaFantasma();

  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 36, child: SkeletonBox(height: 12)),
        SizedBox(width: 12),
        SizedBox(width: 32, child: SkeletonBox(height: 32, radius: 10)),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FractionallySizedBox(widthFactor: .7, child: SkeletonBox(height: 14)),
              SizedBox(height: 6),
              FractionallySizedBox(widthFactor: .45, child: SkeletonBox(height: 11)),
            ],
          ),
        ),
      ],
    ),
  );
}

class _Erro extends StatelessWidget {
  const _Erro(this.msg, this.onRetry, this.retry);

  final String msg;
  final VoidCallback? onRetry;
  final String retry;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: c.muted),
            const SizedBox(height: 12),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink2, fontSize: AppType.body),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              SsButton(
                label: retry,
                icon: Icons.refresh_rounded,
                variant: SsButtonVariant.ghost,
                expand: false,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
