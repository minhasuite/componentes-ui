// v0.23: o relógio do pacote fora do SsTimeField ([catalogoV23]: ss-time-picker), par do showSsDatePicker.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

final catalogoV23 = <Componente>[
  Componente(
    'ss-time-picker',
    'showSsTimePicker',
    'O relógio do pacote fora do SsTimeField (v0.23, par do showSsDatePicker): textos do SsStrings, 24 horas e o tema do app.',
    comportamentos: [
      'Título "Escolher hora", Cancelar e Confirmar do SsStrings (pt, en, es).',
      'use24h: true (padrão) mostra 00–23; initialTime padrão é a hora de agora.',
      'Devolve a hora, ou nulo se cancelar. O SsTimeField e o chip de hora do SsDateTimeField passam a usá-lo.',
    ],
    estados: [
      Estado(
        'aberto',
        'relógio às 18:30',
        (_) => MediaQuery(
          data: const MediaQueryData(alwaysUse24HourFormat: true),
          child: TimePickerDialog(
            initialTime: const TimeOfDay(hour: 18, minute: 30),
            helpText: SsStrings.pt.pickTime,
            confirmText: SsStrings.pt.confirm,
            cancelText: SsStrings.pt.cancel,
          ),
        ),
        tamanho: const Size(360, 560),
      ),
    ],
  ),
];
