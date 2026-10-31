import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Meia-lua com faixas ([bands]: `(até, rótulo, cor)`, em ordem, a última até
/// 1) e um ponto que vai com mola até [value] (0 a 1). A faixa do valor fica
/// forte e as outras apagadas; o rótulo dela vai embaixo (cor nunca sozinha).
/// Sem [bands]: barato / normal / caro em verde, neutro e vermelho. [center]
/// fica dentro da meia-lua (o número); [label] é a legenda de baixo.
class SsGauge extends StatelessWidget {
  const SsGauge({super.key, required this.value, this.bands, this.label, this.center, this.width = 200});

  final double value;
  final List<(double, String, Color)>? bands;
  final String? label;
  final Widget? center;
  final double width;

  /// Faixa de [v] em [bands] (a última se passar de todas).
  static (double, String, Color) bandOf(double v, List<(double, String, Color)> bands) =>
      bands.firstWhere((b) => v <= b.$1, orElse: () => bands.last);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final faixas =
        bands ?? [(1 / 3, 'barato', AppColors.success), (2 / 3, 'normal', c.muted2), (1.0, 'caro', AppColors.danger)];
    final v = value.clamp(0.0, 1.0);
    final (_, rotulo, cor) = bandOf(v, faixas);
    return Semantics(
      label: '${label ?? 'Medidor'}: $rotulo, ${(v * 100).round()}%',
      excludeSemantics: center == null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: width,
            height: width / 2 + 8,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: v),
              duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 900),
              curve: Curves.easeOutBack,
              builder: (_, t, child) =>
                  CustomPaint(painter: _GaugePainter(t.clamp(-.03, 1.03), faixas, v, c.surface, c.ink), child: child),
              child: center == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(padding: const EdgeInsets.only(bottom: 4), child: center),
                    ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: cor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                rotulo,
                style: TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w800, color: c.ink),
              ),
            ],
          ),
          if (label != null)
            Text(
              label!,
              style: TextStyle(fontSize: AppType.meta, color: c.muted),
            ),
        ],
      ),
    );
  }
}

class _GaugePainter extends CustomPainter {
  _GaugePainter(this.t, this.bands, this.value, this.surface, this.ink);

  final double t;
  final List<(double, String, Color)> bands;
  final double value;
  final Color surface;
  final Color ink;

  static const _stroke = 14.0;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2 - _stroke / 2 - 4;
    final c = Offset(size.width / 2, r + _stroke / 2 + 4);
    final rect = Rect.fromCircle(center: c, radius: r);
    final atual = SsGauge.bandOf(value, bands);
    var de = 0.0;
    for (final b in bands) {
      final ate = b.$1.clamp(0.0, 1.0);
      if (ate > de) {
        // 0,012 de folga entre faixas.
        final ini = de == 0 ? 0.0 : de + .006;
        final fim = ate >= 1 ? 1.0 : ate - .006;
        canvas.drawArc(
          rect,
          math.pi + math.pi * ini,
          math.pi * (fim - ini),
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _stroke
            ..strokeCap = StrokeCap.butt
            ..color = b == atual ? b.$3 : b.$3.withValues(alpha: .28),
        );
      }
      de = ate;
    }
    // O ponto: disco da superfície com borda da cor da faixa.
    final a = math.pi + math.pi * t;
    final p = c + Offset(math.cos(a), math.sin(a)) * r;
    canvas.drawCircle(p, _stroke / 2 + 3, Paint()..color = surface);
    canvas.drawCircle(
      p,
      _stroke / 2 + 1.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..color = ink,
    );
  }

  @override
  bool shouldRepaint(_GaugePainter old) => old.t != t || old.bands != bands || old.surface != surface;
}

/// Contagem regressiva em gomos (um por dia de [total]): os [left] que restam
/// ficam na cor (marca; aquecimento quando sobram 20% ou menos; vermelho em 0)
/// e o número vai no meio, com [label] embaixo ("dias").
class SsCountdownRing extends StatelessWidget {
  const SsCountdownRing({super.key, required this.total, required this.left, this.label = 'dias', this.size = 104});

  final int total;
  final int left;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final resta = left.clamp(0, math.max(total, 0)).toInt();
    final cor = resta == 0
        ? AppColors.danger
        : total > 0 && resta / total <= .2
        ? AppColors.aquecFg
        : c.accent;
    final texto = resta == 0
        ? c.dangerText
        : cor == AppColors.aquecFg
        ? c.aquecText
        : c.ink;
    return Semantics(
      label: 'Faltam $resta de $total $label',
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          builder: (_, t, child) => CustomPaint(painter: _GomosPainter(total, resta, t, cor, c.field), child: child),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$resta',
                  style: AppTheme.number(context, size: size * .28, weight: FontWeight.w500, color: texto),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(fontSize: AppType.micro, fontWeight: FontWeight.w700, color: c.muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GomosPainter extends CustomPainter {
  _GomosPainter(this.total, this.left, this.t, this.cor, this.trilha);

  final int total;
  final int left;
  final double t;
  final Color cor;
  final Color trilha;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    const stroke = 8.0;
    final r = size.shortestSide / 2 - stroke / 2;
    final rect = Rect.fromCircle(center: size.center(Offset.zero), radius: r);
    final passo = 2 * math.pi / total;
    // Folga entre gomos: some quando são muitos (vira anel contínuo).
    final folga = total > 60 ? 0.0 : math.min(.06, passo * .3);
    final passados = total - left;
    // Os que restam acendem em sequência ao aparecer.
    final acesos = (left * t).round();
    final p = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.butt;
    for (var i = 0; i < total; i++) {
      final aceso = i >= passados && i < passados + acesos;
      canvas.drawArc(rect, -math.pi / 2 + passo * i + folga / 2, passo - folga, false, p..color = aceso ? cor : trilha);
    }
  }

  @override
  bool shouldRepaint(_GomosPainter old) => old.t != t || old.left != left || old.total != total || old.cor != cor;
}
