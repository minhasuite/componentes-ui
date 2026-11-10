import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'density.dart';
import 'motion.dart';
import 'ss_strings.dart';

/// Item de lista: ícone num quadrado no tom da categoria (14%), título e
/// subtítulo, e o valor à direita em DM Mono. Sem [tone], usa a cor da marca.
/// Com [onTap], afunda de leve no toque e volta com mola ([SsPressable]).
class SsListItem extends StatelessWidget {
  const SsListItem({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.subtitle,
    this.value,
    this.valueColor,
    this.valueCaption,
    this.tone,
    this.onTap,
    this.onLongPress,
    this.trailing,
    this.dimmed = false,
    this.maxLines = 1,
  });

  final String title;
  final IconData? icon;

  /// No lugar do ícone (ex.: [SsAvatar]).
  final Widget? leading;
  final String? subtitle;
  final String? value;
  final Color? valueColor;

  /// Linha pequena embaixo do valor (data, situação).
  final String? valueCaption;
  final Color? tone;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Depois do valor (chevron, [SsOverflowMenu], checkbox).
  final Widget? trailing;

  /// Item apagado (concluído, arquivado, fora de estoque): opacidade 0,5.
  final bool dimmed;

  /// Linhas do título e do subtítulo antes da reticência.
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final cor = tone ?? c.accent;
    final lead = leading ?? (icon == null ? null : SsIconTile(icon!, tone: cor));
    final item = InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(d.radiusField),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: d.rowPadV),
        child: Row(
          children: [
            if (lead != null) ...[lead, SizedBox(width: d.gap)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: maxLines,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.ink, fontSize: d.font(AppType.body), fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: d.font(AppType.sub)),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              SizedBox(width: d.gap - 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value!,
                    style: AppTheme.number(context, size: d.font(AppType.body), color: valueColor ?? c.ink),
                  ),
                  if (valueCaption != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      valueCaption!,
                      style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
                    ),
                  ],
                ],
              ),
            ],
            if (trailing != null) ...[SizedBox(width: d.gap - 4), trailing!],
          ],
        ),
      ),
    );
    // Tocável: afunda de leve no toque e volta com mola ao soltar.
    final tocavel = SsPressable(enabled: onTap != null || onLongPress != null, scale: .98, child: item);
    return dimmed ? Opacity(opacity: .5, child: tocavel) : tocavel;
  }
}

/// Cabeçalho de grupo de lista: "HOJE" à esquerda e o total em DM Mono à direita.
class SsGroupHeader extends StatelessWidget {
  const SsGroupHeader(this.title, {super.key, this.trailing});

  final String title;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(4, d.space(18), 4, d.space(6)),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              style: TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w800, letterSpacing: 1),
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              style: AppTheme.number(context, size: AppType.meta, color: c.muted),
            ),
        ],
      ),
    );
  }
}

/// Avatar com iniciais sobre um gradiente que sai do nome (o mesmo nome dá
/// sempre a mesma cor, na família de cores da marca). Anel da cor da página,
/// para empilhar; [status] = ponto no canto (visitado, pendente...);
/// [unread] = contagem de não lidas no canto de cima; [ring] = anel colorido
/// em volta (selecionado, conversa nova).
class SsAvatar extends StatelessWidget {
  const SsAvatar(this.name, {super.key, this.size = 42, this.status, this.unread, this.ring});

  final String name;
  final double size;
  final Color? status;

  /// Não lidas (0 ou nulo: nada; acima de 99 mostra "99+").
  final int? unread;

  /// Cor do anel em volta (o avatar encolhe um pouco por dentro).
  final Color? ring;

  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first.characters.first;
    return parts.length == 1 ? first.toUpperCase() : (first + parts.last.characters.first).toUpperCase();
  }

  /// Hash estável do nome (o `hashCode` de String muda entre execuções na web).
  static int seed(String name) => name.trim().toLowerCase().codeUnits.fold(7, (h, u) => (h * 31 + u) & 0x7fffffff);

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final base = HSLColor.fromColor(c.brandTo);
    // Cinco vizinhos de matiz da marca (−48° a +48°), luz e saturação fixas.
    final hue = (base.hue + (seed(name) % 5 - 2) * 24) % 360;
    final de = HSLColor.fromAHSL(1, hue, .62, .56).toColor();
    final ate = HSLColor.fromAHSL(1, (hue + 20) % 360, .58, .4).toColor();
    final n = unread ?? 0;
    final inner = ring == null ? size : size - 6;
    Widget face = Container(
      width: inner,
      height: inner,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [de, ate]),
        border: Border.all(color: c.page, width: 2),
      ),
      child: ExcludeSemantics(
        child: Text(
          initials(name),
          style: TextStyle(color: Colors.white, fontSize: inner * .36, fontWeight: FontWeight.w800, height: 1),
        ),
      ),
    );
    if (ring != null) {
      face = Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ring!, width: 2.2),
        ),
        child: face,
      );
    }
    return Semantics(
      label: n > 0 ? SsStrings.of(context).unreadCount(name, n) : name,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            face,
            if (status != null)
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: size * .3,
                  height: size * .3,
                  decoration: BoxDecoration(
                    color: status,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.page, width: 2),
                  ),
                ),
              ),
            if (n > 0)
              Positioned(
                right: -4,
                top: -3,
                child: ExcludeSemantics(
                  child: Container(
                    constraints: BoxConstraints(minWidth: math.max(18, size * .4)),
                    height: math.max(18, size * .4),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accent,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                      border: Border.all(color: c.page, width: 2),
                    ),
                    child: Text(
                      n > 99 ? '99+' : '$n',
                      textScaler: TextScaler.noScaling,
                      style: AppTheme.number(
                        context,
                        size: math.max(10, size * .22),
                        weight: FontWeight.w600,
                        color: AppColors.onDark,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Avatares sobrepostos (−8) com "+N" no fim quando passa de [max]. Com
/// [onAdd], um botão "+" fecha a fileira (convidar, dividir com mais alguém).
class SsAvatarStack extends StatelessWidget {
  const SsAvatarStack(this.names, {super.key, this.max = 3, this.size = 34, this.onAdd, this.addLabel});

  final List<String> names;
  final int max;
  final double size;

  /// Toque no "+" do fim. Nulo: sem botão.
  final VoidCallback? onAdd;

  /// Rótulo do "+" para o leitor de tela. Padrão: [SsStrings.addPerson].
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = size - 8;
    final count = shown.length + (extra > 0 ? 1 : 0) + (onAdd != null ? 1 : 0);
    // Com o "+", a linha ganha altura de alvo de toque (48) e o avatar fica no meio.
    final height = onAdd == null ? size : math.max(size, 48.0);
    final top = (height - size) / 2;
    final width = count == 0 ? 0.0 : step * (count - 1) + size;
    return SizedBox(
      height: height,
      width: onAdd == null ? width : width + (48 - size).clamp(0.0, 48.0) / 2,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              top: top,
              child: SsAvatar(shown[i], size: size),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
              top: top,
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: c.field,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.page, width: 2),
                ),
                child: Text(
                  '+$extra',
                  style: AppTheme.number(context, size: size * .32, color: c.ink2),
                ),
              ),
            ),
          if (onAdd != null)
            Positioned(
              left: step * (count - 1) - (48 - size).clamp(0.0, 48.0) / 2,
              top: 0,
              width: math.max(size, 48),
              height: height,
              child: Semantics(
                button: true,
                label: addLabel ?? SsStrings.of(context).addPerson,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    SsHaptics.tick();
                    onAdd!();
                  },
                  child: Center(
                    child: Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.page, width: 2),
                      ),
                      child: Icon(Icons.add_rounded, size: size * .5, color: c.accentText),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Ícone num quadrado (ou círculo) no tom da cor a 14% (20% no escuro): o
/// "ícone tonal" dos itens, cabeçalhos e estados. Sem [tone], a cor da marca.
class SsIconTile extends StatelessWidget {
  const SsIconTile(
    this.icon, {
    super.key,
    this.size,
    this.tone,
    this.circle = false,
    this.filled = false,
    this.gradient = false,
    this.onGradient = false,
    this.image,
  });

  final IconData icon;

  /// Foto no lugar do [icon] (v0.14; o `<img>` dentro do `.ss-icon-tile` do
  /// web): cobre o quadrado; o [icon] aparece enquanto carrega ou se falhar.
  final ImageProvider? image;

  /// Lado do quadrado. Nulo: o `iconTile` da [SsDensity] (42 no padrão).
  final double? size;
  final Color? tone;
  final bool circle;

  /// Fundo cheio na cor e ícone claro (ex.: concluído em verde).
  final bool filled;

  /// Fundo no gradiente da marca e ícone claro: o "ligado" (o
  /// `.ss-icon-tile.is-grad` do web). Ganha de [filled] e de [tone].
  final bool gradient;

  /// Para pôr sobre o gradiente da marca (herói, [SsAuroraCard]): branco
  /// translúcido com fio claro e ícone branco (v0.10.3; o
  /// `.ss-icon-tile.is-on-grad` do web). Ganha dos outros.
  final bool onGradient;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final size = this.size ?? SsDensity.of(context).iconTile;
    final cor = tone ?? c.accent;
    if (onGradient) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.onDark.withValues(alpha: .18),
          border: Border.all(color: AppColors.onDark.withValues(alpha: .22)),
          shape: circle ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circle ? null : BorderRadius.circular(size * .31),
        ),
        child: Icon(icon, size: size * .5, color: AppColors.onDark),
      );
    }
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: gradient ? null : (filled ? cor : cor.withValues(alpha: c.isDark ? .2 : .14)),
        gradient: gradient
            ? LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [c.brandFrom, c.brandTo])
            : null,
        boxShadow: gradient ? c.primaryShadow : null,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * .31),
      ),
      clipBehavior: image == null ? Clip.none : Clip.antiAlias,
      child: image == null
          ? Icon(icon, size: size * .5, color: filled || gradient ? AppColors.onDark : cor)
          : Image(
              image: image!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Icon(icon, size: size * .5, color: cor),
            ),
    );
  }
}
