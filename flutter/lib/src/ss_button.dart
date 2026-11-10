import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';
import 'ss_badge.dart' show SsTone;

enum SsButtonVariant { primary, ghost, success, danger }

/// Botão do design system. `primary` tem o **glow roxo** direcional que o
/// `elevation` do Material não reproduz. Altura e raio vêm da [SsDensity]
/// (padrão 48 e 14; 36 e 11 quando `small`); o toque nunca fica menor que 48.
/// No toque afunda rápido e, ao soltar, volta com mola ([SsPressable]); o
/// carregando e o conteúdo trocam com um cruzamento curto.
///
/// [SsButton.text] é o botão de texto (link): sem fundo, na cor da marca
/// ("Esqueci a senha", "Ver tudo", "Desfazer"); [danger] o deixa vermelho.
///
/// v0.16: [trailingIcon] vai depois do rótulo ("Ver todas →"); no
/// [SsButton.text], `tone:` pinta o texto no tom ([SsTone.warning],
/// [SsTone.danger]...) e `onDark:` o deixa claro sobre foto, câmera ou gradiente.
class SsButton extends StatelessWidget {
  const SsButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SsButtonVariant.primary,
    this.icon,
    this.small = false,
    this.loading = false,
    this.expand = true,
    this.trailingIcon,
  }) : _text = false,
       _danger = false,
       _tone = null,
       _onDark = false;

  /// Botão de texto: sem fundo nem sombra, rótulo na cor da marca (ou do
  /// perigo, com [danger]); altura 40 (32 com [small], na densidade padrão); não ocupa a
  /// largura toda por padrão.
  const SsButton.text({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.small = false,
    this.loading = false,
    this.expand = false,
    bool danger = false,
    this.trailingIcon,
    SsTone? tone,
    bool onDark = false,
  }) : variant = SsButtonVariant.ghost,
       _text = true,
       // ignore: prefer_initializing_formals
       _danger = danger,
       // ignore: prefer_initializing_formals
       _tone = tone,
       // ignore: prefer_initializing_formals
       _onDark = onDark;

  final bool _text;
  final bool _danger;
  final SsTone? _tone;
  final bool _onDark;

  /// v0.16: ícone depois do rótulo (seta de "ver mais", abrir fora).
  final IconData? trailingIcon;

  final String label;
  final VoidCallback? onPressed;
  final SsButtonVariant variant;
  final IconData? icon;
  final bool small;
  final bool loading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final enabled = onPressed != null && !loading;

    late Color bg;
    late Color fg;
    List<BoxShadow>? shadow;
    switch (variant) {
      case SsButtonVariant.primary:
        bg = c.accent;
        fg = AppColors.onDark;
        shadow = enabled ? c.primaryShadow : null;
      case SsButtonVariant.ghost:
        bg = c.field;
        fg = c.ink2;
      case SsButtonVariant.success:
        bg = AppColors.success;
        fg = AppColors.onDark;
      case SsButtonVariant.danger:
        bg = AppColors.danger;
        fg = AppColors.onDark;
    }

    if (_text) {
      bg = Colors.transparent;
      fg = _onDark
          ? AppColors.onDark
          : _danger
          ? c.dangerText
          : (_tone?.colors(context).text ?? c.accentText);
      shadow = null;
    }

    final height = _text
        ? (small ? d.controlHeightSmall - 4 : d.controlHeightSmall + 4)
        : (small ? d.controlHeightSmall : d.controlHeight);
    final radius = BorderRadius.circular(small ? d.radiusField - 3 : d.radiusField);
    final fontSize = d.font(small ? AppType.meta : AppType.body);

    Widget content;
    if (loading) {
      content = SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: fg));
    } else {
      content = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? d.iconSize - 4 : d.iconSize, color: fg),
            SizedBox(width: d.gap - 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w800),
            ),
          ),
          if (trailingIcon != null) ...[
            SizedBox(width: d.gap - 6),
            Icon(trailingIcon, size: small ? d.iconSize - 4 : d.iconSize - 2, color: fg),
          ],
        ],
      );
    }

    // Conteúdo ↔ carregando: cruza com um pulinho (mola), sem pular o tamanho.
    content = AnimatedSwitcher(
      duration: reduceMotion(context) ? Duration.zero : SsMotion.base,
      switchInCurve: SsMotion.bounce,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, a) => FadeTransition(
        opacity: a,
        child: ScaleTransition(scale: a.drive(Tween(begin: .7, end: 1.0)), child: child),
      ),
      child: KeyedSubtree(key: ValueKey(loading), child: content),
    );

    return SsTapTarget(
      minSize: Size(0, d.minTarget),
      child: _box(context, enabled, height, radius, shadow, bg, content, d),
    );
  }

  Widget _box(
    BuildContext context,
    bool enabled,
    double height,
    BorderRadius radius,
    List<BoxShadow>? shadow,
    Color bg,
    Widget content,
    SsDensity d,
  ) {
    return SsPressable(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
          // Brilho de 1 px no topo dos botões sólidos (volume sem gradiente).
          foregroundDecoration: variant == SsButtonVariant.ghost || _text
              ? null
              : BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.white.withValues(alpha: .22), Colors.white.withValues(alpha: 0)],
                    stops: const [0, .08],
                  ),
                ),
          child: Material(
            color: bg,
            borderRadius: radius,
            child: InkWell(
              onTap: enabled ? onPressed : null,
              borderRadius: radius,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: small ? d.padX - 4 : d.padX + 2),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
