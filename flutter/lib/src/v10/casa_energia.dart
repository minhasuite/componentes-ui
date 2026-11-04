// v0.10 (casa): fluxo de energia e controle remoto (D-pad).
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Tipo de um nó do [SsFlowDiagram]: dá o ícone e a cor padrão.
enum SsFlowKind { grid, solar, battery, home, custom }

/// Onde o nó fica em volta do central.
enum SsFlowSlot { top, left, right, bottom }

/// Um nó do fluxo de energia: rede, solar, bateria, casa ou outro.
class SsFlowNode {
  const SsFlowNode(
    this.id, {
    required this.kind,
    required this.label,
    this.value,
    this.caption,
    this.icon,
    this.color,
    this.slot,
  });

  final String id;
  final SsFlowKind kind;
  final String label;

  /// Valor já formatado ("1,2 kW").
  final String? value;

  /// Linha menor ("82%" da bateria).
  final String? caption;
  final IconData? icon;

  /// Cor do nó (só para `custom`; os outros usam a cor semântica do tipo).
  final Color? color;

  /// Posição em volta do centro; padrão pela ordem: cima, esquerda, direita, baixo.
  final SsFlowSlot? slot;
}

/// Ligação entre dois nós. [power] > 0 corre de [from] para [to]; < 0 ao
/// contrário; 0 parado. A velocidade dos pontos é proporcional ao |power|.
class SsFlowLink {
  const SsFlowLink(this.from, this.to, this.power);
  final String from;
  final String to;
  final double power;
}

/// Diagrama de fluxo de energia: um nó central (casa) e até 4 em volta (rede,
/// solar, bateria...). As ligações são pontos que correm no sentido da energia,
/// mais rápido quanto maior o valor. É o único laço de animação contínuo da
/// suíte; para com [animate] falso e com "reduzir movimento" (aí a ligação
/// mostra uma seta parada no sentido).
///
/// Responsivo: abaixo de ~400 px os discos encolhem (até 75%), os nós dos
/// lados encostam na borda e o nome embaixo de cada nó ganha só a largura que
/// cabe sem encostar no vizinho (corta com reticências).
class SsFlowDiagram extends StatefulWidget {
  const SsFlowDiagram({
    super.key,
    required this.center,
    required this.around,
    required this.links,
    this.maxPower = 5000,
    this.animate = true,
    this.height = 300,
    this.semanticsLabel,
  });

  final SsFlowNode center;

  /// Até 4 nós em volta (os a mais são ignorados).
  final List<SsFlowNode> around;
  final List<SsFlowLink> links;

  /// Potência que dá a velocidade máxima (mesma unidade de [SsFlowLink.power]).
  final double maxPower;
  final bool animate;
  final double height;

  /// Descrição para leitor de tela; padrão: "Rede 1,2 kW, Casa 2 kW…".
  final String? semanticsLabel;

  /// Cor semântica do tipo (fixa da suíte; a casa usa a marca).
  static Color colorOf(BuildContext context, SsFlowNode n) {
    final c = SsColors.of(context);
    return n.color ??
        switch (n.kind) {
          SsFlowKind.grid => const Color(0xFF3B82F6),
          SsFlowKind.solar => AppColors.aquecFg,
          SsFlowKind.battery => AppColors.success,
          SsFlowKind.home => c.accent,
          SsFlowKind.custom => c.muted,
        };
  }

  static IconData iconOf(SsFlowNode n) =>
      n.icon ??
      switch (n.kind) {
        SsFlowKind.grid => Icons.electrical_services_rounded,
        SsFlowKind.solar => Icons.solar_power_rounded,
        SsFlowKind.battery => Icons.battery_charging_full_rounded,
        SsFlowKind.home => Icons.home_rounded,
        SsFlowKind.custom => Icons.bolt_rounded,
      };

  @override
  State<SsFlowDiagram> createState() => _SsFlowDiagramState();
}

class _SsFlowDiagramState extends State<SsFlowDiagram> with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker((d) => _t.value = d.inMicroseconds / 1e6);
  final _t = ValueNotifier<double>(0);

  List<SsFlowNode> get _around => widget.around.take(4).toList();

  bool get _anda => widget.animate && !reduceMotion(context) && widget.links.any((l) => l.power != 0);

  void _sync() {
    if (_anda && !_ticker.isActive) _ticker.start();
    if (!_anda && _ticker.isActive) _ticker.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SsFlowDiagram old) {
    super.didUpdateWidget(old);
    _sync();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _t.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    const ordem = [SsFlowSlot.top, SsFlowSlot.left, SsFlowSlot.right, SsFlowSlot.bottom];
    final usados = <SsFlowSlot>{for (final n in _around) ?n.slot};
    final livres = ordem.where((s) => !usados.contains(s)).iterator;
    final slots = <String, SsFlowSlot>{};
    for (final n in _around) {
      slots[n.id] = n.slot ?? (livres.moveNext() ? livres.current : SsFlowSlot.bottom);
    }
    final nos = {widget.center.id: widget.center, for (final n in _around) n.id: n};
    final cores = {for (final n in nos.values) n.id: SsFlowDiagram.colorOf(context, n)};
    final desc = widget.semanticsLabel ?? nos.values.map((n) => [n.label, ?n.value, ?n.caption].join(' ')).join(', ');

    return Semantics(
      label: desc,
      child: SizedBox(
        height: widget.height,
        child: LayoutBuilder(
          builder: (context, box) {
            final w = box.maxWidth, h = box.maxHeight;
            // Estreito (celular, card): discos menores.
            final k = (w / 400).clamp(.75, 1.0);
            final rCentro = 44.0 * k, rNo = 34.0 * k;
            final lado = rNo + (k < 1 ? 6 : 12);
            Offset pos(String id) {
              if (id == widget.center.id) return Offset(w / 2, h / 2);
              return switch (slots[id]) {
                SsFlowSlot.top => Offset(w / 2, rNo + 4),
                SsFlowSlot.bottom => Offset(w / 2, h - rNo - 18),
                SsFlowSlot.left => Offset(math.max(lado, w / 2 - h * .42 - 30), h / 2),
                SsFlowSlot.right => Offset(math.min(w - lado, w / 2 + h * .42 + 30), h / 2),
                null => Offset(w / 2, h / 2),
              };
            }

            // Largura do nome embaixo de cada nó: os dos lados não passam da
            // borda; o do centro não encosta nos dos lados (mesma altura).
            final ladosX = [
              for (final n in _around)
                if (slots[n.id] == SsFlowSlot.left || slots[n.id] == SsFlowSlot.right) pos(n.id).dx,
            ];
            double larguraLado(double x) => math.max(rNo * 2 + 4, math.min(120.0, 2 * math.min(x, w - x)));
            var larguraCentro = 120.0;
            for (final x in ladosX) {
              final gap = (x - w / 2).abs();
              larguraCentro = math.min(larguraCentro, 2 * (gap - larguraLado(x) / 2 - 4));
            }
            larguraCentro = math.max(larguraCentro, rCentro * 2);
            double largura(SsFlowNode n) {
              if (n.id == widget.center.id) return larguraCentro;
              final sl = slots[n.id];
              if (sl == SsFlowSlot.left || sl == SsFlowSlot.right) return larguraLado(pos(n.id).dx);
              return 120;
            }

            final linhas = [
              for (final l in widget.links)
                if (nos.containsKey(l.from) && nos.containsKey(l.to))
                  _Linha(
                    a: pos(l.from),
                    b: pos(l.to),
                    ra: l.from == widget.center.id ? rCentro : rNo,
                    rb: l.to == widget.center.id ? rCentro : rNo,
                    power: l.power,
                    // A cor de quem manda a energia.
                    cor: cores[l.power >= 0 ? l.from : l.to]!,
                  ),
            ];

            Widget no(SsFlowNode n, double r) {
              final p = pos(n.id);
              final cor = cores[n.id]!;
              final lw = largura(n);
              return Positioned(
                left: p.dx - lw / 2,
                top: p.dy - r,
                width: lw,
                child: Column(
                  children: [
                    Container(
                      width: r * 2,
                      height: r * 2,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color.alphaBlend(cor.withValues(alpha: .12), c.surface),
                        border: Border.all(color: cor, width: 2.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(SsFlowDiagram.iconOf(n), color: cor, size: r * .62),
                          if (n.value != null)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  n.value!,
                                  style: AppTheme.number(
                                    context,
                                    size: r > 40 ? AppType.sub : AppType.label,
                                    weight: FontWeight.w600,
                                    color: c.ink,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      [n.label, ?n.caption].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: c.muted,
                        fontSize: k < 1 ? AppType.label - 1 : AppType.label,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              );
            }

            return Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _FlowPainter(
                        linhas: linhas,
                        t: _t,
                        maxPower: widget.maxPower,
                        animate: _anda,
                        trilho: c.line,
                      ),
                    ),
                  ),
                ),
                for (final n in _around) no(n, rNo),
                no(widget.center, rCentro),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Linha {
  const _Linha({
    required this.a,
    required this.b,
    required this.ra,
    required this.rb,
    required this.power,
    required this.cor,
  });
  final Offset a, b;
  final double ra, rb, power;
  final Color cor;
}

class _FlowPainter extends CustomPainter {
  _FlowPainter({
    required this.linhas,
    required this.t,
    required this.maxPower,
    required this.animate,
    required this.trilho,
  }) : super(repaint: t);
  final List<_Linha> linhas;
  final ValueNotifier<double> t;
  final double maxPower;
  final bool animate;
  final Color trilho;

  @override
  void paint(Canvas canvas, Size size) {
    for (final l in linhas) {
      final dir = l.b - l.a;
      final len = dir.distance;
      if (len < l.ra + l.rb + 4) continue;
      final u = dir / len;
      // Saindo para baixo, a linha passaria pelo nome do nó (fica embaixo do disco): começa depois dele.
      final ini = l.a + u * (l.ra + 2 + (u.dy > .5 ? 16 : 0)), fim = l.b - u * (l.rb + 2 + (u.dy < -.5 ? 16 : 0));
      final ativo = l.power != 0;
      canvas.drawLine(
        ini,
        fim,
        Paint()
          ..color = ativo ? l.cor.withValues(alpha: .35) : trilho
          ..strokeWidth = ativo ? 2.5 : 2
          ..strokeCap = StrokeCap.round,
      );
      if (!ativo) continue;
      // De onde para onde a energia corre.
      final (de, para) = l.power > 0 ? (ini, fim) : (fim, ini);
      final seg = para - de;
      final dot = Paint()..color = l.cor;
      if (!animate) {
        // Parado: uma seta no meio, no sentido da energia.
        final m = de + seg / 2;
        final v = seg / seg.distance;
        final n = Offset(-v.dy, v.dx);
        final path = Path()
          ..moveTo((m + v * 6).dx, (m + v * 6).dy)
          ..lineTo((m - v * 5 + n * 6).dx, (m - v * 5 + n * 6).dy)
          ..lineTo((m - v * 5 - n * 6).dx, (m - v * 5 - n * 6).dy)
          ..close();
        canvas.drawPath(path, dot);
        continue;
      }
      // Velocidade em comprimentos de linha por segundo: 0,15 (pouco) a 1,1 (máximo).
      final vel = .15 + .95 * (l.power.abs() / maxPower).clamp(0.0, 1.0);
      const n = 3;
      for (var i = 0; i < n; i++) {
        final f = (t.value * vel + i / n) % 1;
        // Some nas pontas para o ponto não "pular" de volta.
        final alfa = math.min(1.0, math.min(f, 1 - f) * 6);
        canvas.drawCircle(de + seg * f, 4, Paint()..color = l.cor.withValues(alpha: alfa));
      }
    }
  }

  @override
  bool shouldRepaint(_FlowPainter old) =>
      old.linhas != linhas || old.animate != animate || old.trilho != trilho || old.maxPower != maxPower;
}

// ───────────────────────────────────────────────────────── controle remoto

/// Teclas do [SsDPad].
enum SsDPadKey { up, down, left, right, ok, back, home, menu, volumeUp, volumeDown, mute, channelUp, channelDown }

/// Textos do [SsDPad] (leitor de tela e dicas); o que ficar nulo vem do
/// [SsStrings] do idioma.
class SsDPadLabels {
  const SsDPadLabels({
    this.up,
    this.down,
    this.left,
    this.right,
    this.ok,
    this.back,
    this.home,
    this.menu,
    this.volumeUp,
    this.volumeDown,
    this.mute,
    this.channelUp,
    this.channelDown,
    this.volume,
    this.channel,
  });
  final String? up, down, left, right, ok, back, home, menu;
  final String? volumeUp, volumeDown, mute, channelUp, channelDown, volume, channel;

  /// Todos preenchidos: o que veio nulo sai de [s].
  SsDPadLabels resolve(SsStrings s) => SsDPadLabels(
    up: up ?? s.dpadUp,
    down: down ?? s.dpadDown,
    left: left ?? s.dpadLeft,
    right: right ?? s.dpadRight,
    ok: ok ?? s.dpadOk,
    back: back ?? s.back,
    home: home ?? s.dpadHome,
    menu: menu ?? s.dpadMenu,
    volumeUp: volumeUp ?? s.volumeUp,
    volumeDown: volumeDown ?? s.volumeDown,
    mute: mute ?? s.mute,
    channelUp: channelUp ?? s.channelUp,
    channelDown: channelDown ?? s.channelDown,
    volume: volume ?? s.volumeShort,
    channel: channel ?? s.channelShort,
  );

  /// Texto da tecla (o que veio nulo, em pt).
  String of(SsDPadKey k) {
    final r = resolve(SsStrings.pt);
    return switch (k) {
      SsDPadKey.up => r.up!,
      SsDPadKey.down => r.down!,
      SsDPadKey.left => r.left!,
      SsDPadKey.right => r.right!,
      SsDPadKey.ok => r.ok!,
      SsDPadKey.back => r.back!,
      SsDPadKey.home => r.home!,
      SsDPadKey.menu => r.menu!,
      SsDPadKey.volumeUp => r.volumeUp!,
      SsDPadKey.volumeDown => r.volumeDown!,
      SsDPadKey.mute => r.mute!,
      SsDPadKey.channelUp => r.channelUp!,
      SsDPadKey.channelDown => r.channelDown!,
    };
  }
}

/// Botão aprendido do [SsDPad] (IR/RF gravado: "Netflix", "Entrada", "Zoom +"):
/// o [name] vai para [SsDPad.onCommand] ao apertar.
@immutable
class SsDPadButton {
  const SsDPadButton(this.name, this.label, {this.icon});

  /// Nome do comando enviado ("netflix", "KEY_INPUT").
  final String name;

  /// Texto do botão (e do leitor de tela).
  final String label;

  /// Ícone opcional antes do texto.
  final IconData? icon;
}

/// Controle remoto: cruz (cima, baixo, esquerda, direita) com OK no meio,
/// voltar/início/menu embaixo e, opcional, as gangorras de volume e canal.
/// Com foco, as setas do teclado, Enter e Esc também apertam.
///
/// [onKey] recebe a tecla ([SsDPadKey]); [onCommand] recebe o nome do
/// comando: o de [keys] para aquela tecla (padrão: o nome do enum, "up",
/// "volumeUp") ou o [SsDPadButton.name] dos [extraButtons], que ficam numa
/// grade embaixo. [showNavRow] falso tira voltar/início/menu (câmera PTZ).
class SsDPad extends StatelessWidget {
  const SsDPad({
    super.key,
    this.onKey,
    this.showVolume = false,
    this.showChannel = false,
    this.showMute = false,
    this.enabled = true,
    this.size = 210,
    this.labels = const SsDPadLabels(),
    this.showNavRow = true,
    this.keys,
    this.extraButtons = const [],
    this.onCommand,
  });

  final ValueChanged<SsDPadKey>? onKey;

  /// Falso esconde a linha voltar/início/menu (e o mudo que fica nela).
  final bool showNavRow;

  /// Nome do comando de cada tecla, para [onCommand] ({up: 'KEY_UP'}).
  final Map<SsDPadKey, String>? keys;

  /// Botões aprendidos, numa grade embaixo do controle.
  final List<SsDPadButton> extraButtons;

  /// Nome do comando apertado (tecla mapeada por [keys] ou botão extra).
  final ValueChanged<String>? onCommand;

  /// Nome do comando de [k]: o de [keys] ou o nome do enum.
  String commandOf(SsDPadKey k) => keys?[k] ?? k.name;
  final bool showVolume;
  final bool showChannel;
  final bool showMute;
  final bool enabled;

  /// Diâmetro da cruz.
  final double size;
  final SsDPadLabels labels;

  void _aperta(SsDPadKey k) {
    if (!enabled) return;
    SsHaptics.tick();
    onKey?.call(k);
    onCommand?.call(commandOf(k));
  }

  void _extra(SsDPadButton b) {
    if (!enabled) return;
    SsHaptics.tick();
    onCommand?.call(b.name);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final labels = this.labels.resolve(SsStrings.of(context));
    final s = size;
    Widget seta(SsDPadKey k, IconData icon, Alignment a) => Align(
      alignment: a,
      child: _Tecla(
        label: labels.of(k),
        onTap: enabled ? () => _aperta(k) : null,
        size: s * .3,
        child: Icon(icon, size: s * .17, color: c.ink2),
      ),
    );

    final cruz = SizedBox.square(
      dimension: s,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: c.field,
          border: Border.all(color: c.line),
          boxShadow: c.isDark ? null : AppShadows.card,
        ),
        child: Stack(
          children: [
            seta(SsDPadKey.up, Icons.keyboard_arrow_up_rounded, Alignment.topCenter),
            seta(SsDPadKey.down, Icons.keyboard_arrow_down_rounded, Alignment.bottomCenter),
            seta(SsDPadKey.left, Icons.keyboard_arrow_left_rounded, Alignment.centerLeft),
            seta(SsDPadKey.right, Icons.keyboard_arrow_right_rounded, Alignment.centerRight),
            Center(
              child: _Tecla(
                label: labels.ok!,
                onTap: enabled ? () => _aperta(SsDPadKey.ok) : null,
                size: s * .38,
                fill: c.accent,
                shadow: c.primaryShadow,
                child: Text(
                  labels.ok!,
                  style: const TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w800, fontSize: AppType.md),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Widget redondo(SsDPadKey k, IconData icon) => _Tecla(
      label: labels.of(k),
      onTap: enabled ? () => _aperta(k) : null,
      size: 52,
      fill: c.field,
      border: c.line,
      child: Icon(icon, size: 22, color: c.ink2),
    );

    Widget gangorra(String titulo, SsDPadKey mais, SsDPadKey menos, IconData iMais, IconData iMenos) => Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: c.field,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: c.line),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tecla(
            label: labels.of(mais),
            onTap: enabled ? () => _aperta(mais) : null,
            size: 48,
            child: Icon(iMais, color: c.ink2),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ExcludeSemantics(
              child: Text(
                titulo,
                style: TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          _Tecla(
            label: labels.of(menos),
            onTap: enabled ? () => _aperta(menos) : null,
            size: 48,
            child: Icon(iMenos, color: c.ink2),
          ),
        ],
      ),
    );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp): () => _aperta(SsDPadKey.up),
        const SingleActivator(LogicalKeyboardKey.arrowDown): () => _aperta(SsDPadKey.down),
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _aperta(SsDPadKey.left),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _aperta(SsDPadKey.right),
        const SingleActivator(LogicalKeyboardKey.enter): () => _aperta(SsDPadKey.ok),
        const SingleActivator(LogicalKeyboardKey.escape): () => _aperta(SsDPadKey.back),
      },
      child: Focus(
        child: Opacity(
          opacity: enabled ? 1 : .5,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showVolume) ...[
                    gangorra(
                      labels.volume!,
                      SsDPadKey.volumeUp,
                      SsDPadKey.volumeDown,
                      Icons.add_rounded,
                      Icons.remove_rounded,
                    ),
                    const SizedBox(width: 18),
                  ],
                  cruz,
                  if (showChannel) ...[
                    const SizedBox(width: 18),
                    gangorra(
                      labels.channel!,
                      SsDPadKey.channelUp,
                      SsDPadKey.channelDown,
                      Icons.keyboard_arrow_up_rounded,
                      Icons.keyboard_arrow_down_rounded,
                    ),
                  ],
                ],
              ),
              if (showNavRow) ...[
                const SizedBox(height: 18),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: 18,
                  children: [
                    redondo(SsDPadKey.back, Icons.arrow_back_rounded),
                    redondo(SsDPadKey.home, Icons.home_outlined),
                    redondo(SsDPadKey.menu, Icons.menu_rounded),
                    if (showMute) redondo(SsDPadKey.mute, Icons.volume_off_outlined),
                  ],
                ),
              ] else if (showMute) ...[
                const SizedBox(height: 18),
                redondo(SsDPadKey.mute, Icons.volume_off_outlined),
              ],
              if (extraButtons.isNotEmpty) ...[
                const SizedBox(height: 18),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: math.max(s + 148, 280)),
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in extraButtons)
                        _BotaoExtra(botao: b, onTap: enabled && onCommand != null ? () => _extra(b) : null),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Botão aprendido em pílula (ícone opcional e texto), alvo de 44 dp.
class _BotaoExtra extends StatelessWidget {
  const _BotaoExtra({required this.botao, this.onTap});
  final SsDPadButton botao;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: botao.label,
      excludeSemantics: true,
      child: SsPressable(
        enabled: onTap != null,
        scale: .94,
        child: Material(
          color: c.field,
          shape: StadiumBorder(side: BorderSide(color: c.line)),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            splashColor: c.accent.withValues(alpha: .18),
            highlightColor: c.accent.withValues(alpha: .1),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (botao.icon != null) ...[Icon(botao.icon, size: 18, color: c.ink2), const SizedBox(width: 6)],
                  Text(
                    botao.label,
                    style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: AppType.sub),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Uma tecla redonda: afunda e volta com mola; tinge com a marca ao apertar.
class _Tecla extends StatelessWidget {
  const _Tecla({
    required this.label,
    required this.child,
    required this.size,
    this.onTap,
    this.fill,
    this.border,
    this.shadow,
  });
  final String label;
  final Widget child;
  final double size;
  final VoidCallback? onTap;
  final Color? fill;
  final Color? border;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      excludeSemantics: true,
      child: SsPressable(
        enabled: onTap != null,
        scale: .9,
        child: Material(
          color: fill ?? Colors.transparent,
          shape: CircleBorder(side: border == null ? BorderSide.none : BorderSide(color: border!)),
          shadowColor: Colors.transparent,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            splashColor: c.accent.withValues(alpha: .18),
            highlightColor: c.accent.withValues(alpha: .1),
            child: Container(
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: shadow == null ? null : BoxDecoration(shape: BoxShape.circle, boxShadow: shadow),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
