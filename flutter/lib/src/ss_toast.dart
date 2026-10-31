import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_theme.dart';
import 'motion.dart';

/// Pílula escura (igual nos dois temas) com ícone, texto curto e uma ação
/// ("Desfazer") na cor da marca. Use [showSsToast]; o widget é público para o
/// catálogo e para testes. Com ação e [countdown], uma borda fina se esvazia
/// durante o tempo do aviso (a "contagem do desfazer"; parada com menos
/// movimento).
class SsToast extends StatelessWidget {
  const SsToast(this.message, {super.key, this.icon, this.tone, this.actionLabel, this.onAction, this.countdown});

  final String message;
  final IconData? icon;

  /// Cor do ícone (sucesso, erro); sem ela, a da marca.
  final Color? tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tempo do aviso, para a borda de contagem (só com [actionLabel]).
  final Duration? countdown;

  static const background = Color(0xFF1A1826);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    Widget pilula = Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.fromLTRB(16, 6, 8, 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: const BorderRadius.all(Radius.circular(AppRadius.pill)),
        border: Border.all(color: Colors.white.withValues(alpha: .08)),
        boxShadow: const [BoxShadow(color: Color(0x40000000), offset: Offset(0, 10), blurRadius: 30, spreadRadius: -8)],
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
    );
    if (actionLabel != null && countdown != null) {
      final borda = c.brand.accentDark.withValues(alpha: .85);
      pilula = reduceMotion(context)
          ? CustomPaint(foregroundPainter: _Contagem(1, borda), child: pilula)
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 1, end: 0),
              duration: countdown!,
              builder: (_, t, child) => CustomPaint(foregroundPainter: _Contagem(t, borda), child: child),
              child: pilula,
            );
    }
    return Semantics(liveRegion: true, child: pilula);
  }
}

/// Borda da pílula desenhada só na fração [t] (1 = cheia), a partir do topo.
class _Contagem extends CustomPainter {
  const _Contagem(this.t, this.cor);
  final double t;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0) return;
    final r = Radius.circular(size.height / 2);
    final rect = (Offset.zero & size).deflate(1);
    // Começa no meio do topo e anda no sentido horário.
    final path = Path()
      ..moveTo(rect.center.dx, rect.top)
      ..lineTo(rect.right - r.x, rect.top)
      ..arcToPoint(Offset(rect.right - r.x, rect.bottom), radius: r)
      ..lineTo(rect.left + r.x, rect.bottom)
      ..arcToPoint(Offset(rect.left + r.x, rect.top), radius: r)
      ..close();
    final m = path.computeMetrics().first;
    canvas.drawPath(
      m.extractPath(0, m.length * t),
      Paint()
        ..color = cor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Contagem old) => old.t != t || old.cor != cor;
}

void Function([bool acted])? _fecharAtual;

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
}) => _mostrar(
  context,
  message,
  icon: icon,
  tone: tone,
  actionLabel: actionLabel,
  onAction: onAction,
  duration: duration,
  bottom: bottom,
);

/// Aviso com "Desfazer" e a contagem na borda. Devolve `true` se a pessoa
/// desfez: quem chama só executa a exclusão de verdade quando volta `false`
/// (também volta `false` se outro aviso tomar o lugar).
///
/// `if (!await showSsUndo(context, 'Pedido excluído')) await api.excluir(p);`
Future<bool> showSsUndo(
  BuildContext context,
  String message, {
  String label = 'Desfazer',
  IconData? icon = Icons.delete_outline,
  Duration duration = const Duration(seconds: 5),
  double bottom = 104,
}) {
  final r = Completer<bool>();
  _mostrar(
    context,
    message,
    icon: icon,
    actionLabel: label,
    onAction: () {},
    duration: duration,
    bottom: bottom,
    onClosed: r.complete,
  );
  return r.future;
}

void _mostrar(
  BuildContext context,
  String message, {
  IconData? icon,
  Color? tone,
  String? actionLabel,
  VoidCallback? onAction,
  required Duration duration,
  required double bottom,
  void Function(bool acted)? onClosed,
}) {
  _fecharAtual?.call();
  final overlay = Overlay.of(context, rootOverlay: true);
  late final OverlayEntry entry;
  var fechado = false;
  void fechar([bool acted = false]) {
    if (fechado) return;
    fechado = true;
    if (entry.mounted) entry.remove();
    if (_fecharAtual == fechar) _fecharAtual = null;
    onClosed?.call(acted);
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
            countdown: duration,
            onAction: onAction == null
                ? null
                : () {
                    fechar(true);
                    onAction();
                  },
          ),
        ),
      ),
    ),
  );
  _fecharAtual = fechar;
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
