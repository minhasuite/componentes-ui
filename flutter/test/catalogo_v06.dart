// Entradas do catálogo da v0.6: peças que a migração do meu-personal pediu.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

final catalogoV06 = <Componente>[
  Componente(
    'ss-icon-tile',
    'SsIconTile',
    'Ícone num quadrado (ou círculo) no tom da cor a 14%: o ícone tonal dos itens de lista, cabeçalhos e estados.',
    comportamentos: [
      'Sem cor, usa a da marca; com tone, a cor dada (sucesso, aviso, neutro).',
      'filled: fundo cheio na cor e ícone claro (concluído).',
      'circle: redondo, para estado vazio e conquista.',
      'v0.10.3 onGradient: branco translúcido com fio claro e ícone branco, para pôr sobre o gradiente (herói, aurora).',
    ],
    estados: [
      Estado(
        'tons',
        'marca, sucesso, aviso e neutro',
        (context) => _pad(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const SsIconTile(Icons.fitness_center),
              const SsIconTile(Icons.check_rounded, tone: AppColors.success),
              const SsIconTile(Icons.local_fire_department_outlined, tone: AppColors.aquecFg),
              SsIconTile(Icons.history, tone: SsColors.of(context).muted),
            ],
          ),
        ),
      ),
      Estado(
        'cheio',
        'concluído (filled) e círculo grande',
        (_) => _pad(
          const Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              SsIconTile(Icons.check_rounded, tone: AppColors.success, filled: true, size: 40),
              SsIconTile(Icons.emoji_events_outlined, circle: true, size: 72),
            ],
          ),
        ),
      ),
      Estado(
        'sobre-gradiente',
        'v0.10.3: onGradient sobre o gradiente da marca',
        (context) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [SsColors.of(context).brandFrom, SsColors.of(context).brandTo]),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              SsIconTile(Icons.bolt_rounded, onGradient: true),
              SsIconTile(Icons.home_outlined, onGradient: true, circle: true),
            ],
          ),
        ),
      ),
    ],
  ),
  Componente(
    'ss-time-field',
    'SsTimeField',
    'Campo só de hora (lembrete, horário de treino), com o horário em DM Mono.',
    comportamentos: [
      'O toque abre o relógio do sistema em 24 h.',
      'Sem valor, mostra o texto de ajuda; clearable põe um × para limpar.',
      'validator: vale dentro de Form e mostra o erro embaixo com borda vermelha; helperText é a dica fixa.',
      'SsFieldLabel e SsFieldHelper são o rótulo e a dica dos campos, públicos para campos próprios.',
    ],
    estados: [
      Estado(
        'vazio',
        'sem horário',
        (_) => _pad(
          SizedBox(
            width: 260,
            child: SsTimeField(label: 'Lembrete', value: null, onChanged: (_) {}),
          ),
        ),
        tamanho: const Size(360, 120),
      ),
      Estado(
        'preenchido',
        '07:30 com ×',
        (_) => _pad(
          SizedBox(
            width: 260,
            child: SsTimeField(
              label: 'Lembrete',
              value: const TimeOfDay(hour: 7, minute: 30),
              clearable: true,
              onChanged: (_) {},
            ),
          ),
        ),
        tamanho: const Size(360, 120),
      ),
      Estado(
        'erro',
        'validator dentro de Form (erro embaixo, borda vermelha)',
        (_) => _pad(const _HoraComErro()),
        tamanho: const Size(360, 160),
      ),
      Estado(
        'dica',
        'helperText',
        (_) => _pad(
          SsTimeField(
            label: 'Lembrete',
            value: const TimeOfDay(hour: 7, minute: 30),
            onChanged: (_) {},
            helperText: 'Todos os dias.',
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  Componente(
    'ss-check-row',
    'SsCheckRow',
    'Linha com caixa de marcar (aceite, lembrar): a linha toda é o alvo do toque.',
    comportamentos: [
      'A marca entra com mola e vibra leve ao tocar.',
      'child no lugar de title para texto com link.',
      'Sem onChanged, fica apagada.',
    ],
    estados: [
      Estado(
        'desmarcado',
        'desmarcado',
        (_) => _pad(
          SizedBox(
            width: 300,
            child: SsCheckRow(title: 'Li e aceito os termos', value: false, onChanged: (_) {}),
          ),
        ),
      ),
      Estado(
        'marcado',
        'marcado com subtítulo',
        (_) => _pad(
          SizedBox(
            width: 300,
            child: SsCheckRow(
              title: 'Usar meu CPF',
              subtitle: 'Só para emitir o recibo.',
              value: true,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    ],
  ),
];

/// SsTimeField num Form já validado (mostra o erro).
class _HoraComErro extends StatefulWidget {
  const _HoraComErro();

  @override
  State<_HoraComErro> createState() => _HoraComErroState();
}

class _HoraComErroState extends State<_HoraComErro> {
  final _form = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _form.currentState?.validate());
  }

  @override
  Widget build(BuildContext context) => Form(
    key: _form,
    child: SsTimeField(
      label: 'Horário',
      value: null,
      onChanged: (_) {},
      validator: (v) => v == null ? 'Escolha o horário' : null,
    ),
  );
}
