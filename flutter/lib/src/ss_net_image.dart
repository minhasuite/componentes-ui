import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
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
/// Imagem que precisa de sessão (cookie, token) ou vem de outro lugar:
/// [image] recebe qualquer `ImageProvider`, e [SsNetImage.bytes] carrega os
/// bytes por uma função assíncrona (o `dio` do app com o login), com o
/// mesmo vazio enquanto carrega e no erro.
///
/// Sem altura (numa `Column`, num `ListView`), não estoura: a altura sai da
/// largura por [aspectRatio] (padrão 4:3); sem largura nem altura, fica em
/// 96 × 96.
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
    this.image,
    this.aspectRatio,
  });

  /// Bytes de uma função assíncrona (imagem atrás de login, câmera):
  /// `SsNetImage.bytes(() => api.snapshot(id), cacheKey: 'cam-$id-$t')`.
  /// [cacheKey] identifica a imagem no cache de memória: troque-o para
  /// buscar de novo (ex.: com a hora do instantâneo).
  SsNetImage.bytes(
    Future<Uint8List> Function() load, {
    super.key,
    required Object cacheKey,
    this.width,
    this.height,
    this.radius = AppRadius.thumb,
    this.fit = BoxFit.cover,
    this.fallbackIcon = Icons.image_outlined,
    this.name,
    this.aspectRatio,
  }) : url = null,
       provider = null,
       image = SsBytesImage(load, cacheKey: cacheKey);

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

  /// A imagem pronta (vence [url] e [provider]): `MemoryImage`, um provider
  /// com cabeçalho de sessão, [SsBytesImage].
  final ImageProvider? image;

  /// Largura ÷ altura quando não há altura (nem [height] nem limite de fora).
  /// Padrão: 4:3.
  final double? aspectRatio;

  /// Lado quando não há largura nem altura.
  static const fallbackSize = 96.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, fora) {
      // Sem limite de um lado: tira do outro pela proporção (o vazio usa
      // SizedBox.expand e estouraria).
      var w = width ?? (fora.hasBoundedWidth ? fora.maxWidth : null);
      var h = height ?? (fora.hasBoundedHeight ? fora.maxHeight : null);
      final r = aspectRatio ?? 4 / 3;
      if (w == null && h == null) {
        w = fallbackSize;
        h = fallbackSize;
      } else if (h == null) {
        h = w! / r;
      } else {
        w ??= h * r;
      }
      return _foto(context, width ?? (fora.hasBoundedWidth ? null : w), height ?? (fora.hasBoundedHeight ? null : h));
    },
  );

  Widget _foto(BuildContext context, double? width, double? height) {
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
              if (image == null && u.isEmpty) return placeholder;
              final w = width ?? (box.hasBoundedWidth ? box.maxWidth : null);
              final base = image ?? provider?.call(u) ?? NetworkImage(u);
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

/// `ImageProvider` de bytes que chegam por uma função assíncrona (imagem
/// atrás de login). Fica no cache de memória do Flutter por [cacheKey].
@immutable
class SsBytesImage extends ImageProvider<SsBytesImage> {
  const SsBytesImage(this.load, {required this.cacheKey, this.scale = 1});

  final Future<Uint8List> Function() load;
  final Object cacheKey;
  final double scale;

  @override
  Future<SsBytesImage> obtainKey(ImageConfiguration configuration) => SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(SsBytesImage key, ImageDecoderCallback decode) =>
      MultiFrameImageStreamCompleter(codec: _codec(decode), scale: scale, debugLabel: 'SsBytesImage($cacheKey)');

  Future<ui.Codec> _codec(ImageDecoderCallback decode) async {
    try {
      final bytes = await load();
      if (bytes.isEmpty) throw StateError('SsBytesImage($cacheKey): vazio');
      return await decode(await ui.ImmutableBuffer.fromUint8List(bytes));
    } catch (_) {
      // Falhou: tira do cache para tentar de novo na próxima vez.
      scheduleMicrotask(() => PaintingBinding.instance.imageCache.evict(this));
      rethrow;
    }
  }

  @override
  bool operator ==(Object other) => other is SsBytesImage && other.cacheKey == cacheKey && other.scale == scale;

  @override
  int get hashCode => Object.hash(cacheKey, scale);

  @override
  String toString() => 'SsBytesImage($cacheKey, scale: $scale)';
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
