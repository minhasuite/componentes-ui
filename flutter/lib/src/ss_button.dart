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
///
/// v0.19.2: [stacked] põe o ícone em cima do rótulo (botão de atalho numa
/// fileira, o rótulo encolhe em vez de cortar) e [SsButton.onGradient] é o
/// botão sobre o gradiente da marca ([SsHeroCard], [SsAuroraCard]):
/// translúcido com fio claro (o `.ss-btn.is-on-grad` do web) ou, com
/// `solid: true`, branco com o texto na cor funda da marca (`is-solid`).
///
/// v0.20: `tone:` no ghost ([SsButton.ghost]) pinta o texto no tom
/// ([SsTone.danger] no "Excluir" discreto); nas outras variantes não muda nada.
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
    this.stacked = false,
    SsTone? tone,
  }) : _text = false,
       _danger = false,
       // ignore: prefer_initializing_formals
       _tone = tone,
       _onDark = false,
       _onGradient = false,
       _solid = false;

  /// v0.20: botão discreto (fundo de campo, sem sombra) com o texto no tom:
  /// `SsButton.ghost(label: 'Excluir', icon: Icons.delete_outline, tone: SsTone.danger, onPressed: ...)`.
  /// Igual a `SsButton(variant: SsButtonVariant.ghost, tone: ...)`. Par do
  /// `Ss::ButtonComponent(variant: :ghost, tone: :danger)`.
  const SsButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.small = false,
    this.loading = false,
    this.expand = true,
    this.trailingIcon,
    this.stacked = false,
    SsTone? tone,
  }) : variant = SsButtonVariant.ghost,
       _text = false,
       _danger = false,
       // ignore: prefer_initializing_formals
       _tone = tone,
       _onDark = false,
       _onGradient = false,
       _solid = false;

  /// v0.19.2: botão sobre o gradiente da marca. Os três atalhos do herói:
  /// `SsButton.onGradient(label: 'Voo', icon: Icons.flight, solid: true, stacked: true, onPressed: ...)`.
  const SsButton.onGradient({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.small = false,
    this.loading = false,
    this.expand = true,
    this.trailingIcon,
    this.stacked = false,
    bool solid = false,
  }) : variant = SsButtonVariant.primary,
       _text = false,
       _danger = false,
       _tone = null,
       _onDark = false,
       _onGradient = true,
       // ignore: prefer_initializing_formals
       _solid = solid;

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
       stacked = false,
       _onGradient = false,
       _solid = false,
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
  final bool _onGradient;
  final bool _solid;

  /// v0.19.2: ícone em cima do rótulo (altura pelo conteúdo, mínimo o do
  /// botão da densidade); o rótulo encolhe numa linha para caber.
  final bool stacked;

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
        // v0.20: tone: pinta o texto do ghost (ex. Excluir em vermelho).
        fg = _tone?.colors(context).text ?? c.ink2;
      case SsButtonVariant.success:
        bg = AppColors.success;
        fg = AppColors.onDark;
      case SsButtonVariant.danger:
        bg = AppColors.danger;
        fg = AppColors.onDark;
    }

    Border? border;
    if (_onGradient) {
      bg = _solid ? AppColors.onDark : AppColors.onDark.withValues(alpha: .16);
      fg = _solid ? c.brandDeep : AppColors.onDark;
      border = _solid ? null : Border.all(color: AppColors.onDark.withValues(alpha: .24));
      shadow = null;
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
    } else if (stacked) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: small ? d.iconSize - 2 : d.iconSize + 2, color: fg),
            SizedBox(height: d.gap / 2),
          ],
          // Uma linha que encolhe (nunca "…"): três atalhos lado a lado no celular estreito.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(color: fg, fontSize: fontSize, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      );
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
      child: _box(context, enabled, height, radius, shadow, bg, content, d, border),
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
    Border? border,
  ) {
    return SsPressable(
      enabled: enabled,
      child: Opacity(
        opacity: enabled ? 1 : 0.5,
        child: Container(
          height: stacked ? null : height,
          constraints: stacked ? BoxConstraints(minHeight: height) : null,
          width: expand ? double.infinity : null,
          decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow, border: border),
          // Brilho de 1 px no topo dos botões sólidos (volume sem gradiente).
          foregroundDecoration: variant == SsButtonVariant.ghost || _text || _onGradient
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
                padding: stacked
                    ? EdgeInsets.symmetric(horizontal: 4, vertical: d.gap - 2)
                    : EdgeInsets.symmetric(horizontal: small ? d.padX - 4 : d.padX + 2),
                child: Center(child: content),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
