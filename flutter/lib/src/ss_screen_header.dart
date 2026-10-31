import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Tela com título grande que encolhe ao rolar: monta um `CustomScrollView`
/// com o [SsSliverHeader] e os seus [slivers]. Vai no `body` do Scaffold
/// (sem AppBar).
class SsScreenHeader extends StatelessWidget {
  const SsScreenHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.summary,
    this.bottom,
    this.bottomHeight = 52,
    this.controller,
    required this.slivers,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final Widget? summary;
  final Widget? bottom;
  final double bottomHeight;
  final ScrollController? controller;
  final List<Widget> slivers;

  @override
  Widget build(BuildContext context) => CustomScrollView(
    controller: controller,
    slivers: [
      SsSliverHeader(
        title: title,
        subtitle: subtitle,
        actions: actions,
        summary: summary,
        bottom: bottom,
        bottomHeight: bottomHeight,
      ),
      ...slivers,
    ],
  );
}

/// Cabeçalho para `CustomScrollView`: título grande (28) que, ao rolar, vai
/// para a barra compacta (some embaixo e aparece em cima, crescendo de leve).
/// [summary] (ex.: total do mês em SsAmount) fica sempre na barra; [bottom]
/// (ex.: SsChipBar, SsSegmented) fica preso embaixo, com [bottomHeight].
/// Respeita a área segura de cima.
class SsSliverHeader extends StatelessWidget {
  const SsSliverHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const [],
    this.summary,
    this.bottom,
    this.bottomHeight = 52,
  });

  final String title;
  final String? subtitle;

  /// Normalmente [SsHeaderAction]s.
  final List<Widget> actions;
  final Widget? summary;
  final Widget? bottom;
  final double bottomHeight;

  @override
  Widget build(BuildContext context) => SliverPersistentHeader(
    pinned: true,
    delegate: _Delegate(
      header: this,
      top: MediaQuery.paddingOf(context).top,
      reduce: reduceMotion(context),
      c: SsColors.of(context),
    ),
  );
}

const _bar = 56.0;

class _Delegate extends SliverPersistentHeaderDelegate {
  _Delegate({required this.header, required this.top, required this.reduce, required this.c});

  final SsSliverHeader header;
  final double top;
  final bool reduce;
  final SsColors c;

  double get _large => header.subtitle == null ? 52 : 74;
  double get _bottom => header.bottom == null ? 0 : header.bottomHeight;

  @override
  double get maxExtent => top + _bar + _large + _bottom;

  @override
  double get minExtent => top + _bar + _bottom;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final t = (shrinkOffset / _large).clamp(0.0, 1.0);
    // O título pequeno só entra quando o grande já quase saiu.
    final small = ((t - .6) / .4).clamp(0.0, 1.0);
    final h = header;
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      shape: Border(
        bottom: BorderSide(color: c.line.withValues(alpha: c.line.a * t)),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 20,
            right: 20,
            top: top + _bar - shrinkOffset.clamp(0, _large),
            height: _large,
            child: Opacity(
              opacity: 1 - t,
              child: Semantics(
                header: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.ink,
                        fontSize: AppType.screenTitle,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.01 * AppType.screenTitle,
                        height: 1.2,
                      ),
                    ),
                    if (h.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          h.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: top,
            height: _bar,
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 12),
              child: Row(
                children: [
                  Expanded(
                    child: ExcludeSemantics(
                      excluding: small == 0,
                      child: Opacity(
                        opacity: small,
                        child: Transform.scale(
                          scale: reduce ? 1 : .92 + .08 * small,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            h.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.ink, fontSize: AppType.lg, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (h.summary != null) Padding(padding: const EdgeInsets.only(right: 8), child: h.summary),
                  for (final a in h.actions) Padding(padding: const EdgeInsets.only(left: 4), child: a),
                ],
              ),
            ),
          ),
          if (h.bottom != null) Positioned(left: 0, right: 0, bottom: 0, height: _bottom, child: h.bottom!),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_Delegate old) => true;
}

/// Botão redondo de ação do cabeçalho (40 px, alvo de 48), com tooltip e
/// [badge] opcional ("3"; texto vazio vira só um ponto).
class SsHeaderAction extends StatelessWidget {
  const SsHeaderAction({super.key, required this.icon, required this.tooltip, this.onPressed, this.badge});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    Widget i = Icon(icon, size: 21);
    if (badge != null) {
      i = Badge(
        label: badge!.isEmpty ? null : Text(badge!),
        backgroundColor: AppColors.danger,
        textColor: AppColors.onDark,
        child: i,
      );
    }
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: i,
      style: IconButton.styleFrom(
        backgroundColor: c.field,
        foregroundColor: c.ink2,
        fixedSize: const Size.square(40),
        minimumSize: const Size.square(40),
        shape: const CircleBorder(),
      ),
    );
  }
}
