import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Card que se abre na tela de detalhe (container transform): no toque, o
/// retângulo do card cresce até a tela, o raio vai de 18 a 0 e [closed] dá
/// lugar a [open] em crossfade; ao voltar, encolhe de novo para o card.
/// [open] costuma ser um `Scaffold` com AppBar (o voltar fecha).
class SsOpenCard extends StatefulWidget {
  const SsOpenCard({super.key, required this.closed, required this.open});

  final Widget closed;
  final WidgetBuilder open;

  @override
  State<SsOpenCard> createState() => _SsOpenCardState();
}

class _SsOpenCardState extends State<SsOpenCard> {
  bool _aberto = false;

  Future<void> _abrir() async {
    final nav = Navigator.of(context);
    final box = context.findRenderObject() as RenderBox?;
    final navBox = nav.context.findRenderObject() as RenderBox?;
    if (box == null || navBox == null) return;
    final de = box.localToGlobal(Offset.zero, ancestor: navBox) & box.size;
    final c = SsColors.of(context);
    final rapido = reduceMotion(context);
    setState(() => _aberto = true);
    await nav.push(
      PageRouteBuilder<void>(
        transitionDuration: Duration(milliseconds: rapido ? 200 : 460),
        reverseTransitionDuration: Duration(milliseconds: rapido ? 200 : 380),
        pageBuilder: (context, a, _) {
          final aberta = widget.open(context);
          if (rapido) return FadeTransition(opacity: a, child: aberta);
          return _Transformacao(
            de: de,
            tela: navBox.size,
            closed: widget.closed,
            open: aberta,
            animation: a,
            cor: c.surface,
          );
        },
      ),
    );
    if (mounted) setState(() => _aberto = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final radius = BorderRadius.circular(AppRadius.card);
    // Enquanto a tela está aberta, o card some daqui (é ele que voa).
    return Opacity(
      opacity: _aberto ? 0 : 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: c.isDark ? null : AppShadows.card,
          border: c.isDark ? Border.all(color: c.line) : null,
        ),
        child: Material(
          color: c.surface,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(onTap: _abrir, child: widget.closed),
        ),
      ),
    );
  }
}

class _Transformacao extends StatelessWidget {
  const _Transformacao({
    required this.de,
    required this.tela,
    required this.closed,
    required this.open,
    required this.animation,
    required this.cor,
  });

  final Rect de;
  final Size tela;
  final Widget closed;
  final Widget open;
  final Animation<double> animation;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final curva = CurvedAnimation(parent: animation, curve: Curves.fastOutSlowIn, reverseCurve: Curves.easeInCubic);
    return AnimatedBuilder(
      animation: curva,
      builder: (context, aberta) {
        final t = curva.value;
        final r = Rect.lerp(de, Offset.zero & tela, t)!;
        // Crossfade: o fechado some no primeiro terço, o aberto entra depois.
        final sai = (1 - t / .3).clamp(0.0, 1.0);
        final entra = ((t - .2) / .5).clamp(0.0, 1.0);
        return Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: Colors.black.withValues(alpha: .25 * t)),
            ),
            Positioned.fromRect(
              rect: r,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.card * (1 - t)),
                child: ColoredBox(
                  color: cor,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Sempre no Stack (só a opacidade muda): senão o aberto troca de posição e perde o estado.
                      Opacity(
                        opacity: sai,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topLeft,
                          child: SizedBox.fromSize(
                            size: de.size,
                            child: Material(color: cor, child: closed),
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: entra,
                        child: FittedBox(
                          fit: BoxFit.fitWidth,
                          alignment: Alignment.topLeft,
                          child: SizedBox.fromSize(size: tela, child: aberta),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
      child: open,
    );
  }
}
