import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Um passo do [SsTimeline]. [done] = já passou (nó cheio), [current] = é
/// agora (anel que pulsa uma vez); nenhum dos dois = futuro (tracejado).
/// [tone] troca a cor da marca do nó; [child] vai embaixo do texto.
class SsTimelineItem {
  const SsTimelineItem({
    required this.title,
    this.subtitle,
    this.time,
    this.icon,
    this.tone,
    this.done = false,
    this.current = false,
    this.child,
  });

  final String title;
  final String? subtitle;

  /// "09:30", "12/10": em DM Mono, em cima do título.
  final String? time;
  final IconData? icon;
  final Color? tone;
  final bool done;
  final bool current;
  final Widget? child;
}

/// Linha do tempo vertical: nós ligados por uma linha, cheia no que passou e
/// tracejada no que vem. Os itens entram em cascata ao aparecer.
class SsTimeline extends StatelessWidget {
  const SsTimeline({super.key, required this.items});

  final List<SsTimelineItem> items;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final total = 320 + 60 * (n > 1 ? n - 1 : 0);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: reduceMotion(context) ? Duration.zero : Duration(milliseconds: total),
      builder: (context, t, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < n; i++)
            Builder(
              builder: (context) {
                // Cada item anda 320 ms, 60 ms depois do anterior.
                final k = Curves.easeOutCubic.transform(((t * total - 60 * i) / 320).clamp(0.0, 1.0));
                return Opacity(
                  opacity: k,
                  child: Transform.translate(
                    offset: Offset(0, 12 * (1 - k)),
                    child: _Linha(items[i], last: i == n - 1, index: i, count: n),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.item, {required this.last, required this.index, required this.count});

  final SsTimelineItem item;
  final bool last;
  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = item.tone ?? c.accent;
    final estado = item.done
        ? 'feito'
        : item.current
        ? 'agora'
        : 'a seguir';
    return Semantics(
      label: 'Passo ${index + 1} de $count, $estado',
      selected: item.current,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 32,
              child: Column(
                children: [
                  _No(item, cor),
                  if (!last)
                    Expanded(
                      child: CustomPaint(painter: _Fio(item.done ? cor : c.muted2, tracejado: !item.done)),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: last ? 0 : 20, top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.time != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          item.time!,
                          style: AppTheme.number(
                            context,
                            size: AppType.label,
                            color: item.current ? c.accentText : c.muted,
                          ),
                        ),
                      ),
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: AppType.body,
                        fontWeight: item.current ? FontWeight.w800 : FontWeight.w700,
                        color: item.done || item.current ? c.ink : c.ink2,
                      ),
                    ),
                    if (item.subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          item.subtitle!,
                          style: TextStyle(fontSize: AppType.sub, color: c.muted),
                        ),
                      ),
                    if (item.child != null) Padding(padding: const EdgeInsets.only(top: 8), child: item.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _No extends StatelessWidget {
  const _No(this.item, this.cor);

  final SsTimelineItem item;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final futuro = !item.done && !item.current;
    final no = Container(
      width: 24,
      height: 24,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: futuro ? c.surface : cor,
        boxShadow: item.current ? [BoxShadow(color: cor.withValues(alpha: .22), spreadRadius: 4)] : null,
      ),
      child: futuro
          ? CustomPaint(
              size: const Size.square(24),
              painter: _Fio(c.muted2, tracejado: true, circulo: true),
              child: item.icon == null ? null : Center(child: Icon(item.icon, size: 13, color: c.muted)),
            )
          : Icon(
              item.icon ?? (item.done ? Icons.check_rounded : Icons.circle),
              size: item.icon == null && item.current ? 8 : 14,
              color: Colors.white,
            ),
    );
    if (!item.current) return SizedBox(height: 28, child: Center(child: no));
    // Anel que pulsa UMA vez ao aparecer.
    return SizedBox(
      height: 28,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 900),
        curve: Curves.easeOutCubic,
        builder: (_, t, child) => Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            if (t < 1)
              Container(
                width: 24 + 20 * t,
                height: 24 + 20 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: cor.withValues(alpha: .5 * (1 - t)), width: 2),
                ),
              ),
            child!,
          ],
        ),
        child: no,
      ),
    );
  }
}

/// Fio vertical (ou círculo, no nó futuro), cheio ou tracejado.
class _Fio extends CustomPainter {
  _Fio(this.cor, {required this.tracejado, this.circulo = false});

  final Color cor;
  final bool tracejado;
  final bool circulo;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = cor
      ..strokeWidth = circulo ? 1.6 : 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    if (circulo) {
      final r = Rect.fromCircle(center: size.center(Offset.zero), radius: size.shortestSide / 2 - 1);
      for (var a = 0.0; a < 2 * math.pi; a += math.pi / 6) {
        canvas.drawArc(r, a, math.pi / 10, false, p);
      }
      return;
    }
    final x = size.width / 2;
    if (!tracejado) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      return;
    }
    for (var y = 3.0; y < size.height; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 3, size.height)), p);
    }
  }

  @override
  bool shouldRepaint(_Fio old) => old.cor != cor || old.tracejado != tracejado;
}
