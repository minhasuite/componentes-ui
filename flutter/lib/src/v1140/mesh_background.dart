// v1.14.0 "interface e animação": o fundo de manchas da cor da marca para cabeçalho de destaque. Par do
// Ss::MeshBackgroundComponent.
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../motion.dart';

/// Fundo de manchas suaves da cor da marca que andam devagar (uma volta em [SsMotion.ambient]), para o cabeçalho
/// de destaque ([SsHeroCard] com `mesh: true`, a abertura de um painel). Desenhado com gradientes radiais num
/// `CustomPainter` isolado por `RepaintBoundary`, sem desfoque nem shader próprio: o custo é o de pintar 4
/// círculos por quadro. Por baixo, a cor funda da marca ([SsColors.brandDeep]) e, por cima das manchas, um véu
/// dela: o texto claro ([AppColors.onDark]) passa de 4,5:1 em toda paleta, claro e escuro.
///
/// É **a** animação contínua da tela: não ponha junto de aurora, esqueleto ou outra peça que se mexe sozinha.
/// [animate] falso, "reduzir movimento" ou o app em segundo plano (o `TickerMode`) deixam as manchas paradas.
///
/// `SsMeshBackground(child: Padding(padding: EdgeInsets.all(20), child: Text('Bem-vindo')))`.
class SsMeshBackground extends StatefulWidget {
  const SsMeshBackground({super.key, this.child, this.colors, this.animate = true, this.radius = 0, this.veil = .28});

  final Widget? child;

  /// As cores das manchas (padrão: brandFrom, brandTo, accentBright e accent da marca).
  final List<Color>? colors;
  final bool animate;
  final double radius;

  /// Quanto da cor funda cobre as manchas, no mínimo (0 a .6). O véu sobe sozinho até o texto claro passar de
  /// 4,5:1 sobre a mancha mais clara ([veilFor]).
  final double veil;

  /// O contraste do texto claro sobre [bg] (WCAG).
  static double contrastOnDark(Color bg) {
    final l = bg.computeLuminance();
    return (AppColors.onDark.computeLuminance() + .05) / (l + .05);
  }

  /// A cor mais clara que o fundo chega a ter: a mancha a 85% sobre a [base], coberta pelo véu [veil].
  static Color worst(Color base, Color blob, double veil) =>
      Color.alphaBlend(base.withValues(alpha: veil), Color.alphaBlend(blob.withValues(alpha: .85), base));

  /// O menor véu (a partir de [min]) que deixa o texto claro a 4,5:1 sobre todas as [colors].
  static double veilFor(Color base, List<Color> colors, {double min = .28}) {
    var v = min;
    while (v < 1 && colors.any((x) => contrastOnDark(worst(base, x, v)) < 4.5)) {
      v += .02;
    }
    return v.clamp(0.0, 1.0);
  }

  @override
  State<SsMeshBackground> createState() => _SsMeshBackgroundState();
}

class _SsMeshBackgroundState extends State<SsMeshBackground> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.ambient);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SsMeshBackground old) {
    super.didUpdateWidget(old);
    _sync();
  }

  void _sync() {
    final anda = widget.animate && !reduceMotion(context);
    if (anda && !_c.isAnimating) _c.repeat();
    if (!anda && _c.isAnimating) _c.stop();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cores = widget.colors ?? [c.brandFrom, c.brandTo, c.accentBright, c.accent];
    final r = BorderRadius.circular(widget.radius);
    return ClipRRect(
      borderRadius: r,
      child: CustomPaint(
        painter: _MeshPainter(
          t: _c,
          base: c.brandDeep,
          colors: cores,
          veil: SsMeshBackground.veilFor(c.brandDeep, cores, min: widget.veil.clamp(0.0, .6)),
        ),
        isComplex: true,
        child: widget.child == null
            ? const SizedBox.expand()
            : DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.onDark),
                child: IconTheme.merge(
                  data: const IconThemeData(color: AppColors.onDark),
                  child: widget.child!,
                ),
              ),
      ),
    );
  }
}

class _MeshPainter extends CustomPainter {
  _MeshPainter({required this.t, required this.base, required this.colors, required this.veil}) : super(repaint: t);

  final Animation<double> t;
  final Color base;
  final List<Color> colors;
  final double veil;

  // Centro de partida, raio do passeio e fase de cada mancha (frações do tamanho).
  static const _blobs = [
    (Offset(.15, .2), Offset(.18, .12), 0.0, .75),
    (Offset(.85, .25), Offset(.14, .18), 1.7, .65),
    (Offset(.7, .9), Offset(.2, .1), 3.4, .8),
    (Offset(.25, .85), Offset(.12, .16), 5.0, .6),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(rect, Paint()..color = base);
    final a = t.value * 2 * math.pi;
    final lado = math.max(size.width, size.height);
    for (var i = 0; i < _blobs.length; i++) {
      final (centro, passeio, fase, raio) = _blobs[i];
      final cor = colors[i % colors.length];
      final p = Offset(
        (centro.dx + passeio.dx * math.sin(a + fase)) * size.width,
        (centro.dy + passeio.dy * math.cos(a * (i.isEven ? 1 : -1) + fase)) * size.height,
      );
      final r = lado * raio;
      canvas.drawCircle(
        p,
        r,
        Paint()
          ..shader = RadialGradient(colors: [cor.withValues(alpha: .85), cor.withValues(alpha: 0)])
              .createShader(Rect.fromCircle(center: p, radius: r)),
      );
    }
    // O véu da cor funda: o texto claro por cima sempre lê.
    canvas.drawRect(rect, Paint()..color = base.withValues(alpha: veil));
  }

  @override
  bool shouldRepaint(_MeshPainter old) => old.base != base || old.colors != colors || old.veil != veil;
}
