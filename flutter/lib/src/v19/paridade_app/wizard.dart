// v1.9 · paridade_app: passo a passo (par do Ss::WizardComponent).
import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../density.dart';
import '../../motion.dart';
import '../../ss_button.dart';
import '../../ss_strings.dart';
import '../../v09/a_nav.dart' show SsStepTopBar;
import '../../v10/tela_lista.dart' show SsStepHeading;
import 'comum.dart';

/// Um passo do [SsWizard]. O corpo vai dentro de um `Form` do próprio passo:
/// os `validator` dos campos (SsTextField…) seguram o Avançar, como o
/// `checkValidity` do web. [validate] é a conferência extra (escolha
/// obrigatória, consulta à API): falso segura.
class SsWizardStep {
  const SsWizardStep({required this.title, required this.builder, this.validate});

  final String title;
  final WidgetBuilder builder;
  final FutureOr<bool> Function()? validate;
}

/// Passo a passo em tela cheia: a barra do topo com "2 / 4", Cancelar e a
/// barrinha minhoca ([SsStepTopBar]), o título numerado do passo
/// ([SsStepHeading]), um passo por vez (os outros ficam montados, então o que
/// foi digitado não se perde) e embaixo Voltar / Avançar; no último, o botão
/// vira [submitLabel] e chama [onSubmit] (fica ocupado até terminar).
///
/// Com [summary], entra um passo final "Revisão" com o resumo antes de
/// concluir. Com [onSaveForLater], aparece "Salvar e continuar depois": o app
/// grava o rascunho (recebe o índice do passo atual) e reabre com
/// [initialStep]. No web, o mesmo é o `draft_key:` (rascunho no navegador) ou
/// o `save_later_label:` (envia o form sem validar).
///
/// Use como corpo de uma tela (precisa de altura): `Scaffold(body: SafeArea(child: SsWizard(...)))`.
class SsWizard extends StatefulWidget {
  const SsWizard({
    super.key,
    required this.steps,
    required this.onSubmit,
    this.submitLabel,
    this.summary,
    this.onSaveForLater,
    this.saveForLaterLabel,
    this.onCancel,
    this.initialStep = 0,
    this.onStepChanged,
  });

  final List<SsWizardStep> steps;
  final Future<void> Function() onSubmit;

  /// Padrão: [SsStrings.wizardSubmit] ("Concluir").
  final String? submitLabel;

  /// Corpo do passo "Revisão" (o último). Nulo: sem revisão.
  final WidgetBuilder? summary;

  /// "Salvar e continuar depois" (recebe o passo atual). Nulo: sem o botão.
  final ValueChanged<int>? onSaveForLater;
  final String? saveForLaterLabel;

  /// O × do topo. Nulo: sem Cancelar.
  final VoidCallback? onCancel;

  /// Onde começa (retomar um rascunho).
  final int initialStep;
  final ValueChanged<int>? onStepChanged;

  @override
  State<SsWizard> createState() => SsWizardState();
}

class SsWizardState extends State<SsWizard> with SingleTickerProviderStateMixin {
  late int _i;
  var _dir = 1;
  var _ocupado = false;
  late List<GlobalKey<FormState>> _forms;
  late final _anim = AnimationController(vsync: this, duration: SsMotion.base, value: 1);

  int get _total => widget.steps.length + (widget.summary != null ? 1 : 0);

  /// O passo atual (0 = o primeiro).
  int get index => _i;

  @override
  void initState() {
    super.initState();
    _forms = [for (var i = 0; i < _total; i++) GlobalKey<FormState>()];
    _i = widget.initialStep.clamp(0, _total - 1);
  }

  @override
  void didUpdateWidget(SsWizard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_forms.length != _total) {
      _forms = [for (var i = 0; i < _total; i++) i < _forms.length ? _forms[i] : GlobalKey<FormState>()];
      _i = _i.clamp(0, _total - 1);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  void _mostrar(int i) {
    if (i == _i) return;
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _dir = i > _i ? 1 : -1;
      _i = i;
    });
    if (reduceMotion(context)) {
      _anim.value = 1;
    } else {
      _anim.forward(from: 0);
    }
    SsHaptics.tick();
    widget.onStepChanged?.call(i);
  }

  Future<bool> _valido() async {
    final okForm = _forms[_i].currentState?.validate() ?? true;
    if (!okForm) return false;
    final v = _i < widget.steps.length ? widget.steps[_i].validate : null;
    return v == null || await v();
  }

  /// Avança se o passo atual passar na validação (o botão Avançar).
  Future<void> next() async {
    if (_ocupado) return;
    if (!await _valido()) {
      SsHaptics.error();
      return;
    }
    if (!mounted) return;
    if (_i < _total - 1) {
      _mostrar(_i + 1);
      return;
    }
    setState(() => _ocupado = true);
    try {
      await widget.onSubmit();
    } finally {
      if (mounted) setState(() => _ocupado = false);
    }
  }

  void back() {
    if (_i > 0) _mostrar(_i - 1);
  }

  @override
  Widget build(BuildContext context) {
    final s = SsStrings.of(context);
    final d = SsDensity.of(context);
    final ultimo = _i == _total - 1;
    String titulo(int i) => i < widget.steps.length ? widget.steps[i].title : s.wizardReview;

    final paineis = IndexedStack(
      index: _i,
      sizing: StackFit.expand,
      children: [
        for (var i = 0; i < _total; i++)
          Semantics(
            container: true,
            label: ssFill(s.wizardStep, {'n': i + 1, 'title': titulo(i)}),
            child: ExcludeFocus(
              excluding: i != _i,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(d.padX, d.gap, d.padX, d.gap * 2),
                child: Form(
                  key: _forms[i],
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SsStepHeading(i + 1, titulo(i)),
                      SizedBox(height: d.gap * 1.5),
                      Builder(builder: i < widget.steps.length ? widget.steps[i].builder : widget.summary!),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SsStepTopBar(step: _i + 1, total: _total, onCancel: widget.onCancel),
        Expanded(
          child: AnimatedBuilder(
            animation: _anim,
            child: paineis,
            builder: (context, child) {
              final v = Curves.easeOutCubic.transform(_anim.value);
              return Opacity(
                opacity: .25 + .75 * v,
                child: Transform.translate(offset: Offset(_dir * 24 * (1 - v), 0), child: child),
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(d.padX, 8, d.padX, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: SsButton.ghost(label: s.back, onPressed: _i == 0 || _ocupado ? null : back),
                    ),
                    SizedBox(width: d.gap),
                    Expanded(
                      flex: 2,
                      child: SsButton(
                        label: ultimo ? (widget.submitLabel ?? s.wizardSubmit) : s.wizardNext,
                        icon: ultimo ? Icons.check_rounded : null,
                        trailingIcon: ultimo ? null : Icons.arrow_forward_rounded,
                        loading: _ocupado,
                        onPressed: next,
                      ),
                    ),
                  ],
                ),
                if (widget.onSaveForLater != null)
                  Center(
                    child: SsButton.text(
                      label: widget.saveForLaterLabel ?? s.wizardSaveLater,
                      icon: Icons.bookmark_outline_rounded,
                      onPressed: _ocupado ? null : () => widget.onSaveForLater!(_i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
