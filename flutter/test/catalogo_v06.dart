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
    ],
  ),
  Componente(
    'ss-time-field',
    'SsTimeField',
    'Campo só de hora (lembrete, horário de treino), com o horário em DM Mono.',
    comportamentos: [
      'O toque abre o relógio do sistema em 24 h.',
      'Sem valor, mostra o texto de ajuda; clearable põe um × para limpar.',
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
