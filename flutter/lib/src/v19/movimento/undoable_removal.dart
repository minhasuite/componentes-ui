// v1.9 · movimento: ação otimista com desfazer animado (par do controller `ss-undoable` do web).
import 'dart:ui' show lerpDouble;

import 'package:material_ui/material_ui.dart';

import '../../app_theme.dart';
import '../../motion.dart';
import '../../ss_strings.dart';
import '../../ss_toast.dart';

/// Monta o item com a função que o remove ([SsUndoableRemoval.builder]).
typedef SsUndoableBuilder = Widget Function(BuildContext context, VoidCallback remove);

/// Remoção otimista com desfazer: `remove()` faz o item sair **encolhendo** (altura, opacidade e
/// um pouco de escala, [SsMotion.medium] na curva [SsMotion.exit]) e mostra o [SsToast] com
/// "Desfazer" e a contagem ([showSsUndo]). Desfez: o item volta crescendo no mesmo lugar
/// ([SsMotion.enter]). Não desfez: chama [onCommit] (a exclusão de verdade) e depois [onRemoved]
/// (o app tira da lista). Se [onCommit] falhar, o item volta e um aviso de erro aparece
/// ([errorMessage], com a vibração de erro).
///
/// ```dart
/// SsUndoableRemoval(
///   key: ValueKey(p.id),
///   message: 'Pedido excluído',
///   onCommit: () => api.excluir(p),
///   onRemoved: () => setState(() => pedidos.remove(p)),
///   builder: (context, remove) => SsListItem(title: p.nome, trailing: IconButton(onPressed: remove, ...)),
/// )
/// ```
///
/// Vibração: atenção ([SsHaptics.warning]) ao remover, seleção ao desfazer. Leitor de tela: o
/// item removido sai da árvore de semântica enquanto espera; o aviso é região viva. Com menos
/// movimento, some e volta sem animar.
class SsUndoableRemoval extends StatefulWidget {
  const SsUndoableRemoval({
    super.key,
    required this.message,
    required this.onCommit,
    required this.builder,
    this.onRemoved,
    this.onUndo,
    this.errorMessage,
    this.undoLabel,
    this.icon = Icons.delete_outline,
    this.duration = const Duration(seconds: 5),
    this.bottom = 104,
  });

  /// Texto do aviso ("Pedido excluído").
  final String message;

  /// A ação de verdade, depois que o tempo do desfazer passa sem desfazer.
  final Future<void> Function() onCommit;

  /// Tirou de vez (o [onCommit] deu certo): o app tira o item da lista.
  final VoidCallback? onRemoved;

  /// A pessoa desfez.
  final VoidCallback? onUndo;

  /// Aviso quando o [onCommit] falha (padrão: [SsStrings.genericError]).
  final String? errorMessage;

  /// Texto do botão (padrão: [SsStrings.undo]).
  final String? undoLabel;
  final IconData? icon;

  /// Tempo do aviso (o do desfazer).
  final Duration duration;

  /// Distância do aviso ao pé da tela (a mesma do [showSsUndo]).
  final double bottom;
  final SsUndoableBuilder builder;

  @override
  State<SsUndoableRemoval> createState() => SsUndoableRemovalState();
}

/// Estado do [SsUndoableRemoval]; [remove] também serve por `GlobalKey`.
class SsUndoableRemovalState extends State<SsUndoableRemoval> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, value: 1, duration: SsMotion.medium);
  bool _fora = false;

  /// O item está fora (encolhido, esperando o desfazer ou o fim).
  bool get removed => _fora;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _anima(double alvo) async {
    if (!mounted) return;
    if (reduceMotion(context)) {
      _c.value = alvo;
      return;
    }
    await _c.animateTo(alvo, curve: alvo == 0 ? SsMotion.exit : SsMotion.enter).orCancel.catchError((_) {});
  }

  /// Tira o item (com o aviso de desfazer). Chamar de novo enquanto ele está fora não faz nada.
  Future<void> remove() async {
    if (_fora || !mounted) return;
    setState(() => _fora = true);
    SsHaptics.warning();
    final s = SsStrings.of(context);
    final desfez = showSsUndo(
      context,
      widget.message,
      label: widget.undoLabel,
      icon: widget.icon,
      duration: widget.duration,
      bottom: widget.bottom,
    );
    await _anima(0);
    if (await desfez) {
      SsHaptics.selection();
      widget.onUndo?.call();
      await _volta();
      return;
    }
    try {
      await widget.onCommit();
      widget.onRemoved?.call();
    } catch (_) {
      await _volta();
      final msg = widget.errorMessage ?? s.genericError;
      if (mounted) {
        showSsToast(context, msg, icon: Icons.error_outline, tone: AppColors.danger, bottom: widget.bottom);
      } else {
        showSsToastGlobal(msg, icon: Icons.error_outline, tone: AppColors.danger, bottom: widget.bottom);
      }
    }
  }

  Future<void> _volta() async {
    if (!mounted) return;
    setState(() => _fora = false);
    await _anima(1);
  }

  @override
  Widget build(BuildContext context) {
    final filho = widget.builder(context, remove);
    return IgnorePointer(
      ignoring: _fora,
      child: ExcludeSemantics(
        excluding: _fora,
        child: SizeTransition(
          sizeFactor: _c,
          alignment: AlignmentDirectional.topStart,
          child: AnimatedBuilder(
            animation: _c,
            builder: (_, child) => Opacity(
              opacity: _c.value.clamp(0.0, 1.0),
              child: Transform.scale(scale: lerpDouble(.94, 1, _c.value), child: child),
            ),
            child: filho,
          ),
        ),
      ),
    );
  }
}
