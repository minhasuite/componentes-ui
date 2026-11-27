// v1.10.0: o par Flutter do Ss::JobProgressComponent (importação, relatório, tarefa longa).
import 'package:material_ui/material_ui.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_badge.dart';
import '../ss_button.dart';
import '../ss_card.dart';
import '../ss_progress.dart';
import '../ss_strings.dart';

/// Situação da tarefa ([SsJobProgress.state]).
enum SsJobState { queued, running, done, failed }

/// Situação de uma etapa com tempo ([SsJobStage]).
enum SsJobStageStatus { done, failed, skipped, running }

/// Etapa de uma execução (o `stages:` do web): nome, situação, tempo e um detalhe.
class SsJobStage {
  const SsJobStage(this.name, {this.status = SsJobStageStatus.done, this.duration, this.durationLabel, this.detail});
  final String name;
  final SsJobStageStatus status;
  final Duration? duration;

  /// Texto pronto no lugar do [duration] ("1,2 s").
  final String? durationLabel;
  final String? detail;
}

/// Tarefa longa (v1.10, par do `Ss::JobProgressComponent`): na fila, rodando n%, concluída com o botão
/// do resultado ou falhou com o motivo e "Tentar de novo"; passos ([steps] + [currentStep]) e etapas com
/// tempo ([stages], com o total). [onCancel] mostra "Cancelar" enquanto está na fila ou rodando
/// ([cancelling]: "Cancelando…", desligado). O leitor de tela ouve a mudança de situação (região viva).
///
/// ```dart
/// SsJobProgress(title: 'Importar clientes', state: SsJobState.running, progress: .4,
///   steps: const ['Ler arquivo', 'Validar', 'Gravar'], currentStep: 1, onCancel: cancelar)
/// ```
class SsJobProgress extends StatelessWidget {
  const SsJobProgress({
    super.key,
    required this.title,
    this.state = SsJobState.queued,
    this.progress,
    this.steps = const [],
    this.currentStep,
    this.onOpenResult,
    this.resultLabel,
    this.error,
    this.detail,
    this.onRetry,
    this.stages = const [],
    this.total,
    this.onCancel,
    this.cancelling = false,
    this.flush = false,
  });

  final String title;
  final SsJobState state;

  /// 0 a 1 enquanto roda; nulo: a barra corre sem número.
  final double? progress;
  final List<String> steps;
  final int? currentStep;
  final VoidCallback? onOpenResult;

  /// Padrão: [SsStrings.jobResult].
  final String? resultLabel;

  /// Motivo da falha (padrão: [SsStrings.jobError]).
  final String? error;
  final String? detail;
  final VoidCallback? onRetry;
  final List<SsJobStage> stages;

  /// Troca a soma das durações das etapas.
  final Duration? total;
  final VoidCallback? onCancel;
  final bool cancelling;

  /// Sem a moldura de card (dentro de outro card), o `is-flush` do web.
  final bool flush;

  int get pct => state == SsJobState.done ? 100 : ((progress ?? 0).clamp(0.0, 1.0) * 100).round();
  bool get determinate => state == SsJobState.done || (state == SsJobState.running && progress != null);
  bool get _ended => state == SsJobState.done || state == SsJobState.failed;
  bool get _bar => !(stages.isNotEmpty && _ended);

  /// 820 ms → "820 ms"; 1,2 s; 65 s → "1 min 5 s" (o mesmo do web).
  static String durationText(Duration v, SsStrings s) {
    final ms = v.inMilliseconds;
    if (ms < 1000) return '$ms ms';
    if (ms < 60000) {
      final t = (ms / 1000).toStringAsFixed(1);
      return '${s.locale.languageCode == 'en' ? t : t.replaceAll('.', ',')} s';
    }
    final seg = (ms / 1000).round();
    final min = seg ~/ 60, sec = seg % 60;
    return sec == 0 ? '$min min' : '$min min $sec s';
  }

  String stateLabel(SsStrings s) => switch (state) {
    SsJobState.queued => s.jobQueued,
    SsJobState.running => s.jobRunning,
    SsJobState.done => s.jobDone,
    SsJobState.failed => s.jobFailed,
  };

  SsTone get _tone => switch (state) {
    SsJobState.queued => SsTone.info,
    SsJobState.running => SsTone.accent,
    SsJobState.done => SsTone.success,
    SsJobState.failed => SsTone.danger,
  };

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final rodando = state == SsJobState.running && determinate;
    final situacao = rodando ? '${stateLabel(s)} · $pct%' : stateLabel(s);
    final corpo = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(color: c.ink, fontSize: d.font(AppType.md), fontWeight: FontWeight.w800),
              ),
            ),
            SizedBox(width: d.space(12)),
            Semantics(
              liveRegion: true,
              child: SsStatusBadge(state.name, map: {state.name: _tone}, label: situacao),
            ),
          ],
        ),
        if (state != SsJobState.failed && _bar) ...[
          SizedBox(height: d.space(12)),
          Semantics(
            label: title,
            value: determinate ? '$pct%' : null,
            child: ExcludeSemantics(
              child: SsProgress(
                determinate ? pct / 100 : null,
                color: state == SsJobState.queued ? c.muted.withValues(alpha: .45) : null,
              ),
            ),
          ),
        ],
        if (steps.isNotEmpty) ...[
          SizedBox(height: d.space(12)),
          Wrap(
            spacing: d.space(14),
            runSpacing: d.space(6),
            children: [for (var i = 0; i < steps.length; i++) _Passo(steps[i], _passo(i))],
          ),
        ],
        if (stages.isNotEmpty) ...[SizedBox(height: d.space(10)), _Etapas(stages, total)],
        if (detail != null && state != SsJobState.failed) ...[
          SizedBox(height: d.space(10)),
          Text(
            detail!,
            style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
          ),
        ],
        if (state == SsJobState.failed) ...[SizedBox(height: d.space(12)), _Erro(error ?? s.jobError)],
        if (_acoes(s) case final acoes?) ...[
          SizedBox(height: d.space(12)),
          Align(alignment: Alignment.centerLeft, child: acoes),
        ],
      ],
    );
    final semantica = Semantics(container: true, label: '$title, $situacao', child: corpo);
    if (flush) return semantica;
    return SsCard(padding: EdgeInsets.all(d.cardPad - 2), child: semantica);
  }

  Widget? _acoes(SsStrings s) {
    if (state == SsJobState.done && onOpenResult != null) {
      return SsButton.ghost(label: resultLabel ?? s.jobResult, small: true, expand: false, onPressed: onOpenResult);
    }
    if (state == SsJobState.failed && onRetry != null) {
      return SsButton.ghost(
        label: s.retry,
        icon: Icons.refresh_rounded,
        small: true,
        expand: false,
        onPressed: onRetry,
      );
    }
    if (!_ended && onCancel != null) {
      return SsButton.ghost(
        label: cancelling ? s.cancelling : s.cancel,
        tone: SsTone.danger,
        small: true,
        expand: false,
        onPressed: cancelling ? null : onCancel,
      );
    }
    return null;
  }

  _PassoEstado _passo(int i) {
    if (state == SsJobState.done || (currentStep != null && i < currentStep!)) return _PassoEstado.done;
    if (currentStep == i) return state == SsJobState.failed ? _PassoEstado.failed : _PassoEstado.current;
    return _PassoEstado.pending;
  }
}

enum _PassoEstado { done, current, failed, pending }

class _Passo extends StatelessWidget {
  const _Passo(this.nome, this.estado);
  final String nome;
  final _PassoEstado estado;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    final (cor, fg, peso, nomeEstado) = switch (estado) {
      _PassoEstado.done => (AppColors.success, c.ink2, FontWeight.w500, s.jobStageDone),
      _PassoEstado.current => (c.accent, c.ink, FontWeight.w700, s.jobStageRunning),
      _PassoEstado.failed => (AppColors.danger, c.dangerText, FontWeight.w700, s.jobStageFailed),
      _PassoEstado.pending => (c.line, c.muted, FontWeight.w500, s.jobStagePending),
    };
    const lado = 15.0;
    final Widget marca = switch (estado) {
      _PassoEstado.done => Container(
        width: lado,
        height: lado,
        decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
        child: const Icon(Icons.check_rounded, size: 11, color: AppColors.onDark),
      ),
      _PassoEstado.current => SizedBox(
        width: lado,
        height: lado,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: cor,
          backgroundColor: c.line,
          value: reduceMotion(context) ? .3 : null,
        ),
      ),
      _ => Container(
        width: lado,
        height: lado,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: estado == _PassoEstado.failed ? cor : null,
          border: Border.all(color: cor, width: 2),
        ),
      ),
    };
    return Semantics(
      container: true,
      label: '$nome, $nomeEstado',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          marca,
          SizedBox(width: d.space(6)),
          Flexible(
            child: Text(
              nome,
              style: TextStyle(color: fg, fontSize: d.font(AppType.meta), fontWeight: peso),
            ),
          ),
        ],
      ),
    );
  }
}

class _Etapas extends StatelessWidget {
  const _Etapas(this.stages, this.total);
  final List<SsJobStage> stages;
  final Duration? total;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final s = SsStrings.of(context);
    String? tempo(SsJobStage e) =>
        e.durationLabel ?? (e.duration == null ? null : SsJobProgress.durationText(e.duration!, s));
    final soma =
        total ??
        stages.map((e) => e.duration).whereType<Duration>().fold<Duration?>(null, (a, b) => (a ?? Duration.zero) + b);
    final num = AppTheme.number(context, size: d.font(AppType.meta), color: c.ink2);
    Widget linha(Widget ico, String nome, String? detalhe, String? t, {bool forte = false, String? sr}) => Semantics(
      container: true,
      label: [nome, ?sr, ?detalhe, ?t].join(', '),
      excludeSemantics: true,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: d.space(7)),
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: c.line)),
        ),
        child: Row(
          children: [
            ico,
            SizedBox(width: d.space(10)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nome,
                    style: TextStyle(
                      color: c.ink,
                      fontSize: d.font(AppType.sub),
                      fontWeight: forte ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  if (detalhe != null)
                    Text(
                      detalhe,
                      style: TextStyle(color: c.muted, fontSize: d.font(AppType.meta)),
                    ),
                ],
              ),
            ),
            if (t != null) Text(t, style: num),
          ],
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final e in stages) linha(_IcoEtapa(e.status), e.name, e.detail, tempo(e), sr: _rotulo(s, e.status)),
        if (soma != null)
          linha(const SizedBox(width: 22), s.jobTotal, null, SsJobProgress.durationText(soma, s), forte: true),
      ],
    );
  }

  static String _rotulo(SsStrings s, SsJobStageStatus st) => switch (st) {
    SsJobStageStatus.done => s.jobStageDone,
    SsJobStageStatus.failed => s.jobStageFailed,
    SsJobStageStatus.skipped => s.jobStageSkipped,
    SsJobStageStatus.running => s.jobStageRunning,
  };
}

class _IcoEtapa extends StatelessWidget {
  const _IcoEtapa(this.status);
  final SsJobStageStatus status;

  @override
  Widget build(BuildContext context) {
    final t = switch (status) {
      SsJobStageStatus.done => SsTone.success,
      SsJobStageStatus.failed => SsTone.danger,
      SsJobStageStatus.skipped => SsTone.neutral,
      SsJobStageStatus.running => SsTone.accent,
    }.colors(context);
    final icon = switch (status) {
      SsJobStageStatus.done => Icons.check_rounded,
      SsJobStageStatus.failed => Icons.close_rounded,
      SsJobStageStatus.skipped => Icons.remove_rounded,
      SsJobStageStatus.running => Icons.refresh_rounded,
    };
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: t.soft, shape: BoxShape.circle),
      child: Icon(icon, size: 14, color: t.text),
    );
  }
}

class _Erro extends StatelessWidget {
  const _Erro(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final d = SsDensity.of(context);
    final t = SsTone.danger.colors(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: d.padX - 3, vertical: d.rowPadV - 2),
      decoration: BoxDecoration(color: t.soft, borderRadius: BorderRadius.circular(d.radiusField)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, size: 18, color: t.text),
          SizedBox(width: d.space(8)),
          Expanded(
            child: Text(
              texto,
              style: TextStyle(color: t.text, fontSize: d.font(AppType.sub), fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
