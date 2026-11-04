// v0.10 (casa): clima, relógio e radar de busca.
import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Condição do tempo do [SsWeatherCard].
enum SsWeatherCondition { clear, clearNight, partlyCloudy, cloudy, rain, storm, snow, fog, wind }

/// Um ponto da faixa de previsão: hora ("14h") ou dia ("Ter").
class SsForecast {
  const SsForecast(this.label, this.condition, this.temp, {this.min, this.precip});
  final String label;
  final SsWeatherCondition condition;

  /// Temperatura (por hora) ou máxima (por dia).
  final double temp;

  /// Mínima do dia (previsão diária).
  final double? min;

  /// Chance de chuva, 0..100 (por hora fica no lugar da mínima; por dia, embaixo dela).
  final int? precip;

  /// O mesmo que [precip] (nome igual ao do [SsWeatherCard.rainChance]).
  int? get rainChance => precip;
}

// Azul da chuva (gota e %), o mesmo da previsão.
const _corChuva = Color(0xFF3B82F6);

/// Card de clima: temperatura atual, ícone e texto da condição, mín/máx,
/// umidade, vento e a faixa de previsão. Só recebe dados (sem rede).
/// [rainChance] põe a gota com a chance de chuva ao lado da condição atual e
/// [feelsLike], a sensação térmica embaixo da temperatura.
class SsWeatherCard extends StatelessWidget {
  const SsWeatherCard({
    super.key,
    required this.temperature,
    required this.condition,
    this.conditionText,
    this.location,
    this.min,
    this.max,
    this.humidity,
    this.wind,
    this.forecast = const [],
    this.unit = '°',
    this.windUnit = 'km/h',
    this.minLabel,
    this.maxLabel,
    this.humidityLabel,
    this.windLabel,
    this.conditionLabels,
    this.rainChance,
    this.feelsLike,
    this.rainChanceLabel,
    this.feelsLikeLabel,
  });

  final double temperature;
  final SsWeatherCondition condition;

  /// Texto da condição; padrão: [conditionLabels].
  final String? conditionText;
  final String? location;
  final double? min;
  final double? max;

  /// Umidade relativa, 0..100.
  final int? humidity;

  /// Vento em [windUnit].
  final double? wind;
  final List<SsForecast> forecast;
  final String unit;
  final String windUnit;
  final String? minLabel;
  final String? maxLabel;
  final String? humidityLabel;
  final String? windLabel;

  /// Chance de chuva agora, 0..100 (gota azul ao lado da condição).
  final int? rainChance;

  /// Sensação térmica agora ("Sensação 24°").
  final double? feelsLike;

  /// Textos (padrão: "Chance de chuva" e "Sensação" do [SsStrings]).
  final String? rainChanceLabel, feelsLikeLabel;

  /// Nome de cada condição (padrão: [labelsOf] no idioma).
  final Map<SsWeatherCondition, String>? conditionLabels;

  /// Nomes das condições no idioma de [s].
  static Map<SsWeatherCondition, String> labelsOf(SsStrings s) => {
    SsWeatherCondition.clear: s.weatherClear,
    SsWeatherCondition.clearNight: s.weatherClearNight,
    SsWeatherCondition.partlyCloudy: s.weatherPartlyCloudy,
    SsWeatherCondition.cloudy: s.weatherCloudy,
    SsWeatherCondition.rain: s.weatherRain,
    SsWeatherCondition.storm: s.weatherStorm,
    SsWeatherCondition.snow: s.weatherSnow,
    SsWeatherCondition.fog: s.weatherFog,
    SsWeatherCondition.wind: s.weatherWind,
  };

  /// Os nomes em pt-BR.
  static final defaultLabels = labelsOf(SsStrings.pt);

  String _t(double v) => '${v.round()}$unit';

  @override
  Widget build(BuildContext context) {
    final ssText = SsStrings.of(context);
    final minLabel = this.minLabel ?? ssText.weatherMin;
    final maxLabel = this.maxLabel ?? ssText.weatherMax;
    final humidityLabel = this.humidityLabel ?? ssText.humidity;
    final windLabel = this.windLabel ?? ssText.wind;
    final conditionLabels = this.conditionLabels ?? labelsOf(ssText);
    final c = SsColors.of(context);
    final texto = conditionText ?? conditionLabels[condition] ?? '';
    final chuvaTxt = rainChance == null ? null : '${rainChanceLabel ?? ssText.rainChance} $rainChance%';
    final sensacao = feelsLike == null ? null : '${feelsLikeLabel ?? ssText.feelsLike} ${_t(feelsLike!)}';
    final temChuvaDia = forecast.any((f) => f.min != null && f.precip != null);
    final pilulas = <(IconData, String, String)>[
      if (humidity != null) (Icons.water_drop_outlined, humidityLabel, '$humidity%'),
      if (wind != null) (Icons.air_rounded, windLabel, '${wind!.round()} $windUnit'),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: c.isDark ? Border.all(color: c.line) : null,
        boxShadow: c.isDark ? null : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: [?location, _t(temperature), ?sensacao, texto, ?chuvaTxt].join(', '),
            excludeSemantics: true,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (location != null)
                        Text(
                          location!,
                          style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w700),
                        ),
                      Text(
                        _t(temperature),
                        style: AppTheme.number(context, size: 52, weight: FontWeight.w500, color: c.ink),
                      ),
                      if (sensacao != null)
                        Text(
                          sensacao,
                          style: TextStyle(color: c.muted, fontSize: AppType.meta, fontWeight: FontWeight.w600),
                        ),
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        children: [
                          Text(
                            texto,
                            style: TextStyle(color: c.ink2, fontSize: AppType.body, fontWeight: FontWeight.w700),
                          ),
                          if (rainChance != null) _Chuva(rainChance!, size: AppType.sub),
                        ],
                      ),
                      if (min != null || max != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            [
                              if (max != null) '$maxLabel ${_t(max!)}',
                              if (min != null) '$minLabel ${_t(min!)}',
                            ].join('  ·  '),
                            style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                          ),
                        ),
                    ],
                  ),
                ),
                SsWeatherIcon(condition, size: 64),
              ],
            ),
          ),
          if (pilulas.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final (icon, label, v) in pilulas)
                  Semantics(
                    label: '$label $v',
                    excludeSemantics: true,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 15, color: c.muted),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: TextStyle(color: c.muted, fontSize: AppType.label),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            v,
                            style: AppTheme.number(context, size: AppType.meta, color: c.ink),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
          if (forecast.isNotEmpty) ...[
            const SizedBox(height: 14),
            Divider(height: 1, color: c.line),
            const SizedBox(height: 10),
            SizedBox(
              height: temChuvaDia ? 116 : 100,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                separatorBuilder: (_, _) => const SizedBox(width: 4),
                itemBuilder: (context, i) {
                  final f = forecast[i];
                  final txt = conditionLabels[f.condition] ?? '';
                  return Semantics(
                    label:
                        '${f.label}, $txt, ${_t(f.temp)}${f.min == null ? '' : ' / ${_t(f.min!)}'}'
                        '${f.precip == null ? '' : ', ${rainChanceLabel ?? ssText.rainChance} ${f.precip}%'}',
                    excludeSemantics: true,
                    child: SizedBox(
                      width: 54,
                      child: Column(
                        children: [
                          Text(
                            f.label,
                            style: TextStyle(color: c.muted, fontSize: AppType.label, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          SsWeatherIcon(f.condition, size: 26),
                          const SizedBox(height: 4),
                          Text(
                            _t(f.temp),
                            style: AppTheme.number(context, size: AppType.sub, color: c.ink),
                          ),
                          if (f.min != null)
                            Text(
                              _t(f.min!),
                              style: AppTheme.number(context, size: AppType.label, color: c.muted),
                            ),
                          if (f.min == null && f.precip != null)
                            Text(
                              '${f.precip}%',
                              style: AppTheme.number(context, size: AppType.label, color: _corChuva),
                            ),
                          // Por dia: a chance de chuva vai embaixo da mínima, com a gota.
                          if (f.min != null && f.precip != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: _Chuva(f.precip!, size: AppType.label),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Gota azul com a chance de chuva ("40%").
class _Chuva extends StatelessWidget {
  const _Chuva(this.pct, {required this.size});
  final int pct;
  final double size;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.water_drop_rounded, size: size + 1, color: _corChuva),
      const SizedBox(width: 2),
      Text(
        '$pct%',
        style: AppTheme.number(context, size: size, color: _corChuva),
      ),
    ],
  );
}

/// Ícone da condição do tempo (Material, com as cores semânticas da suíte).
class SsWeatherIcon extends StatelessWidget {
  const SsWeatherIcon(this.condition, {super.key, this.size = 32});
  final SsWeatherCondition condition;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    const sol = AppColors.aquecFg, chuva = Color(0xFF3B82F6);
    final nuvem = c.isDark ? AppColors.ink2Dark : AppColors.mutedLight;
    final (IconData icon, Color cor, IconData? extra, Color? corExtra) = switch (condition) {
      SsWeatherCondition.clear => (Icons.wb_sunny_rounded, sol, null, null),
      SsWeatherCondition.clearNight => (Icons.nightlight_round, const Color(0xFF8E9BD8), null, null),
      SsWeatherCondition.partlyCloudy => (Icons.wb_sunny_rounded, sol, Icons.cloud_rounded, nuvem),
      SsWeatherCondition.cloudy => (Icons.cloud_rounded, nuvem, null, null),
      SsWeatherCondition.rain => (Icons.water_drop_rounded, chuva, Icons.cloud_rounded, nuvem),
      SsWeatherCondition.storm => (Icons.thunderstorm_rounded, nuvem, Icons.bolt_rounded, sol),
      SsWeatherCondition.snow => (Icons.ac_unit_rounded, chuva, null, null),
      SsWeatherCondition.fog => (Icons.foggy, nuvem, null, null),
      SsWeatherCondition.wind => (Icons.air_rounded, nuvem, null, null),
    };
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          children: [
            if (extra == null)
              Center(
                child: Icon(icon, size: size, color: cor),
              )
            else if (condition == SsWeatherCondition.partlyCloudy) ...[
              Positioned(
                top: 0,
                right: 0,
                child: Icon(icon, size: size * .7, color: cor),
              ),
              Positioned(
                left: 0,
                bottom: size * .02,
                child: Icon(extra, size: size * .8, color: corExtra),
              ),
            ] else if (condition == SsWeatherCondition.storm) ...[
              Center(
                child: Icon(icon, size: size, color: cor),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Icon(extra, size: size * .5, color: corExtra),
              ),
            ] else ...[
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Icon(extra, size: size * .8, color: corExtra),
              ),
              Positioned(
                left: size * .18,
                bottom: 0,
                child: Icon(icon, size: size * .3, color: cor),
              ),
              Positioned(
                left: size * .5,
                bottom: size * .06,
                child: Icon(icon, size: size * .3, color: cor),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────── relógio

/// Como o [SsClock] mostra os segundos (com [SsClock.showSeconds]).
enum SsClockSeconds {
  /// Ponto que pisca a cada segundo (padrão).
  dot,

  /// Os dígitos dos segundos, menores, depois dos minutos (":05").
  digits,
}

/// Relógio digital grande com data e, opcional, o ponto dos segundos (pisca a
/// cada segundo). Atualiza a cada segundo com um `Timer` (cancelado ao sair);
/// com [now] fixo não tem timer (testes e captura). [seconds] troca o ponto
/// pelos dígitos. Em caixa estreita (card de grade com ~160 px) as horas
/// encolhem para caber e a data quebra em até duas linhas.
class SsClock extends StatefulWidget {
  const SsClock({
    super.key,
    this.now,
    this.showSeconds = false,
    this.showDate = true,
    this.use24h = true,
    this.size = 64,
    this.weekdays,
    this.months,
    this.dateFormat,
    this.align = CrossAxisAlignment.center,
    this.seconds = SsClockSeconds.dot,
  });

  /// Hora fixa (sem timer).
  final DateTime? now;
  final bool showSeconds;
  final bool showDate;
  final bool use24h;

  /// Altura da fonte das horas.
  final double size;

  /// Segunda a domingo (DateTime.weekday 1..7); padrão: os do [SsStrings].
  final List<String>? weekdays;
  final List<String>? months;

  /// Data já formatada pelo app; padrão no idioma: "quarta-feira, 4 de
  /// novembro", "Wednesday, November 4", "miércoles, 4 de noviembre".
  final String Function(DateTime)? dateFormat;
  final CrossAxisAlignment align;

  /// Ponto que pisca ou dígitos (só com [showSeconds]).
  final SsClockSeconds seconds;

  @override
  State<SsClock> createState() => _SsClockState();
}

class _SsClockState extends State<SsClock> {
  Timer? _timer;
  late DateTime _agora = widget.now ?? DateTime.now();

  void _sync() {
    _timer?.cancel();
    _timer = null;
    if (widget.now != null) {
      _agora = widget.now!;
      return;
    }
    _agora = DateTime.now();
    // Acerta na virada do segundo e depois anda de 1 em 1 s.
    _timer = Timer(Duration(milliseconds: 1000 - _agora.millisecond), () {
      if (!mounted) return;
      setState(() => _agora = DateTime.now());
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _agora = DateTime.now());
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didUpdateWidget(SsClock old) {
    super.didUpdateWidget(old);
    if (old.now != widget.now) _sync();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final rm = reduceMotion(context);
    final d = _agora;
    String pad(int n) => n.toString().padLeft(2, '0');
    var h = d.hour;
    String? ampm;
    if (!widget.use24h) {
      ampm = h < 12 ? 'AM' : 'PM';
      h = h % 12 == 0 ? 12 : h % 12;
    }
    final hh = widget.use24h ? pad(h) : '$h';
    final s = SsStrings.of(context);
    final data =
        widget.dateFormat?.call(d) ??
        s.longDatePattern(
          (widget.weekdays ?? s.weekdaysFull)[d.weekday - 1],
          d.day,
          (widget.months ?? s.months)[d.month - 1],
        );
    final estilo = AppTheme.number(context, size: widget.size, weight: FontWeight.w500, color: c.ink);
    // O ponto acende nos segundos pares (com "reduzir movimento", fica aceso).
    final aceso = rm || d.second.isEven;
    final digitos = widget.showSeconds && widget.seconds == SsClockSeconds.digits;
    final alinha = switch (widget.align) {
      CrossAxisAlignment.start => Alignment.centerLeft,
      CrossAxisAlignment.end => Alignment.centerRight,
      _ => Alignment.center,
    };

    return Semantics(
      label:
          '$hh:${pad(d.minute)}${digitos ? ':${pad(d.second)}' : ''}'
          '${ampm == null ? '' : ' $ampm'}${widget.showDate ? ', $data' : ''}',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.align,
        children: [
          // Em caixa estreita, as horas encolhem para caber (não estouram).
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: alinha,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(hh, style: estilo.copyWith(height: 1)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: widget.size * .06),
                  child: Text(':', style: estilo.copyWith(height: 1, color: c.muted)),
                ),
                Text(pad(d.minute), style: estilo.copyWith(height: 1)),
                if (digitos)
                  Padding(
                    padding: EdgeInsets.only(left: widget.size * .06, top: widget.size * .3),
                    child: Text(
                      ':${pad(d.second)}',
                      style: AppTheme.number(context, size: widget.size * .42, weight: FontWeight.w500, color: c.muted),
                    ),
                  )
                else if (widget.showSeconds)
                  Padding(
                    padding: EdgeInsets.only(left: widget.size * .14),
                    child: AnimatedOpacity(
                      opacity: aceso ? 1 : .2,
                      duration: rm ? Duration.zero : const Duration(milliseconds: 240),
                      child: Container(
                        width: widget.size * .14,
                        height: widget.size * .14,
                        decoration: BoxDecoration(color: c.accent, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                if (ampm != null)
                  Padding(
                    padding: EdgeInsets.only(left: widget.size * .1),
                    child: Text(
                      ampm,
                      style: AppTheme.number(context, size: widget.size * .28, color: c.muted),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.showDate)
            Padding(
              padding: EdgeInsets.only(top: widget.size * .12),
              child: Text(
                data,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: switch (widget.align) {
                  CrossAxisAlignment.start => TextAlign.start,
                  CrossAxisAlignment.end => TextAlign.end,
                  _ => TextAlign.center,
                },
                style: TextStyle(
                  color: c.muted,
                  fontSize: math.max(AppType.sub, widget.size * .22),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────── radar de busca

/// Situação do [SsScanRadar].
enum SsScanState { searching, found, empty }

/// Um item achado pelo [SsScanRadar].
class SsScanItem {
  const SsScanItem(this.label, {this.icon = Icons.devices_other_rounded});
  final String label;
  final IconData icon;
}

/// Radar de busca: ondas saem do ícone no centro enquanto procura; os itens
/// achados "pulam" em volta como chips. Achou N: as ondas param e o texto
/// conta; nada: mensagem e "procurar de novo".
///
/// [compact] deita a peça numa linha (cabe num card ou numa lista): radar
/// pequeno (até 72 px, ou [size] se menor) à esquerda e, ao lado, o texto, o
/// "procurar de novo" e os achados como chips.
class SsScanRadar extends StatefulWidget {
  const SsScanRadar({
    super.key,
    this.state = SsScanState.searching,
    this.items = const [],
    this.icon = Icons.home_rounded,
    this.onItemTap,
    this.onRetry,
    this.size = 240,
    this.animate = true,
    this.searchingLabel,
    this.foundLabel,
    this.emptyLabel,
    this.retryLabel,
    this.compact = false,
  });

  final SsScanState state;

  /// Em linha: radar pequeno ao lado do texto.
  final bool compact;

  /// Itens achados (também durante a busca). Mostra até 6 em volta.
  final List<SsScanItem> items;
  final IconData icon;
  final ValueChanged<SsScanItem>? onItemTap;
  final VoidCallback? onRetry;
  final double size;
  final bool animate;
  final String? searchingLabel;
  final String Function(int n)? foundLabel;
  final String? emptyLabel;
  final String? retryLabel;

  /// "1 encontrado", "3 encontrados" (pt); mantido por compatibilidade.
  static String foundPt(int n) => SsStrings.pt.foundCount(n);

  @override
  State<SsScanRadar> createState() => _SsScanRadarState();
}

class _SsScanRadarState extends State<SsScanRadar> with SingleTickerProviderStateMixin {
  SsStrings get _s => SsStrings.of(context);
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200));

  void _sync() {
    final anda = widget.animate && widget.state == SsScanState.searching && !reduceMotion(context);
    if (anda && !_c.isAnimating) _c.repeat();
    if (!anda && _c.isAnimating) _c.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(SsScanRadar old) {
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
    final s = widget.compact ? math.min(widget.size, 72.0) : widget.size;
    final buscando = widget.state == SsScanState.searching;
    final vazio = widget.state == SsScanState.empty;
    final rm = reduceMotion(context);
    final itens = widget.items.take(6).toList();
    final texto = switch (widget.state) {
      SsScanState.searching => widget.searchingLabel ?? _s.searching,
      SsScanState.found => (widget.foundLabel ?? _s.foundCount)(widget.items.length),
      SsScanState.empty => widget.emptyLabel ?? _s.nothingFound,
    };
    final cor = vazio ? c.muted : c.accent;

    final radar = SizedBox.square(
      dimension: s,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) => CustomPaint(
                painter: _OndasPainter(
                  t: buscando && widget.animate && !rm ? _c.value : null,
                  cor: cor,
                  grade: c.line,
                  centro: s * .14,
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              width: s * .28,
              height: s * .28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: vazio ? null : LinearGradient(colors: [c.brandFrom, c.brandTo]),
                color: vazio ? c.field : null,
                boxShadow: vazio ? null : c.primaryShadow,
              ),
              child: Icon(widget.icon, color: vazio ? c.muted : AppColors.onDark, size: s * .13),
            ),
          ),
          if (!widget.compact)
            for (final (i, it) in itens.indexed)
              _ChipNoRadar(
                key: ValueKey(it.label),
                item: it,
                // Ângulos espalhados (não colam uns nos outros), começando em cima.
                angulo: -math.pi / 2 + i * (2 * math.pi / 6) + (i.isOdd ? .25 : 0),
                raio: s * (i.isEven ? .40 : .33),
                centro: s / 2,
                onTap: widget.onItemTap == null ? null : () => widget.onItemTap!(it),
              ),
        ],
      ),
    );
    final retry = vazio && widget.onRetry != null
        ? TextButton.icon(
            onPressed: widget.onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: Text(widget.retryLabel ?? _s.searchAgain),
            style: TextButton.styleFrom(foregroundColor: c.accentText),
          )
        : null;

    if (widget.compact) {
      return Row(
        children: [
          radar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  liveRegion: true,
                  child: Text(
                    texto,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: vazio ? c.muted : c.ink,
                      fontWeight: FontWeight.w800,
                      fontSize: AppType.set,
                    ),
                  ),
                ),
                if (itens.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final it in itens)
                        _ChipItem(
                          key: ValueKey(it.label),
                          item: it,
                          onTap: widget.onItemTap == null ? null : () => widget.onItemTap!(it),
                        ),
                    ],
                  ),
                ],
                if (retry != null)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Transform.translate(offset: const Offset(-8, 0), child: retry),
                  ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        radar,
        const SizedBox(height: 12),
        Semantics(
          liveRegion: true,
          child: Text(
            texto,
            style: TextStyle(color: vazio ? c.muted : c.ink, fontWeight: FontWeight.w800, fontSize: AppType.md),
          ),
        ),
        if (retry != null) ...[const SizedBox(height: 8), retry],
      ],
    );
  }
}

class _ChipNoRadar extends StatelessWidget {
  const _ChipNoRadar({
    super.key,
    required this.item,
    required this.angulo,
    required this.raio,
    required this.centro,
    this.onTap,
  });
  final SsScanItem item;
  final double angulo, raio, centro;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = Offset(centro + math.cos(angulo) * raio, centro + math.sin(angulo) * raio);
    return Positioned(
      left: p.dx,
      top: p.dy,
      child: FractionalTranslation(
        translation: const Offset(-.5, -.5),
        child: _ChipItem(item: item, onTap: onTap),
      ),
    );
  }
}

/// Chip de um achado (em volta do radar ou, no compacto, ao lado).
class _ChipItem extends StatelessWidget {
  const _ChipItem({super.key, required this.item, this.onTap});
  final SsScanItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final rm = reduceMotion(context);
    // Entra "pulando" (mola solta) quando o item aparece.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: rm ? 1 : 0, end: 1),
      duration: rm ? Duration.zero : SsMotion.slow,
      curve: SsMotion.pop,
      builder: (context, v, child) => Transform.scale(scale: v, child: child),
      child: Semantics(
        button: onTap != null,
        label: item.label,
        excludeSemantics: true,
        child: SsPressable(
          enabled: onTap != null,
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 4, 10, 4),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: c.accent.withValues(alpha: .5)),
              boxShadow: c.isDark ? null : AppShadows.card,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, size: 16, color: c.accentText),
                const SizedBox(width: 4),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 96),
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: c.ink, fontSize: AppType.label, fontWeight: FontWeight.w700),
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

class _OndasPainter extends CustomPainter {
  _OndasPainter({required this.t, required this.cor, required this.grade, required this.centro});

  /// Fase das ondas (0..1); nulo = parado (só a grade).
  final double? t;
  final Color cor;
  final Color grade;
  final double centro;

  @override
  void paint(Canvas canvas, Size size) {
    final o = size.center(Offset.zero);
    final max = size.width / 2 - 2;
    final g = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = grade;
    for (final f in [.45, .72, 1.0]) {
      canvas.drawCircle(o, max * f, g);
    }
    final t = this.t;
    if (t == null) return;
    for (var i = 0; i < 3; i++) {
      final v = (t + i / 3) % 1;
      canvas.drawCircle(
        o,
        centro + v * (max - centro),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = cor.withValues(alpha: (1 - v) * .55),
      );
    }
    // Varredura: um arco que gira (como o radar do login do app).
    canvas.drawArc(
      Rect.fromCircle(center: o, radius: max),
      t * 2 * math.pi,
      .9,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..color = cor,
    );
  }

  @override
  bool shouldRepaint(_OndasPainter old) => old.t != t || old.cor != cor || old.grade != grade;
}
