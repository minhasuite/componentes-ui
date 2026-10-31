import 'dart:async';

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Estado de sincronização de quem salva primeiro no aparelho e envia depois.
enum SsSyncState { synced, pending, sending, failed, offline }

/// Pílula "pontinho + texto curto" para a AppBar ou uma linha: "Tudo salvo",
/// "3 a enviar", "Enviando…" (pulsa), "Sem conexão" e, em erro, "Falhou ·
/// Tentar de novo". Com [onTap], é tocável (abrir a fila, tentar de novo).
class SsSyncStatus extends StatelessWidget {
  const SsSyncStatus({super.key, required this.state, this.pendingCount = 0, this.onTap});

  final SsSyncState state;
  final int pendingCount;
  final VoidCallback? onTap;

  /// Texto da pílula (público para teste e leitor de tela).
  static String label(SsSyncState s, int n) => switch (s) {
    SsSyncState.synced => 'Tudo salvo',
    SsSyncState.pending => n == 1 ? '1 a enviar' : '$n a enviar',
    SsSyncState.sending => 'Enviando…',
    SsSyncState.failed => 'Falhou · Tentar de novo',
    SsSyncState.offline => n > 0 ? 'Sem conexão · $n a enviar' : 'Sem conexão',
  };

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final (cor, texto) = _cores(c, state);
    final t = label(state, pendingCount);
    return Semantics(
      liveRegion: true,
      button: onTap != null,
      label: t,
      child: ExcludeSemantics(
        child: Material(
          color: state == SsSyncState.failed ? AppColors.dangerSoft : c.field,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: onTap == null ? 28 : 36),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (state == SsSyncState.failed)
                      Icon(Icons.refresh_rounded, size: 14, color: cor)
                    else
                      _Ponto(cor: cor, pulsa: state == SsSyncState.sending),
                    const SizedBox(width: 6),
                    Text(
                      t,
                      style: TextStyle(color: texto, fontSize: AppType.meta, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

(Color, Color) _cores(SsColors c, SsSyncState s) => switch (s) {
  SsSyncState.synced => (AppColors.success, c.successText),
  SsSyncState.pending => (AppColors.aquecFg, c.aquecText),
  SsSyncState.sending => (c.accent, c.accentText),
  SsSyncState.failed => (AppColors.danger, c.dangerText),
  SsSyncState.offline => (c.muted, c.muted),
};

class _Ponto extends StatefulWidget {
  const _Ponto({super.key, required this.cor, this.pulsa = false});
  final Color cor;
  final bool pulsa;

  @override
  State<_Ponto> createState() => _PontoState();
}

class _PontoState extends State<_Ponto> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 900), value: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(_Ponto old) {
    super.didUpdateWidget(old);
    _sync();
  }

  // Pulsar é indicador de carregamento (a única animação contínua permitida).
  void _sync() {
    if (widget.pulsa && !reduceMotion(context)) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c
        ..stop()
        ..value = 1;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween(begin: .3, end: 1.0).animate(_c),
    child: Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: widget.cor, shape: BoxShape.circle),
    ),
  );
}

/// Marquinha de canto de item de lista (UI otimista: o item aparece na hora).
/// Enviando: ponto que pulsa; pendente: relógio; sem conexão: nuvem cortada;
/// falhou: ! em vermelho. Ao virar [SsSyncState.synced], mostra um ✓ que some
/// sozinho (item já sincronizado ao montar não mostra nada).
class SsSyncDot extends StatefulWidget {
  const SsSyncDot(this.state, {super.key});

  final SsSyncState state;

  @override
  State<SsSyncDot> createState() => _SsSyncDotState();
}

class _SsSyncDotState extends State<SsSyncDot> {
  bool _mostraOk = false;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(SsSyncDot old) {
    super.didUpdateWidget(old);
    if (old.state != SsSyncState.synced && widget.state == SsSyncState.synced) {
      setState(() => _mostraOk = true);
      _t?.cancel();
      _t = Timer(const Duration(milliseconds: 1400), () => setState(() => _mostraOk = false));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final (cor, _) = _cores(c, widget.state);
    final Widget filho = switch (widget.state) {
      SsSyncState.synced => Icon(Icons.check_circle_rounded, key: const ValueKey('ok'), size: 14, color: cor),
      SsSyncState.sending => _Ponto(key: const ValueKey('envia'), cor: cor, pulsa: true),
      SsSyncState.pending => Icon(Icons.schedule_rounded, key: const ValueKey('pend'), size: 14, color: cor),
      SsSyncState.offline => Icon(Icons.cloud_off_rounded, key: const ValueKey('off'), size: 14, color: cor),
      SsSyncState.failed => Icon(Icons.error_rounded, key: const ValueKey('erro'), size: 14, color: cor),
    };
    final visivel = widget.state != SsSyncState.synced || _mostraOk;
    final rotulo = switch (widget.state) {
      SsSyncState.synced => 'Salvo',
      SsSyncState.sending => 'Enviando',
      SsSyncState.pending => 'Aguardando envio',
      SsSyncState.offline => 'Sem conexão',
      SsSyncState.failed => 'Falhou ao enviar',
    };
    final d = reduceMotion(context) ? Duration.zero : SsMotion.base;
    return Semantics(
      label: visivel ? rotulo : null,
      child: SizedBox.square(
        dimension: 16,
        child: AnimatedOpacity(
          opacity: visivel ? 1 : 0,
          duration: d,
          child: AnimatedSwitcher(
            duration: d,
            switchInCurve: SsMotion.spring,
            transitionBuilder: (w, a) => ScaleTransition(scale: a, child: w),
            child: Center(child: filho),
          ),
        ),
      ),
    );
  }
}
