// v1.14.0 "interface e animação": o check que se desenha no fim de uma ação que deu certo. Par do
// Ss::SuccessCheckComponent (e do `ss:sound` do web, para o som).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../motion.dart';
import 'strings.dart';

/// Os sons curtos da suíte (o pacote não toca nada: só chama o [SsSounds.player] do app).
enum SsSound { success }

/// O gancho do som curto: o app liga o player dele (`audioplayers`, `just_audio`, o som do sistema) e o pacote
/// chama na hora certa (o [SsSuccessCheck] com `sound: true`). Sem [player], nada toca. [enabled] falso desliga
/// (a preferência "Sons" do app; nos testes também). No web, o par é o evento `ss:sound` ({ name: "success" }).
///
/// `SsSounds.player = (s) => player.play(AssetSource('sons/${s.name}.mp3'));`
class SsSounds {
  const SsSounds._();

  static void Function(SsSound sound)? player;
  static bool enabled = true;

  static void play(SsSound sound) {
    if (enabled) player?.call(sound);
  }
}

/// Check de sucesso que se desenha: o círculo corre em volta (de cima, no sentido do relógio) e o traço do ✓ vem
/// logo depois, com um pulinho de mola no fim ([SsMotion.long] + [SsMotion.medium]); com [haptic], a vibração
/// de sucesso ([SsHaptics.success]) e, com [sound], o som curto do app ([SsSounds]). Com "reduzir movimento",
/// aparece pronto (e ainda vibra). O leitor de tela ouve [label] (padrão "Concluído") como região viva.
///
/// [filled]: disco cheio na cor com o ✓ em [checkColor] (o fim do [SsMorphButton] e do [SsSwipeToConfirm]);
/// sem ele, só o contorno e o traço na [color] (padrão o sucesso da suíte).
/// [play] falso mostra parado no começo; ao virar `true`, desenha (o [SsPixCard] liga quando o Pix é pago).
class SsSuccessCheck extends StatefulWidget {
  const SsSuccessCheck({
    super.key,
    this.size = 56,
    this.color,
    this.checkColor,
    this.filled = false,
    this.play = true,
    this.haptic = true,
    this.sound = false,
    this.label,
    this.onDone,
  });

  final double size;
  final Color? color;
  final Color? checkColor;
  final bool filled;
  final bool play;
  final bool haptic;
  final bool sound;
  final String? label;
  final VoidCallback? onDone;

  @override
  State<SsSuccessCheck> createState() => _SsSuccessCheckState();
}

class _SsSuccessCheckState extends State<SsSuccessCheck> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.long + SsMotion.medium);
  bool _feito = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.play && !_feito) _start();
  }

  @override
  void didUpdateWidget(SsSuccessCheck old) {
    super.didUpdateWidget(old);
    if (widget.play && !old.play) {
      _feito = false;
      _c.value = 0;
      _start();
    }
  }

  void _start() {
    _feito = true;
    if (widget.haptic) SsHaptics.success();
    if (widget.sound) SsSounds.play(SsSound.success);
    if (reduceMotion(context)) {
      _c.value = 1;
      widget.onDone?.call();
      return;
    }
    _c.forward(from: 0).whenComplete(() {
      if (mounted) widget.onDone?.call();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cor = widget.color ?? AppColors.success;
    return Semantics(
      liveRegion: widget.play,
      label: widget.label ?? SsInterfaceStrings.of(context).success,
      image: true,
      child: SizedBox.square(
        dimension: widget.size,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(
            painter: _CheckPainter(
              t: _c.value,
              color: cor,
              check: widget.checkColor ?? (widget.filled ? AppColors.onDark : cor),
              filled: widget.filled,
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckPainter extends CustomPainter {
  _CheckPainter({required this.t, required this.color, required this.check, required this.filled});

  final double t;
  final Color color, check;
  final bool filled;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final centro = size.center(Offset.zero);
    final traco = math.max(2.0, s * .08);
    // 0–.55: o círculo; .45–.85: o ✓; .8–1: o pulinho (escala com mola).
    final circ = SsMotion.enter.transform((t / .55).clamp(0.0, 1.0));
    final tique = SsMotion.standard.transform(((t - .45) / .4).clamp(0.0, 1.0));
    final pulo = t <= .8 ? 1.0 : 1 + .08 * math.sin(((t - .8) / .2) * math.pi);
    canvas.translate(centro.dx, centro.dy);
    canvas.scale(pulo);
    canvas.translate(-centro.dx, -centro.dy);
    final r = s / 2 - traco / 2;
    final rect = Rect.fromCircle(center: centro, radius: r);
    if (filled) {
      canvas.drawCircle(centro, r * circ + (traco / 2) * circ, Paint()..color = color.withValues(alpha: circ));
    } else {
      canvas.drawArc(
        rect,
        -math.pi / 2,
        2 * math.pi * circ,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = traco
          ..strokeCap = StrokeCap.round,
      );
    }
    if (tique <= 0) return;
    final a = Offset(centro.dx - s * .2, centro.dy + s * .01);
    final b = Offset(centro.dx - s * .05, centro.dy + s * .16);
    final c = Offset(centro.dx + s * .22, centro.dy - s * .14);
    final path = Path()
      ..moveTo(a.dx, a.dy)
      ..lineTo(b.dx, b.dy)
      ..lineTo(c.dx, c.dy);
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * tique),
      Paint()
        ..color = check
        ..style = PaintingStyle.stroke
        ..strokeWidth = traco * 1.15
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter old) => old.t != t || old.color != color || old.check != check;
}
