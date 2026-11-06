// v0.10 (casa): tile de câmera e player de mídia.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Situação do quadro de uma câmera no [SsCameraTile].
enum SsCameraState { loading, live, stale, error, offline }

/// Tile de câmera: o quadro (imagem parada ou o `<video>`/widget do app),
/// título, selo "AO VIVO", idade do quadro parado ("há 12 s") e ações por cima.
/// Não faz WebRTC: o app põe o player dele em [child].
///
/// `SsCameraTile(title: 'Garagem', state: SsCameraState.stale, image: NetworkImage(url), age: Duration(seconds: 12))`
///
/// [status] (ou [statusWidget]) põe um selo de situação no canto de baixo
/// ("Gravando", "Movimento há 2 min"). Offline e erro cobrem o quadro, mas o
/// título continua por cima, e a mensagem encolhe para caber em tile pequeno.
class SsCameraTile extends StatelessWidget {
  const SsCameraTile({
    super.key,
    required this.title,
    this.state = SsCameraState.live,
    this.image,
    this.child,
    this.age,
    this.actions = const [],
    this.onTap,
    this.onRetry,
    this.aspectRatio = 16 / 9,
    this.liveLabel,
    this.loadingLabel,
    this.errorLabel,
    this.offlineLabel,
    this.retryLabel,
    this.ageFormat,
    this.status,
    this.statusWidget,
  });

  final String title;

  /// Situação em texto, num selo no canto de baixo ("Gravando").
  final String? status;

  /// Selo próprio no lugar de [status] (ícone, cor).
  final Widget? statusWidget;
  final SsCameraState state;

  /// Quadro parado (snapshot). Ignorado quando há [child].
  final ImageProvider? image;

  /// O quadro vivo do app (WebRTC, HLS): ocupa a área toda.
  final Widget? child;

  /// Idade do quadro parado; aparece em `live` (se houver) e `stale`.
  final Duration? age;

  /// Botões por cima do quadro, no canto de baixo (gravar, áudio, tela cheia).
  final List<Widget> actions;
  final VoidCallback? onTap;

  /// Em `error` e `offline`, mostra o botão de tentar de novo.
  final VoidCallback? onRetry;
  final double aspectRatio;
  final String? liveLabel;
  final String? loadingLabel;
  final String? errorLabel;
  final String? offlineLabel;
  final String? retryLabel;

  /// Idade do quadro (padrão: [formatAge] no idioma).
  final String Function(Duration)? ageFormat;

  /// "há 12 s", "há 3 min", "há 2 h", "há 1 d" (no idioma de [s]; padrão: pt).
  static String formatAge(Duration d, [SsStrings? s]) {
    final t = s ?? SsStrings.pt;
    if (d.inSeconds < 60) return t.agoSeconds(d.inSeconds);
    if (d.inMinutes < 60) return t.agoMinutes(d.inMinutes);
    if (d.inHours < 24) return t.agoHours(d.inHours);
    return t.agoDaysShort(d.inDays);
  }

  @override
  Widget build(BuildContext context) {
    final ssText = SsStrings.of(context);
    final liveLabel = this.liveLabel ?? ssText.cameraLive;
    final loadingLabel = this.loadingLabel ?? ssText.cameraLoading;
    final errorLabel = this.errorLabel ?? ssText.cameraError;
    final offlineLabel = this.offlineLabel ?? ssText.cameraOffline;
    final retryLabel = this.retryLabel ?? ssText.retry;
    final ageFormat = this.ageFormat ?? ((Duration d) => formatAge(d, ssText));
    final c = SsColors.of(context);
    final radius = BorderRadius.circular(SsDensity.of(context).radiusCard);
    final temQuadro = child != null || image != null;
    final apagado = state == SsCameraState.error || state == SsCameraState.offline;

    Widget quadro;
    if (state == SsCameraState.loading) {
      quadro = const _Shimmer();
    } else if (child != null) {
      quadro = child!;
    } else if (image != null) {
      quadro = Image(image: image!, fit: BoxFit.cover, gaplessPlayback: true);
    } else {
      quadro = ColoredBox(color: c.field);
    }
    if (state == SsCameraState.stale && temQuadro) {
      // Quadro velho: um pouco apagado, para não passar por ao vivo.
      quadro = Opacity(opacity: .72, child: quadro);
    }
    if (apagado) quadro = ColoredBox(color: c.isDark ? c.field : AppColors.inkLight);

    final semantica = [
      switch (state) {
        SsCameraState.loading => '$title, $loadingLabel',
        SsCameraState.live => '$title, $liveLabel',
        SsCameraState.stale => '$title, ${age == null ? '' : ageFormat(age!)}',
        SsCameraState.error => '$title, $errorLabel',
        SsCameraState.offline => '$title, $offlineLabel',
      },
      ?status,
    ].join(', ');
    final selo = statusWidget ?? (status == null ? null : _Selo.status(status!));
    final idadeEmbaixo = state == SsCameraState.live && age != null;

    return Semantics(
      container: true,
      label: semantica,
      button: onTap != null,
      child: GestureDetector(
        onTap: onTap,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              fit: StackFit.expand,
              children: [
                quadro,
                // Véu escuro em cima e embaixo para o texto branco ler sobre qualquer imagem.
                const IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x99000000), Color(0x00000000), Color(0x00000000), Color(0x8C000000)],
                        stops: [0, .32, .62, 1],
                      ),
                    ),
                  ),
                ),
                if (idadeEmbaixo || selo != null)
                  Positioned(
                    left: 12,
                    bottom: 10,
                    right: actions.isNotEmpty && !apagado ? 12 + 44.0 * actions.length : 12,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 6,
                      children: [
                        if (idadeEmbaixo) _Selo.age(ageFormat(age!)),
                        if (selo != null) Flexible(child: selo),
                      ],
                    ),
                  ),
                if (apagado)
                  // Abaixo da faixa do título e acima do selo. Sem altura para o
                  // bloco (tile pequeno de grade), vira uma linha: ícone, texto e
                  // o "tentar de novo" só com o ícone.
                  Positioned.fill(
                    top: 34,
                    bottom: selo != null ? 38 : 8,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final icone = state == SsCameraState.offline
                            ? Icons.videocam_off_rounded
                            : Icons.broken_image_rounded;
                        final msg = state == SsCameraState.offline ? offlineLabel : errorLabel;
                        const estiloMsg = TextStyle(
                          color: AppColors.onDark,
                          fontSize: AppType.meta,
                          fontWeight: FontWeight.w700,
                        );
                        final retryStyle = TextButton.styleFrom(
                          foregroundColor: AppColors.onDark,
                          backgroundColor: AppColors.onDark.withValues(alpha: .16),
                          shape: const StadiumBorder(),
                          visualDensity: VisualDensity.compact,
                        );
                        if (box.maxHeight < 110) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icone, color: AppColors.onDarkMuted, size: 18),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(msg, maxLines: 1, style: estiloMsg),
                                  ),
                                ),
                                if (onRetry != null) ...[
                                  const SizedBox(width: 4),
                                  IconButton(
                                    tooltip: retryLabel,
                                    onPressed: onRetry,
                                    style: IconButton.styleFrom(
                                      foregroundColor: AppColors.onDark,
                                      backgroundColor: AppColors.onDark.withValues(alpha: .16),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    icon: const Icon(Icons.refresh_rounded, size: 18),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }
                        return FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(icone, color: AppColors.onDarkMuted, size: 30),
                                const SizedBox(height: 6),
                                Text(msg, textAlign: TextAlign.center, style: estiloMsg),
                                if (onRetry != null) ...[
                                  const SizedBox(height: 10),
                                  SsPressable(
                                    child: TextButton.icon(
                                      onPressed: onRetry,
                                      style: retryStyle,
                                      icon: const Icon(Icons.refresh_rounded, size: 18),
                                      label: Text(retryLabel),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                // O título fica por cima de tudo (até do aviso de offline).
                Positioned(
                  left: 12,
                  top: 10,
                  right: 12,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.onDark,
                            fontWeight: FontWeight.w800,
                            fontSize: AppType.sub,
                            shadows: [Shadow(color: Color(0x66000000), blurRadius: 6)],
                          ),
                        ),
                      ),
                      if (state == SsCameraState.live) _Selo.live(liveLabel),
                      if (state == SsCameraState.stale && age != null) _Selo.age(ageFormat(age!)),
                    ],
                  ),
                ),
                if (actions.isNotEmpty && !apagado && state != SsCameraState.loading)
                  Positioned(
                    right: 8,
                    bottom: 6,
                    child: IconButtonTheme(
                      data: IconButtonThemeData(
                        style: IconButton.styleFrom(
                          foregroundColor: AppColors.onDark,
                          backgroundColor: const Color(0x52000000),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, spacing: 4, children: actions),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Selo sobre o quadro: "AO VIVO" (ponto vermelho) ou a idade (relógio).
class _Selo extends StatelessWidget {
  const _Selo.live(this.text) : live = true, status = false;
  const _Selo.age(this.text) : live = false, status = false;
  const _Selo.status(this.text) : live = false, status = true;
  final String text;
  final bool live;

  /// Situação em texto (sem ícone).
  final bool status;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: live ? AppColors.danger : const Color(0x80000000),
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live)
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 5),
            decoration: const BoxDecoration(color: AppColors.onDark, shape: BoxShape.circle),
          )
        else if (!status)
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.schedule_rounded, size: 12, color: AppColors.onDark),
          ),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.onDark,
              fontSize: AppType.micro,
              fontWeight: FontWeight.w800,
              letterSpacing: live ? .6 : 0,
            ),
          ),
        ),
      ],
    ),
  );
}

/// Brilho que passa (esqueleto do quadro). Parado com "reduzir movimento".
class _Shimmer extends StatefulWidget {
  const _Shimmer();

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotion(context)) {
      _c
        ..stop()
        ..value = .5;
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final brilho = c.isDark ? c.surface : AppColors.surfaceLight;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final x = -1.5 + _c.value * 3;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(x - 1, -.3),
              end: Alignment(x + 1, .3),
              colors: [c.field, brilho, c.field],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────── player de mídia

/// Situação do [SsMediaPlayer].
enum SsMediaState { idle, playing, paused, buffering, unavailable }

/// Player de mídia: capa, título, subtítulo, anterior/tocar/próxima,
/// progresso com tempos, volume e a fonte ("Spotify · Sala").
/// O app manda os comandos ao aparelho pelos callbacks.
///
/// [onVolume] anda com o dedo; [onVolumeEnd] só ao soltar (um comando).
/// [onVolumeUp]/[onVolumeDown] põem os botões − e + do volume (aparelho sem
/// volume absoluto: aí a linha aparece mesmo sem [volume]); [onMute] com
/// [muted] liga e desliga o som. [power] não nulo mostra o botão de ligar no
/// canto ([onPower]); [mediaPicker] fica embaixo (escolher o que tocar).
class SsMediaPlayer extends StatelessWidget {
  const SsMediaPlayer({
    super.key,
    this.title,
    this.subtitle,
    this.art,
    this.state = SsMediaState.idle,
    this.position,
    this.duration,
    this.volume,
    this.source,
    this.onPlayPause,
    this.onPrevious,
    this.onNext,
    this.onSeek,
    this.onVolume,
    this.playLabel,
    this.pauseLabel,
    this.previousLabel,
    this.nextLabel,
    this.volumeLabel,
    this.progressLabel,
    this.idleLabel,
    this.unavailableLabel,
    this.bufferingLabel,
    this.onVolumeEnd,
    this.onVolumeUp,
    this.onVolumeDown,
    this.muted,
    this.onMute,
    this.power,
    this.onPower,
    this.mediaPicker,
  });

  /// Volume escolhido ao soltar o dedo (manda um comando só).
  final ValueChanged<double>? onVolumeEnd;

  /// Botões − e + do volume.
  final VoidCallback? onVolumeUp, onVolumeDown;

  /// Sem som agora (nulo: sem botão de mudo).
  final bool? muted;
  final VoidCallback? onMute;

  /// Ligado (verdadeiro) ou desligado; nulo esconde o botão de ligar.
  final bool? power;
  final VoidCallback? onPower;

  /// Escolher o que tocar (fontes, playlists, favoritos), embaixo do player.
  final Widget? mediaPicker;

  final String? title;
  final String? subtitle;

  /// Capa (imagem do app); sem ela, um quadrado com nota musical.
  final Widget? art;
  final SsMediaState state;
  final Duration? position;
  final Duration? duration;

  /// 0..1; nulo esconde a linha de volume.
  final double? volume;

  /// De onde vem: "Spotify · Sala de estar".
  final String? source;
  final VoidCallback? onPlayPause;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final ValueChanged<Duration>? onSeek;
  final ValueChanged<double>? onVolume;
  final String? playLabel;
  final String? pauseLabel;
  final String? previousLabel;
  final String? nextLabel;
  final String? volumeLabel;
  final String? progressLabel;
  final String? idleLabel;
  final String? unavailableLabel;
  final String? bufferingLabel;

  /// 3:07 ou 1:02:03.
  static String formatTime(Duration d) {
    final s = d.inSeconds % 60;
    final m = d.inMinutes % 60;
    String pad(int n) => n.toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:${pad(m)}:${pad(s)}' : '$m:${pad(s)}';
  }

  @override
  Widget build(BuildContext context) {
    final ssText = SsStrings.of(context);
    final playLabel = this.playLabel ?? ssText.play;
    final pauseLabel = this.pauseLabel ?? ssText.pause;
    final previousLabel = this.previousLabel ?? ssText.previous;
    final nextLabel = this.nextLabel ?? ssText.nextTrack;
    final volumeLabel = this.volumeLabel ?? ssText.volume;
    final progressLabel = this.progressLabel ?? ssText.position;
    final idleLabel = this.idleLabel ?? ssText.nothingPlaying;
    final unavailableLabel = this.unavailableLabel ?? ssText.unavailable;
    final bufferingLabel = this.bufferingLabel ?? ssText.loading;
    final c = SsColors.of(context);
    final dn = SsDensity.of(context);
    final off = state == SsMediaState.unavailable;
    final ativo = !off && state != SsMediaState.idle;
    final tocando = state == SsMediaState.playing || state == SsMediaState.buffering;
    final dur = duration;
    final pos = position ?? Duration.zero;
    final frac = dur == null || dur.inMilliseconds == 0
        ? 0.0
        : (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);

    final titulo = switch (state) {
      SsMediaState.idle => title ?? idleLabel,
      SsMediaState.unavailable => title ?? unavailableLabel,
      _ => title ?? '',
    };

    Widget botao(IconData icon, String label, VoidCallback? onTap) => IconButton(
      tooltip: label,
      onPressed: ativo ? onTap : null,
      icon: Icon(icon, size: dn.iconSize + 8),
      color: c.ink,
      disabledColor: c.muted2,
    );

    return Opacity(
      opacity: off ? .55 : 1,
      child: Container(
        padding: EdgeInsets.all(dn.cardPad),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(dn.radiusCard),
          border: c.isDark ? Border.all(color: c.line) : null,
          boxShadow: c.isDark ? null : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(dn.radiusField),
                  child: SizedBox.square(
                    // Capa: 58 / 64 / 68.
                    dimension: dn.iconTile + 22,
                    child:
                        art ??
                        DecoratedBox(
                          decoration: BoxDecoration(gradient: c.gradient4),
                          child: const Icon(Icons.music_note_rounded, color: AppColors.onDark, size: 30),
                        ),
                  ),
                ),
                SizedBox(width: dn.space(14)),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: dn.font(AppType.md)),
                      ),
                      if (subtitle != null && ativo)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: dn.font(AppType.sub)),
                        ),
                      if (source != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Icon(Icons.speaker_rounded, size: 14, color: c.accentText),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  source!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: c.accentText,
                                    fontSize: dn.font(AppType.label),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (power != null)
                  IconButton(
                    tooltip: power! ? ssText.turnOff : ssText.turnOn,
                    onPressed: off || onPower == null ? null : onPower,
                    isSelected: power,
                    icon: const Icon(Icons.power_settings_new_rounded),
                    style: IconButton.styleFrom(
                      foregroundColor: power! ? AppColors.onDark : c.ink2,
                      backgroundColor: power! ? c.accent : c.field,
                      disabledForegroundColor: c.muted2,
                    ),
                  ),
              ],
            ),
            if (dur != null && ativo) ...[
              SizedBox(height: dn.gap),
              _Trilha(
                value: frac,
                label: progressLabel,
                valueText: '${formatTime(pos)} / ${formatTime(dur)}',
                onChanged: onSeek == null
                    ? null
                    : (v) => onSeek!(Duration(milliseconds: (v * dur.inMilliseconds).round())),
              ),
              Row(
                children: [
                  Text(
                    formatTime(pos),
                    style: AppTheme.number(context, size: AppType.label, color: c.muted),
                  ),
                  const Spacer(),
                  Text(
                    formatTime(dur),
                    style: AppTheme.number(context, size: AppType.label, color: c.muted),
                  ),
                ],
              ),
            ],
            SizedBox(height: dn.space(6)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                botao(Icons.skip_previous_rounded, previousLabel, onPrevious),
                SizedBox(width: dn.gap),
                _PlayButton(
                  playing: tocando,
                  buffering: state == SsMediaState.buffering,
                  enabled: !off && onPlayPause != null,
                  label: state == SsMediaState.buffering ? bufferingLabel : (tocando ? pauseLabel : playLabel),
                  onTap: onPlayPause,
                ),
                SizedBox(width: dn.gap),
                botao(Icons.skip_next_rounded, nextLabel, onNext),
              ],
            ),
            if (volume != null || onVolumeUp != null || onVolumeDown != null || onMute != null) ...[
              SizedBox(height: dn.space(4)),
              Row(
                // Sem volume absoluto (TV por IR): mudo, − e + juntos no meio.
                mainAxisAlignment: volume == null ? MainAxisAlignment.center : MainAxisAlignment.start,
                spacing: volume == null ? 12 : 0,
                children: [
                  if (onMute != null)
                    IconButton(
                      tooltip: muted == true ? ssText.unmute : ssText.mute,
                      onPressed: off ? null : onMute,
                      isSelected: muted == true,
                      icon: Icon(
                        muted == true ? Icons.volume_off_rounded : Icons.volume_off_outlined,
                        color: muted == true ? c.dangerText : c.ink2,
                      ),
                    )
                  else if (volume != null && onVolumeDown == null)
                    Icon(
                      volume! <= 0 || muted == true ? Icons.volume_off_rounded : Icons.volume_down_rounded,
                      size: 20,
                      color: c.muted,
                    ),
                  if (onVolumeDown != null)
                    IconButton(
                      tooltip: ssText.volumeDown,
                      onPressed: off ? null : onVolumeDown,
                      icon: Icon(Icons.volume_down_rounded, color: c.ink2),
                    ),
                  if (volume != null)
                    Expanded(
                      child: _Trilha(
                        value: volume!.clamp(0, 1),
                        label: volumeLabel,
                        valueText: '${(volume!.clamp(0, 1) * 100).round()}%',
                        dim: muted == true,
                        onChanged: off ? null : (onVolume ?? (onVolumeEnd == null ? null : (_) {})),
                        onChangeEnd: off ? null : onVolumeEnd,
                      ),
                    ),
                  if (onVolumeUp != null)
                    IconButton(
                      tooltip: ssText.volumeUp,
                      onPressed: off ? null : onVolumeUp,
                      icon: Icon(Icons.volume_up_rounded, color: c.ink2),
                    )
                  else if (volume != null)
                    Icon(Icons.volume_up_rounded, size: 20, color: c.muted),
                ],
              ),
            ],
            if (mediaPicker != null) ...[SizedBox(height: dn.space(8)), mediaPicker!],
          ],
        ),
      ),
    );
  }
}

/// Trilha fina com bolinha (progresso e volume), na cor da marca.
class _Trilha extends StatefulWidget {
  const _Trilha({
    required this.value,
    required this.label,
    required this.valueText,
    this.onChanged,
    this.onChangeEnd,
    this.dim = false,
  });
  final double value;
  final String label;
  final String valueText;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;

  /// Apagada (volume no mudo).
  final bool dim;

  @override
  State<_Trilha> createState() => _TrilhaState();
}

// Guarda o valor enquanto arrasta: só com onChangeEnd o pai não acompanha o dedo.
class _TrilhaState extends State<_Trilha> {
  double? _arrasto;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final c = SsColors.of(context);
    final cor = w.dim ? c.muted2 : c.accent;
    return Semantics(
      label: w.label,
      value: w.valueText,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          activeTrackColor: cor,
          inactiveTrackColor: c.field,
          thumbColor: cor,
          overlayColor: cor.withValues(alpha: .12),
          disabledActiveTrackColor: c.muted2,
          disabledThumbColor: c.muted2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(
          value: _arrasto ?? w.value,
          onChanged: w.onChanged == null
              ? null
              : (v) {
                  setState(() => _arrasto = v);
                  w.onChanged!(v);
                },
          onChangeEnd: (v) {
            setState(() => _arrasto = null);
            w.onChangeEnd?.call(v);
          },
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.buffering,
    required this.enabled,
    required this.label,
    this.onTap,
  });
  final bool playing;
  final bool buffering;
  final bool enabled;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    // 52 / 60 / 64.
    final tam = d.controlHeight + 12;
    final rm = reduceMotion(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SsPressable(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        child: Container(
          width: tam,
          height: tam,
          decoration: BoxDecoration(
            color: enabled ? c.accent : c.field,
            shape: BoxShape.circle,
            boxShadow: enabled ? c.primaryShadow : null,
          ),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: rm ? Duration.zero : SsMotion.base,
            switchInCurve: SsMotion.bounce,
            transitionBuilder: (child, a) => ScaleTransition(scale: a, child: child),
            child: buffering
                ? const SizedBox(
                    key: ValueKey('buf'),
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.6, color: AppColors.onDark),
                  )
                : Icon(
                    playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    key: ValueKey(playing),
                    size: d.iconSize + 12,
                    color: enabled ? AppColors.onDark : c.muted2,
                  ),
          ),
        ),
      ),
    );
  }
}
