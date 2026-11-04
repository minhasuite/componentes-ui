import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_button.dart';
import 'a_cards.dart' show SsShape, SsShapeIcon;
import 'a_fundacao.dart' show SsGlow;

/// Abertura do app: título enorme com **uma palavra destacada** na cor da
/// marca, ornamento de anéis em linha no canto, texto curto e a ação com
/// brilho. Sem [actionLabel], a ação é um botão hexagonal com seta.
class SsHeroSplash extends StatelessWidget {
  const SsHeroSplash({
    super.key,
    required this.title,
    this.highlight,
    this.text,
    this.actionLabel,
    this.onAction,
    this.ornament = true,
  });

  /// Título (quebras de linha com `\n` são respeitadas).
  final String title;

  /// Trecho de [title] pintado na cor da marca (a 1ª ocorrência).
  final String? highlight;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool ornament;

  /// Divide [title] em (antes, destaque, depois).
  static (String, String, String) split(String title, String? highlight) {
    if (highlight == null || highlight.isEmpty) return (title, '', '');
    final i = title.indexOf(highlight);
    if (i < 0) return (title, '', '');
    return (title.substring(0, i), highlight, title.substring(i + highlight.length));
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final (a, h, b) = split(title, highlight);
    final style = TextStyle(color: c.ink, fontSize: 40, fontWeight: FontWeight.w800, height: 1.18, letterSpacing: -.8);
    return Stack(
      children: [
        if (ornament)
          Positioned(
            right: -24,
            top: 0,
            width: 200,
            height: 200,
            child: IgnorePointer(
              child: CustomPaint(
                painter: _RingsPainter(c.muted2.withValues(alpha: .9), c.accent.withValues(alpha: .7)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SsReveal(
                child: Text.rich(
                  TextSpan(
                    style: style,
                    children: [
                      TextSpan(text: a),
                      if (h.isNotEmpty)
                        TextSpan(
                          text: h,
                          style: TextStyle(color: c.accentText),
                        ),
                      TextSpan(text: b),
                    ],
                  ),
                ),
              ),
              if (text != null) ...[
                const SizedBox(height: 16),
                SsReveal(
                  index: 1,
                  child: Text(
                    text!,
                    style: TextStyle(color: c.muted, fontSize: AppType.body, height: 1.45),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SsReveal(
                index: 2,
                child: actionLabel != null
                    ? SsGlow(
                        spread: 18,
                        intensity: .28,
                        child: SsButton(label: actionLabel!, onPressed: onAction),
                      )
                    : Center(child: SsHexButton(onTap: onAction)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Botão hexagonal na cor da marca com seta e brilho (ação do herói).
class SsHexButton extends StatelessWidget {
  const SsHexButton({
    super.key,
    this.onTap,
    this.icon = Icons.arrow_forward_rounded,
    this.label = 'Começar',
    this.size = 72,
  });

  final VoidCallback? onTap;
  final IconData icon;
  final String label;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: label,
    excludeSemantics: true,
    child: SsGlow(
      spread: 26,
      child: SsPressable(
        onTap: onTap,
        scale: .92,
        child: SsShapeIcon(icon, shape: SsShape.hexagono, filled: true, size: size),
      ),
    ),
  );
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.line, this.accent);
  final Color line;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide * .32;
    for (var i = 0; i < 7; i++) {
      final ctr = Offset(size.width * .38 + i * 7, size.height * .3 + i * 9);
      canvas.drawOval(
        Rect.fromCenter(center: ctr, width: r * 2.1, height: r * 1.7),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = i == 3 ? accent : line,
      );
    }
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.line != line || old.accent != accent;
}

/// Tela de apresentação com ilustração em cima (fundo tonal da marca) e um
/// painel embaixo que sobe numa curva, com título, texto, ação e (opcional)
/// os pontinhos de página.
class SsIllustratedSplit extends StatelessWidget {
  const SsIllustratedSplit({
    super.key,
    required this.art,
    required this.title,
    this.text,
    this.actionLabel,
    this.onAction,
    this.secondaryLabel,
    this.onSecondary,
    this.page,
    this.pages,
  });

  /// Ilustração (widget do app ou `SsArt`).
  final Widget art;
  final String title;
  final String? text;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  /// Página atual e total (mostra os pontinhos).
  final int? page;
  final int? pages;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    return ColoredBox(
      color: c.accentSoft,
      child: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(32, 24, 32, 48),
                child: Center(child: art),
              ),
            ),
          ),
          ClipPath(
            clipper: _TopCurve(),
            child: Container(
              color: c.surface,
              padding: EdgeInsets.fromLTRB(28, 52, 28, 20 + MediaQuery.paddingOf(context).bottom),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (page != null && pages != null) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < pages!; i++)
                          AnimatedContainer(
                            duration: dur,
                            curve: SsMotion.spring,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: i == page ? 22 : 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: i == page ? c.accent : c.muted2,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.ink, fontSize: 26, fontWeight: FontWeight.w800, height: 1.2),
                  ),
                  if (text != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      text!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: c.muted, fontSize: AppType.body, height: 1.45),
                    ),
                  ],
                  if (actionLabel != null) ...[
                    const SizedBox(height: 24),
                    SsButton(label: actionLabel!, onPressed: onAction),
                  ],
                  if (secondaryLabel != null)
                    TextButton(
                      onPressed: onSecondary,
                      style: TextButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      child: Text(secondaryLabel!),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCurve extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const d = 36.0;
    return Path()
      ..moveTo(0, d)
      ..quadraticBezierTo(size.width / 2, -d, size.width, d)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_TopCurve old) => false;
}

/// Hero da imagem do produto da lista para o detalhe: mesma [tag] nas duas
/// telas. No voo a imagem cresce com um leve passo além do tamanho final
/// (mola) e pousa; com menos movimento, o voo é o padrão do Flutter.
class SsHeroFlight extends StatelessWidget {
  const SsHeroFlight({super.key, required this.tag, required this.child});

  final Object tag;
  final Widget child;

  /// O que voa: o filho de destino, com a escala em mola.
  static Widget shuttle(
    BuildContext flightContext,
    Animation<double> animation,
    HeroFlightDirection direction,
    BuildContext fromContext,
    BuildContext toContext,
  ) {
    final to = (toContext.widget as Hero).child;
    final from = (fromContext.widget as Hero).child;
    final shown = direction == HeroFlightDirection.push ? to : from;
    if (reduceMotion(flightContext)) return shown;
    return AnimatedBuilder(
      animation: animation,
      builder: (_, child) {
        // Sobe até ~6% acima no meio do voo e volta a 1 no pouso.
        final bump = 1 + .06 * math.sin(math.pi * animation.value);
        return Transform.scale(scale: bump, child: child);
      },
      child: Material(type: MaterialType.transparency, child: shown),
    );
  }

  @override
  Widget build(BuildContext context) => Hero(tag: tag, flightShuttleBuilder: shuttle, child: child);
}
