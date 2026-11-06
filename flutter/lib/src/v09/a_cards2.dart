import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_stat.dart' show SsAmount;
import '../ss_strings.dart';

// ---------------------------------------------------------------------------
// Cartão de saldo
// ---------------------------------------------------------------------------

/// Cartão de saldo no gradiente de 4 paradas da marca, com sombra na própria
/// cor. [tilt] (−1 a 1 em x e y, vindo do giroscópio que o app liga) inclina
/// o cartão em 3D e move o brilho junto. Sem [tilt], fica reto. Texto claro
/// com véu escuro por baixo (AA em qualquer paleta).
class SsWalletCard extends StatelessWidget {
  const SsWalletCard({
    super.key,
    required this.amount,
    this.label,
    this.holder,
    this.number,
    this.network,
    this.expiry,
    this.tilt = Offset.zero,
    this.onTap,
  });

  /// Valor já formatado ("R$ 10.000,00"); os centavos saem menores.
  final String amount;

  /// Padrão: [SsStrings.totalBalance].
  final String? label;
  final String? holder;

  /// Final do cartão ("•••• 4086").
  final String? number;

  /// Bandeira em texto (o app passa o nome; sem logo de marca).
  final String? network;
  final String? expiry;
  final Offset tilt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final label = this.label ?? SsStrings.of(context).totalBalance;
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 160);
    final radius = BorderRadius.circular(AppRadius.cardActive);
    const muted = AppColors.onDarkSoft;
    final card = AspectRatio(
      aspectRatio: 1.586,
      child: Container(
        decoration: BoxDecoration(borderRadius: radius, boxShadow: c.tintedShadow(c.brandTo, strength: 1.2)),
        child: ClipRRect(
          borderRadius: radius,
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: Offset(tilt.dx.clamp(-1.0, 1.0), tilt.dy.clamp(-1.0, 1.0))),
            duration: dur,
            builder: (_, t, child) => Stack(
              fit: StackFit.expand,
              children: [
                DecoratedBox(decoration: BoxDecoration(gradient: c.gradient4)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                      colors: [AppColors.scrim.withValues(alpha: .5), AppColors.scrim.withValues(alpha: .15)],
                    ),
                  ),
                ),
                // Brilho que segue a inclinação.
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment(-t.dx * .9, -t.dy * .9 - .3),
                      radius: .9,
                      colors: [AppColors.onDark.withValues(alpha: .2), AppColors.onDark.withValues(alpha: 0)],
                    ),
                  ),
                ),
                child!,
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.onDark),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 26,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.onDark.withValues(alpha: .4)),
                            color: AppColors.onDark.withValues(alpha: .12),
                          ),
                        ),
                        const Spacer(),
                        if (expiry != null)
                          Text(
                            expiry!,
                            style: AppTheme.number(context, size: AppType.sub, color: muted),
                          ),
                      ],
                    ),
                    const Spacer(),
                    _FitAmount(amount),
                    const SizedBox(height: 2),
                    Text(
                      label,
                      style: const TextStyle(color: muted, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        if (holder != null)
                          Expanded(
                            child: Text(
                              holder!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w700),
                            ),
                          )
                        else
                          const Spacer(),
                        if (number != null)
                          Text(
                            number!,
                            style: AppTheme.number(context, size: AppType.sub, color: muted),
                          ),
                        if (network != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            network!.toUpperCase(),
                            style: const TextStyle(
                              fontSize: AppType.md,
                              fontWeight: FontWeight.w900,
                              fontStyle: FontStyle.italic,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    return Semantics(
      label: '$label: $amount',
      button: onTap != null,
      child: SsPressable(
        onTap: onTap,
        child: _TouchTilt(
          child: TweenAnimationBuilder<Offset>(
            tween: Tween(end: tilt),
            duration: dur,
            builder: (_, t, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0015)
                ..rotateX(-t.dy.clamp(-1.0, 1.0) * .16)
                ..rotateY(t.dx.clamp(-1.0, 1.0) * .16),
              child: child,
            ),
            child: card,
          ),
        ),
      ),
    );
  }
}

/// Inclina o cartão para o lado do dedo enquanto ele está em cima (até ~5°)
/// e volta com mola ao soltar. Com menos movimento, não inclina.
class _TouchTilt extends StatefulWidget {
  const _TouchTilt({required this.child});
  final Widget child;

  @override
  State<_TouchTilt> createState() => _TouchTiltState();
}

class _TouchTiltState extends State<_TouchTilt> {
  Offset _t = Offset.zero;
  bool _down = false;

  void _em(Offset local) {
    final s = context.size;
    if (s == null || s.isEmpty) return;
    setState(() {
      _down = true;
      _t = Offset((local.dx / s.width * 2 - 1).clamp(-1.0, 1.0), (local.dy / s.height * 2 - 1).clamp(-1.0, 1.0));
    });
  }

  void _solta() => setState(() {
    _down = false;
    _t = Offset.zero;
  });

  @override
  Widget build(BuildContext context) {
    if (reduceMotion(context)) return widget.child;
    return Listener(
      onPointerDown: (e) => _em(e.localPosition),
      onPointerMove: (e) => _em(e.localPosition),
      onPointerUp: (_) => _solta(),
      onPointerCancel: (_) => _solta(),
      child: TweenAnimationBuilder<Offset>(
        tween: Tween(end: _t),
        // Segue o dedo rápido; ao soltar, volta com a mola da suíte.
        duration: _down ? SsMotion.fast : SsMotion.indicator,
        curve: _down ? Curves.easeOut : SsMotion.bounce,
        builder: (_, t, child) => Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0015)
            ..rotateX(-t.dy * .09)
            ..rotateY(t.dx * .09),
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}

// Valor grande em DM Mono que encolhe para caber (usado nos cards).
class _FitAmount extends StatelessWidget {
  const _FitAmount(this.text, {this.size = 30, this.color = AppColors.onDark});
  final String text;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    // Valor que muda rola na vertical (para cima quando aumentou).
    child: SsAmount(text, size: size, color: color, roll: true),
  );
}

// ---------------------------------------------------------------------------
// Pilha de cartões
// ---------------------------------------------------------------------------

/// Cartões empilhados (só a borda de cima dos de trás aparece); um toque abre
/// em lista com mola, outro fecha. A mola é física (passa ~9% e assenta) e,
/// tocando no meio do movimento, parte da posição e velocidade em que está. Cada filho ganha a altura [cardHeight].
class SsCardStack extends StatefulWidget {
  const SsCardStack({
    super.key,
    required this.children,
    this.cardHeight = 180,
    this.peek = 14,
    this.gap = 12,
    this.initiallyOpen = false,
    this.onChanged,
  });

  final List<Widget> children;
  final double cardHeight;
  final double peek;
  final double gap;
  final bool initiallyOpen;
  final ValueChanged<bool>? onChanged;

  /// Altura total para a fração de abertura [t] (0 fechado, 1 aberto).
  static double heightFor(int n, double h, double peek, double gap, double t) =>
      lerpDouble((n - 1) * peek + h, n * h + (n - 1) * gap, t)!;

  @override
  State<SsCardStack> createState() => _SsCardStackState();
}

class _SsCardStackState extends State<SsCardStack> with SingleTickerProviderStateMixin {
  // Sem limites: a mola passa de 1 (e de 0) e volta.
  late final _c = AnimationController.unbounded(vsync: this, value: widget.initiallyOpen ? 1 : 0);
  late bool _open = widget.initiallyOpen;

  /// Mola de verdade (física): passa ~9% e assenta em ~0,5 s.
  static final _mola = SpringDescription.withDampingRatio(mass: 1, stiffness: 180, ratio: .62);

  void _vai(bool open) {
    final mudou = open != _open;
    setState(() => _open = open);
    if (mudou) {
      SsHaptics.tick();
      widget.onChanged?.call(_open);
    }
    final alvo = open ? 1.0 : 0.0;
    if (reduceMotion(context)) {
      _c.value = alvo;
      return;
    }
    // Inverter no meio herda a velocidade atual (não para e recomeça).
    _c.animateWith(SpringSimulation(_mola, _c.value, alvo, _c.velocity)).then((_) => _c.value = alvo);
  }

  void _toggle() => _vai(!_open);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final n = widget.children.length;
    final h = widget.cardHeight;
    return Semantics(
      button: true,
      label: _open ? SsStrings.of(context).closeCards : SsStrings.of(context).openCards(n),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) {
            final t = _c.value;
            return SizedBox(
              height: SsCardStack.heightFor(n, h, widget.peek, widget.gap, t.clamp(-.1, 1.15)),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  for (var i = n - 1; i >= 0; i--)
                    Positioned(
                      left: 0,
                      right: 0,
                      top: lerpDouble((n - 1 - i) * widget.peek, i * (h + widget.gap), t),
                      height: h,
                      child: Transform.scale(
                        scale: lerpDouble(1 - .05 * i, 1, t.clamp(0.0, 1.0)),
                        alignment: Alignment.topCenter,
                        child: Opacity(
                          opacity: lerpDouble(i > 2 ? 0 : 1 - .12 * i, 1, t.clamp(0.0, 1.0))!.clamp(0.0, 1.0),
                          child: widget.children[i],
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Produto que vaza do card
// ---------------------------------------------------------------------------

/// Card de produto em que a imagem "vaza" para cima da borda; embaixo, nome,
/// detalhe, preço em DM Mono e botão redondo de ação (adicionar).
class SsPopOutCard extends StatelessWidget {
  const SsPopOutCard({
    super.key,
    required this.image,
    required this.title,
    this.subtitle,
    this.price,
    this.onAdd,
    this.onTap,
    this.imageHeight = 120,
    this.popOut = 44,
    this.tone,
    this.actionIcon = Icons.add_rounded,
    this.actionLabel,
  });

  /// Imagem recortada (fundo transparente fica melhor); o app passa o widget.
  final Widget image;
  final String title;
  final String? subtitle;
  final String? price;
  final VoidCallback? onAdd;
  final VoidCallback? onTap;
  final double imageHeight;

  /// Quanto a imagem passa da borda de cima.
  final double popOut;

  /// Cor do fundo do card (tonal); sem ela, a superfície.
  final Color? tone;
  final IconData actionIcon;

  /// Padrão: [SsStrings.add].
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final bg = tone == null ? c.surface : Color.lerp(c.surface, tone, c.isDark ? .22 : .14)!;
    final d = SsDensity.of(context);
    return SsPressable(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            margin: EdgeInsets.only(top: popOut),
            padding: EdgeInsets.fromLTRB(d.cardPad, imageHeight - popOut + 10, d.cardPad - 4, d.cardPad - 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(AppRadius.cardActive),
              boxShadow: AppShadows.card,
              border: c.isDark ? Border.all(color: c.line) : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: c.ink, fontSize: AppType.md, fontWeight: FontWeight.w800),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.muted, fontSize: AppType.meta),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    if (price != null)
                      Expanded(
                        child: _FitAmount(price!, size: AppType.lg, color: c.ink),
                      )
                    else
                      const Spacer(),
                    if (onAdd != null)
                      Semantics(
                        button: true,
                        label: actionLabel ?? SsStrings.of(context).add,
                        excludeSemantics: true,
                        child: SsPressable(
                          onTap: onAdd,
                          scale: .9,
                          child: SizedBox.square(
                            dimension: d.minTarget,
                            child: Center(
                              child: Container(
                                width: d.iconButton,
                                height: d.iconButton,
                                decoration: BoxDecoration(
                                  color: c.accent,
                                  borderRadius: BorderRadius.circular(d.radiusField),
                                  boxShadow: c.tintedShadow(c.accent, strength: .8),
                                ),
                                child: Icon(actionIcon, color: AppColors.onDark),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: imageHeight,
            child: Center(child: image),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Duas estatísticas
// ---------------------------------------------------------------------------

/// Um lado do [SsDuoStat].
class SsDuoItem {
  const SsDuoItem(this.label, this.value, {this.icon});
  final String label;
  final String value;
  final IconData? icon;
}

/// Duas estatísticas lado a lado (despesa × receita): a ativa ganha fundo no
/// gradiente da marca e texto claro; tocar na outra troca (a pílula de fundo
/// passa de um lado para o outro com mola).
class SsDuoStat extends StatelessWidget {
  const SsDuoStat({super.key, required this.items, required this.index, required this.onChanged})
    : assert(items.length == 2);

  final List<SsDuoItem> items;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : const Duration(milliseconds: 380);
    final grad = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [c.brandTo, Color.lerp(c.brandTo, c.brandDeep, .55)!],
    );
    final d = SsDensity.of(context);
    return Row(
      children: [
        for (var i = 0; i < 2; i++) ...[
          if (i == 1) SizedBox(width: d.gap),
          Expanded(
            child: Semantics(
              button: true,
              selected: i == index,
              label: '${items[i].label}: ${items[i].value}',
              excludeSemantics: true,
              child: SsPressable(
                onTap: () {
                  if (i == index) return;
                  SsHaptics.tick();
                  onChanged(i);
                },
                child: AnimatedContainer(
                  duration: dur,
                  curve: Curves.easeOutCubic,
                  constraints: BoxConstraints(minHeight: d.controlHeight + 24),
                  padding: EdgeInsets.symmetric(horizontal: d.cardPad - 2, vertical: d.cardPad - 4),
                  decoration: BoxDecoration(
                    color: i == index ? null : c.surface,
                    gradient: i == index ? grad : null,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    boxShadow: i == index ? c.tintedShadow(c.brandTo) : AppShadows.card,
                    border: i != index && c.isDark ? Border.all(color: c.line) : null,
                  ),
                  child: Row(
                    children: [
                      if (items[i].icon != null) ...[
                        AnimatedRotation(
                          turns: i == index ? 0 : -.125,
                          duration: dur,
                          curve: SsMotion.spring,
                          child: Icon(items[i].icon, size: 22, color: i == index ? AppColors.onDark : c.muted),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              items[i].label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: i == index ? AppColors.onDarkSoft : c.muted,
                                fontSize: AppType.meta,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            _FitAmount(items[i].value, size: AppType.lg, color: i == index ? AppColors.onDark : c.ink),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Meta, QR, recorrente, destaque
// ---------------------------------------------------------------------------

/// Card de meta/convite: ilustração (ou ícone grande) em cima, texto curto
/// centrado e uma ação em texto sublinhado na cor da marca ("Criar meta").
/// Quando entra na tela, a arte brota com mola e o sublinhado se desenha.
class SsGoalCard extends StatelessWidget {
  const SsGoalCard({super.key, required this.text, required this.actionLabel, this.onAction, this.art, this.icon});

  final String text;
  final String actionLabel;
  final VoidCallback? onAction;

  /// Ilustração (widget do app). Sem ela, usa [icon] num brilho da marca.
  final Widget? art;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.cardActive),
        boxShadow: AppShadows.card,
        border: c.isDark ? Border.all(color: c.line) : null,
      ),
      child: Column(
        children: [
          // A arte brota com mola quando o card entra na tela.
          SsInView(
            duration: SsMotion.indicator,
            curve: SsMotion.bounce,
            builder: (_, t, child) => Transform.scale(
              scale: .6 + .4 * t.value,
              child: Opacity(opacity: (t.value * 1.6).clamp(0.0, 1.0), child: child),
            ),
            child:
                art ??
                Icon(
                  icon ?? Icons.flag_rounded,
                  size: 64,
                  color: c.accent,
                  shadows: [Shadow(color: c.accent.withValues(alpha: .45), blurRadius: 24, offset: const Offset(0, 8))],
                ),
          ),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: TextStyle(color: c.ink2, fontSize: AppType.body, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 6),
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    actionLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: c.accentText, fontSize: AppType.md, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  // O sublinhado se desenha do meio para as pontas, depois da arte.
                  SsTweenInView(
                    end: 1,
                    delay: const Duration(milliseconds: 220),
                    duration: SsMotion.slow,
                    // Escala só no desenho (a largura intrínseca não muda).
                    builder: (_, t, _) => Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.diagonal3Values(t.clamp(0.0, 1.0), 1, 1),
                      child: Container(height: 2, color: c.accent),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card do QR: área branca (sempre branca, para a câmera ler) com o QR que o
/// app passa como widget (`Image.memory(bytes)` ou o widget do gerador dele),
/// instrução embaixo e um rodapé opcional. Sem plugin no pacote.
class SsQrCard extends StatelessWidget {
  const SsQrCard({super.key, required this.qr, this.title, this.instruction, this.footer, this.tone});

  final Widget qr;
  final String? title;
  final String? instruction;
  final Widget? footer;

  /// Fundo do card (sem ela, a cor da marca). O texto é claro.
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final bg = tone ?? Color.lerp(c.brandTo, c.brandDeep, .35)!;
    final d = SsDensity.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: d.cardPad + 4, vertical: d.cardPad + 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.cardActive),
        boxShadow: c.tintedShadow(bg),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(color: AppColors.onDark),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Text(
                title!.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: AppType.sub, fontWeight: FontWeight.w800, letterSpacing: 1.6),
              ),
              const SizedBox(height: 14),
            ],
            Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 240),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: AppColors.onDark, borderRadius: BorderRadius.circular(18)),
                child: AspectRatio(aspectRatio: 1, child: qr),
              ),
            ),
            if (instruction != null) ...[
              const SizedBox(height: 12),
              Text(
                instruction!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.onDarkSoft, fontSize: AppType.sub),
              ),
            ],
            if (footer != null) ...[const SizedBox(height: 16), footer!],
          ],
        ),
      ),
    );
  }
}

/// Lançamento recorrente: "Todo domingo · 11:00", valor em DM Mono, destino
/// e um check redondo (cheio quando já foi feito neste ciclo; estoura com
/// mola ao marcar). O valor rola ao mudar.
class SsRecurringCard extends StatelessWidget {
  const SsRecurringCard({
    super.key,
    required this.schedule,
    required this.amount,
    this.time,
    this.destination,
    this.done = false,
    this.onTap,
    this.onMenu,
  });

  /// "Todo domingo".
  final String schedule;
  final String amount;
  final String? time;

  /// "para Instituto Sol".
  final String? destination;
  final bool done;
  final VoidCallback? onTap;
  final VoidCallback? onMenu;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    final d = SsDensity.of(context);
    return SsPressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(d.cardPad, d.cardPad, 6, d.cardPad - 6),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: AppShadows.card,
          border: c.isDark ? Border.all(color: c.line) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  label: done ? SsStrings.of(context).taskDone : SsStrings.of(context).taskPending,
                  excludeSemantics: true,
                  child: AnimatedContainer(
                    duration: dur,
                    width: d.chipHeight,
                    height: d.chipHeight,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? AppColors.success : c.field,
                      border: Border.all(color: done ? AppColors.success : c.muted2, width: 1.5),
                    ),
                    // O check estoura com a mola da suíte ao marcar.
                    child: AnimatedScale(
                      scale: done ? 1 : .6,
                      duration: reduceMotion(context) ? Duration.zero : SsMotion.indicator,
                      curve: SsMotion.bounce,
                      child: Icon(Icons.check_rounded, size: 18, color: done ? AppColors.onDark : c.muted),
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        schedule,
                        style: TextStyle(color: c.ink2, fontSize: AppType.sub, fontWeight: FontWeight.w700),
                      ),
                      if (time != null)
                        Text(
                          time!,
                          style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FitAmount(amount, size: 24, color: c.ink),
                      if (destination != null)
                        Text(
                          destination!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                        ),
                    ],
                  ),
                ),
                if (onMenu != null)
                  IconButton(
                    tooltip: SsStrings.of(context).moreOptions,
                    onPressed: onMenu,
                    icon: Icon(Icons.more_horiz_rounded, color: c.muted),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Card de destaque (recurso, categoria): fundo tonal na cor, ícone num
/// círculo elevado (superfície com sombra na cor), título e texto.
class SsFeatureTile extends StatelessWidget {
  const SsFeatureTile({super.key, required this.icon, required this.title, this.text, this.tone, this.onTap});

  final IconData icon;
  final String title;
  final String? text;
  final Color? tone;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final k = tone ?? c.accent;
    final bg = Color.lerp(c.surface, k, c.isDark ? .18 : .1)!;
    final fg = tone == null ? c.accentText : Color.lerp(k, c.ink, c.isDark ? .1 : .35)!;
    final d = SsDensity.of(context);
    return SsPressable(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(d.cardPad),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.cardActive)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: d.iconTile + 6,
              height: d.iconTile + 6,
              decoration: BoxDecoration(
                color: c.surface,
                shape: BoxShape.circle,
                boxShadow: c.tintedShadow(k, strength: .7),
              ),
              child: Icon(icon, color: fg, size: d.iconSize + 4),
            ),
            SizedBox(height: d.space(14)),
            Text(
              title,
              style: TextStyle(color: c.ink, fontSize: d.font(AppType.md), fontWeight: FontWeight.w800),
            ),
            if (text != null) ...[
              const SizedBox(height: 4),
              Text(
                text!,
                style: TextStyle(color: c.ink2, fontSize: AppType.sub, height: 1.35),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
