import 'package:flutter/material.dart';

import 'app_theme.dart';

enum SsBadgeVariant {
  accent,
  success,
  warning,
  danger,
  ghost,
  aquec,

  /// Neutro sobre o fundo de campo, texto escuro (o `.ss-badge-muted` do web):
  /// rascunho, "sem área", contagem que não pede atenção.
  muted,
}

/// Badge pill "soft" do design system: fundo dessaturado + texto na cor. Espelha
/// `.mp-badge` (font 11/700, pill). `micro` = variante compacta (10/700, uppercase).
/// Sem largura para o rótulo inteiro, ele termina em "…" (o leitor de tela lê tudo).
class SsBadge extends StatelessWidget {
  const SsBadge(
    this.label, {
    super.key,
    this.variant = SsBadgeVariant.accent,
    this.micro = false,
    this.icon,
    this.dot = false,
    this.solid = false,
    this.mono = false,
  });

  final String label;
  final SsBadgeVariant variant;
  final bool micro;

  /// Ícone antes do texto, na cor do texto.
  final IconData? icon;

  /// Ponto na cor do texto antes do rótulo (situação: online, offline). O
  /// `.ss-badge-dot` do web. Ignorado quando há [icon].
  final bool dot;

  /// v0.19.2: fundo cheio na cor do tom e texto claro (o `.ss-badge.is-solid`
  /// do web): o marcador forte de um trecho ("DIA 3" do roteiro, "HOJE").
  /// Em `muted`/`ghost` sai invertido (fundo de tinta, texto da superfície).
  final bool solid;

  /// v0.19.2: rótulo em DM Mono tabular (número, código, "DIA 3"; o
  /// `.ss-badge.is-mono` do web).
  final bool mono;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    var (fg, bg) = _cores(c);
    if (solid) (fg, bg) = _solidas(c);
    final fontSize = micro ? AppType.micro : AppType.label;
    final base = TextStyle(
      color: fg,
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      letterSpacing: micro ? 0.5 : 0,
      height: 1.1,
    );
    final style = mono
        ? AppTheme.number(context, size: fontSize, weight: FontWeight.w500, color: fg).copyWith(height: 1.1)
        : base;
    return Semantics(
      label: label,
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: micro ? 8 : 12, vertical: micro ? 3 : 5),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: micro ? 11 : 13, color: fg),
              const SizedBox(width: 4),
            ] else if (dot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
            ],
            // v0.15.2: rótulo longo num Wrap/coluna estreita encolhe com "…" em vez de estourar.
            Flexible(
              child: Text(
                micro ? label.toUpperCase() : label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                softWrap: false,
                style: style,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _branco = [AppColors.onDark];

  (Color, Color) _solidas(SsColors c) => switch (variant) {
    SsBadgeVariant.accent => (AppColors.onDark, c.accentSolid),
    // Escurece o tom até o branco passar de 4,5:1 (igual nos dois temas).
    SsBadgeVariant.success => (AppColors.onDark, ssUntilContrast(AppColors.success, AppColors.scrim, _branco, 4.5)),
    SsBadgeVariant.warning ||
    SsBadgeVariant.aquec => (AppColors.onDark, ssUntilContrast(AppColors.aquecFg, AppColors.scrim, _branco, 4.5)),
    SsBadgeVariant.danger => (AppColors.onDark, ssUntilContrast(AppColors.danger, AppColors.scrim, _branco, 4.5)),
    SsBadgeVariant.ghost || SsBadgeVariant.muted => (c.surface, c.ink),
  };

  (Color, Color) _cores(SsColors c) {
    late final Color fg;
    late final Color bg;
    switch (variant) {
      case SsBadgeVariant.accent:
        fg = c.accentText;
        bg = c.accentSoft;
      case SsBadgeVariant.success:
        fg = c.successText;
        bg = AppColors.successSoft;
      case SsBadgeVariant.warning:
        fg = AppColors.warnFg;
        bg = AppColors.warnBg;
      case SsBadgeVariant.danger:
        fg = c.dangerText;
        bg = AppColors.dangerSoft;
      case SsBadgeVariant.ghost:
        fg = c.muted;
        bg = AppColors.ghostSoft;
      case SsBadgeVariant.aquec:
        fg = c.aquecText;
        bg = c.aquecSoft;
      case SsBadgeVariant.muted:
        fg = c.ink2;
        bg = c.field;
    }
    return (fg, bg);
  }
}

/// Selo de destaque pontual ("Novo", "Meta batida"): contorno firme e sombra
/// deslocada sem desfoque. Personalidade em doses: no máximo um por tela.
class SsSeal extends StatelessWidget {
  const SsSeal(this.text, {super.key, this.icon});

  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 4, 10, 4),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.accentText, width: 1.5),
        boxShadow: [BoxShadow(color: c.accent.withValues(alpha: .35), offset: const Offset(3, 3))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: c.accentText), const SizedBox(width: 4)],
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: c.accentText,
              fontSize: AppType.label,
              fontWeight: FontWeight.w800,
              letterSpacing: .8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tom semântico de um estado: pinta [SsStatusBadge] e `SsDealBadge`.
/// `info` é o azul de informação; `accent` é a cor da marca.
enum SsTone {
  neutral,
  info,
  success,
  warning,
  danger,
  accent;

  /// Cores do tom no tema atual: `text` (AA sobre `soft`), `soft` (fundo) e
  /// `solid` (ponto, ícone, preenchimento).
  ({Color text, Color soft, Color solid}) colors(BuildContext context) {
    final c = SsColors.of(context);
    return switch (this) {
      neutral => (text: c.muted, soft: AppColors.ghostSoft, solid: c.muted),
      info => (
        text: c.isDark ? const Color(0xFF8AB4FF) : const Color(0xFF1D5FC4),
        soft: const Color(0x243B82F6),
        solid: const Color(0xFF3B82F6),
      ),
      success => (text: c.successText, soft: AppColors.successSoft, solid: AppColors.success),
      warning => (text: c.aquecText, soft: c.aquecSoft, solid: AppColors.aquecFg),
      danger => (text: c.dangerText, soft: AppColors.dangerSoft, solid: AppColors.danger),
      accent => (text: c.accentText, soft: c.accentSoft, solid: c.accent),
    };
  }
}

/// Situação de um registro (pedido, título, lote) como pílula com ponto +
/// texto: a cor nunca vai sozinha. O app passa o mapa status → tom; status
/// fora do mapa sai neutro. [label] troca o texto (padrão: o próprio status).
///
/// `SsStatusBadge(p.status, map: {'pago': SsTone.success, 'vencido': SsTone.danger}, label: rotulos[p.status])`
class SsStatusBadge extends StatelessWidget {
  const SsStatusBadge(this.status, {super.key, this.map = const {}, this.label});

  final String status;
  final Map<String, SsTone> map;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final t = (map[status] ?? SsTone.neutral).colors(context);
    final text = label ?? status;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 4),
        decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: t.solid, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: t.text, fontSize: AppType.label, fontWeight: FontWeight.w700, height: 1.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
