// v1.10.0: o par Flutter do Ss::ProductCardComponent (cartão de produto com a imagem vazando).
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_card.dart';
import '../ss_net_image.dart';
import '../ss_stat.dart';

/// O botão de ação do [SsProductCard] (o `action:` do web): "Adicionar ao carrinho".
class SsProductAction {
  const SsProductAction(this.label, this.onPressed, {this.icon = Icons.add_rounded});

  /// Nome da ação; o leitor de tela ouve "Adicionar: Costela-de-adão".
  final String label;
  final VoidCallback? onPressed;
  final IconData icon;
}

/// Cartão de produto com a imagem vazando acima do card (v1.10, par do `Ss::ProductCardComponent`):
/// nome, texto, preço e o botão de ação quadrado na cor da marca.
///
/// ```dart
/// SsProductCard(
///   name: 'Costela-de-adão', text: 'Meia-sombra', price: r'R$ 89,90',
///   imageUrl: url, onTap: () => abrir(p),
///   action: SsProductAction('Adicionar', () => carrinho.add(p)),
/// )
/// ```
/// [image] troca o [imageUrl] por um widget próprio (SVG, ilustração). [badge]: o selo do canto
/// ("Novo", "-20%"). A imagem ocupa 72% da largura e sobe [overhang] acima do card (64, como o web);
/// numa grade, deixe esse espaço livre em cima (o card não reserva por fora). Tocar no card ([onTap])
/// e na ação são alvos separados, os dois de 48 no mínimo.
class SsProductCard extends StatelessWidget {
  const SsProductCard({
    super.key,
    required this.name,
    this.price,
    this.text,
    this.image,
    this.imageUrl,
    this.onTap,
    this.action,
    this.badge,
    this.overhang = 64,
  });

  final String name;

  /// Preço já formatado ("R$ 89,90"), em DM Mono como o `ss_amount`.
  final String? price;
  final String? text;
  final Widget? image;
  final String? imageUrl;
  final VoidCallback? onTap;
  final SsProductAction? action;
  final String? badge;

  /// Quanto a imagem sobe acima do card.
  final double overhang;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth.isFinite ? box.maxWidth : 220.0;
        final img = w * .72;
        final sobe = math.min(overhang, img - 8);
        final arte =
            image ??
            (imageUrl != null
                ? SsNetImage(imageUrl!, fit: BoxFit.contain, radius: 0, fallbackIcon: Icons.inventory_2_outlined)
                : Icon(Icons.inventory_2_outlined, size: img * .5, color: c.muted));
        final pad = d.cardPad - 2;
        final card = SsCard(
          onTap: onTap,
          padding: EdgeInsets.fromLTRB(pad, img - sobe + d.space(8), pad, pad),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Semantics(
                header: true,
                child: Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: d.font(AppType.md),
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
              if (text != null) ...[
                SizedBox(height: d.space(4)),
                Text(
                  text!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
                ),
              ],
              if (price != null || action != null) ...[
                SizedBox(height: d.space(12)),
                Row(
                  children: [
                    if (price != null)
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SsAmount(price!, size: d.font(20), weight: FontWeight.w600),
                          ),
                        ),
                      )
                    else
                      const Spacer(),
                    if (action != null) ...[SizedBox(width: d.space(10)), _Acao(action!, name)],
                  ],
                ),
              ],
            ],
          ),
        );
        return Semantics(
          container: true,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Padding(
                padding: EdgeInsets.only(top: sobe),
                child: card,
              ),
              Positioned(
                top: 0,
                left: (w - img) / 2,
                width: img,
                height: img,
                child: IgnorePointer(
                  child: ExcludeSemantics(child: Center(child: arte)),
                ),
              ),
              if (badge != null)
                Positioned(
                  top: sobe + d.space(12),
                  left: d.space(12),
                  child: IgnorePointer(child: _Selo(badge!)),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _Selo extends StatelessWidget {
  const _Selo(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(
        text,
        style: TextStyle(color: c.accentText, fontSize: AppType.label, fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _Acao extends StatelessWidget {
  const _Acao(this.action, this.name);
  final SsProductAction action;
  final String name;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final lado = d.controlHeight + 2;
    final on = action.onPressed != null;
    return SsTapTarget(
      semantics: true,
      child: Semantics(
        container: true,
        button: true,
        enabled: on,
        label: '${action.label}: $name',
        excludeSemantics: true,
        child: SsPressable(
          onTap: action.onPressed,
          enabled: on,
          scale: .92,
          child: AnimatedContainer(
            duration: reduceMotion(context) ? Duration.zero : SsMotion.short,
            width: lado,
            height: lado,
            decoration: BoxDecoration(
              color: on ? c.accentSolid : c.field,
              borderRadius: BorderRadius.circular(d.radiusField + 2),
            ),
            child: Icon(action.icon, size: 20, color: on ? AppColors.onDark : c.muted),
          ),
        ),
      ),
    );
  }
}
