import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Faixa fina no topo de [child]: desce com mola quando [offline] vira
/// `true` ("Sem conexão — mostrando o que já foi baixado") e, quando a rede
/// volta, troca por um "De volta online" que some em 2 s. Anuncia a mudança
/// para leitor de tela. Bom no `MaterialApp.builder`.
///
/// [message] troca o texto offline ("Sem conexão — mostrando o último painel
/// salvo"); [actionLabel] + [onAction] põem um botão à direita enquanto está
/// offline ("Tentar de novo").
class SsOfflineBanner extends StatefulWidget {
  const SsOfflineBanner({
    super.key,
    required this.offline,
    required this.child,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final bool offline;
  final Widget child;

  /// Texto offline. Padrão: [SsStrings.offlineBanner].
  final String? message;

  /// Rótulo do botão (padrão: [SsStrings.retry] quando há [onAction]).
  final String? actionLabel;
  final VoidCallback? onAction;

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
    final s = SsStrings.of(context);
    final texto = off ? widget.message ?? s.offlineBanner : s.backOnline;
    final acao = off && widget.onAction != null;
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
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, acao ? 2 : 7, acao ? 6 : 16, acao ? 2 : 7),
                        child: Row(
                          children: [
                            Expanded(
                              child: Semantics(
                                liveRegion: true,
                                label: texto,
                                child: ExcludeSemantics(
                                  child: Row(
                                    children: [
                                      Icon(
                                        off ? Icons.cloud_off_rounded : Icons.cloud_done_rounded,
                                        size: 17,
                                        color: fg,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          texto,
                                          style: TextStyle(
                                            color: fg,
                                            fontWeight: FontWeight.w700,
                                            fontSize: AppType.sub,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            if (acao)
                              TextButton.icon(
                                onPressed: widget.onAction,
                                icon: const Icon(Icons.refresh_rounded, size: 17),
                                label: Text(widget.actionLabel ?? s.retry),
                                style: TextButton.styleFrom(
                                  foregroundColor: fg,
                                  visualDensity: VisualDensity.compact,
                                  textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: AppType.sub),
                                ),
                              ),
                          ],
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
