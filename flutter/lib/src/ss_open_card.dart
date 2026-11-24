import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'v19/transicoes/open_container.dart';

/// Card que se abre na tela de detalhe (container transform): no toque, o
/// retângulo do card cresce até a tela, o raio vai de 18 a 0 e [closed] dá
/// lugar a [open] em crossfade; ao voltar, encolhe de novo para o card.
/// [open] costuma ser um `Scaffold` com AppBar (o voltar fecha).
///
/// v1.9: é o [SsOpenContainer] com a casca de card (sombra no claro, borda no
/// escuro); o gesto de voltar preditivo do Android 14+ leva a tela de volta ao
/// card junto com o dedo. Com go_router, dê [tag] e [onOpen] e use o
/// [SsOpenPage] com o mesmo tag na rota.
class SsOpenCard extends StatelessWidget {
  const SsOpenCard({super.key, required this.closed, this.open, this.tag, this.onOpen})
    : assert(open != null || onOpen != null, 'Dê open ou onOpen (go_router).');

  final Widget closed;
  final WidgetBuilder? open;

  /// v1.9: o mesmo do [SsOpenPage.tag] (go_router).
  final Object? tag;

  /// v1.9: abre por fora (`() => context.push('/pedidos/12')`).
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    return SsOpenContainer<void>(
      tag: tag,
      openBuilder: open,
      onOpen: onOpen,
      closedBuilder: (context, abrir) => DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: c.isDark ? null : AppShadows.card,
          border: c.isDark ? Border.all(color: c.line) : null,
        ),
        child: Material(
          color: c.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: abrir, child: closed),
        ),
      ),
    );
  }
}
