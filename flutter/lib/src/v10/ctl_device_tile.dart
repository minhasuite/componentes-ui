import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_dialogs.dart' show showSsConfirm;
import '../ss_strings.dart';
import 'ctl_comum.dart';

/// Situação do aparelho além de ligado/desligado.
enum SsDeviceStatus {
  /// Normal: responde a comandos.
  ready,

  /// Sem sinal: apagado, borda tracejada e "Indisponível".
  unavailable,

  /// Comando em andamento: anel girando no ícone e a chave travada.
  pending,

  /// O último comando falhou: borda e texto de erro.
  error,

  /// Sem permissão para comandar: cadeado no lugar da chave.
  locked,
}

/// Tile de aparelho da casa (luz, tomada, portão, sensor), numa linha só
/// (v0.12): o ícone, e à direita dele o nome e o estado em texto ("Ligada ·
/// 80%"); cadeado no fim quando não há permissão. Tocar no tile abre os
/// detalhes ([onTap]). Com [onToggle], **o ícone é a chave**: tocar no quadrado
/// do ícone liga/desliga (no leitor de tela é um interruptor, com o nome e o
/// estado ligado/desligado; teclado: Enter ou Espaço com o foco nele). [footer]
/// fica embaixo, na largura toda (um [SsSlider] ou chips).
///
/// Ligado ([on]), o tile tinge com [color] (padrão: a cor da marca), o ícone
/// fica cheio na cor e ganha um brilho; desligado com chave, o quadrado fica
/// claro com contorno na cor. [wide] continua aceito (o tile já é deitado).
///
/// Modo ação: com [onPress], tocar no tile executa um comando (portão, cena,
/// botão) no lugar de abrir os detalhes, depois de confirmar quando há
/// [confirm]. [color] aceita a cor real da luz, mesmo clara (amarelo-claro,
/// branco quente): o ícone troca para tinta escura para continuar legível.
///
/// Toque longo ([onLongPress], v0.10.3): menu ou detalhes, com vibração e a
/// ação no leitor de tela ([longPressLabel], padrão "Mais opções"). Vale em
/// qualquer situação, até indisponível (para editar ou remover). [onDoubleTap]
/// é um atalho (ex. alternar): o toque simples passa a esperar o tempo do duplo.
class SsDeviceTile extends StatelessWidget {
  const SsDeviceTile({
    super.key,
    required this.icon,
    required this.name,
    this.state,
    this.on = false,
    this.status = SsDeviceStatus.ready,
    this.color,
    this.onTap,
    this.onToggle,
    this.footer,
    this.wide = false,
    this.errorText,
    this.unavailableLabel,
    this.pendingLabel,
    this.errorLabel,
    this.lockedLabel,
    this.turnOnLabel,
    this.turnOffLabel,
    this.detailsLabel,
    this.onPress,
    this.confirm,
    this.confirmTitle,
    this.pressLabel,
    this.onLongPress,
    this.longPressLabel,
    this.onDoubleTap,
    this.level,
  });

  final IconData icon;
  final String name;

  /// Texto do estado ("Ligada · 80%", "21,5 °C"). Indisponível, mostra
  /// [unavailableLabel] no lugar.
  final String? state;
  final bool on;
  final SsDeviceStatus status;

  /// Cor de ligado (tom do aparelho). Padrão: a cor da marca.
  final Color? color;

  /// Abre os detalhes do aparelho.
  final VoidCallback? onTap;

  /// Executa o comando ao tocar no tile (ganha de [onTap]). Só vale pronto
  /// ou com erro (não indisponível, enviando ou sem permissão).
  final VoidCallback? onPress;

  /// Pergunta antes de [onPress] ("Abrir o portão da garagem?"). Com
  /// [confirmTitle], vira a mensagem embaixo do título.
  final String? confirm;
  final String? confirmTitle;

  /// Dica do leitor de tela no modo ação (padrão: "Acionar").
  final String? pressLabel;

  /// Toque longo: menu do aparelho, detalhes no modo ação, editar.
  final VoidCallback? onLongPress;

  /// Nome da ação do toque longo no leitor de tela (padrão: [SsStrings.moreOptions]).
  final String? longPressLabel;

  /// Toque duplo (atalho; o toque simples espera o tempo do duplo).
  final VoidCallback? onDoubleTap;

  /// Brilho real do aparelho, de 0 a 1 (v0.21; o nível do dimmer da lâmpada).
  /// Ligado, a tinta e o brilho do tile acompanham: 0 fica fraco (35%), 1
  /// fica como sem [level]. Nulo = intensidade cheia (o de sempre).
  final double? level;

  /// Intensidade da cor de ligado, de .35 a 1, pelo [level].
  double get intensity => level == null ? 1 : .35 + .65 * level!.clamp(0.0, 1.0);

  /// Chave rápida (o ícone): recebe o estado pedido. Sem ela, o ícone é só desenho.
  final ValueChanged<bool>? onToggle;
  final Widget? footer;

  /// Desde a v0.12 o tile é sempre deitado; fica por compatibilidade.
  final bool wide;

  /// Mensagem do erro (padrão: [errorLabel]).
  final String? errorText;

  /// Textos (padrão: os do [SsStrings] do idioma).
  final String? unavailableLabel, pendingLabel, errorLabel, lockedLabel;
  final String? turnOnLabel, turnOffLabel, detailsLabel;

  bool get _available => status != SsDeviceStatus.unavailable;
  bool get _lit => on && _available;
  bool get _pressable => status == SsDeviceStatus.ready || status == SsDeviceStatus.error;

  Future<void> _press(BuildContext context) async {
    if (confirm != null || confirmTitle != null) {
      final ok = await showSsConfirm(
        context,
        title: confirmTitle ?? confirm!,
        message: confirmTitle == null ? null : confirm,
        icon: icon,
      );
      if (!ok) return;
    }
    SsHaptics.tick();
    onPress?.call();
  }

  /// Texto que aparece embaixo do nome no estado atual (textos de [strings],
  /// padrão: pt).
  String stateLine([SsStrings? strings]) {
    final s = strings ?? SsStrings.pt;
    return switch (status) {
      SsDeviceStatus.unavailable => unavailableLabel ?? s.unavailable,
      SsDeviceStatus.error => errorText ?? errorLabel ?? s.deviceNoResponse,
      SsDeviceStatus.pending => [?state, pendingLabel ?? s.sending].join(' · '),
      _ => state ?? '',
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final tone = color ?? c.accent;
    final reduce = reduceMotion(context);
    final dur = reduce ? Duration.zero : SsMotion.base;
    final radius = d.radiusCard;
    final erro = status == SsDeviceStatus.error;

    final bg = !_available
        ? c.field
        : _lit
        ? Color.alphaBlend(tone.withValues(alpha: (c.isDark ? .16 : .10) * intensity), c.surface)
        : c.surface;
    final border = erro
        ? c.danger.withValues(alpha: .6)
        : _lit
        ? Color.alphaBlend(tone.withValues(alpha: .38 * intensity), c.surface)
        : c.line;

    final s = SsStrings.of(context);
    final texto = stateLine(s);
    final corEstado = erro
        ? c.dangerText
        : !_available
        ? c.muted
        : (_lit ? c.ink2 : c.muted);

    final nome = Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontWeight: FontWeight.w700,
        color: _available ? c.ink : c.ink2,
        fontSize: d.font(AppType.set),
        height: 1.25,
      ),
    );
    final estado = Row(
      children: [
        if (erro) ...[
          Icon(Icons.error_outline_rounded, size: d.iconSize - 6, color: c.dangerText),
          const SizedBox(width: 4),
        ],
        Flexible(
          child: AnimatedSwitcher(
            duration: dur,
            child: Text(
              texto,
              key: ValueKey(texto),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: corEstado, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
    // O texto vai no rótulo do tile (Semantics abaixo): aqui fica fora da árvore.
    final textos = ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [nome, const SizedBox(height: 2), estado],
      ),
    );

    final pode = (status == SsDeviceStatus.ready || status == SsDeviceStatus.error) && _available;
    final chave = onToggle != null && status != SsDeviceStatus.locked;
    final acao = on ? turnOffLabel ?? s.turnOff : turnOnLabel ?? s.turnOn;
    Widget bolha = _Icone(
      icon: icon,
      tone: tone,
      lit: _lit,
      available: _available,
      pending: status == SsDeviceStatus.pending,
      toggle: chave,
      intensity: intensity,
    );
    if (chave) {
      final raio = BorderRadius.circular(d.radiusField);
      bolha = Tooltip(
        message: '$acao $name',
        excludeFromSemantics: true,
        child: Semantics(
          container: true,
          toggled: _lit,
          enabled: pode,
          label: name,
          hint: acao,
          onTap: pode ? () => _toggle() : null,
          excludeSemantics: true,
          child: SsTapTarget(
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: pode ? _toggle : null,
                borderRadius: raio,
                customBorder: RoundedRectangleBorder(borderRadius: raio),
                focusColor: tone.withValues(alpha: .18),
                child: bolha,
              ),
            ),
          ),
        ),
      );
    }
    final fim = _trailing(context, c);

    // Uma linha: ícone (a chave), nome e estado ao lado e o cadeado no fim.
    final linha = Row(
      children: [
        bolha,
        SizedBox(width: d.space(12)),
        Expanded(child: textos),
        if (fim != null) ...[SizedBox(width: d.space(8)), fim],
      ],
    );

    final semantica = '$name: $texto';
    // Modo ação: o toque executa; senão, abre os detalhes.
    final VoidCallback? toque = onPress != null ? (_pressable ? () => _press(context) : null) : onTap;
    final dica = onPress != null ? pressLabel ?? s.deviceRun : detailsLabel ?? s.openDetails;
    Widget tile = AnimatedContainer(
      duration: dur,
      curve: Curves.easeOut,
      padding: EdgeInsets.all(d.cardPad - 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: _available ? Border.all(color: border, width: _lit || erro ? 1.4 : 1) : null,
        boxShadow: _lit
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: (c.isDark ? .32 : .22) * intensity),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -8,
                ),
              ]
            : (_available ? AppShadows.card : null),
      ),
      child: LayoutBuilder(
        builder: (context, cons) {
          final limitado = cons.hasBoundedHeight;
          final rotulado = Semantics(
            button: toque != null,
            enabled: onPress != null ? _pressable : null,
            label: semantica,
            hint: toque != null ? dica : null,
            onTap: toque,
            onLongPress: onLongPress,
            onLongPressHint: onLongPress == null ? null : longPressLabel ?? s.moreOptions,
            container: true,
            child: linha,
          );
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (limitado) Flexible(child: Center(child: rotulado)) else rotulado,
              if (footer != null) ...[SizedBox(height: d.gap), footer!],
            ],
          );
        },
      ),
    );
    if (!_available) {
      tile = CustomPaint(
        foregroundPainter: CtlDashedBorder(color: c.muted2, radius: radius),
        child: tile,
      );
    }
    final clicavel = toque == null && onLongPress == null && onDoubleTap == null
        ? tile
        : SsPressable(
            scale: onPress != null ? .95 : .98,
            onTap: toque,
            onLongPress: onLongPress,
            onDoubleTap: onDoubleTap,
            child: tile,
          );
    return AnimatedOpacity(opacity: _available ? 1 : .72, duration: dur, child: clicavel);
  }

  Widget? _trailing(BuildContext context, SsColors c) {
    final s = SsStrings.of(context);
    final d = SsDensity.of(context);
    if (status == SsDeviceStatus.locked) {
      return Semantics(
        label: lockedLabel ?? s.noPermission,
        // Não é tocável (v0.12): só o desenho, sem a caixa de 48 que apertava o nome.
        child: Icon(Icons.lock_outline_rounded, color: c.muted, size: d.iconSize - 2),
      );
    }
    return null;
  }

  void _toggle() {
    SsHaptics.tick();
    onToggle?.call(!on);
  }
}

/// Bolha do ícone: cheia na cor (com brilho) quando ligado; anel girando
/// enquanto o comando corre.
class _Icone extends StatelessWidget {
  const _Icone({
    required this.icon,
    required this.tone,
    required this.lit,
    required this.available,
    required this.pending,
    this.toggle = false,
    this.intensity = 1,
  });

  final IconData icon;
  final Color tone;
  final bool lit, available, pending;

  /// v0.21: brilho da lâmpada (.35 a 1) no degradê e no halo do ícone aceso.
  final double intensity;

  /// É a chave (v0.12): desligado, fundo claro com contorno na cor.
  final bool toggle;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    // Quadrado do ícone: 2 a mais que o SsIconTile (38 / 44 / 48).
    final tam = d.iconTile + 2;
    final bolha = AnimatedContainer(
      duration: dur,
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(d.radiusField),
        color: lit ? null : (available ? (toggle ? c.surface : c.field) : c.surface),
        border: !lit && toggle && available
            ? Border.all(color: Color.alphaBlend(tone.withValues(alpha: .35), c.line), width: 1.5)
            : null,
        gradient: lit
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.lerp(tone, Colors.white, .18)!.withValues(alpha: .55 + .45 * intensity),
                  tone.withValues(alpha: .55 + .45 * intensity),
                ],
              )
            : null,
        boxShadow: lit
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: .55 * intensity),
                  blurRadius: 6 + 12 * intensity,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: d.iconSize + 2,
        // Cor de luz clara (amarelo-claro, branco quente): ícone em tinta escura.
        color: lit
            ? (ThemeData.estimateBrightnessForColor(tone) == Brightness.light ? const Color(0xFF2A2418) : Colors.white)
            : (available ? c.ink2 : c.muted),
      ),
    );
    if (!pending) return bolha;
    return SizedBox(
      width: tam + 8,
      height: tam + 8,
      child: Stack(
        alignment: Alignment.center,
        children: [
          bolha,
          SizedBox.expand(
            child: CircularProgressIndicator(
              // Com menos movimento, o anel fica parado (meio cheio).
              value: reduceMotion(context) ? .3 : null,
              strokeWidth: 2.4,
              color: tone,
              backgroundColor: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}
