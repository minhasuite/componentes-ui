// v0.13: mosaico em colunas, conteúdo + coluna lateral e card de foto (pares
// do Ss::MasonryComponent, Ss::AsideLayoutComponent e Ss::PhotoCardComponent).
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../ss_card.dart';

/// Mosaico em colunas: os [children] na ordem, distribuídos um por coluna
/// (1 abaixo de 640, 2 até 1024, 3 até 1440 e 4 acima, pela largura que o
/// mosaico recebe), cada coluna descendo na própria altura. [maxColumns]
/// limita (1 a 4). Espaço entre cards: [spacing] (padrão: o `gap` da densidade).
/// O web (`Ss::MasonryComponent`) usa o column-count do CSS.
class SsMasonry extends StatelessWidget {
  const SsMasonry({super.key, required this.children, this.maxColumns = 4, this.spacing});

  final List<Widget> children;
  final int maxColumns;
  final double? spacing;

  /// Colunas para a largura (as mesmas quebras do web).
  static int columnsFor(double width, {int max = 4}) =>
      (width < 640 ? 1 : (width < 1024 ? 2 : (width < 1440 ? 3 : 4))).clamp(1, max.clamp(1, 4));

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? SsDensity.of(context).gap;
    return LayoutBuilder(
      builder: (context, box) {
        final n = columnsFor(box.maxWidth, max: maxColumns);
        if (n == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, w) in children.indexed) ...[if (i > 0) SizedBox(height: gap), w],
            ],
          );
        }
        final cols = List.generate(n, (_) => <Widget>[]);
        for (final (i, w) in children.indexed) {
          final col = cols[i % n];
          if (col.isNotEmpty) col.add(SizedBox(height: gap));
          col.add(w);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final (i, col) in cols.indexed) ...[
              if (i > 0) SizedBox(width: gap),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: col),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Conteúdo + coluna lateral: a partir de [breakpoint] (1024) o [main] ocupa
/// 2/3 e o [aside] 1/3, lado a lado e alinhados em cima; abaixo, o [aside]
/// desce para baixo do [main]. [asideLabel] nomeia a coluna para o leitor de
/// tela. O web (`Ss::AsideLayoutComponent`) ainda gruda a coluna no topo ao rolar.
class SsAsideLayout extends StatelessWidget {
  const SsAsideLayout({
    super.key,
    required this.main,
    this.aside,
    this.breakpoint = 1024,
    this.spacing,
    this.asideLabel,
  });

  final Widget main;
  final Widget? aside;
  final double breakpoint;

  /// Espaço entre o principal e a coluna (padrão: 1,67 × o `gap` da densidade).
  final double? spacing;
  final String? asideLabel;

  @override
  Widget build(BuildContext context) {
    final gap = spacing ?? SsDensity.of(context).gap * 1.67;
    final side = aside == null
        ? null
        : Semantics(container: true, label: asideLabel, explicitChildNodes: true, child: aside);
    return LayoutBuilder(
      builder: (context, box) {
        if (side == null) return main;
        if (box.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              main,
              SizedBox(height: gap),
              side,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 2, child: main),
            SizedBox(width: gap),
            Expanded(child: side),
          ],
        );
      },
    );
  }
}

/// Card de foto: a [image] cobrindo o card na [aspectRatio] (16:9), com o
/// [title] e um selo de estado ([badge]: "Ligada", "22 °C") por cima de um
/// véu escuro embaixo. [dimmed] deixa a foto em cinza e mais escura (aparelho
/// desligado). O app passa a imagem pronta (`SsNetImage`, cache). O web é o
/// `Ss::PhotoCardComponent`.
class SsPhotoCard extends StatelessWidget {
  const SsPhotoCard({
    super.key,
    this.image,
    this.title,
    this.badge,
    this.aspectRatio = 16 / 9,
    this.dimmed = false,
    this.onTap,
  });

  final Widget? image;
  final String? title;
  final String? badge;
  final double aspectRatio;
  final bool dimmed;
  final VoidCallback? onTap;

  /// Cinza e escuro da foto apagada (o grayscale(.85) brightness(.6) do web).
  static const dimFilter = ColorFilter.matrix([
    .3, .3, .3, 0, 0, //
    .3, .3, .3, 0, 0,
    .3, .3, .3, 0, 0,
    0, 0, 0, 1, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    final pic = image == null ? null : (dimmed ? ColorFiltered(colorFilter: dimFilter, child: image) : image);
    return Semantics(
      image: true,
      label: [?title, ?badge].join(', '),
      child: SsCard(
        padding: EdgeInsets.zero,
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(d.radiusCard),
          child: AspectRatio(
            aspectRatio: aspectRatio > 0 ? aspectRatio : 16 / 9,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ?pic,
                if (title != null || badge != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.scrim.withValues(alpha: 0), AppColors.scrim.withValues(alpha: .55)],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(d.cardPad * .9, 24, d.cardPad * .9, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title ?? '',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w700),
                              ),
                            ),
                            if (badge != null)
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: AppColors.onDark.withValues(alpha: .2),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                                  child: Text(
                                    badge!,
                                    style: const TextStyle(
                                      color: AppColors.onDark,
                                      fontSize: AppType.meta,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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
