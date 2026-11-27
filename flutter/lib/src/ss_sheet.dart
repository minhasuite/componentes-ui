import 'package:material_ui/material_ui.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion_view.dart';
import 'ss_strings.dart';
import 'v1110/platform.dart';
import 'v1140/detent_sheet.dart';
import 'v19/transicoes/predictive_back.dart';

/// Abre uma folha de baixo no padrão da suíte: alça, raio 26, área segura,
/// sobe junto com o teclado e rola quando o conteúdo passa da tela. Sobe com
/// mola (passa um pouco e assenta) e desce reta ([SsOverlayMotion.sheet]).
/// [title] monta o [SsSheetHeader]; [child] é o corpo (sem Scaffold).
///
/// v1.11.0: no iOS, a folha ganha o × de fechar no canto (lá não há voltar do sistema; o arrastar para
/// baixo continua). Com [dismissible] falso, não há ×: quem fecha é o próprio conteúdo.
///
/// v1.14.0: [detents] (`[.33, .5, 1]`, frações da tela) dá à folha alturas fixas, começando em
/// `detents[initialDetent]`: arrastar a alça leva entre elas e, ao soltar, ela assenta com mola
/// ([SsDetentSheet]). Par do `Ss::DrawerComponent(detents:)` do web no celular.
Future<T?> showSsSheet<T>(
  BuildContext context, {
  required Widget child,
  String? title,
  String? subtitle,
  IconData? icon,
  bool dismissible = true,
  EdgeInsetsGeometry padding = const EdgeInsets.fromLTRB(20, 0, 20, 16),
  List<double>? detents,
  int initialDetent = 0,
}) => detents != null
    ? showSsDetentSheet<T>(
        context,
        detents: detents,
        initial: initialDetent,
        title: title,
        subtitle: subtitle,
        icon: icon,
        dismissible: dismissible,
        padding: padding,
        child: child,
      )
    : showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: dismissible,
        enableDrag: dismissible,
        showDragHandle: false,
        sheetAnimationStyle: SsOverlayMotion.sheet(context),
        builder: (context) => SsSheet(
          title: title,
          subtitle: subtitle,
          icon: icon,
          padding: padding,
          showClose: dismissible ? null : false,
          child: child,
        ),
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
    this.showClose,
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  /// v1.11.0: o × de fechar no canto de cima. Nulo: só no iOS (lá não há voltar do sistema).
  final bool? showClose;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final kb = MediaQuery.viewInsetsOf(context).bottom;
    final fechar = showClose ?? SsPlatform.cupertino(context);
    // v1.9: o gesto de voltar do Android 14+ desce e encolhe a folha antes de fechar.
    return SsPredictiveBackScope(
      child: Padding(
        padding: EdgeInsets.only(bottom: kb),
        child: SafeArea(
          top: false,
          child: Stack(
            children: [
              Column(
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
                      padding: EdgeInsets.fromLTRB(20, 8, fechar ? 48 : 20, 4),
                      child: SsSheetHeader(title!, subtitle: subtitle, icon: icon),
                    ),
                  Flexible(
                    child: SingleChildScrollView(padding: padding.add(const EdgeInsets.only(top: 8)), child: child),
                  ),
                ],
              ),
              if (fechar)
                Positioned(
                  top: 4,
                  right: 4,
                  child: IconButton(
                    key: const ValueKey('ss-sheet-close'),
                    tooltip: SsStrings.of(context).close,
                    color: c.muted,
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.maybePop(context),
                  ),
                ),
            ],
          ),
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
    final d = SsDensity.of(context);
    final cor = tone ?? c.accent;
    final lado = d.iconTile - 2;
    return Semantics(
      header: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Container(
              width: lado,
              height: lado,
              decoration: BoxDecoration(
                color: cor.withValues(alpha: c.isDark ? .2 : .14),
                borderRadius: BorderRadius.circular(d.radiusField - 2),
              ),
              child: Icon(icon, size: d.iconSize + 1, color: cor),
            ),
            SizedBox(width: d.gap),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.ink,
                    fontSize: d.font(AppType.lg),
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub), height: 1.35),
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
