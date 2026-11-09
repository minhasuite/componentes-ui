// Entradas do catálogo da v0.12: tile de aparelho com o ícone como chave,
// agenda com a faixa do dia inteiro, cabeçalho de card, card de indicador e
// lista ranqueada (pares do web).
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

const _ambar = AppColors.aquecFg;

Widget _luzes() => _pad(
  Column(
    spacing: 10,
    children: [
      Row(
        spacing: 10,
        children: [
          Expanded(
            child: SsDeviceTile(
              icon: Icons.lightbulb_rounded,
              name: 'Luz da sala',
              state: 'Ligada',
              on: true,
              color: _ambar,
              onTap: _nada,
              onToggle: (_) {},
            ),
          ),
          Expanded(
            child: SsDeviceTile(
              icon: Icons.lightbulb_outline_rounded,
              name: 'Fita de LED da bancada',
              state: 'Desligada',
              color: _ambar,
              onTap: _nada,
              onToggle: (_) {},
            ),
          ),
        ],
      ),
      Row(
        spacing: 10,
        children: [
          Expanded(
            child: SsDeviceTile(
              icon: Icons.lightbulb_rounded,
              name: 'Abajur',
              state: 'Ligado',
              on: true,
              color: _ambar,
              status: SsDeviceStatus.pending,
              onTap: _nada,
              onToggle: (_) {},
            ),
          ),
          Expanded(
            child: SsDeviceTile(
              icon: Icons.lightbulb_outline_rounded,
              name: 'Jardim',
              state: 'Desligado',
              status: SsDeviceStatus.unavailable,
              onTap: _nada,
              onToggle: (_) {},
            ),
          ),
        ],
      ),
      const Row(
        spacing: 10,
        children: [
          Expanded(
            child: SsDeviceTile(
              icon: Icons.garage_outlined,
              name: 'Portão da garagem',
              state: 'Fechado',
              onPress: _nada,
            ),
          ),
          Expanded(
            child: SsDeviceTile(
              icon: Icons.thermostat_rounded,
              name: 'Temperatura',
              state: '24,6 °C',
              status: SsDeviceStatus.locked,
            ),
          ),
        ],
      ),
    ],
  ),
);

Widget _agenda() => _pad(
  SsCard(
    child: SsDayAgenda(
      startHour: 15,
      endHour: 18,
      hourHeight: 44,
      now: const TimeOfDay(hour: 15, minute: 20),
      allDay: const [
        SsAgendaItem(
          title: 'NOTA TÉCNICA S-1.3 Nº 07/2026 - Implantação em produção restrita do novo leiaute do eSocial',
        ),
        SsAgendaItem(title: 'Aniversário da Mariana', detail: 'Pessoal', tone: SsTone.success),
      ],
      events: const [
        SsAgendaEvent(
          start: TimeOfDay(hour: 16, minute: 0),
          end: TimeOfDay(hour: 17, minute: 0),
          title: 'Reunião com fornecedor',
          subtitle: 'Escritório',
        ),
      ],
    ),
  ),
);

Widget _kpis() => _pad(
  Row(
    spacing: 10,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Expanded(
        child: SsKpiCard(
          label: 'Gasto de hoje',
          value: r'R$ 18,42',
          icon: Icons.attach_money_rounded,
          tone: Color(0xFF10B981),
        ),
      ),
      Expanded(
        child: SsKpiCard(
          label: 'Gasto do mês',
          value: r'R$ 312,75',
          icon: Icons.calendar_month_rounded,
          caption: '01/11 a 30/11',
          delta: const SsDelta('4%', up: true, good: false),
          hint: 'vs. outubro',
        ),
      ),
    ],
  ),
);

Widget _ranking() => _pad(
  SsCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SsCardHeader(
          title: 'Consumo por aparelho',
          subtitle: r'Mês · 401,5 kWh · R$ 381,44',
          icon: Icons.bar_chart_rounded,
          tone: _ambar,
        ),
        const SizedBox(height: 12),
        SsRankList(
          tone: _ambar,
          items: const [
            SsRankItem(
              label: 'Ar-condicionado do quarto',
              value: '163,6 kWh',
              amount: 163.6,
              share: '41%',
              caption: r'R$ 155,44',
            ),
            SsRankItem(label: 'Chuveiro', value: '128 kWh', amount: 128, share: '32%', caption: r'R$ 121,59'),
            SsRankItem(label: 'Máquina de lavar', value: '39 kWh', amount: 39, share: '10%'),
            SsRankItem(label: 'Geladeira', value: '28,9 kWh', amount: 28.9, share: '7%'),
          ],
        ),
      ],
    ),
  ),
);

final catalogoV12 = <Componente>[
  Componente(
    'ss-device-tile-v012',
    'SsDeviceTile (v0.12: o ícone é a chave)',
    'Tile numa linha: o quadrado do ícone liga/desliga (onToggle) e o nome e o estado ficam onde era a chave. Mesmo desenho do Ss::DeviceTileComponent do web.',
    comportamentos: [
      'Ícone com chave: interruptor no leitor de tela (toggled, rótulo = nome, dica Ligar/Desligar), Enter/Espaço com foco, alvo de 48 dp e vibração leve.',
      'Ligado: quadrado cheio na cor (color) com brilho; desligado: claro com contorno na cor.',
      'Enviando: anel girando no ícone e a chave travada; indisponível: tracejado e travada; sem permissão: o ícone não é chave e o cadeado vai no fim.',
      'Tocar no resto do tile abre os detalhes (onTap); o modo ação (onPress) não muda.',
    ],
    estados: [
      Estado(
        'luzes',
        'ligada · desligada · enviando · sem sinal · aperto · sem permissão',
        (_) => _luzes(),
        tamanho: const Size(390, 300),
      ),
    ],
  ),
  Componente(
    'ss-day-agenda-all-day',
    'SsDayAgenda(allDay:)',
    'Faixa de compromissos de dia inteiro em cima das horas (v0.12), como o Ss::AgendaComponent do web.',
    comportamentos: [
      '"Dia todo" na coluna da hora; cada compromisso numa linha com reticências, sempre dentro da largura do card.',
      'O título inteiro (com o detalhe) no tooltip (toque longo) e no leitor de tela.',
      'Cor por color, tone ou a paleta da suíte na ordem; onTap faz o item tocável.',
    ],
    estados: [Estado('longo', 'título longo e dois compromissos', (_) => _agenda(), tamanho: const Size(360, 300))],
  ),
  Componente(
    'ss-kpi-card',
    'SsKpiCard',
    'Um número num card com o cabeçalho padrão de card (rótulo como título, linha menor, ícone tonal), valor em DM Mono no tamanho de card, variação e minigráfico opcional. Par do Ss::KpiCardComponent.',
    comportamentos: [
      'O número conta ao entrar na tela e rola quando muda (SsAmount); encolhe em vez de estourar a coluna.',
      'Variação colorida pelo sentido (SsDelta good:), não pelo sinal.',
      'onTap: o card todo afunda e volta com a mola. Leitor de tela: "rótulo, valor, legenda".',
    ],
    estados: [
      Estado('gastos', 'gasto de hoje · gasto do mês com variação', (_) => _kpis(), tamanho: const Size(390, 170)),
    ],
  ),
  Componente(
    'ss-card-header-rank',
    'SsCardHeader · SsRankList',
    'Cabeçalho de card (título 14/800, linha menor, ícone tonal ou trailing) e lista ranqueada com barra proporcional ao maior, valor · fatia e linha menor. Pares do Ss::CardHeaderComponent e Ss::RankListComponent.',
    comportamentos: [
      'O 1º lugar ganha a posição na cor (tone); as barras enchem da esquerda com a mola (paradas com menos movimento).',
      'Nome numa linha com reticências; valor e fatia em DM Mono.',
      'Leitor de tela: "1. nome valor fatia legenda" por item, dentro de uma lista "Ranking" (SsStrings.ranking).',
    ],
    estados: [Estado('consumo', 'consumo por aparelho', (_) => _ranking(), tamanho: const Size(390, 330))],
  ),
];
