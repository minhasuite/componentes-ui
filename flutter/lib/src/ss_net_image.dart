import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_list.dart';

/// Foto da rede (produto, planta, destino) com o vazio do design system:
/// enquanto carrega, no erro ou sem [url], mostra listras diagonais na cor do
/// campo com as iniciais de [name] (ou [fallbackIcon]); a foto entra com fade.
/// Decodifica no tamanho da tela (`cacheWidth` pelo devicePixelRatio), não no
/// tamanho original.
///
/// Sem cache em disco: só o cache de memória do Flutter (o pacote não tem
/// dependência de cache). App que precisa de offline passa o provider do
/// próprio plugin em [provider] (ex. `CachedNetworkImageProvider.new`).
///
/// `SsNetImage(p.photoUrl, width: 56, height: 56, name: p.name)`
class SsNetImage extends StatelessWidget {
  const SsNetImage(
    this.url, {
    super.key,
    this.width,
    this.height,
    this.radius = AppRadius.thumb,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.name,
    this.provider,
  });

  final String? url;
  final double? width;
  final double? height;
  final double radius;
  final BoxFit fit;
  final IconData fallbackIcon;

  /// Iniciais no vazio e rótulo para o leitor de tela.
  final String? name;

  /// Troca o `NetworkImage` (cache em disco, cabeçalhos): recebe a URL.
  final ImageProvider Function(String url)? provider;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final fade = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 220);
    return Semantics(
      image: name != null,
      label: name,
      excludeSemantics: true,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: SizedBox(
          width: width,
          height: height,
          child: LayoutBuilder(
            builder: (context, box) {
              final placeholder = _Striped(icon: fallbackIcon, name: name);
              final u = url?.trim() ?? '';
              if (u.isEmpty) return placeholder;
              final w = width ?? (box.hasBoundedWidth ? box.maxWidth : null);
              final base = provider?.call(u) ?? NetworkImage(u);
              return Image(
                image: ResizeImage.resizeIfNeeded(w == null ? null : (w * dpr).round(), null, base),
                width: width,
                height: height,
                fit: fit,
                frameBuilder: (_, child, frame, sync) {
                  if (sync) return child;
                  return Stack(
                    fit: StackFit.passthrough,
                    children: [
                      if (frame == null) Positioned.fill(child: placeholder),
                      AnimatedOpacity(opacity: frame == null ? 0 : 1, duration: fade, child: child),
                    ],
                  );
                },
                errorBuilder: (_, _, _) => placeholder,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Striped extends StatelessWidget {
  const _Striped({required this.icon, this.name});
  final IconData icon;
  final String? name;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final side = math.min(box.hasBoundedWidth ? box.maxWidth : 48.0, box.hasBoundedHeight ? box.maxHeight : 48.0);
        final n = name?.trim() ?? '';
        return CustomPaint(
          painter: _StripePainter(c.field, Color.alphaBlend(c.ink.withValues(alpha: .05), c.field)),
          child: SizedBox.expand(
            child: Center(
              child: n.isEmpty
                  ? Icon(icon, color: c.muted, size: side * .4)
                  : Text(
                      SsAvatar.initials(n),
                      style: TextStyle(color: c.muted, fontSize: side * .32, fontWeight: FontWeight.w800, height: 1),
                    ),
            ),
          ),
        );
      },
    );
  }
}

/// Listras a 135° de 6 px.
class _StripePainter extends CustomPainter {
  _StripePainter(this.a, this.b);
  final Color a;
  final Color b;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = a);
    final p = Paint()
      ..color = b
      ..strokeWidth = 6;
    for (var x = -size.height; x < size.width; x += 12) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), p);
    }
  }

  @override
  bool shouldRepaint(_StripePainter old) => old.a != a || old.b != b;
}
