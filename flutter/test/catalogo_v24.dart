// v0.24: o sino de avisos da barra de cima ([catalogoV24]: ss-notification-bell), par do Ss::NotificationBellComponent.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

final catalogoV24 = <Componente>[
  Componente(
    'ss-notification-bell',
    'SsNotificationBell',
    'Sino de avisos da barra de cima (v0.24, par do Ss::NotificationBellComponent): o SsIconButton com o número de não lidos.',
    comportamentos: [
      'count: 0 tira o selo; acima de 99 mostra "99+".',
      'Dica e leitor de tela: "Avisos, 3 não lidos" (label: e unreadLabel: trocam o texto).',
      'onPressed: é do app (folha com os últimos avisos ou a central).',
    ],
    estados: [
      Estado(
        'lidos',
        'sem não lidos',
        (_) => SsNotificationBell(count: 0, onPressed: () {}),
        tamanho: const Size(64, 64),
      ),
      Estado(
        'novos',
        'com 3 não lidos',
        (_) => SsNotificationBell(count: 3, onPressed: () {}),
        tamanho: const Size(64, 64),
      ),
    ],
  ),
];
