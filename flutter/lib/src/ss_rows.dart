import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Linha "rótulo … valor" de detalhe, recibo ou resumo. O rótulo à esquerda
/// nunca é espremido (até 60% da largura); quem cede é o valor: em DM Mono
/// ([mono]) ele encolhe numa linha só (não quebra "R$ 2.231,70" no meio); em
/// texto comum, quebra. [caption] vai embaixo do rótulo; [emphasis] marca o
/// total (valor maior e mais pesado). Com [onTap], a linha é tocável.
///
/// `SsValueRow('Frete', r'R$ 18,90', caption: 'PAC · 5 dias')`
class SsValueRow extends StatelessWidget {
  const SsValueRow(
    this.label,
    this.value, {
    super.key,
    this.caption,
    this.mono = true,
    this.emphasis = false,
    this.onTap,
  });

  final String label;
  final String value;
  final String? caption;
  final bool mono;
  final bool emphasis;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final size = emphasis ? AppType.lg : AppType.body;
    final weight = emphasis ? FontWeight.w700 : FontWeight.w500;
    final valueText = mono
        ? FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              value,
              maxLines: 1,
              softWrap: false,
              style: AppTheme.number(context, size: size, weight: weight, color: c.ink),
            ),
          )
        : Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: c.ink, fontSize: size, fontWeight: weight),
          );
    final row = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 44),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: LayoutBuilder(
          builder: (context, box) => Row(
            children: [
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: box.maxWidth * .6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: emphasis ? c.ink : c.ink2,
                        fontSize: emphasis ? AppType.md : AppType.body,
                        fontWeight: emphasis ? FontWeight.w800 : FontWeight.w600,
                      ),
                    ),
                    if ((caption ?? '').isNotEmpty)
                      Text(
                        caption!,
                        style: TextStyle(color: c.muted, fontSize: AppType.meta),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Align(alignment: Alignment.centerRight, child: valueText),
              ),
              if (onTap != null) ...[const SizedBox(width: 4), Icon(Icons.chevron_right_rounded, color: c.muted2)],
            ],
          ),
        ),
      ),
    );
    return Semantics(
      label: '$label: $value${caption == null ? '' : ', $caption'}',
      button: onTap != null,
      excludeSemantics: true,
      child: onTap == null ? row : InkWell(onTap: onTap, child: row),
    );
  }
}

/// Divisória tracejada, de recibo ou de "a partir daqui é o total".
///
/// `SsDashedDivider()` · `SsDashedDivider(height: 24, dash: 6, gap: 3)`
class SsDashedDivider extends StatelessWidget {
  const SsDashedDivider({super.key, this.height = 17, this.dash = 4, this.gap = 4, this.color});

  /// Altura total ocupada (o traço fica no meio, como o `Divider`).
  final double height;
  final double dash;
  final double gap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _DashPainter(color ?? c.muted2, dash, gap)),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color, this.dash, this.gap);
  final Color color;
  final double dash;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.2;
    final y = size.height / 2;
    for (var x = 0.0; x < size.width; x += dash + gap) {
      canvas.drawLine(Offset(x, y), Offset((x + dash).clamp(0, size.width), y), p);
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color || old.dash != dash || old.gap != gap;
}

/// Realce de "acabou de salvar": quando [active] passa a verdadeiro (ou o
/// widget nasce ativo, como um item recém-criado na lista), um véu na cor da
/// marca a 14% acende e some em ~600 ms. Troca o toast de "Salvo". Com menos
/// animação no sistema, o véu aparece e some sem esmaecer.
///
/// `SsHighlight(active: item.id == recemSalvo, child: SsListItem(...))`
class SsHighlight extends StatefulWidget {
  const SsHighlight({super.key, required this.child, this.active = false, this.radius = AppRadius.card});

  final Widget child;
  final bool active;
  final double radius;

  @override
  State<SsHighlight> createState() => _SsHighlightState();
}

class _SsHighlightState extends State<SsHighlight> with SingleTickerProviderStateMixin {
  late final _ctl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

  // Acende rápido (20%) e apaga devagar.
  static final _curve = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: 20),
    TweenSequenceItem(tween: Tween<double>(begin: 1, end: 0).chain(CurveTween(curve: Curves.easeOut)), weight: 80),
  ]);

  @override
  void initState() {
    super.initState();
    if (widget.active) _ctl.forward();
  }

  @override
  void didUpdateWidget(SsHighlight old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) _ctl.forward(from: 0);
  }

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = SsColors.of(context).accent;
    final reduce = reduceMotion(context);
    return AnimatedBuilder(
      animation: _ctl,
      child: widget.child,
      builder: (context, child) {
        final t = _ctl.value;
        final k = reduce ? (_ctl.isAnimating ? 1.0 : 0.0) : _curve.transform(t);
        return DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: k == 0 ? null : accent.withValues(alpha: .14 * k),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          child: child,
        );
      },
    );
  }
}
