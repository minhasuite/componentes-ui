import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_list.dart' show SsAvatarStack;
import '../ss_strings.dart';

// ---------------------------------------------------------------------------
// Mosaico
// ---------------------------------------------------------------------------

/// Um bloco do [SsMosaicGrid]: fundo no gradiente da marca (com imagem
/// opcional por baixo, tingida), ícone de traço, título e contador em
/// versalete ("450 LUGARES"). [variant] desloca o tom para os blocos não
/// ficarem iguais; [wide] ocupa as duas colunas.
class SsMosaicTile extends StatelessWidget {
  const SsMosaicTile({
    super.key,
    required this.title,
    this.caption,
    this.icon,
    this.height = 180,
    this.image,
    this.background,
    this.variant = 0,
    this.wide = false,
    this.onTap,
    this.facts,
  });

  final String title;

  /// Pílulas de resumo no lugar do [caption] (v0.13; o `facts:` do
  /// `Ss::MosaicTileComponent`): "2 ligados", "87 W", com ícone opcional,
  /// numa linha que rola de lado se não couber (no web, quebram linha).
  final List<SsMosaicFact>? facts;

  /// Linha em versalete embaixo do título (contador).
  final String? caption;
  final IconData? icon;
  final double height;

  /// Foto por baixo do gradiente (o app passa o provider, com cache).
  final ImageProvider? image;

  /// Fundo pintado alternativo (ex.: `SsTexture`), por cima da imagem.
  final Widget? background;
  final int variant;
  final bool wide;
  final VoidCallback? onTap;

  /// As duas cores do bloco [variant], derivadas da marca (matiz deslocado).
  static List<Color> colorsFor(SsColors c, int variant) {
    final hsl = HSLColor.fromColor(c.brandTo);
    final sat = math.max(hsl.saturation, .42);
    final shift = const [0.0, 22.0, -18.0, 40.0, -34.0][variant % 5];
    HSLColor tone(double dh, double l) =>
        hsl.withHue((hsl.hue + shift + dh) % 360).withSaturation(sat).withLightness(l);
    return [tone(18, .56).toColor(), tone(-8, .42).toColor()];
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cores = colorsFor(c, variant);
    final radius = BorderRadius.circular(AppRadius.cardActive);
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Semantics(
      button: onTap != null,
      label: [title, if (facts?.isNotEmpty ?? false) ...facts!.map((f) => f.label) else ?caption].join(', '),
      excludeSemantics: true,
      child: SsPressable(
        onTap: onTap,
        child: Container(
          height: height * math.max(1, textScale * .9),
          decoration: BoxDecoration(borderRadius: radius, boxShadow: c.tintedShadow(cores[1], strength: .6)),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image != null) Image(image: image!, fit: BoxFit.cover, errorBuilder: (_, _, _) => const SizedBox()),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [
                        cores[0].withValues(alpha: image == null ? 1 : .8),
                        cores[1].withValues(alpha: image == null ? 1 : .88),
                      ],
                    ),
                  ),
                ),
                ?background,
                // Véu embaixo: o texto claro passa AA mesmo em tom claro.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [AppColors.scrim.withValues(alpha: 0), AppColors.scrim.withValues(alpha: .35)],
                      stops: [.35, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(SsDensity.of(context).cardPad + 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (icon != null) Icon(icon, size: 34, color: AppColors.onDark, weight: 300),
                      const Spacer(),
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.onDark,
                          fontSize: AppType.lg,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                      if (facts?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        // Uma linha só (a altura do bloco é fixa): o que não cabe rola de lado.
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(spacing: 6, children: [for (final f in facts!) _FactPill(f)]),
                        ),
                      ] else if (caption != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          caption!.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.onDark.withValues(alpha: .86),
                            fontSize: AppType.label,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Pílula de resumo do [SsMosaicTile.facts] (v0.13): texto e ícone opcional.
@immutable
class SsMosaicFact {
  const SsMosaicFact(this.label, {this.icon});

  final String label;
  final IconData? icon;
}

class _FactPill extends StatelessWidget {
  const _FactPill(this.fact);

  final SsMosaicFact fact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(color: AppColors.onDark.withValues(alpha: .2), borderRadius: BorderRadius.circular(999)),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (fact.icon != null) ...[Icon(fact.icon, size: 14, color: AppColors.onDark), const SizedBox(width: 4)],
          Text(
            fact.label,
            style: const TextStyle(color: AppColors.onDark, fontSize: AppType.meta, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    ),
  );
}

/// Grade "masonry" de 2 colunas com alturas variadas: cada bloco vai para a
/// coluna mais baixa; bloco [SsMosaicTile.wide] ocupa a largura toda e
/// realinha as colunas. Entram em cascata ([SsReveal]).
class SsMosaicGrid extends StatelessWidget {
  const SsMosaicGrid({super.key, required this.tiles, this.spacing = 12});

  final List<SsMosaicTile> tiles;
  final double spacing;

  /// Distribui as alturas em 2 colunas (a mais baixa recebe): devolve o índice
  /// da coluna de cada bloco. Bloco largo zera as colunas.
  static List<int> columnsFor(List<double> heights, List<bool> wide, double spacing) {
    final out = <int>[];
    var a = 0.0, b = 0.0;
    for (var i = 0; i < heights.length; i++) {
      if (wide[i]) {
        out.add(-1);
        a = b = 0;
        continue;
      }
      if (a <= b) {
        out.add(0);
        a += heights[i] + spacing;
      } else {
        out.add(1);
        b += heights[i] + spacing;
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final cols = columnsFor([for (final t in tiles) t.height], [for (final t in tiles) t.wide], spacing);
    final blocks = <Widget>[];
    var left = <Widget>[], right = <Widget>[];
    void flush() {
      if (left.isEmpty && right.isEmpty) return;
      blocks.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: Column(children: left)),
            SizedBox(width: spacing),
            Expanded(child: Column(children: right)),
          ],
        ),
      );
      left = [];
      right = [];
    }

    for (var i = 0; i < tiles.length; i++) {
      final w = Padding(
        padding: EdgeInsets.only(bottom: spacing),
        child: SsReveal(index: i, child: tiles[i]),
      );
      if (cols[i] == -1) {
        flush();
        blocks.add(w);
      } else {
        (cols[i] == 0 ? left : right).add(w);
      }
    }
    flush();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: blocks);
  }
}

// ---------------------------------------------------------------------------
// Ticket
// ---------------------------------------------------------------------------

/// Card de ingresso: duas seções ([top] e [bottom]) separadas por um picote
/// (linha tracejada) com recortes semicirculares nas laterais, na altura
/// exata do picote. [badge] (ex.: botão de QR) fica encaixado num recorte
/// maior à direita. Sombra segue o recorte.
class SsTicketCard extends StatelessWidget {
  const SsTicketCard({
    super.key,
    required this.top,
    required this.bottom,
    this.badge,
    this.badgeSize = 52,
    this.color,
    this.bottomColor,
    this.notchRadius = 12,
    this.radius = AppRadius.cardActive,
  });

  final Widget top;
  final Widget bottom;
  final Widget? badge;
  final double badgeSize;
  final Color? color;

  /// Cor da seção de baixo (sem ela, a mesma de cima).
  final Color? bottomColor;
  final double notchRadius;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return _TicketLayout(
      color: color ?? c.surface,
      bottomColor: bottomColor ?? color ?? c.surface,
      line: c.muted2,
      border: c.isDark ? c.line : null,
      notch: notchRadius,
      radius: radius,
      badgeSize: badge == null ? 0 : badgeSize,
      children: [
        top,
        bottom,
        if (badge != null) SizedBox(width: badgeSize, height: badgeSize, child: badge),
      ],
    );
  }
}

class _TicketParentData extends ContainerBoxParentData<RenderBox> {}

class _TicketLayout extends MultiChildRenderObjectWidget {
  const _TicketLayout({
    required this.color,
    required this.bottomColor,
    required this.line,
    required this.border,
    required this.notch,
    required this.radius,
    required this.badgeSize,
    required super.children,
  });

  final Color color;
  final Color bottomColor;
  final Color line;
  final Color? border;
  final double notch;
  final double radius;
  final double badgeSize;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderTicket()..set(this);

  @override
  void updateRenderObject(BuildContext context, _RenderTicket renderObject) => renderObject.set(this);
}

class _RenderTicket extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _TicketParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _TicketParentData> {
  late _TicketLayout _w;

  void set(_TicketLayout w) {
    _w = w;
    markNeedsLayout();
  }

  /// Raio do recorte da direita (maior quando há badge) e o centro dele.
  double get _rightR => _w.badgeSize > 0 ? _w.badgeSize / 2 + 6 : _w.notch;
  double _rightX(double width) => _w.badgeSize > 0 ? width - _rightR + 6 : width;

  double _cut = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _TicketParentData) child.parentData = _TicketParentData();
  }

  @override
  Size computeDryLayout(BoxConstraints constraints) {
    final w = constraints.maxWidth;
    final top = firstChild!.getDryLayout(BoxConstraints.tightFor(width: w));
    final bottom = childAfter(firstChild!)!.getDryLayout(BoxConstraints.tightFor(width: w));
    return constraints.constrain(Size(w, top.height + bottom.height));
  }

  @override
  void performLayout() {
    assert(constraints.hasBoundedWidth, 'SsTicketCard precisa de largura definida');
    final w = constraints.maxWidth;
    final top = firstChild!;
    final bottom = childAfter(top)!;
    top.layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
    bottom.layout(BoxConstraints.tightFor(width: w), parentUsesSize: true);
    _cut = top.size.height;
    (top.parentData! as _TicketParentData).offset = Offset.zero;
    (bottom.parentData! as _TicketParentData).offset = Offset(0, _cut);
    final badge = childAfter(bottom);
    if (badge != null) {
      badge.layout(BoxConstraints.tight(Size.square(_w.badgeSize)));
      (badge.parentData! as _TicketParentData).offset = Offset(_rightX(w) - _w.badgeSize / 2, _cut - _w.badgeSize / 2);
    }
    size = constraints.constrain(Size(w, _cut + bottom.size.height));
  }

  Path _shape(Offset o) {
    final rect = o & size;
    final body = Path()..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(_w.radius)));
    final holes = Path()
      ..addOval(Rect.fromCircle(center: o + Offset(0, _cut), radius: _w.notch))
      ..addOval(Rect.fromCircle(center: o + Offset(_rightX(size.width), _cut), radius: _rightR));
    return Path.combine(PathOperation.difference, body, holes);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final canvas = context.canvas;
    final path = _shape(offset);
    if (_w.border == null) canvas.drawShadow(path.shift(const Offset(0, 2)), AppColors.shadowInk, 5, false);
    canvas
      ..save()
      ..clipPath(path)
      ..drawRect(Rect.fromLTWH(offset.dx, offset.dy, size.width, _cut), Paint()..color = _w.color)
      ..drawRect(
        Rect.fromLTWH(offset.dx, offset.dy + _cut, size.width, size.height - _cut),
        Paint()..color = _w.bottomColor,
      )
      ..restore();
    if (_w.border != null) {
      canvas.drawPath(
        path,
        Paint()
          ..color = _w.border!
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
    // Picote tracejado entre os recortes.
    final dash = Paint()
      ..color = _w.line
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    final y = offset.dy + _cut;
    final end = offset.dx + _rightX(size.width) - _rightR - 8;
    for (var x = offset.dx + _w.notch + 8; x < end; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(math.min(x + 5, end), y), dash);
    }
    defaultPaint(context, offset);
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}

// ---------------------------------------------------------------------------
// Cartão de embarque
// ---------------------------------------------------------------------------

/// Cartão de embarque: códigos grandes de origem e destino ligados por um arco
/// tracejado com o avião na posição [progress] (0–1, anima com mola), cidades,
/// horários, grade de campos (assento, portão...) e, no picote, o botão do QR.
class SsBoardingPass extends StatelessWidget {
  const SsBoardingPass({
    super.key,
    required this.fromCode,
    required this.toCode,
    this.fromCity,
    this.toCity,
    this.departure,
    this.arrival,
    this.departureDate,
    this.arrivalDate,
    this.progress = 0,
    this.fields = const [],
    this.footer,
    this.onQr,
  });

  final String fromCode;
  final String toCode;
  final String? fromCity;
  final String? toCity;

  /// Horários ("20:50").
  final String? departure;
  final String? arrival;
  final String? departureDate;
  final String? arrivalDate;

  /// Andamento do voo (0 = no chão na origem, 1 = pousou).
  final double progress;

  /// (rótulo, valor), em 2 colunas.
  final List<(String, String)> fields;

  /// Seção de baixo (companhia, passageiro).
  final Widget? footer;
  final VoidCallback? onQr;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    Widget lado(CrossAxisAlignment a, String code, String? city, String? date, String? time) => Column(
      crossAxisAlignment: a,
      children: [
        Text(
          code,
          style: AppTheme.number(context, size: 30, weight: FontWeight.w500, color: c.ink).copyWith(letterSpacing: 1),
        ),
        if (city != null) ...[
          const SizedBox(height: 4),
          Text(
            city,
            style: TextStyle(color: c.muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
          ),
        ],
        if (date != null) ...[
          const SizedBox(height: 10),
          Text(
            date,
            style: TextStyle(color: c.ink2, fontSize: AppType.sub, fontWeight: FontWeight.w700),
          ),
        ],
        if (time != null) ...[
          const SizedBox(height: 2),
          Text(
            time,
            style: AppTheme.number(context, size: AppType.set, color: c.muted),
          ),
        ],
      ],
    );
    final top = Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            label: SsStrings.of(context).flightLabel(fromCode, toCode, (progress * 100).round()),
            excludeSemantics: true,
            child: SizedBox(
              height: 64,
              // O avião voa da origem até onde está quando o cartão entra na tela.
              child: SsTweenInView(
                end: progress.clamp(0.0, 1.0),
                duration: const Duration(milliseconds: 1100),
                curve: Curves.easeInOutCubic,
                builder: (_, p, _) => CustomPaint(
                  painter: _RoutePainter(progress: p, line: c.muted2, done: c.accent, dot: c.ink),
                  child: LayoutBuilder(
                    builder: (context, box) {
                      final (pt, ang) = _RoutePainter.at(box.biggest, p);
                      return Stack(
                        children: [
                          Positioned(
                            left: pt.dx - 13,
                            top: pt.dy - 13,
                            child: Transform.rotate(
                              angle: ang,
                              child: Icon(Icons.flight_rounded, size: 26, color: c.accent),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: lado(CrossAxisAlignment.start, fromCode, fromCity, departureDate, departure)),
              Expanded(child: lado(CrossAxisAlignment.end, toCode, toCity, arrivalDate, arrival)),
            ],
          ),
          if (fields.isNotEmpty) ...[
            const SizedBox(height: 18),
            Wrap(
              runSpacing: 14,
              children: [
                for (final (k, v) in fields)
                  FractionallySizedBox(
                    widthFactor: .5,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k,
                          style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          v,
                          style: TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
    return SsTicketCard(
      top: top,
      bottom: Padding(padding: const EdgeInsets.fromLTRB(20, 16, 20, 18), child: footer ?? const SizedBox(height: 8)),
      badge: onQr == null
          ? null
          : Semantics(
              button: true,
              label: SsStrings.of(context).showBoardingQr,
              excludeSemantics: true,
              child: SsPressable(
                onTap: onQr,
                scale: .92,
                child: Container(
                  decoration: BoxDecoration(
                    color: c.accent,
                    shape: BoxShape.circle,
                    boxShadow: c.tintedShadow(c.accent),
                  ),
                  child: const Icon(Icons.qr_code_2_rounded, color: AppColors.onDark, size: 26),
                ),
              ),
            ),
    );
  }
}

class _RoutePainter extends CustomPainter {
  _RoutePainter({required this.progress, required this.line, required this.done, required this.dot});
  final double progress;
  final Color line;
  final Color done;
  final Color dot;

  static (Offset, Offset, Offset) _pts(Size s) =>
      (Offset(6, s.height - 6), Offset(s.width / 2, -s.height * .55), Offset(s.width - 6, s.height - 6));

  static Offset _b(Size s, double t) {
    final (p0, p1, p2) = _pts(s);
    return p0 * ((1 - t) * (1 - t)) + p1 * (2 * (1 - t) * t) + p2 * (t * t);
  }

  /// Ponto e ângulo (do ícone de avião, que aponta para cima) em [t].
  static (Offset, double) at(Size s, double t) {
    final (p0, p1, p2) = _pts(s);
    final d = (p1 - p0) * (2 * (1 - t)) + (p2 - p1) * (2 * t);
    return (_b(s, t), math.atan2(d.dy, d.dx) + math.pi / 2);
  }

  @override
  void paint(Canvas canvas, Size size) {
    const steps = 60;
    final solid = Paint()
      ..color = done
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final dashed = Paint()
      ..color = line
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    final path = Path();
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final p = _b(size, t);
      if (t <= progress) {
        i == 0 ? path.moveTo(p.dx, p.dy) : path.lineTo(p.dx, p.dy);
      } else if (i.isEven && i < steps) {
        canvas.drawLine(p, _b(size, (i + 1) / steps), dashed);
      }
    }
    canvas.drawPath(path, solid);
    final (p0, _, p2) = _pts(size);
    canvas
      ..drawCircle(p0, 4, Paint()..color = dot)
      ..drawCircle(p2, 4, Paint()..color = progress >= 1 ? dot : line);
  }

  @override
  bool shouldRepaint(_RoutePainter old) => old.progress != progress || old.line != line || old.done != done;
}

// ---------------------------------------------------------------------------
// Ícone em forma
// ---------------------------------------------------------------------------

/// Forma do [SsShapeIcon].
enum SsShape { losango, hexagono }

/// Ícone dentro de um losango ou hexágono de cantos arredondados. Tonal (cor a
/// 14%, ícone na cor) ou [filled] (forma cheia, ícone claro). Sem [color], a marca.
class SsShapeIcon extends StatelessWidget {
  const SsShapeIcon(
    this.icon, {
    super.key,
    this.shape = SsShape.losango,
    this.color,
    this.filled = false,
    this.size = 52,
    this.iconColor,
  });

  final IconData icon;
  final SsShape shape;
  final Color? color;
  final bool filled;
  final double size;

  /// Cor do ícone (sobrepõe o padrão do tonal/cheio).
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final k = color ?? c.accent;
    final fill = filled ? k : k.withValues(alpha: c.isDark ? .22 : .14);
    final fg = iconColor ?? (filled ? AppColors.onDark : (color == null ? c.accentText : k));
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _ShapePainter(shape, fill),
        child: Icon(icon, size: size * .42, color: fg),
      ),
    );
  }

  /// Contorno da forma (também usado no botão hexagonal do herói).
  static Path pathFor(SsShape shape, Size s) {
    final r = math.min(s.width, s.height) / 2;
    final ctr = s.center(Offset.zero);
    final n = shape == SsShape.losango ? 4 : 6;
    final start = -math.pi / 2;
    final pts = [
      for (var i = 0; i < n; i++)
        ctr + Offset(math.cos(start + i * 2 * math.pi / n), math.sin(start + i * 2 * math.pi / n)) * r,
    ];
    // Cantos arredondados: corta perto de cada vértice e passa uma curva por ele.
    final k = shape == SsShape.losango ? .24 : .2;
    final path = Path();
    for (var i = 0; i < n; i++) {
      final p = pts[i], prev = pts[(i - 1 + n) % n], next = pts[(i + 1) % n];
      final a = Offset.lerp(p, prev, k)!, b = Offset.lerp(p, next, k)!;
      i == 0 ? path.moveTo(a.dx, a.dy) : path.lineTo(a.dx, a.dy);
      path.quadraticBezierTo(p.dx, p.dy, b.dx, b.dy);
    }
    return path..close();
  }
}

class _ShapePainter extends CustomPainter {
  _ShapePainter(this.shape, this.color);
  final SsShape shape;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) => canvas.drawPath(SsShapeIcon.pathFor(shape, size), Paint()..color = color);

  @override
  bool shouldRepaint(_ShapePainter old) => old.shape != shape || old.color != color;
}

// ---------------------------------------------------------------------------
// Card com aba de status
// ---------------------------------------------------------------------------

/// Card de tarefa com uma **aba de status** no topo à esquerda (o card sobe
/// nela num recorte em S), avatares e progresso no topo à direita, ícone em
/// losango, título, subtítulo e menu ⋮. [tone] é a cor do status (sucesso,
/// aviso, marca...).
class SsStatusTabCard extends StatelessWidget {
  const SsStatusTabCard({
    super.key,
    required this.status,
    required this.title,
    this.subtitle,
    this.tone,
    this.icon = Icons.checklist_rounded,
    this.people = const [],
    this.progress,
    this.onTap,
    this.onMenu,
  });

  final String status;
  final String title;
  final String? subtitle;
  final Color? tone;
  final IconData icon;
  final List<String> people;

  /// 0–1 (nulo: sem barra).
  final double? progress;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  static const _tabH = 40.0;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final k = tone ?? c.accent;
    final fill = Color.lerp(c.surface, k, c.isDark ? .26 : .2)!;
    final d = SsDensity.of(context);
    return SsPressable(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final tabW = (w * .36).clamp(104.0, 170.0);
          return CustomPaint(
            painter: _TabCardPainter(fill: fill, tabW: tabW, tabH: _tabH, shadow: !c.isDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: _tabH,
                  child: Row(
                    children: [
                      SizedBox(
                        width: tabW,
                        child: Center(
                          child: Text(
                            status,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: c.ink, fontSize: AppType.sub, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      if (people.isNotEmpty) SsAvatarStack(people, size: 28),
                      const Spacer(),
                      if (progress != null) ...[
                        SizedBox(
                          width: 54,
                          height: 4,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(2),
                            // Enche quando o card entra na tela.
                            child: SsTweenInView(
                              end: progress!.clamp(0.0, 1.0),
                              duration: const Duration(milliseconds: 700),
                              builder: (_, v, _) =>
                                  LinearProgressIndicator(value: v, color: k, backgroundColor: c.field, minHeight: 4),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(progress! * 100).round()}%',
                          style: AppTheme.number(context, size: AppType.meta, color: c.ink2),
                        ),
                        const SizedBox(width: 4),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(d.cardPad, d.cardPad - 2, 4, d.cardPad),
                  child: Row(
                    children: [
                      SsShapeIcon(icon, color: c.isDark ? c.page : c.ink, filled: true, iconColor: fill, size: 54),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: c.ink, fontSize: AppType.lg, fontWeight: FontWeight.w800),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: TextStyle(color: c.ink2, fontSize: AppType.set, fontWeight: FontWeight.w500),
                              ),
                          ],
                        ),
                      ),
                      if (onMenu != null)
                        IconButton(
                          tooltip: SsStrings.of(context).moreOptions,
                          onPressed: onMenu,
                          icon: Icon(Icons.more_vert_rounded, color: c.ink),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TabCardPainter extends CustomPainter {
  _TabCardPainter({required this.fill, required this.tabW, required this.tabH, required this.shadow});
  final Color fill;
  final double tabW;
  final double tabH;
  final bool shadow;

  @override
  void paint(Canvas canvas, Size size) {
    const r = AppRadius.cardActive;
    const s = 18.0;
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(0, r)
      ..quadraticBezierTo(0, 0, r, 0)
      ..lineTo(tabW - s, 0)
      // O "S": desce da aba para o corpo do card.
      ..cubicTo(tabW - 2, 0, tabW + 2, tabH, tabW + s, tabH)
      ..lineTo(w - r, tabH)
      ..quadraticBezierTo(w, tabH, w, tabH + r)
      ..lineTo(w, h - r)
      ..quadraticBezierTo(w, h, w - r, h)
      ..lineTo(r, h)
      ..quadraticBezierTo(0, h, 0, h - r)
      ..close();
    if (shadow) canvas.drawShadow(path, AppColors.shadowInk, 3, false);
    canvas.drawPath(path, Paint()..color = fill);
  }

  @override
  bool shouldRepaint(_TabCardPainter old) => old.fill != fill || old.tabW != tabW;
}
