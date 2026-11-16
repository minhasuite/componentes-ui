// v0.24: auditoria de UX de novembro (minhas-vendas e meu-gestor). Peça nova
// ([catalogoV24]: ss-ai-insight-card) e o que mudou nas existentes ([comV24]).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final catalogoV24 = <Componente>[
  Componente(
    'ss-ai-insight-card',
    'SsAiInsightCard',
    'Insight da IA num cartão (v0.24, par do Ss::AiInsightCardComponent): selo IA, título, texto, fontes recolhíveis, '
        'Aplicar/Ignorar e a espera da IA dentro do cartão, com Cancelar, sem cobrir a tela.',
    comportamentos: [
      'thinking: true troca o conteúdo pela espera: roda, thinkingText ("Analisando seus dados…"), thinkingHint '
          '("Pode continuar usando a tela.") e linhas-fantasma; a tela continua livre (não use ssRunBlocking para isso).',
      'Depois de showElapsedAfter (5 s) os segundos aparecem ao lado do texto; o texto é região viva para o leitor de tela.',
      'onCancel põe "Cancelar" na espera (o app cancela a chamada, ex. o CancelToken).',
      'confidence e whenText ao lado do selo; sources recolhidas em "De onde vem isso (n)"; onApply/onDismiss viram os botões.',
    ],
    estados: [
      Estado(
        'pronto',
        'insight com fontes e ações',
        (_) => _pad(
          const SsAiInsightCard(
            title: 'Gasto com mercado subiu 18%',
            text: 'Outubro fechou R\$ 1.240 contra R\$ 1.050 em setembro, puxado por bebidas.',
            confidence: 'alta',
            whenText: 'hoje, 9:12',
            sources: ['42 lançamentos de outubro', '38 de setembro'],
            onApply: _nada,
            applyLabel: 'Criar meta de R\$ 900',
            onDismiss: _nada,
          ),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'pensando',
        'a IA lendo, com Cancelar',
        (_) =>
            _pad(const SsAiInsightCard(thinking: true, thinkingText: 'A IA está lendo a sugestão.', onCancel: _nada)),
        tamanho: const Size(360, 210),
      ),
    ],
  ),
];

final _cols = [
  const SsDataColumn('Nº', mobile: SsDataSlot.meta),
  const SsDataColumn('Cliente', mobile: SsDataSlot.title),
  const SsDataColumn('Emissão', mobile: SsDataSlot.meta),
  const SsDataColumn('Situação', mobile: SsDataSlot.badge),
  const SsDataColumn('Total', numeric: true, mobile: SsDataSlot.value),
];

SsDataRow _pedido(String n, String cli, String data, String sit, SsBadgeVariant v, String total) =>
    SsDataRow([Text(n), Text(cli), Text(data), SsBadge(sit, variant: v), Text(total)], onTap: _nada);

final Map<String, (List<String>, List<Estado>)> _v24 = {
  'ss-data-table': (
    [
      'v0.24: mobile: SsDataTableMobile.compact troca, no celular, o cartão "RÓTULO valor" por uma linha compacta: título e '
          'valor em cima, meta (separadas por ·) e selo embaixo. SsDataColumn(mobile: SsDataSlot.title|value|meta|badge|hide); '
          'sem papel, a 1ª coluna é o título, a 1ª numérica é o valor e o resto vira meta. Par do DataTableComponent(mobile: :compact).',
    ],
    [
      Estado(
        'linha-compacta',
        'mobile: compact no celular (v0.24)',
        (_) => _pad(
          SsDataTable(
            mobile: SsDataTableMobile.compact,
            columns: _cols,
            rows: [
              _pedido('#2904', 'Sabor Caseiro Restaurante', '14/11', 'Aguarda', SsBadgeVariant.warning, r'R$ 2.380,00'),
              _pedido('#2903', 'Consumidor final', '14/11', 'Entregue', SsBadgeVariant.success, r'R$ 22,87'),
              _pedido('#2902', 'Dani Festas', '13/11', 'Entregue', SsBadgeVariant.success, r'R$ 15,97'),
            ],
            footer: const [Text(''), Text('Total'), Text(''), Text(''), Text(r'R$ 2.418,84')],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
  'ss-button': (
    [
      'v0.24: o botão é um nó próprio de acessibilidade (Semantics container + button + enabled), mesmo dentro de um cartão '
          'que junta a semântica dos filhos.',
    ],
    const <Estado>[],
  ),
  'ss-fab': (
    [
      'v0.24: SsFab.clearance(context) é a folga que a lista reserva no fim para o último item não ficar sob o botão; '
          'safeListPadding(context, fab: true) já soma.',
    ],
    const <Estado>[],
  ),
  'ss-choice-field': (
    [
      'v0.24: abrir a folha solta o foco do campo de texto anterior (fechar não reabre o teclado); o mesmo no SsDateField e no SsTimeField.',
    ],
    const <Estado>[],
  ),
  'ss-menu': (
    [
      'v0.24: tocar fora da busca (uma linha, a barra de abas) solta o foco dela; voltar de um item não reabre o teclado.',
    ],
    const <Estado>[],
  ),
};

List<Componente> comV24(List<Componente> base) => [
  for (final c in base)
    if (_v24[c.slug] case (final comp, final est))
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
