import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Pílula escura (igual nos dois temas) com ícone, texto curto e uma ação
/// ("Desfazer") na cor da marca. Use [showSsToast]; o widget é público para o
/// catálogo e para testes.
class SsToast extends StatelessWidget {
  const SsToast(this.message, {super.key, this.icon, this.tone, this.actionLabel, this.onAction});

  final String message;
  final IconData? icon;

  /// Cor do ícone (sucesso, erro); sem ela, a da marca.
  final Color? tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  static const background = Color(0xFF1A1826);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      liveRegion: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 52),
        padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
        decoration: BoxDecoration(
          color: background,
          borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
          border: Border.all(color: Colors.white.withValues(alpha: .08)),
          boxShadow: const [
            BoxShadow(color: Color(0x40000000), offset: Offset(0, 10), blurRadius: 30, spreadRadius: -8),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[Icon(icon, size: 20, color: tone ?? c.brand.accentDark), const SizedBox(width: 10)],
              Flexible(
                child: Text(
                  message,
                  style: const TextStyle(color: AppColors.onDark, fontSize: AppType.set, fontWeight: FontWeight.w600),
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: c.brand.accentDark,
                    shape: const StadiumBorder(),
                    textStyle: GoogleFonts.manrope(fontWeight: FontWeight.w800, fontSize: AppType.set),
                  ),
                  child: Text(actionLabel!),
                ),
              ] else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}

OverlayEntry? _atual;

/// Mostra um [SsToast] subindo de baixo com mola, acima da barra de abas, por
/// [duration]. Um novo substitui o anterior. Tocar na ação fecha o aviso.
void showSsToast(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? tone,
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
  double bottom = 104,
}) {
  _atual?.remove();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  void fechar() {
    if (entry.mounted) entry.remove();
    if (identical(_atual, entry)) _atual = null;
  }

  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      left: 16,
      right: 16,
      bottom: bottom + MediaQuery.viewPaddingOf(ctx).bottom,
      child: Center(
        child: _Entrada(
          duration: duration,
          onDone: fechar,
          child: SsToast(
            message,
            icon: icon,
            tone: tone,
            actionLabel: actionLabel,
            onAction: onAction == null
                ? null
                : () {
                    fechar();
                    onAction();
                  },
          ),
        ),
      ),
    ),
  );
  _atual = entry;
  overlay.insert(entry);
}

class _Entrada extends StatefulWidget {
  const _Entrada({required this.child, required this.duration, required this.onDone});

  final Widget child;
  final Duration duration;
  final VoidCallback onDone;

  @override
  State<_Entrada> createState() => _EntradaState();
}

class _EntradaState extends State<_Entrada> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _c.forward();
    _timer = Timer(widget.duration, () async {
      if (!mounted) return;
      await _c.reverse();
      widget.onDone();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        final t = Curves.easeOutBack.transform(_c.value);
        return Opacity(
          opacity: _c.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, 40 * (1 - t)),
            child: Transform.scale(scale: .92 + .08 * t, child: child),
          ),
        );
      },
      child: widget.child,
    );
  }
}
