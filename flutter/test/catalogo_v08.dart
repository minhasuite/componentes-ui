// Estados e comportamentos da v0.8 (parâmetros pedidos pelas migrações),
// somados às entradas que já existem no catálogo, pelo slug.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Soma [extras] às entradas de [base] com o mesmo slug.
List<Componente> comV08(List<Componente> base) => [
  for (final c in base)
    if (_v08[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
];

final Map<String, (List<String>, List<Estado>)> _v08 = {
  'ss-list-item': (
    [
      'trailing: widget depois do valor (chevron, menu).',
      'dimmed: item apagado a 50% (concluído, arquivado).',
      'maxLines: título e subtítulo em mais de uma linha; onLongPress para seleção.',
    ],
    [
      Estado(
        'trailing-apagado',
        'com chevron, e outro apagado',
        (_) => _pad(
          const Column(
            children: [
              SsListItem(
                title: 'Mercado do bairro',
                subtitle: 'Hoje · Pix',
                icon: Icons.shopping_cart_outlined,
                value: r'R$ 84,90',
                trailing: Icon(Icons.chevron_right_rounded),
              ),
              SsListItem(
                title: 'Assinatura cancelada',
                subtitle: 'Desde março',
                icon: Icons.block,
                value: r'R$ 29,90',
                dimmed: true,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  'ss-badge': (
    ['icon: ícone antes do texto, na cor do texto.'],
    [
      Estado(
        'com-icone',
        'badge com ícone',
        (_) => _pad(
          const Row(
            spacing: 8,
            children: [
              SsBadge('Pago', variant: SsBadgeVariant.success, icon: Icons.check_rounded),
              SsBadge('Vence hoje', variant: SsBadgeVariant.warning, icon: Icons.schedule),
            ],
          ),
        ),
      ),
    ],
  ),
  'ss-card': (
    ['tint: fundo com 8% da cor dada sobre a superfície (destaque por tom).'],
    [
      Estado(
        'tint',
        'card tingido de sucesso',
        (_) => _pad(const SsCard(tint: AppColors.success, child: Text('Meta do mês batida'))),
      ),
    ],
  ),
  'ss-segmented': (
    ['icons: um ícone por opção; disabled: opções apagadas que não respondem ao toque.'],
    [
      Estado(
        'icone-desabilitado',
        'com ícones e uma opção desabilitada',
        (_) => _pad(
          SsSegmented<int>(
            segments: const [(0, 'Lista'), (1, 'Grade'), (2, 'Mapa')],
            icons: const [Icons.list_rounded, Icons.grid_view_rounded, Icons.map_outlined],
            disabled: const {2},
            value: 0,
            onChanged: (_) {},
          ),
        ),
      ),
    ],
  ),
  'ss-filter-chip': (
    ['icon: ícone antes do texto; quando marcado, dá lugar ao ✓.'],
    [
      Estado(
        'com-icone',
        'com ícone, solto e marcado',
        (_) => _pad(
          Row(
            spacing: 8,
            children: [
              SsFilterChip('Favoritos', icon: Icons.star_outline_rounded, selected: false, onTap: () {}),
              SsFilterChip('Favoritos', icon: Icons.star_outline_rounded, selected: true, onTap: () {}),
            ],
          ),
        ),
      ),
    ],
  ),
  'ss-search-field': (
    [
      'debounce: onChanged só depois que a pessoa para de digitar; limpar dispara na hora.',
      'suffix: widget no fim (filtro, leitor de código).',
    ],
    [
      Estado(
        'suffix',
        'com botão de leitor de código',
        (_) => _pad(
          SsSearchField(
            hint: 'Buscar produto',
            debounce: const Duration(milliseconds: 300),
            suffix: IconButton(onPressed: () {}, icon: const Icon(Icons.qr_code_scanner_rounded)),
          ),
        ),
      ),
    ],
  ),
  'ss-date-field': (
    [
      'initialDate: onde o calendário abre sem valor.',
      'showShortcuts falso: só o chip "Escolher data".',
      'validator: funciona dentro de Form e mostra o erro embaixo.',
    ],
    [
      Estado(
        'sem-atalhos',
        'sem atalhos (nascimento)',
        (_) => _pad(SsDateField(label: 'Nascimento', value: null, onChanged: (_) {}, showShortcuts: false)),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  'ss-switch-row': (
    ['icon: quadrado tonal à esquerda.'],
    [
      Estado(
        'com-icone',
        'com ícone',
        (_) => _pad(
          SsSwitchRow(
            icon: Icons.notifications_outlined,
            title: 'Lembrete diário',
            subtitle: 'Às 20:00',
            value: true,
            onChanged: (_) {},
          ),
        ),
      ),
    ],
  ),
  'ss-progress': (
    ['value nulo: indeterminado (faixa que corre); com movimento reduzido, parada em 1/3.'],
    [Estado('indeterminado', 'enviando, sem saber quanto falta', (_) => _pad(const SsProgress(null)), aguarde: 300)],
  ),
  'ss-countdown-ring': (
    [
      'format: troca o número (SsCountdownRing.mmss para descanso em segundos).',
      'onDark: texto claro e trilha translúcida para fundo escuro ou gradiente.',
    ],
    [
      Estado(
        'descanso-escuro',
        'descanso em mm:ss sobre fundo escuro',
        (_) => Container(
          color: AppColors.headerDarkBg,
          padding: const EdgeInsets.all(16),
          alignment: Alignment.center,
          child: SsCountdownRing(total: 90, left: 75, label: 'descanso', format: SsCountdownRing.mmss, onDark: true),
        ),
        tamanho: const Size(360, 140),
      ),
    ],
  ),
  'ss-empty-state': (
    ['art: arte própria do produto no lugar da ilustração com ícone.'],
    [
      Estado(
        'arte-propria',
        'com arte própria',
        (_) => const SsEmptyState(
          art: SsIconTile(Icons.local_florist_outlined, size: 72, circle: true),
          title: 'Nenhuma planta ainda',
          subtitle: 'Fotografe a primeira para começar.',
          compact: true,
        ),
        tamanho: const Size(360, 230),
      ),
    ],
  ),
  'ss-chat': (
    [
      'SsChatInput: enabled falso trava campo e botão; leading vai antes do campo (anexar).',
      'SsChatInput: maxLength corta no limite e mostra a contagem perto dele (80%); sendTooltip é a dica do botão.',
    ],
    [
      Estado(
        'input-limite',
        'maxLength: contagem perto do limite',
        (_) => SsChatInput(
          controller: TextEditingController(text: 'Liga a luz da sala às 18h e desliga às 23h'),
          onSend: (_) {},
          maxLength: 48,
        ),
        tamanho: const Size(360, 100),
      ),
      Estado(
        'input-anexo-travado',
        'campo travado com botão de anexar',
        (_) => SsChatInput(
          controller: TextEditingController(),
          onSend: (_) {},
          enabled: false,
          hint: 'Sem perguntas este mês',
          leading: IconButton(onPressed: null, icon: const Icon(Icons.attach_file_rounded)),
        ),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  'ss-plan': (
    ['secondaryLabel + onSecondary: o segundo botão vira uma ação ("Apagar um antigo").'],
    [
      Estado(
        'acao-alternativa',
        'limite com ação alternativa',
        (_) => _pad(
          SsPlanLimit(
            title: 'Limite de 3 viagens',
            message: 'No plano grátis cabem 3 viagens ativas.',
            onUpgrade: () {},
            secondaryLabel: 'Arquivar uma antiga',
            onSecondary: () {},
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
  'ss-text-field': (
    ['helperText: dica fixa embaixo (some com erro); minLines: altura mínima em linhas.'],
    [
      Estado(
        'ajuda-varias-linhas',
        'observação com dica e 3 linhas',
        (_) => _pad(
          const SsTextField(
            label: 'Observação',
            hint: 'Opcional',
            maxLines: 5,
            minLines: 3,
            helperText: 'Aparece só para você.',
          ),
        ),
        tamanho: const Size(360, 190),
      ),
    ],
  ),
  'ss-run-blocking': (
    ['onCancel: o cartão ganha "Cancelar"; o app cancela a tarefa e a tela fecha quando ela termina.'],
    [
      Estado(
        'cancelavel',
        'com Cancelar',
        (_) => SsBlockingIndicator(label: 'Lendo o cupom…', onCancel: () {}),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  'ss-overflow-menu': (
    ['icon troca o ⋮; SsMenuAction ganha checked (✓ no fim) e subtitle.'],
    [
      Estado(
        'linhas-marcada',
        'linhas com subtítulo e marcada',
        (_) => _pad(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 14,
            children: [
              SsMenuActionRow(SsMenuAction(Icons.sort_rounded, 'Mais recentes', () {}, checked: true)),
              SsMenuActionRow(
                SsMenuAction(Icons.attach_money, 'Maior valor', () {}, subtitle: 'Do maior para o menor'),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  'ss-onboarding': (['SsOnboardingPage.action: widget embaixo do texto (permitir notificações).'], const []),
};
