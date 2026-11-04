// v0.9 (lote b): social e IA — pessoas, avatares vivos, perfil e chamada.
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../motion_view.dart';
import '../ss_aurora.dart';
import '../ss_list.dart';
import '../ss_strings.dart';

// ---------------------------------------------------------------------------
// SsPeoplePicker
// ---------------------------------------------------------------------------

/// Fileira horizontal de pessoas em pílulas altas (avatar, nome e um "+" que
/// vira ✓) para escolher várias: com quem dividir, quem convidar. As
/// escolhidas ganham anel e fundo na cor da marca, e o avatar estoura com
/// mola ao ser escolhido. [onAdd] põe um "Novo" no começo.
class SsPeoplePicker extends StatelessWidget {
  const SsPeoplePicker({
    super.key,
    required this.people,
    required this.selected,
    required this.onChanged,
    this.onAdd,
    this.addLabel,
  });

  final List<String> people;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback? onAdd;

  /// Padrão: [SsStrings.newItem].
  final String? addLabel;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    final addLabel = this.addLabel ?? SsStrings.of(context).newItem;
    Widget pilula({required bool on, required Widget top, required String nome, required Widget badge}) =>
        AnimatedContainer(
          duration: dur,
          curve: SsMotion.spring,
          width: 76,
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: on ? c.accentSoft : c.surface,
            borderRadius: BorderRadius.circular(38),
            border: Border.all(color: on ? c.accent.withValues(alpha: .5) : c.line),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              top,
              const SizedBox(height: 6),
              Text(
                nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: on ? c.accentText : c.ink, fontSize: AppType.meta, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              badge,
            ],
          ),
        );
    return SizedBox(
      height: 132,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          if (onAdd != null)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                button: true,
                label: addLabel,
                excludeSemantics: true,
                child: SsPressable(
                  onTap: onAdd,
                  child: pilula(
                    on: false,
                    top: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(color: c.field, shape: BoxShape.circle),
                      child: Icon(Icons.person_add_alt_1_rounded, color: c.ink2, size: 22),
                    ),
                    nome: addLabel,
                    badge: const SizedBox(height: 22),
                  ),
                ),
              ),
            ),
          for (final p in people)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Semantics(
                button: true,
                checked: selected.contains(p),
                label: p,
                excludeSemantics: true,
                child: SsPressable(
                  onTap: () {
                    final novo = {...selected};
                    if (!novo.remove(p)) novo.add(p);
                    onChanged(novo);
                  },
                  child: Builder(
                    builder: (context) {
                      final on = selected.contains(p);
                      return pilula(
                        on: on,
                        top: _Pop(
                          on: on,
                          child: SsAvatar(p, size: 44, ring: on ? c.accent : null),
                        ),
                        nome: p.split(' ').first,
                        badge: AnimatedContainer(
                          duration: dur,
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(color: on ? c.accent : c.field, shape: BoxShape.circle),
                          child: AnimatedSwitcher(
                            duration: reduceMotion(context) ? Duration.zero : SsMotion.indicator,
                            switchInCurve: SsMotion.bounce,
                            switchOutCurve: Curves.easeIn,
                            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
                            child: Icon(
                              on ? Icons.check_rounded : Icons.add_rounded,
                              key: ValueKey(on),
                              size: 15,
                              color: on ? AppColors.onDark : c.ink2,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Estoura com mola (encolhe e volta passando um pouco) quando [on] liga.
class _Pop extends StatefulWidget {
  const _Pop({required this.on, required this.child});
  final bool on;
  final Widget child;

  @override
  State<_Pop> createState() => _PopState();
}

class _PopState extends State<_Pop> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: SsMotion.indicator, value: 1);

  @override
  void didUpdateWidget(_Pop old) {
    super.didUpdateWidget(old);
    if (widget.on && !old.on && !reduceMotion(context)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.scale(scale: .78 + .22 * SsMotion.bounce.transform(_c.value), child: child),
    child: widget.child,
  );
}

// ---------------------------------------------------------------------------
// SsPulseAvatar
// ---------------------------------------------------------------------------

/// Avatar com ondas concêntricas pulsando enquanto [active]: "IA ouvindo",
/// "chamando", "sincronizando". Inativo (ou com menos movimento), as ondas
/// param e fica só um anel parado. [child] troca o avatar (ex.: ícone da IA).
class SsPulseAvatar extends StatefulWidget {
  const SsPulseAvatar({super.key, this.name, this.child, this.active = true, this.size = 72, this.color, this.status})
    : assert(name != null || child != null);

  final String? name;
  final Widget? child;
  final bool active;

  /// Diâmetro do avatar; o widget ocupa o dobro (espaço das ondas).
  final double size;
  final Color? color;

  /// Lido pelo leitor de tela ("ouvindo").
  final String? status;

  @override
  State<SsPulseAvatar> createState() => _SsPulseAvatarState();
}

class _SsPulseAvatarState extends State<SsPulseAvatar> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  void _sync() {
    final anda = widget.active && !reduceMotion(context);
    if (anda && !_c.isAnimating) {
      _c.repeat();
    } else if (!anda && _c.isAnimating) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SsPulseAvatar old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final cor = widget.color ?? c.accent;
    final parado = !widget.active || reduceMotion(context);
    return Semantics(
      label: [?widget.name, ?widget.status].join(', '),
      liveRegion: true,
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: widget.size * 2,
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, child) => CustomPaint(
            painter: _OndasPainter(
              t: _c.value,
              color: cor,
              inner: widget.size / 2,
              parado: parado,
              ativo: widget.active,
            ),
            child: child,
          ),
          child: Center(child: widget.child ?? SsAvatar(widget.name!, size: widget.size)),
        ),
      ),
    );
  }
}

class _OndasPainter extends CustomPainter {
  _OndasPainter({required this.t, required this.color, required this.inner, required this.parado, required this.ativo});

  final double t, inner;
  final Color color;
  final bool parado, ativo;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    if (parado) {
      if (!ativo) return;
      // Com menos movimento: dois anéis parados dizem "ativo" sem mexer.
      for (var k = 1; k <= 2; k++) {
        canvas.drawCircle(c, inner + (outer - inner) * k / 3, Paint()..color = color.withValues(alpha: .14 / k));
      }
      return;
    }
    for (var k = 0; k < 3; k++) {
      final f = (t + k / 3) % 1;
      final r = inner + (outer - inner) * Curves.easeOut.transform(f);
      canvas.drawCircle(c, r, Paint()..color = color.withValues(alpha: .22 * (1 - f)));
    }
  }

  @override
  bool shouldRepaint(_OndasPainter old) => old.t != t || old.parado != parado || old.color != color;
}

// ---------------------------------------------------------------------------
// SsStoryRing
// ---------------------------------------------------------------------------

/// Avatar com anel de status em gomos (um por novidade): os novos no
/// gradiente da marca, os vistos numa linha neutra fina; quando entra na tela,
/// os gomos se desenham em sequência. [onAdd] põe um "+" no canto (adicionar o
/// seu). [caption] vai embaixo (o nome).
class SsStoryRing extends StatelessWidget {
  const SsStoryRing(
    this.name, {
    super.key,
    this.segments = 1,
    this.seen = 0,
    this.size = 64,
    this.caption,
    this.onTap,
    this.onAdd,
  });

  final String name;

  /// Total de novidades (gomos).
  final int segments;

  /// Quantas já foram vistas (as primeiras).
  final int seen;
  final double size;
  final String? caption;
  final VoidCallback? onTap;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final novos = math.max(0, segments - seen);
    final anel = SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Os gomos se desenham um após o outro quando o anel entra na tela.
          SsTweenInView(
            end: 1,
            duration: Duration(milliseconds: 500 + 60 * math.min(segments, 8)),
            builder: (_, t, _) => CustomPaint(
              size: Size.square(size),
              painter: _StoryPainter(
                segments: math.max(1, segments),
                seen: seen.clamp(0, segments),
                cores: auroraColors(c),
                neutro: c.muted2,
                vazio: segments == 0,
                t: t,
              ),
            ),
          ),
          Center(child: SsAvatar(name, size: size - 10)),
          if (onAdd != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Semantics(
                button: true,
                label: SsStrings.of(context).add,
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    SsHaptics.tick();
                    onAdd!();
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      width: size * .34,
                      height: size * .34,
                      decoration: BoxDecoration(
                        color: c.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.page, width: 2),
                      ),
                      child: Icon(Icons.add_rounded, size: size * .22, color: AppColors.onDark),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      button: onTap != null,
      label: '$name${novos > 0 ? SsStrings.of(context).newsCount(novos) : ''}',
      child: SsPressable(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            anel,
            if (caption != null) ...[
              const SizedBox(height: 6),
              SizedBox(
                width: size + 4,
                child: ExcludeSemantics(
                  child: Text(
                    caption!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: novos > 0 ? c.ink : c.muted,
                      fontSize: AppType.meta,
                      fontWeight: novos > 0 ? FontWeight.w700 : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StoryPainter extends CustomPainter {
  _StoryPainter({
    required this.segments,
    required this.seen,
    required this.cores,
    required this.neutro,
    required this.vazio,
    this.t = 1,
  });

  final int segments, seen;
  final List<Color> cores;
  final Color neutro;
  final bool vazio;

  /// Quanto do anel já se desenhou (0 a 1), gomo a gomo.
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.shortestSide / 2 - 1.5;
    final rect = Rect.fromCircle(center: c, radius: r);
    if (vazio) return;
    final gap = segments > 1 ? .12 : 0.0;
    final sweep = 2 * math.pi / segments;
    final grad = SweepGradient(
      colors: [cores[0], cores[1], cores[2], cores[0]],
      transform: const GradientRotation(-math.pi / 2),
    ).createShader(rect);
    for (var i = 0; i < segments; i++) {
      final k = (t * segments - i).clamp(0.0, 1.0);
      if (k <= 0) break;
      final visto = i < seen;
      final p = Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = visto ? 1.5 : 2.6;
      if (visto) {
        p.color = neutro;
      } else {
        p.shader = grad;
      }
      canvas.drawArc(rect, -math.pi / 2 + i * sweep + gap / 2, (sweep - gap) * k, false, p);
    }
  }

  @override
  bool shouldRepaint(_StoryPainter old) =>
      old.segments != segments || old.seen != seen || old.neutro != neutro || old.t != t;
}

// ---------------------------------------------------------------------------
// SsProfileHero
// ---------------------------------------------------------------------------

/// Cabeçalho de perfil: foto grande arredondada (sem foto, o [SsAvatar]),
/// nome, status com ponto e até três métricas em destaque, sobre um fundo
/// tonal da marca com a borda de baixo curva. [actions] vai no topo.
class SsProfileHero extends StatelessWidget {
  const SsProfileHero({
    super.key,
    required this.name,
    this.photo,
    this.status,
    this.online = false,
    this.metrics = const [],
    this.actions = const [],
    this.leading,
  });

  final String name;
  final ImageProvider? photo;
  final String? status;

  /// Ponto verde ao lado do status.
  final bool online;

  /// (valor pronto, rótulo): `('128', 'pedidos')`.
  final List<(String, String)> metrics;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    const foto = 104.0;
    return ClipPath(
      clipper: _CurvaClipper(),
      child: Container(
        color: c.accentSoft,
        padding: EdgeInsets.fromLTRB(8, MediaQuery.paddingOf(context).top + 4, 8, 40),
        child: Column(
          children: [
            SizedBox(height: 48, child: Row(children: [?leading, const Spacer(), ...actions])),
            Container(
              width: foto,
              height: foto,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: c.surface, width: 4),
                boxShadow: c.activeShadow,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: photo == null ? _Iniciais(name) : Image(image: photo!, fit: BoxFit.cover, semanticLabel: name),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              name,
              textAlign: TextAlign.center,
              style: TextStyle(color: c.ink, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -.3),
            ),
            if (status != null) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (online) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Flexible(
                    child: Text(
                      status!,
                      style: TextStyle(color: c.ink2, fontSize: AppType.sub, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
            if (metrics.isNotEmpty) ...[
              const SizedBox(height: 18),
              IntrinsicHeight(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < metrics.length && i < 3; i++) ...[
                      if (i > 0) VerticalDivider(width: 32, thickness: 1, color: c.accent.withValues(alpha: .25)),
                      Semantics(
                        label: '${metrics[i].$1} ${metrics[i].$2}',
                        excludeSemantics: true,
                        child: Column(
                          children: [
                            Text(metrics[i].$1, style: AppTheme.number(context, size: 24, color: c.ink)),
                            const SizedBox(height: 4),
                            Text(
                              metrics[i].$2,
                              style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Iniciais no gradiente estável do nome (o do [SsAvatar]), em quadrado.
class _Iniciais extends StatelessWidget {
  const _Iniciais(this.name);
  final String name;

  @override
  Widget build(BuildContext context) {
    final base = HSLColor.fromColor(SsColors.of(context).brandTo);
    final hue = (base.hue + (SsAvatar.seed(name) % 5 - 2) * 24) % 360;
    return Semantics(
      label: name,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              HSLColor.fromAHSL(1, hue, .62, .56).toColor(),
              HSLColor.fromAHSL(1, (hue + 20) % 360, .58, .4).toColor(),
            ],
          ),
        ),
        child: ExcludeSemantics(
          child: Text(
            SsAvatar.initials(name),
            style: const TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1),
          ),
        ),
      ),
    );
  }
}

class _CurvaClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) => Path()
    ..lineTo(0, size.height - 28)
    ..quadraticBezierTo(size.width / 2, size.height + 20, size.width, size.height - 28)
    ..lineTo(size.width, 0)
    ..close();

  @override
  bool shouldReclip(_CurvaClipper old) => false;
}

// ---------------------------------------------------------------------------
// SsCelebrate
// ---------------------------------------------------------------------------

/// Comemora uma conquista: quando [achieved] passa de falso para verdadeiro,
/// solta o confete da suíte (`showSsConfetti`), vibra o "deu certo" e dá um
/// pulo de escala no [child]. Com menos movimento, só vibra.
class SsCelebrate extends StatefulWidget {
  const SsCelebrate({super.key, required this.achieved, required this.child});

  final bool achieved;
  final Widget child;

  @override
  State<SsCelebrate> createState() => _SsCelebrateState();
}

class _SsCelebrateState extends State<SsCelebrate> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));

  @override
  void didUpdateWidget(SsCelebrate old) {
    super.didUpdateWidget(old);
    if (widget.achieved && !old.achieved) {
      SsHaptics.success();
      if (!reduceMotion(context)) _c.forward(from: 0);
      // O confete entra no overlay: fora do build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) showSsConfetti(context);
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) {
      // Sobe até 1,08 e volta com mola.
      final s = 1 + .08 * math.sin(_c.value * math.pi) * (1 - _c.value * .3);
      return Transform.scale(scale: s, child: child);
    },
    child: widget.child,
  );
}

// ---------------------------------------------------------------------------
// SsCallControls
// ---------------------------------------------------------------------------

/// Um botão do [SsCallControls].
class SsCallAction {
  const SsCallAction(this.icon, this.label, {this.onTap, this.active = false, this.activeIcon, this.danger = false});

  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  /// Ligado (câmera aberta, alto-falante): fundo da marca.
  final bool active;
  final IconData? activeIcon;

  /// Ação de encerrar: vermelho e maior.
  final bool danger;
}

/// Fileira de botões redondos grandes de chamada ou ação ao vivo (vídeo,
/// microfone, encerrar). O de [SsCallAction.danger] é vermelho e maior;
/// ligado fica na cor da marca. Com [labels], o nome vai embaixo.
class SsCallControls extends StatelessWidget {
  const SsCallControls({super.key, required this.actions, this.size = 60, this.labels = false});

  final List<SsCallAction> actions;
  final double size;
  final bool labels;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        for (final a in actions)
          Semantics(
            button: true,
            toggled: a.danger ? null : a.active,
            enabled: a.onTap != null,
            label: a.label,
            excludeSemantics: true,
            child: SsPressable(
              onTap: a.onTap,
              scale: .92,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedContainer(
                    duration: dur,
                    curve: SsMotion.spring,
                    width: a.danger ? size * 1.2 : size,
                    height: a.danger ? size * 1.2 : size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.danger
                          ? AppColors.danger
                          : a.active
                          ? c.accent
                          : c.surface,
                      border: !a.danger && !a.active ? Border.all(color: c.line) : null,
                      boxShadow: a.danger
                          ? [
                              BoxShadow(
                                color: AppColors.danger.withValues(alpha: .4),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                                spreadRadius: -8,
                              ),
                            ]
                          : a.active
                          ? c.primaryShadow
                          : AppShadows.card,
                    ),
                    child: Icon(
                      a.active ? (a.activeIcon ?? a.icon) : a.icon,
                      size: size * (a.danger ? .46 : .4),
                      color: a.danger || a.active ? AppColors.onDark : (a.onTap == null ? c.muted2 : c.ink),
                    ),
                  ),
                  if (labels) ...[
                    const SizedBox(height: 8),
                    Text(
                      a.label,
                      style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
