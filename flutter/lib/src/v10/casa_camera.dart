// v0.10 (casa): tile de câmera e player de mídia.
import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Situação do quadro de uma câmera no [SsCameraTile].
enum SsCameraState { loading, live, stale, error, offline }

/// Tile de câmera: o quadro (imagem parada ou o `<video>`/widget do app),
/// título, selo "AO VIVO", idade do quadro parado ("há 12 s") e ações por cima.
/// Não faz WebRTC: o app põe o player dele em [child].
///
/// `SsCameraTile(title: 'Garagem', state: SsCameraState.stale, image: NetworkImage(url), age: Duration(seconds: 12))`
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
  });

  final String title;
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
    final radius = BorderRadius.circular(AppRadius.card);
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

    final semantica = switch (state) {
      SsCameraState.loading => '$title, $loadingLabel',
      SsCameraState.live => '$title, $liveLabel',
      SsCameraState.stale => '$title, ${age == null ? '' : ageFormat(age!)}',
      SsCameraState.error => '$title, $errorLabel',
      SsCameraState.offline => '$title, $offlineLabel',
    };

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
                if (state == SsCameraState.live && age != null)
                  Positioned(left: 12, bottom: 10, child: _Selo.age(ageFormat(age!))),
                if (apagado)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            state == SsCameraState.offline ? Icons.videocam_off_rounded : Icons.broken_image_rounded,
                            color: AppColors.onDarkMuted,
                            size: 30,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            state == SsCameraState.offline ? offlineLabel : errorLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.onDark,
                              fontSize: AppType.meta,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (onRetry != null) ...[
                            const SizedBox(height: 10),
                            SsPressable(
                              child: TextButton.icon(
                                onPressed: onRetry,
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.onDark,
                                  backgroundColor: AppColors.onDark.withValues(alpha: .16),
                                  shape: const StadiumBorder(),
                                  visualDensity: VisualDensity.compact,
                                ),
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: Text(retryLabel),
                              ),
                            ),
                          ],
                        ],
                      ),
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
  const _Selo.live(this.text) : live = true;
  const _Selo.age(this.text) : live = false;
  final String text;
  final bool live;

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
        else
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.schedule_rounded, size: 12, color: AppColors.onDark),
          ),
        Text(
          text,
          style: TextStyle(
            color: AppColors.onDark,
            fontSize: AppType.micro,
            fontWeight: FontWeight.w800,
            letterSpacing: live ? .6 : 0,
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
  });

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
      icon: Icon(icon, size: 28),
      color: c.ink,
      disabledColor: c.muted2,
    );

    return Opacity(
      opacity: off ? .55 : 1,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: c.isDark ? Border.all(color: c.line) : null,
          boxShadow: c.isDark ? null : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.field),
                  child: SizedBox.square(
                    dimension: 64,
                    child:
                        art ??
                        DecoratedBox(
                          decoration: BoxDecoration(gradient: c.gradient4),
                          child: const Icon(Icons.music_note_rounded, color: AppColors.onDark, size: 30),
                        ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: c.ink, fontWeight: FontWeight.w800, fontSize: AppType.md),
                      ),
                      if (subtitle != null && ativo)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: c.muted, fontSize: AppType.sub),
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
                                    fontSize: AppType.label,
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
              ],
            ),
            if (dur != null && ativo) ...[
              const SizedBox(height: 12),
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
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                botao(Icons.skip_previous_rounded, previousLabel, onPrevious),
                const SizedBox(width: 12),
                _PlayButton(
                  playing: tocando,
                  buffering: state == SsMediaState.buffering,
                  enabled: !off && onPlayPause != null,
                  label: state == SsMediaState.buffering ? bufferingLabel : (tocando ? pauseLabel : playLabel),
                  onTap: onPlayPause,
                ),
                const SizedBox(width: 12),
                botao(Icons.skip_next_rounded, nextLabel, onNext),
              ],
            ),
            if (volume != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(volume! <= 0 ? Icons.volume_off_rounded : Icons.volume_down_rounded, size: 20, color: c.muted),
                  Expanded(
                    child: _Trilha(
                      value: volume!.clamp(0, 1),
                      label: volumeLabel,
                      valueText: '${(volume!.clamp(0, 1) * 100).round()}%',
                      onChanged: off ? null : onVolume,
                    ),
                  ),
                  Icon(Icons.volume_up_rounded, size: 20, color: c.muted),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Trilha fina com bolinha (progresso e volume), na cor da marca.
class _Trilha extends StatelessWidget {
  const _Trilha({required this.value, required this.label, required this.valueText, this.onChanged});
  final double value;
  final String label;
  final String valueText;
  final ValueChanged<double>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Semantics(
      label: label,
      value: valueText,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 4,
          activeTrackColor: c.accent,
          inactiveTrackColor: c.field,
          thumbColor: c.accent,
          overlayColor: c.accent.withValues(alpha: .12),
          disabledActiveTrackColor: c.muted2,
          disabledThumbColor: c.muted2,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
        ),
        child: Slider(value: value, onChanged: onChanged),
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
    final rm = reduceMotion(context);
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: SsPressable(
        enabled: enabled,
        onTap: enabled ? onTap : null,
        child: Container(
          width: 60,
          height: 60,
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
                    size: 32,
                    color: enabled ? AppColors.onDark : c.muted2,
                  ),
          ),
        ),
      ),
    );
  }
}
