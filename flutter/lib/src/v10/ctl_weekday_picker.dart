import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../density.dart';
import '../motion.dart';
import '../ss_strings.dart';

/// Dias da semana (agenda, automação): sete bolinhas (S T Q Q S S D) que
/// marcam e desmarcam, mais os atalhos "Todos os dias", "Dias úteis" e "Fim de
/// semana". Os dias são os do [DateTime.weekday]: 1 = segunda … 7 = domingo.
/// [firstDay] 7 começa no domingo.
class SsWeekdayPicker extends StatelessWidget {
  const SsWeekdayPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.firstDay = DateTime.monday,
    this.shortcuts = true,
    this.letters,
    this.names,
    this.everyDayLabel,
    this.weekdaysLabel,
    this.weekendLabel,
    this.label,
  });

  /// Dias marcados (1 = segunda … 7 = domingo).
  final Set<int> value;

  /// Nulo = apagado.
  final ValueChanged<Set<int>>? onChanged;
  final int firstDay;
  final bool shortcuts;

  /// Letras e nomes de segunda a domingo (padrão: os do [SsStrings]).
  final List<String>? letters, names;
  final String? everyDayLabel, weekdaysLabel, weekendLabel, label;

  static const everyDay = {1, 2, 3, 4, 5, 6, 7};
  static const weekdays = {1, 2, 3, 4, 5};
  static const weekend = {6, 7};

  /// Ordem das bolinhas a partir de [firstDay].
  static List<int> order(int firstDay) => [for (var i = 0; i < 7; i++) (firstDay - 1 + i) % 7 + 1];

  static bool _igual(Set<int> a, Set<int> b) => a.length == b.length && a.containsAll(b);

  void _troca(int d) {
    final n = {...value};
    if (!n.remove(d)) n.add(d);
    onChanged?.call(n);
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final on = onChanged != null;
    final dias = order(firstDay);
    final s = SsStrings.of(context);
    // weekdayInitials começa no domingo; aqui a lista vai de segunda a domingo.
    final letters = this.letters ?? [...s.weekdayInitials.skip(1), s.weekdayInitials.first];
    final names = this.names ?? [for (final n in s.weekdaysLong) n.isEmpty ? n : n[0].toUpperCase() + n.substring(1)];
    return Semantics(
      container: true,
      label: label ?? s.weekdayPickerLabel,
      child: Opacity(
        opacity: on ? 1 : .5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                for (final d in dias)
                  Expanded(
                    child: _Dia(
                      letra: letters[d - 1],
                      nome: names[d - 1],
                      marcado: value.contains(d),
                      onTap: on ? () => _troca(d) : null,
                    ),
                  ),
              ],
            ),
            if (shortcuts) ...[
              SizedBox(height: SsDensity.of(context).space(10)),
              Wrap(
                spacing: SsDensity.of(context).space(8),
                runSpacing: SsDensity.of(context).space(8),
                alignment: WrapAlignment.center,
                children: [
                  for (final (t, grupo) in [
                    (everyDayLabel ?? s.everyDay, everyDay),
                    (weekdaysLabel ?? s.weekdaysOnly, weekdays),
                    (weekendLabel ?? s.weekend, weekend),
                  ])
                    _Atalho(
                      texto: t,
                      marcado: _igual(value, grupo),
                      onTap: on ? () => onChanged!({...grupo}) : null,
                      cor: c,
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Dia extends StatelessWidget {
  const _Dia({required this.letra, required this.nome, required this.marcado, required this.onTap});
  final String letra, nome;
  final bool marcado;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final d = SsDensity.of(context);
    final reduce = reduceMotion(context);
    return Semantics(
      checked: marcado,
      enabled: onTap != null,
      label: nome,
      excludeSemantics: true,
      onTap: onTap,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap == null
            ? null
            : () {
                SsHaptics.tick();
                onTap!();
              },
        child: SizedBox(
          // Faixa de toque 48 / 52 / 56 e bolinha 36 / 42 / 46.
          height: d.target(d.iconTile + 10),
          child: Center(
            child: AnimatedScale(
              scale: marcado ? 1 : .9,
              duration: reduce ? Duration.zero : SsMotion.indicator,
              curve: SsMotion.pop,
              child: AnimatedContainer(
                duration: reduce ? Duration.zero : SsMotion.fast,
                width: d.iconTile,
                height: d.iconTile,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: marcado ? c.accent : c.field,
                  border: Border.all(color: marcado ? c.accent : c.line),
                  boxShadow: marcado ? c.primaryShadow : null,
                ),
                child: Text(
                  letra,
                  style: TextStyle(
                    color: marcado ? Colors.white : c.ink2,
                    fontWeight: FontWeight.w800,
                    fontSize: d.font(AppType.set),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Atalho extends StatelessWidget {
  const _Atalho({required this.texto, required this.marcado, required this.onTap, required this.cor});
  final String texto;
  final bool marcado;
  final VoidCallback? onTap;
  final SsColors cor;

  @override
  Widget build(BuildContext context) {
    final c = cor;
    final d = SsDensity.of(context);
    // Chip de 30 / 34 / 38 (era 48 de desenho); o toque continua com 48.
    return SsTapTarget(
      child: Semantics(
        button: true,
        selected: marcado,
        label: texto,
        excludeSemantics: true,
        child: SsPressable(scale: .94, enabled: onTap != null, onTap: onTap, child: _corpo(context, c, d)),
      ),
    );
  }

  Widget _corpo(BuildContext context, SsColors c, SsDensity d) {
    return AnimatedContainer(
      duration: reduceMotion(context) ? Duration.zero : SsMotion.fast,
      constraints: BoxConstraints(minHeight: d.chipHeight),
      padding: EdgeInsets.symmetric(horizontal: d.padX - 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.pill),
        color: marcado ? c.accentSoft : c.surface,
        border: Border.all(color: marcado ? c.accent.withValues(alpha: .5) : c.line),
      ),
      child: Align(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          texto,
          style: TextStyle(
            color: marcado ? c.accentText : c.ink2,
            fontWeight: FontWeight.w700,
            fontSize: d.font(AppType.meta),
          ),
        ),
      ),
    );
  }
}
