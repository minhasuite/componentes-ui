import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Item de lista: ícone num quadrado no tom da categoria (14%), título e
/// subtítulo, e o valor à direita em DM Mono. Sem [tone], usa a cor da marca.
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

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = tone ?? c.accent;
    final lead = leading ?? (icon == null ? null : SsIconTile(icon!, tone: cor));
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            if (lead != null) ...[lead, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w700),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: c.muted, fontSize: AppType.sub),
                    ),
                  ],
                ],
              ),
            ),
            if (value != null) ...[
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    value!,
                    style: AppTheme.number(context, size: AppType.body, color: valueColor ?? c.ink),
                  ),
                  if (valueCaption != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      valueCaption!,
                      style: TextStyle(color: c.muted, fontSize: AppType.meta),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 18, 4, 6),
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
/// para empilhar; [status] = ponto no canto (visitado, pendente...).
class SsAvatar extends StatelessWidget {
  const SsAvatar(this.name, {super.key, this.size = 42, this.status});

  final String name;
  final double size;
  final Color? status;

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
    return Semantics(
      label: name,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [de, ate]),
                border: Border.all(color: c.page, width: 2),
              ),
              child: ExcludeSemantics(
                child: Text(
                  initials(name),
                  style: TextStyle(color: Colors.white, fontSize: size * .36, fontWeight: FontWeight.w800, height: 1),
                ),
              ),
            ),
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
          ],
        ),
      ),
    );
  }
}

/// Avatares sobrepostos (−8) com "+N" no fim quando passa de [max].
class SsAvatarStack extends StatelessWidget {
  const SsAvatarStack(this.names, {super.key, this.max = 3, this.size = 34});

  final List<String> names;
  final int max;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final shown = names.take(max).toList();
    final extra = names.length - shown.length;
    final step = size - 8;
    final count = shown.length + (extra > 0 ? 1 : 0);
    return SizedBox(
      height: size,
      width: count == 0 ? 0 : step * (count - 1) + size,
      child: Stack(
        children: [
          for (var i = 0; i < shown.length; i++)
            Positioned(
              left: step * i,
              child: SsAvatar(shown[i], size: size),
            ),
          if (extra > 0)
            Positioned(
              left: step * shown.length,
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
        ],
      ),
    );
  }
}

/// Ícone num quadrado (ou círculo) no tom da cor a 14% (20% no escuro): o
/// "ícone tonal" dos itens, cabeçalhos e estados. Sem [tone], a cor da marca.
class SsIconTile extends StatelessWidget {
  const SsIconTile(this.icon, {super.key, this.size = 42, this.tone, this.circle = false, this.filled = false});

  final IconData icon;
  final double size;
  final Color? tone;
  final bool circle;

  /// Fundo cheio na cor e ícone claro (ex.: concluído em verde).
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = tone ?? c.accent;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? cor : cor.withValues(alpha: c.isDark ? .2 : .14),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(size * .31),
      ),
      child: Icon(icon, size: size * .5, color: filled ? AppColors.onDark : cor),
    );
  }
}
