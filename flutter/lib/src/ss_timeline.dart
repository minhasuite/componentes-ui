import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'motion_view.dart';

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
/// tracejada no que vem. Quando entra na tela, os itens chegam em cascata
/// (70 ms entre eles, subindo com mola) e o fio de cada um se desenha para
/// baixo até o próximo.
class SsTimeline extends StatelessWidget {
  const SsTimeline({super.key, required this.items});

  final List<SsTimelineItem> items;

  // Cada item: 70 ms depois do anterior, 460 ms de mola; o fio começa 120 ms
  // depois do item e leva 300 ms.
  static const _passo = 70, _item = 460, _fioIni = 120, _fioDur = 300;

  @override
  Widget build(BuildContext context) {
    final n = items.length;
    final total = _passo * (n > 1 ? n - 1 : 0) + _item;
    return SsInView(
      duration: Duration(milliseconds: total),
      curve: Curves.linear,
      builder: (context, anim, _) {
        final ms = anim.value * total;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < n; i++)
              Builder(
                builder: (context) {
                  final local = ((ms - _passo * i) / _item).clamp(0.0, 1.0);
                  final k = SsMotion.bounce.transform(local);
                  final fio = anim.value >= 1
                      ? 1.0
                      : Curves.easeInOutCubic.transform(((ms - _passo * i - _fioIni) / _fioDur).clamp(0.0, 1.0));
                  return Opacity(
                    opacity: (local * 2).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 14 * (1 - k)),
                      child: _Linha(items[i], last: i == n - 1, index: i, count: n, fio: fio),
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _Linha extends StatelessWidget {
  const _Linha(this.item, {required this.last, required this.index, required this.count, this.fio = 1});

  final SsTimelineItem item;
  final bool last;
  final int index;
  final int count;

  /// Quanto do fio até o próximo já se desenhou (0 a 1, de cima para baixo).
  final double fio;

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
                      child: CustomPaint(
                        painter: _Fio(item.done ? cor : c.muted2, tracejado: !item.done, ate: fio),
                      ),
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
    // Anel que pulsa UMA vez quando entra na tela.
    return SizedBox(
      height: 28,
      child: SsTweenInView(
        end: 1,
        duration: const Duration(milliseconds: 900),
        delay: const Duration(milliseconds: 200),
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
  _Fio(this.cor, {required this.tracejado, this.circulo = false, this.ate = 1});

  final Color cor;
  final bool tracejado;
  final bool circulo;

  /// Fração desenhada, de cima para baixo.
  final double ate;

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
    final h = size.height * ate.clamp(0.0, 1.0);
    if (h <= 0) return;
    if (!tracejado) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), p);
      return;
    }
    for (var y = 3.0; y < h; y += 8) {
      canvas.drawLine(Offset(x, y), Offset(x, math.min(y + 3, h)), p);
    }
  }

  @override
  bool shouldRepaint(_Fio old) => old.cor != cor || old.tracejado != tracejado || old.ate != ate;
}
