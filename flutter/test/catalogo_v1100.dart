// v1.10.0 ([comV1100]): os pares Flutter das peças que só existiam no web: cartão de produto, barra e folha
// de filtros, tarefa longa, árvore e balão ancorado. Os pares web das peças do Flutter estão no
// rails/catalogo/index.html.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// A arte do produto da vitrine: um vaso na cor da marca (sem imagem da rede no teste).
class _Vaso extends StatelessWidget {
  const _Vaso(this.icon);
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return AspectRatio(
      aspectRatio: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [c.brandFrom, c.brandTo],
          ),
          boxShadow: c.tintedShadow(c.accent),
        ),
        child: FractionallySizedBox(
          widthFactor: .5,
          heightFactor: .5,
          child: FittedBox(child: Icon(icon, color: AppColors.onDark)),
        ),
      ),
    );
  }
}

const _filtros = [
  SsFilterGroup(
    param: 'status',
    label: 'Situação',
    options: [
      SsFilterOption('Pago', 'pago'),
      SsFilterOption('Vencido', 'vencido'),
      SsFilterOption('A vencer', 'aberto'),
    ],
  ),
  SsFilterGroup(
    param: 'tag',
    label: 'Etiqueta',
    multiple: true,
    options: [
      SsFilterOption('Atacado', 'atacado'),
      SsFilterOption('Varejo', 'varejo'),
      SsFilterOption('Recorrente', 'recorrente'),
      SsFilterOption('Novo cliente', 'novo'),
    ],
  ),
];

int _conta(SsFilterValues v) => 48 - 9 * SsFilters.count(_filtros, v);

/// A barra que guarda os filtros (a vitrine mexe de verdade).
class _Barra extends StatefulWidget {
  const _Barra(this.inicio);
  final SsFilterValues inicio;

  @override
  State<_Barra> createState() => _BarraState();
}

class _BarraState extends State<_Barra> {
  late SsFilterValues v = widget.inicio;

  @override
  Widget build(BuildContext context) => SsFilterBar(
    filters: _filtros,
    values: v,
    onChanged: (n) => setState(() => v = n),
    count: _conta,
    views: const [
      SsFilterView('Todos'),
      SsFilterView(
        'Vencidos',
        values: {
          'status': ['vencido'],
        },
        count: 6,
      ),
      SsFilterView(
        'Atacado',
        values: {
          'tag': ['atacado'],
        },
      ),
    ],
  );
}

/// A folha desenhada no lugar (a captura não pega a rota de cima).
Widget _folha(SsFilterValues v) => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return ColoredBox(
      color: c.page,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: c.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
          clipBehavior: Clip.antiAlias,
          child: SsFilterSheet(filters: _filtros, values: v, count: _conta, onApply: (_) {}),
        ),
      ),
    );
  },
);

/// O balão aberto: um Navigator dentro da captura para a rota do balão sair na imagem.
class _BalaoAberto extends StatelessWidget {
  const _BalaoAberto();

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const Align(
        alignment: Alignment.topLeft,
        child: Padding(padding: EdgeInsets.all(16), child: _Abre()),
      ),
    ),
  );
}

class _Abre extends StatefulWidget {
  const _Abre();

  @override
  State<_Abre> createState() => _AbreState();
}

class _AbreState extends State<_Abre> {
  VoidCallback? _abrir;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _abrir?.call());
  }

  @override
  Widget build(BuildContext context) => SsPopover(
    label: 'Como calculamos',
    title: 'Ticket médio',
    triggerBuilder: (ctx, abrir) {
      _abrir = abrir;
      return SsButton.ghost(label: 'Como calculamos', small: true, expand: false, onPressed: abrir);
    },
    child: const Text('Soma das vendas do mês dividida pelo número de pedidos fechados. Devolução não entra.'),
  );
}

class _BalaoIcone extends StatelessWidget {
  const _BalaoIcone();

  @override
  Widget build(BuildContext context) => Navigator(
    onGenerateRoute: (_) => PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => const Align(
        alignment: Alignment.topRight,
        child: Padding(padding: EdgeInsets.all(16), child: _AbreIcone()),
      ),
    ),
  );
}

class _AbreIcone extends StatefulWidget {
  const _AbreIcone();

  @override
  State<_AbreIcone> createState() => _AbreIconeState();
}

class _AbreIconeState extends State<_AbreIcone> {
  final _k = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => showSsPopover<void>(
        _k.currentContext!,
        placement: SsPopoverPlacement.bottomEnd,
        label: 'Mais ações',
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SsButton.text(label: 'Duplicar', icon: Icons.copy_rounded, onPressed: _nada),
            SsButton.text(label: 'Arquivar', icon: Icons.archive_outlined, onPressed: _nada),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) =>
      SsIconButton(key: _k, icon: Icons.more_vert_rounded, tooltip: 'Mais ações', onPressed: _nada);
}

const _arvore = [
  SsTreeNode(
    'Receitas',
    count: 3,
    value: r'R$ 12.400,00',
    open: true,
    children: [
      SsTreeNode('Vendas', value: r'R$ 9.000,00'),
      SsTreeNode('Serviços', value: r'R$ 2.900,00'),
      SsTreeNode('Juros recebidos', value: r'R$ 500,00'),
    ],
  ),
  SsTreeNode(
    'Despesas',
    count: 2,
    value: r'R$ 7.180,00',
    children: [
      SsTreeNode('Aluguel', value: r'R$ 4.000,00'),
      SsTreeNode('Folha', value: r'R$ 3.180,00'),
    ],
  ),
];

const _categorias = [
  SsTreeNode(
    'Casa',
    id: 'casa',
    open: true,
    children: [
      SsTreeNode('Luz', id: 'luz'),
      SsTreeNode('Água', id: 'agua'),
      SsTreeNode('Internet', id: 'internet'),
    ],
  ),
  SsTreeNode(
    'Transporte',
    id: 'transporte',
    open: true,
    children: [
      SsTreeNode('Combustível', id: 'comb'),
      SsTreeNode('Aplicativo', id: 'app'),
    ],
  ),
];

List<Componente> comV1100(List<Componente> base) => [...base, ..._v1100];

final _v1100 = <Componente>[
  Componente(
    'ss-product-card',
    'SsProductCard',
    'Cartão de produto com a imagem vazando acima do card (v1.10, par do Ss::ProductCardComponent): nome, texto, preço e o botão de ação.',
    comportamentos: const [
      'A imagem ocupa 72% da largura e sobe 64 acima do card (overhang:); numa grade, deixe esse espaço em cima.',
      'image: troca o imageUrl: por um widget próprio; sem nenhum, um ícone de produto apagado.',
      'Tocar no card (onTap:) e no botão da ação são alvos separados, os dois de 48 no mínimo; o card afunda de leve e volta com mola.',
      'Leitor de tela: o nome é título; a ação lê "Adicionar: Costela-de-adão". Ação com onPressed nulo fica cinza e desligada.',
      'badge: o selo no canto ("Novo", "-20%").',
    ],
    estados: [
      Estado(
        'grade',
        'dois produtos, com selo e ação',
        (_) => _pad(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SsProductCard(
                  name: 'Costela-de-adão',
                  text: 'Meia-sombra, rega 2× por semana',
                  price: r'R$ 89,90',
                  image: const _Vaso(Icons.local_florist_rounded),
                  badge: 'Novo',
                  onTap: _nada,
                  action: const SsProductAction('Adicionar', _nada),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: SsProductCard(
                  name: 'Jiboia',
                  text: 'Pendente, luz indireta',
                  price: r'R$ 34,50',
                  image: const _Vaso(Icons.eco_rounded),
                  onTap: _nada,
                  action: const SsProductAction('Adicionar', null),
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
  Componente(
    'ss-filter-bar',
    'SsFilterBar',
    'Barra de filtros (v1.10, par do Ss::FilterBarComponent): visões salvas, o botão Filtros com o número de ativos, os chips do que está ativo e limpar.',
    comportamentos: const [
      'O botão "Filtros" abre a SsFilterSheet (showSsFilterSheet); ao aplicar, onChanged recebe os novos valores.',
      'Com filtro ativo, o botão fica na cor da marca com o número; o leitor de tela ouve "Filtros, 2 ativos".',
      'Cada valor ativo é um chip; o × tira só aquele valor ("Tirar o filtro Situação: Vencido"). "Limpar filtros" tira todos.',
      'views: chips das visões salvas, marcada a que bate com os filtros atuais (sem ligar para a ordem). onSearch: o campo de busca.',
      'Os valores são parâmetro → lista (o status=pago e o tag[]=a do web); quem guarda é o app.',
    ],
    estados: [
      Estado(
        'ativos',
        'dois filtros ativos',
        (_) => _pad(
          const _Barra({
            'status': ['vencido'],
            'tag': ['atacado'],
          }),
        ),
      ),
      Estado('vazia', 'nenhum filtro', (_) => _pad(const _Barra({}))),
    ].map((e) => Estado(e.slug, e.titulo, e.build, tamanho: const Size(360, 180))).toList(),
  ),
  Componente(
    'ss-filter-sheet',
    'SsFilterSheet',
    'Folha de filtros com "Mostrar N resultados" ao vivo (v1.10, par do Ss::FilterBarComponent).',
    comportamentos: const [
      'Cada filtro mostra as opções em chips; no simples, tocar troca (ou tira); no múltiplo (multiple: true), soma.',
      'count: conta o rascunho a cada toque ("Mostrar 12 resultados", "Nenhum resultado"); assíncrono, mantém o número anterior até chegar e ignora a resposta velha.',
      'Os chips do topo são o que está ativo no rascunho (o × tira); entram e saem com animação (reduzir movimento: direto).',
      '"Limpar filtros" esvazia o rascunho (desligado sem nada ativo); o botão fica fixo embaixo e as opções rolam.',
      'Só aplica no botão: fechar a folha (tocar fora, voltar) descarta o rascunho.',
    ],
    estados: [
      Estado(
        'rascunho',
        'dois ativos, 30 resultados',
        (_) => _folha(const {
          'status': ['vencido'],
          'tag': ['atacado'],
        }),
      ),
      Estado('vazio', 'sem filtro, 48 resultados', (_) => _folha(const {})),
    ].map((e) => Estado(e.slug, e.titulo, e.build, tamanho: const Size(360, 470))).toList(),
  ),
  Componente(
    'ss-job-progress',
    'SsJobProgress',
    'Tarefa longa (v1.10, par do Ss::JobProgressComponent): na fila, rodando n%, concluída com o resultado ou falhou com o motivo.',
    comportamentos: const [
      'state: queued | running | done | failed; a pílula de situação é região viva (o leitor de tela ouve a troca).',
      'progress: 0 a 1 (nulo: a barra corre sem número; reduzir movimento: parada). Na fila, a barra fica apagada; concluída, verde.',
      'steps: + currentStep: ✓ nos feitos, o atual girando, o que falhou em vermelho.',
      'stages: etapas com tempo ("820 ms", "1,2 s", "1 min 5 s") e o total; com etapas e a tarefa terminada, a barra sai.',
      'onCancel: "Cancelar" na fila ou rodando (cancelling: "Cancelando…", desligado). Concluída: onOpenResult; falhou: onRetry ("Tentar de novo").',
    ],
    estados: [
      Estado(
        'rodando',
        'rodando 40%, passo 2 de 3, cancelar',
        (_) => _pad(
          const SsJobProgress(
            title: 'Importar clientes',
            state: SsJobState.running,
            progress: .4,
            steps: ['Ler arquivo', 'Validar', 'Gravar'],
            currentStep: 1,
            detail: '412 de 1.030 linhas',
            onCancel: _nada,
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'fila',
        'na fila',
        (_) => _pad(const SsJobProgress(title: 'Relatório de vendas', onCancel: _nada)),
        tamanho: const Size(360, 180),
      ),
      Estado(
        'etapas',
        'concluído, com etapas e o total',
        (_) => _pad(
          const SsJobProgress(
            title: 'Comando de voz',
            state: SsJobState.done,
            stages: [
              SsJobStage('Ouvir', duration: Duration(milliseconds: 820)),
              SsJobStage('Entender', duration: Duration(milliseconds: 1240)),
              SsJobStage('Executar', status: SsJobStageStatus.skipped, detail: 'Nada a fazer'),
            ],
            onOpenResult: _nada,
          ),
        ),
        tamanho: const Size(360, 320),
      ),
      Estado(
        'falhou',
        'falhou no passo 2, tentar de novo',
        (_) => _pad(
          const SsJobProgress(
            title: 'Importar clientes',
            state: SsJobState.failed,
            steps: ['Ler arquivo', 'Validar', 'Gravar'],
            currentStep: 1,
            error: 'A coluna CNPJ está vazia em 12 linhas.',
            onRetry: _nada,
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-tree-view',
    'SsTreeView',
    'Árvore de categorias ou plano de contas (v1.10, par do Ss::TreeViewComponent): expandir, recolher e escolher.',
    comportamentos: const [
      'Tocar no galho abre e recolhe: a seta gira com mola e os filhos descem (reduzir movimento: na hora). open: começa aberto.',
      'Recuo com o fio à esquerda; contagem em pílula e valor em DM Mono (some com a privacidade ligada).',
      'selection: none (folha com onTap abre o detalhe), single (marca a folha tocada, fundo da marca e ✓) ou multiple (caixa em cada nó).',
      'No multiple, a caixa do galho marca ou desmarca as folhas de baixo e fica "misturada" com só parte marcada.',
      'Leitor de tela: "Receitas, 3 itens, R\$ 12.400,00", aberto/fechado e a dica "Recolher"/"Expandir"; cada linha tem 48 de altura.',
    ],
    estados: [
      Estado(
        'contas',
        'plano de contas, um galho aberto',
        (_) => _pad(const SsTreeView(label: 'Plano de contas', nodes: _arvore)),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'multipla',
        'escolha múltipla, um galho parcial',
        (_) => _pad(
          SsTreeView(
            label: 'Categorias',
            nodes: _categorias,
            selection: SsTreeSelection.multiple,
            selected: const {'luz', 'agua', 'internet', 'comb'},
            onSelectionChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 380),
      ),
    ],
  ),
  Componente(
    'ss-popover',
    'SsPopover',
    'Balão ancorado com seta (v1.10, par do Ss::PopoverComponent): detalhe curto ou menu de ações perto do botão.',
    comportamentos: const [
      'Abre abaixo do botão, alinhado pelo começo (placement: bottomStart | bottomEnd | topStart); sem espaço embaixo, vira para cima.',
      'A seta aponta para o centro do botão; o balão não passa de 352 nem sai da tela (12 de margem).',
      'Fecha ao tocar fora, no voltar do Android e no Esc; SsPopover.close(context) fecha de dentro.',
      'Entra crescendo do lado da seta com mola (reduzir movimento: aparece direto). O leitor de tela entra no balão com o nome do title:.',
      'Gatilho: botão discreto com o label: (padrão), icon: (o label vira a dica) ou triggerBuilder:. showSsPopover abre por código.',
    ],
    estados: [
      Estado(
        'aberto',
        'aberto abaixo do botão',
        (_) => const _BalaoAberto(),
        tamanho: const Size(360, 220),
        aguarde: 600,
      ),
      Estado(
        'menu',
        'menu ⋮ alinhado pelo fim',
        (_) => const _BalaoIcone(),
        tamanho: const Size(360, 220),
        aguarde: 600,
      ),
    ],
  ),
];
