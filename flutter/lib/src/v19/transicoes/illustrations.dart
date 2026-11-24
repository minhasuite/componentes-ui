import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../motion.dart';

/// Ilustrações dos estados vazios (v1.9), as mesmas do
/// `Ss::EmptyStateComponent(illustration:)` no web.
enum SsIllustration {
  /// Nada ainda (primeira vez na lista).
  empty,

  /// Sem conexão.
  offline,

  /// A busca ou o filtro não achou nada.
  noResults,

  /// Tudo feito (lista de tarefas zerada, caixa de entrada limpa).
  allDone,

  /// Deu erro ao carregar.
  error,
}

/// A arte de um [SsIllustration]: bolha na cor suave da marca, chão, órbita,
/// brilhos e o símbolo do caso por cima, desenhados em código na paleta do
/// tema (erro na cor de perigo da suíte). Entra crescendo com mola e, parada,
/// flutua devagar com os brilhos piscando. Com "reduzir movimento", fica
/// parada. Decorativa: o leitor de tela lê o título do estado vazio.
class SsIllustrationArt extends StatefulWidget {
  const SsIllustrationArt(this.illustration, {super.key, this.size = 132});

  final SsIllustration illustration;
  final double size;

  /// O símbolo de cada caso.
  static IconData iconOf(SsIllustration i) => switch (i) {
    SsIllustration.empty => Icons.inbox_outlined,
    SsIllustration.offline => Icons.cloud_off_rounded,
    SsIllustration.noResults => Icons.search_off_rounded,
    SsIllustration.allDone => Icons.task_alt_rounded,
    SsIllustration.error => Icons.error_outline_rounded,
  };

  @override
  State<SsIllustrationArt> createState() => _SsIllustrationArtState();
}

class _SsIllustrationArtState extends State<SsIllustrationArt> with TickerProviderStateMixin {
  late final AnimationController _entra = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 620), // ritmo próprio
  );
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600), // ritmo próprio
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _entra.value = 1;
      _loop.stop();
      _loop.value = 0;
    } else {
      if (_entra.isDismissed) _entra.forward();
      if (!_loop.isAnimating) _loop.repeat();
    }
  }

  @override
  void dispose() {
    _entra.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final s = widget.size;
    final erro = widget.illustration == SsIllustration.error;
    final tinta = erro ? c.danger : c.accent;
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: s,
        child: AnimatedBuilder(
          animation: Listenable.merge([_entra, _loop]),
          builder: (context, _) {
            final e = SsMotion.bounce.transform(_entra.value);
            final ciclo = math.sin(_loop.value * 2 * math.pi);
            return Opacity(
              opacity: _entra.value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: .82 + .18 * e,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: Size.square(s),
                      painter: _ArtePainter(
                        kind: widget.illustration,
                        loop: _loop.value,
                        fundo: erro ? c.danger.withValues(alpha: c.isDark ? .18 : .1) : c.accentSoft,
                        tinta: tinta,
                        linha: c.line,
                        cartao: c.surface,
                      ),
                    ),
                    Transform.translate(
                      offset: Offset(0, -s * .03 + ciclo * s * .025),
                      child: Icon(SsIllustrationArt.iconOf(widget.illustration), size: s * .34, color: tinta),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ArtePainter extends CustomPainter {
  _ArtePainter({
    required this.kind,
    required this.loop,
    required this.fundo,
    required this.tinta,
    required this.linha,
    required this.cartao,
  });

  final SsIllustration kind;
  final double loop;
  final Color fundo, tinta, linha, cartao;

  void _brilho(Canvas canvas, Offset c, double r, double alpha) {
    final p = Path()
      ..moveTo(c.dx, c.dy - r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx + r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy + r)
      ..quadraticBezierTo(c.dx, c.dy, c.dx - r, c.dy)
      ..quadraticBezierTo(c.dx, c.dy, c.dx, c.dy - r)
      ..close();
    canvas.drawPath(p, Paint()..color = tinta.withValues(alpha: tinta.a * alpha));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.shortestSide;
    final c = Offset(size.width / 2, size.height * .46);
    final ciclo = math.sin(loop * 2 * math.pi);

    // Chão: a sombra encolhe quando o símbolo sobe.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(c.dx, size.height * .88), width: s * (.62 - .04 * ciclo), height: s * .07),
      Paint()..color = linha,
    );
    // Bolha e órbita.
    canvas.drawCircle(c, s * .34, Paint()..color = fundo);
    canvas.drawCircle(
      c,
      s * .42,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = tinta.withValues(alpha: .18),
    );
    // Um detalhe por caso, atrás do símbolo.
    final fino = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = s * .018
      ..color = tinta.withValues(alpha: .35);
    switch (kind) {
      case SsIllustration.empty:
        final r = RRect.fromRectAndRadius(
          Rect.fromCenter(center: c.translate(s * .2, s * .14), width: s * .26, height: s * .18),
          Radius.circular(s * .04),
        );
        canvas.drawRRect(r, Paint()..color = cartao);
        canvas.drawRRect(r, fino);
      case SsIllustration.offline:
        // Ondas do sinal, apagadas.
        for (var k = 1; k <= 2; k++) {
          canvas.drawArc(
            Rect.fromCircle(center: c.translate(-s * .22, s * .18), radius: s * .05 * k),
            -math.pi * .75,
            math.pi / 2,
            false,
            fino,
          );
        }
      case SsIllustration.noResults:
        for (var k = 0; k < 3; k++) {
          final y = c.dy + s * (.1 + k * .06);
          canvas.drawLine(Offset(c.dx - s * .34, y), Offset(c.dx - s * (.2 - k * .03), y), fino);
        }
      case SsIllustration.allDone:
        // Anel que se completa no ciclo.
        canvas.drawArc(
          Rect.fromCircle(center: c, radius: s * .28),
          -math.pi / 2,
          2 * math.pi * (.75 + .25 * (ciclo + 1) / 2),
          false,
          fino,
        );
      case SsIllustration.error:
        canvas.drawLine(c.translate(s * .2, s * .2), c.translate(s * .3, s * .1), fino);
    }
    // Brilhos piscando defasados.
    double pisca(double fase) => .35 + .65 * (math.sin((loop + fase) * 2 * math.pi) + 1) / 2;
    _brilho(canvas, Offset(size.width * .8, size.height * .16), s * .05, pisca(0));
    _brilho(canvas, Offset(size.width * .16, size.height * .3), s * .035, pisca(.4));
    canvas.drawCircle(
      Offset(size.width * .84, size.height * .66),
      s * .018,
      Paint()..color = tinta.withValues(alpha: .4 * pisca(.7)),
    );
  }

  @override
  bool shouldRepaint(_ArtePainter old) =>
      old.loop != loop || old.kind != kind || old.fundo != fundo || old.tinta != tinta || old.linha != linha;
}
