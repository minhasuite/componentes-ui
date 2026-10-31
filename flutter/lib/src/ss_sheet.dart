import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Abre uma folha de baixo no padrão da suíte: alça, raio 26, área segura,
/// sobe junto com o teclado e rola quando o conteúdo passa da tela.
/// [title] monta o [SsSheetHeader]; [child] é o corpo (sem Scaffold).
Future<T?> showSsSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  String? subtitle,
  IconData? icon,
  bool dismissible = true,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  isDismissible: dismissible,
  enableDrag: dismissible,
  showDragHandle: false,
  builder: (context) => SsSheet(title: title, subtitle: subtitle, icon: icon, padding: padding, child: child),
);

/// Casca da folha (o que o [showSsSheet] monta). Pública para quem precisa
/// do `showModalBottomSheet` direto (folha com altura própria, catálogo).
class SsSheet extends StatelessWidget {
  const SsSheet({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.icon,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: kb),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 6),
                width: 38,
                height: 5,
                decoration: BoxDecoration(color: c.muted2, borderRadius: BorderRadius.circular(AppRadius.pill)),
              ),
            ),
            if (title != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: SsSheetHeader(title!, subtitle: subtitle, icon: icon),
              ),
            Flexible(
              child: SingleChildScrollView(padding: padding.add(const EdgeInsets.only(top: 8)), child: child),
            ),
          ],
        ),
      ),
    );
  }
}

/// Cabeçalho de folha ou formulário: ícone num quadrado tonal, título e uma
/// linha de ajuda.
class SsSheetHeader extends StatelessWidget {
  const SsSheetHeader(this.title, {super.key, this.subtitle, this.icon, this.tone});

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Cor do ícone; sem ela, a da marca.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = tone ?? c.accent;
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: c.isDark ? .2 : .14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, size: 21, color: cor),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(color: c.ink, fontSize: AppType.lg, fontWeight: FontWeight.w800, height: 1.2),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(color: c.muted, fontSize: AppType.sub, height: 1.35),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
