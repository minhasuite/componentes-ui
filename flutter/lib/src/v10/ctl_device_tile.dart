import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_dialogs.dart' show showSsConfirm;
import '../ss_strings.dart';
import '../ss_fields.dart' show SsSwitch;
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

/// Tile de aparelho da casa (luz, tomada, portão, sensor): ícone, nome e o
/// estado em texto ("Ligada · 80%"). Tocar abre os detalhes ([onTap]); com
/// [onToggle], ganha a chave de liga/desliga rápida à direita. [footer] fica
/// embaixo, na largura toda (um [SsSlider] ou chips).
///
/// Ligado ([on]), o tile tinge com [color] (padrão: a cor da marca), o ícone
/// fica cheio e ganha um brilho na mesma cor. [wide] deita o tile (ícone, texto
/// e chave numa linha); o padrão é o compacto (ícone e chave em cima, texto
/// embaixo, para grades de 2 colunas no celular.
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

  /// Chave rápida: recebe o estado pedido. Sem ela, não há chave.
  final ValueChanged<bool>? onToggle;
  final Widget? footer;
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
    final tone = color ?? c.accent;
    final reduce = reduceMotion(context);
    final dur = reduce ? Duration.zero : SsMotion.base;
    const radius = AppRadius.card;
    final erro = status == SsDeviceStatus.error;

    final bg = !_available
        ? c.field
        : _lit
        ? Color.alphaBlend(tone.withValues(alpha: c.isDark ? .16 : .10), c.surface)
        : c.surface;
    final border = erro
        ? c.danger.withValues(alpha: .6)
        : _lit
        ? Color.alphaBlend(tone.withValues(alpha: .38), c.surface)
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
        fontSize: AppType.set,
        height: 1.25,
      ),
    );
    final estado = Row(
      children: [
        if (erro) ...[Icon(Icons.error_outline_rounded, size: 14, color: c.dangerText), const SizedBox(width: 4)],
        Flexible(
          child: AnimatedSwitcher(
            duration: dur,
            child: Text(
              texto,
              key: ValueKey(texto),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: corEstado, fontSize: AppType.sub, fontWeight: FontWeight.w600),
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

    final bolha = _Icone(
      icon: icon,
      tone: tone,
      lit: _lit,
      available: _available,
      pending: status == SsDeviceStatus.pending,
    );
    final fim = _trailing(context, c);

    final corpo = wide
        ? Row(
            children: [
              bolha,
              const SizedBox(width: 12),
              Expanded(child: textos),
              if (fim != null) ...[const SizedBox(width: 8), fim],
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [bolha, const Spacer(), ?fim]),
              const SizedBox(height: 10),
              textos,
            ],
          );

    final semantica = '$name: $texto';
    // Modo ação: o toque executa; senão, abre os detalhes.
    final VoidCallback? toque = onPress != null ? (_pressable ? () => _press(context) : null) : onTap;
    final dica = onPress != null ? pressLabel ?? s.deviceRun : detailsLabel ?? s.openDetails;
    Widget tile = AnimatedContainer(
      duration: dur,
      curve: Curves.easeOut,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: _available ? Border.all(color: border, width: _lit || erro ? 1.4 : 1) : null,
        boxShadow: _lit
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: c.isDark ? .32 : .22),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                  spreadRadius: -8,
                ),
              ]
            : (_available ? AppShadows.card : null),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: toque != null,
            enabled: onPress != null ? _pressable : null,
            label: semantica,
            hint: toque != null ? dica : null,
            onTap: toque,
            onLongPress: onLongPress,
            onLongPressHint: onLongPress == null ? null : longPressLabel ?? s.moreOptions,
            container: true,
            child: corpo,
          ),
          if (footer != null) ...[const SizedBox(height: 12), footer!],
        ],
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
    if (status == SsDeviceStatus.locked) {
      return Semantics(
        label: lockedLabel ?? s.noPermission,
        child: SizedBox(width: 48, height: 48, child: Icon(Icons.lock_outline_rounded, color: c.muted, size: 20)),
      );
    }
    if (onToggle == null) return null;
    final pode = status == SsDeviceStatus.ready || status == SsDeviceStatus.error;
    final acao = on ? turnOffLabel ?? s.turnOff : turnOnLabel ?? s.turnOn;
    return Tooltip(
      message: acao,
      child: Semantics(
        label: '$acao $name',
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 56),
          child: Center(
            child: Opacity(
              opacity: pode ? 1 : .5,
              child: SsSwitch(value: on, activeColor: color, onChanged: pode && _available ? onToggle : null),
            ),
          ),
        ),
      ),
    );
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
  });

  final IconData icon;
  final Color tone;
  final bool lit, available, pending;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final dur = reduceMotion(context) ? Duration.zero : SsMotion.base;
    const tam = 44.0;
    final bolha = AnimatedContainer(
      duration: dur,
      width: tam,
      height: tam,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: lit ? null : (available ? c.field : c.surface),
        gradient: lit
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color.lerp(tone, Colors.white, .18)!, tone],
              )
            : null,
        boxShadow: lit
            ? [
                BoxShadow(
                  color: tone.withValues(alpha: .55),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                  spreadRadius: -6,
                ),
              ]
            : null,
      ),
      child: Icon(
        icon,
        size: 22,
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
