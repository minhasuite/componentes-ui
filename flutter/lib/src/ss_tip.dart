import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Dica dispensável: entra suave e, no ×, encolhe e some; só então chama
/// [onDismiss]. Quem lembra que foi fechada é o app (grave pelo [id] e não
/// monte de novo). Use com parcimônia: dica que volta sempre é interrupção.
class SsTip extends StatefulWidget {
  const SsTip({
    super.key,
    this.id,
    this.icon = Icons.lightbulb_outline_rounded,
    this.title,
    required this.text,
    required this.onDismiss,
    this.actionLabel,
    this.onAction,
  });

  /// Chave do "já vi" do app (o componente não grava nada).
  final String? id;
  final IconData icon;
  final String? title;
  final String text;
  final VoidCallback onDismiss;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  State<SsTip> createState() => _SsTipState();
}

class _SsTipState extends State<SsTip> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.base);
  bool _fechando = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_fechando || _c.status != AnimationStatus.dismissed) return;
    if (reduceMotion(context)) {
      _c.value = 1;
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _fechar() async {
    if (_fechando) return;
    _fechando = true;
    SsHaptics.tick();
    if (!reduceMotion(context)) await _c.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final anim = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);
    return SizeTransition(
      sizeFactor: anim,
      alignment: Alignment.topCenter,
      child: FadeTransition(
        opacity: anim,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 4, 10),
          decoration: BoxDecoration(color: c.accentSoft, borderRadius: BorderRadius.circular(AppRadius.card)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(widget.icon, color: c.accentText, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.title != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            widget.title!,
                            style: TextStyle(color: c.ink, fontSize: AppType.set, fontWeight: FontWeight.w800),
                          ),
                        ),
                      Text(
                        widget.text,
                        style: TextStyle(color: c.ink2, fontSize: AppType.sub, height: 1.4),
                      ),
                      if (widget.actionLabel != null && widget.onAction != null)
                        TextButton(
                          onPressed: widget.onAction,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(0, 36),
                            foregroundColor: c.accentText,
                          ),
                          child: Text(widget.actionLabel!),
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: SsStrings.of(context).dismissTip,
                onPressed: _fechar,
                icon: Icon(Icons.close_rounded, size: 18, color: c.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
