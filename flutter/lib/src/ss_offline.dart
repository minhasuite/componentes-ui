import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Faixa fina no topo de [child]: desce com mola quando [offline] vira
/// `true` ("Sem conexão — mostrando o que já foi baixado") e, quando a rede
/// volta, troca por um "De volta online" que some em 2 s. Anuncia a mudança
/// para leitor de tela. Bom no `MaterialApp.builder`.
class SsOfflineBanner extends StatefulWidget {
  const SsOfflineBanner({super.key, required this.offline, required this.child});

  final bool offline;
  final Widget child;

  @override
  State<SsOfflineBanner> createState() => _SsOfflineBannerState();
}

class _SsOfflineBannerState extends State<SsOfflineBanner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 220),
    value: widget.offline ? 1 : 0,
  );
  late final _altura = CurvedAnimation(parent: _c, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
  Timer? _volta;

  @override
  void didUpdateWidget(SsOfflineBanner old) {
    super.didUpdateWidget(old);
    if (old.offline == widget.offline) return;
    _volta?.cancel();
    _ir(1);
    if (!widget.offline) _volta = Timer(const Duration(seconds: 2), () => _ir(0));
  }

  void _ir(double alvo) {
    if (!mounted) return;
    if (reduceMotion(context)) {
      _c.value = alvo;
    } else {
      alvo == 1 ? _c.forward() : _c.reverse();
    }
  }

  @override
  void dispose() {
    _volta?.cancel();
    _altura.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final off = widget.offline;
    final fg = off ? c.aquecText : c.successText;
    final texto = off ? SsStrings.of(context).offlineBanner : SsStrings.of(context).backOnline;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final aberto = _c.value > 0;
        // Column com o banner sempre no índice 0 (SizedBox quando fechado):
        // assim a tela continua no mesmo lugar da árvore.
        return Column(
          children: [
            if (!aberto)
              const SizedBox.shrink()
            else
              ClipRect(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  heightFactor: _altura.value.clamp(0.0, 1.2),
                  child: Material(
                    color: off ? c.aquecSoft : AppColors.success.withValues(alpha: c.isDark ? .18 : .14),
                    child: SafeArea(
                      bottom: false,
                      child: Semantics(
                        liveRegion: true,
                        label: texto,
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            child: Row(
                              children: [
                                Icon(off ? Icons.cloud_off_rounded : Icons.cloud_done_rounded, size: 17, color: fg),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    texto,
                                    style: TextStyle(color: fg, fontWeight: FontWeight.w700, fontSize: AppType.sub),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              // Sempre o mesmo widget em volta: trocar a árvore desmontaria a tela.
              child: MediaQuery.removePadding(context: context, removeTop: aberto, child: child!),
            ),
          ],
        );
      },
      child: widget.child,
    );
  }
}
