// Entradas do catálogo da extras: microinterações que os apps ainda não têm.
import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

var _ponteiro = 900;

/// Navigator próprio: rota e overlay ficam dentro da captura e somem com o estado.
Widget _nav(Widget w) => Navigator(onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => w));

/// Toca no meio do widget de [k], como um dedo.
void _tocar(GlobalKey k) {
  final box = k.currentContext!.findRenderObject() as RenderBox;
  final p = box.localToGlobal(box.size.center(Offset.zero));
  final id = _ponteiro++;
  GestureBinding.instance.handlePointerEvent(PointerDownEvent(pointer: id, position: p));
  GestureBinding.instance.handlePointerEvent(PointerUpEvent(pointer: id, position: p));
}

/// Monta com [de] e troca para [para] logo depois do 1º quadro.
class _Muda extends StatefulWidget {
  const _Muda(this.de, this.para, this.build);
  final String de;
  final String para;
  final Widget Function(String) build;

  @override
  State<_Muda> createState() => _MudaState();
}

class _MudaState extends State<_Muda> {
  late String _v = widget.de;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _v = widget.para);
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(_v);
}

/// Monta [child] (que tem [alvo]) e, depois do 1º quadro, toca nele.
class _Toca extends StatefulWidget {
  const _Toca(this.alvo, this.child);
  final GlobalKey alvo;
  final Widget child;

  @override
  State<_Toca> createState() => _TocaState();
}

class _TocaState extends State<_Toca> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _tocar(widget.alvo);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Abre o menu logo depois do 1º quadro (o toque longo de 500 ms cairia
/// num quadro só da captura, com a animação parada no começo).
class _Abre extends StatefulWidget {
  const _Abre(this.menu, this.child);
  final GlobalKey<SsContextMenuState> menu;
  final Widget child;

  @override
  State<_Abre> createState() => _AbreState();
}

class _AbreState extends State<_Abre> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => widget.menu.currentState?.open());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

Widget _acao(Future<void> Function() f, {bool tocar = true}) {
  final k = GlobalKey();
  final b = SsActionButton(key: k, label: 'Salvar pedido', icon: Icons.save_outlined, onPressed: f);
  return _pad(tocar ? _Toca(k, b) : b);
}

final _comandos = [
  SsCommand(Icons.add_shopping_cart_rounded, 'Novo pedido', keywords: ['venda'], group: 'Ações', onRun: _nada),
  SsCommand(Icons.person_add_alt_rounded, 'Novo cliente', group: 'Ações', onRun: _nada),
  SsCommand(Icons.bar_chart_rounded, 'Relatório de vendas', keywords: ['painel'], group: 'Telas', onRun: _nada),
  SsCommand(
    Icons.receipt_long_rounded,
    'Títulos a receber',
    keywords: ['relatorio', 'cobrança'],
    group: 'Telas',
    onRun: _nada,
  ),
  SsCommand(Icons.settings_outlined, 'Configurações', group: 'Telas', onRun: _nada),
];

Widget _paleta(String q) => Padding(
  padding: const EdgeInsets.all(12),
  child: Align(
    alignment: Alignment.topCenter,
    child: SsCommandPalette(
      commands: _comandos,
      recent: [_comandos[2], _comandos[0]],
      initialQuery: q,
      onSelected: (_) {},
    ),
  ),
);

Widget _linhaCliente(BuildContext context, String nome, String sub, String valor) => Container(
  decoration: BoxDecoration(color: SsColors.of(context).surface, borderRadius: BorderRadius.circular(AppRadius.card)),
  child: SsListItem(leading: SsAvatar(nome), title: nome, subtitle: sub, value: valor),
);

Widget _menu({bool abrir = false}) {
  final k = GlobalKey<SsContextMenuState>();
  return Builder(
    builder: (context) {
      final item = SsContextMenu(
        key: k,
        actions: [
          SsContextAction(Icons.edit_outlined, 'Editar', _nada),
          SsContextAction(Icons.copy_rounded, 'Duplicar pedido', _nada),
          SsContextAction(Icons.share_outlined, 'Compartilhar', _nada),
          SsContextAction(Icons.delete_outline_rounded, 'Excluir', _nada, destructive: true),
        ],
        child: _linhaCliente(context, 'Mercado Bom Preço', 'Asa Sul · pedido #1042', r'R$ 1.250,00'),
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
        child: Column(
          children: [
            _linhaCliente(context, 'Padaria Central', 'Taguatinga', r'R$ 380,00'),
            const SizedBox(height: 10),
            abrir ? _Abre(k, item) : item,
          ],
        ),
      );
    },
  );
}

const _nomes = ['Mercado Bom Preço', 'Padaria Central', 'Açougue do Zé', 'Hortifruti Sol'];

Widget _lista({required bool selecionando}) => Builder(
  builder: (context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      for (var i = 0; i < _nomes.length; i++)
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: SsSelectable(
            selected: selecionando && i != 1 && i != 3,
            selecting: selecionando,
            onToggle: _nada,
            child: SsListItem(leading: SsAvatar(_nomes[i]), title: _nomes[i], subtitle: 'pedido #10${40 + i}'),
          ),
        ),
    ],
  ),
);

Widget _abreCard({bool tocar = false}) {
  final k = GlobalKey();
  final card = SsOpenCard(
    key: k,
    closed: Padding(
      padding: const EdgeInsets.all(16),
      child: Builder(
        builder: (context) => Row(
          children: [
            const SsAvatar('Mercado Bom Preço'),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido #1042',
                    style: TextStyle(fontWeight: FontWeight.w800, color: SsColors.of(context).ink),
                  ),
                  Text('Mercado Bom Preço', style: TextStyle(color: SsColors.of(context).muted)),
                ],
              ),
            ),
            const SsAmount(r'R$ 1.250,00', size: AppType.lg),
          ],
        ),
      ),
    ),
    open: (context) => Scaffold(
      appBar: AppBar(title: const Text('Pedido #1042')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SsAmount(r'R$ 1.250,00'),
          SizedBox(height: 16),
          SsListItem(leading: SsAvatar('Mercado Bom Preço'), title: 'Mercado Bom Preço', subtitle: 'Asa Sul'),
          SsListItem(title: 'Arroz 5 kg × 20', value: r'R$ 520,00'),
          SsListItem(title: 'Feijão 1 kg × 40', value: r'R$ 330,00'),
          SsListItem(title: 'Óleo 900 ml × 50', value: r'R$ 400,00'),
        ],
      ),
    ),
  );
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
    child: Align(alignment: Alignment.topCenter, child: tocar ? _Toca(k, card) : card),
  );
}

/// "Foto" de mentira para o comparador: gradiente com um ícone.
Widget _foto(Color a, Color b, IconData icon, double size) => DecoratedBox(
  decoration: BoxDecoration(
    gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [a, b]),
  ),
  child: Center(
    child: Icon(icon, size: size, color: Colors.white.withValues(alpha: .9)),
  ),
);

Widget _compare(double t) => _pad(
  SizedBox(
    height: 240,
    child: SsCompare(
      initial: t,
      before: _foto(const Color(0xFF8A6A3D), const Color(0xFFC9A46A), Icons.grass_rounded, 54),
      after: _foto(const Color(0xFF1E7A4A), const Color(0xFF58C27D), Icons.local_florist_rounded, 120),
    ),
  ),
);

class _Card {
  const _Card(this.titulo, this.cliente, this.valor);
  final String titulo;
  final String cliente;
  final String valor;
}

Widget _kanban() => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return SsKanban<_Card>(
      columns: [
        SsKanbanColumn(
          id: 'novo',
          title: 'Recebido',
          items: const [
            _Card('Pedido #1042', 'Mercado Bom Preço', r'R$ 1.250,00'),
            _Card('Pedido #1043', 'Padaria Central', r'R$ 380,00'),
            _Card('Pedido #1045', 'Hortifruti Sol', r'R$ 92,40'),
          ],
        ),
        SsKanbanColumn(
          id: 'sep',
          title: 'Em separação',
          color: AppColors.aquecFg,
          items: const [_Card('Pedido #1039', 'Açougue do Zé', r'R$ 2.410,00')],
        ),
        const SsKanbanColumn(id: 'ok', title: 'Entregue', color: AppColors.success, items: <_Card>[]),
      ],
      onMove: (_, _, _, _) {},
      cardBuilder: (context, card) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: c.isDark ? null : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.titulo,
              style: TextStyle(color: c.ink, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              card.cliente,
              style: TextStyle(color: c.muted, fontSize: AppType.sub),
            ),
            const SizedBox(height: 8),
            SsAmount(card.valor, size: AppType.md),
          ],
        ),
      ),
    );
  },
);

/// Chip "+ R$ 42,90" que voa até o total depois do 1º quadro.
class _Voo extends StatefulWidget {
  const _Voo();

  @override
  State<_Voo> createState() => _VooState();
}

class _VooState extends State<_Voo> {
  final _de = GlobalKey();
  final _para = GlobalKey();
  var _total = r'R$ 1.207,10';

  Widget get _chip => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(99)),
    child: const Text(
      r'+ R$ 42,90',
      style: TextStyle(color: AppColors.onDark, fontWeight: FontWeight.w800),
    ),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await ssFlyTo(context, from: _de, to: _para, child: _chip);
      if (mounted) setState(() => _total = r'R$ 1.250,00');
    });
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TOTAL DO PEDIDO',
          style: TextStyle(color: SsColors.of(context).muted, fontSize: AppType.label),
        ),
        SsOdometer(_total, key: _para),
        const Spacer(),
        Align(
          alignment: Alignment.centerRight,
          child: KeyedSubtree(key: _de, child: _chip),
        ),
      ],
    ),
  );
}

final catalogoExtras = <Componente>[
  Componente(
    'ss-odometer',
    'SsOdometer',
    'Número em DM Mono com centavos menores (como o SsAmount) em que só os dígitos que mudam rolam. A microinteração-assinatura de número da suíte.',
    comportamentos: [
      'Cada dígito é uma coluna 0–9 que desliza com mola (560 ms, passa um pouco e volta) até o dígito novo.',
      'Sobe quando o valor aumentou e desce quando caiu; 9 → 0 subindo dá a volta pela coluna.',
      'Vírgula, ponto e "R\$" ficam parados; casa nova à esquerda (999 → 1.000) entra com fade.',
      'Troca no meio da rolagem continua de onde a coluna está.',
      'Leitor de tela lê o texto inteiro (região viva); sem animação quando o sistema pede menos movimento.',
    ],
    estados: [
      Estado('parado', 'R\$ 1.234,56', (_) => _pad(const SsOdometer(r'R$ 1.234,56'))),
      Estado(
        'subindo',
        'aumentou: dígitos rolando para cima',
        (_) => _pad(_Muda(r'R$ 1.234,56', r'R$ 1.289,90', SsOdometer.new)),
        aguarde: 170,
      ),
      Estado(
        'descendo',
        'caiu: dígitos rolando para baixo',
        (_) => _pad(_Muda(r'R$ 1.289,90', r'R$ 1.234,56', SsOdometer.new)),
        aguarde: 170,
      ),
      Estado(
        'casa-nova',
        'R\$ 998 → R\$ 1.004: a casa do milhar entra com fade',
        (_) => _pad(_Muda(r'R$ 998,00', r'R$ 1.004,50', SsOdometer.new)),
        aguarde: 140,
      ),
    ],
  ),
  Componente(
    'ss-action-button',
    'SsActionButton',
    'SsButton que roda uma ação assíncrona e mostra o resultado no próprio botão.',
    comportamentos: [
      'Toque: spinner enquanto a ação roda (sem segundo toque).',
      'Deu certo: vira ✓ "Pronto" em verde com uma pequena mola e haptic; volta ao normal em 1,4 s.',
      'Deu erro (a ação lançou): o botão sacode, haptic forte e volta ao normal; o aviso é de quem chamou.',
      'Leitor de tela anuncia a troca (região viva); com menos movimento, sem sacudir nem mola.',
    ],
    estados: [
      Estado('normal', 'pronto para tocar', (_) => _acao(() async {}, tocar: false)),
      Estado('carregando', 'rodando a ação', (_) => _acao(() => Completer<void>().future), aguarde: 300),
      Estado('pronto', 'deu certo', (_) => _acao(() async {}), aguarde: 500),
      Estado('erro', 'deu erro: sacudindo', (_) => _acao(() async => throw Exception('falhou')), aguarde: 90),
    ],
  ),
  Componente(
    'ss-command-palette',
    'showSsCommandPalette',
    'Busca global de ações e telas num diálogo de topo (SsCommandPalette é o painel).',
    comportamentos: [
      'Entra deslizando de cima com mola; o campo já vem com o teclado aberto.',
      'Filtra por rótulo e palavras-chave sem ligar para acento ou maiúscula ("relatorio" acha "Relatório").',
      'Vários termos: todos precisam casar. Quem casa no rótulo vem antes de quem só casa nas palavras-chave.',
      'Agrupa por grupo, destaca em negrito o trecho que casou e marca o 1º resultado (é o que o Enter executa).',
      'Toque ou Enter executa e fecha. Sem busca, mostra os recentes (ou tudo, se não houver).',
    ],
    estados: [
      Estado('recentes', 'sem busca: recentes', (_) => _paleta(''), tamanho: const Size(360, 300)),
      Estado('buscando', 'buscando "relat"', (_) => _paleta('relat'), tamanho: const Size(360, 340)),
      Estado('vazio', 'nada encontrado', (_) => _paleta('xyz'), tamanho: const Size(360, 200)),
    ],
  ),
  Componente(
    'ss-context-menu',
    'SsContextMenu',
    'Menu de contexto no toque longo, com o item levantado sobre o fundo escurecido.',
    comportamentos: [
      'Toque longo: haptic, o item levanta (escala 1,03 com mola e sombra) e o fundo escurece (sem blur).',
      'A lista de ações aparece ancorada abaixo do item, ou acima se não couber, crescendo a partir dele.',
      'Ação destrutiva em vermelho; tocar numa ação fecha e executa; tocar fora fecha.',
      'preview opcional troca o item levantado por uma prévia compacta.',
      'Leitor de tela: as ações viram ações personalizadas do item, sem toque longo.',
    ],
    estados: [
      Estado('fechado', 'item na lista', (_) => _nav(_menu()), tamanho: const Size(360, 230)),
      Estado(
        'aberto',
        'toque longo: item levantado e ações',
        (_) => _nav(_menu(abrir: true)),
        tamanho: const Size(360, 430),
        aguarde: 1000,
      ),
    ],
  ),
  Componente(
    'ss-selection-bar',
    'SsSelectionBar',
    'Barra da seleção múltipla: contagem, ações em ícone e o X para limpar.',
    comportamentos: [
      'Sobe de baixo com mola quando há seleção e desce quando zera (mostrando o último número ao sair).',
      'O número rola (SsOdometer) a cada item marcado ou desmarcado; "1 selecionado" / "3 selecionados".',
      'Ações com dica (tooltip) e rótulo para leitor de tela; destrutiva em vermelho.',
    ],
    estados: [
      for (final n in [1, 3])
        Estado(
          '$n',
          '$n ${n == 1 ? 'selecionado' : 'selecionados'}',
          (_) => Align(
            alignment: Alignment.bottomCenter,
            child: SsSelectionBar(
              count: n,
              onClear: _nada,
              actions: [
                SsContextAction(Icons.share_outlined, 'Compartilhar', _nada),
                SsContextAction(Icons.archive_outlined, 'Arquivar', _nada),
                SsContextAction(Icons.delete_outline_rounded, 'Excluir', _nada, destructive: true),
              ],
            ),
          ),
          tamanho: const Size(360, 110),
        ),
    ],
  ),
  Componente(
    'ss-selectable',
    'SsSelectable',
    'Envolve um item de lista para a seleção múltipla.',
    comportamentos: [
      'Toque longo entra na seleção (haptic) e marca o item.',
      'Selecionando: o círculo de ✓ entra com mola à esquerda e o toque marca/desmarca (não abre o item).',
      'Selecionado ganha fundo tonal da marca; leitor de tela diz "selecionado".',
    ],
    estados: [
      Estado('normal', 'fora da seleção', (_) => _lista(selecionando: false), tamanho: const Size(360, 300)),
      Estado(
        'selecionando',
        'selecionando: 2 marcados',
        (_) => _lista(selecionando: true),
        tamanho: const Size(360, 300),
      ),
    ],
  ),
  Componente(
    'ss-open-card',
    'SsOpenCard',
    'Card que se abre na tela de detalhe (container transform) e volta para o card ao fechar.',
    comportamentos: [
      'Toque: o retângulo do card cresce até a tela (460 ms), o raio vai de 18 a 0 e o fundo escurece.',
      'O conteúdo do card some no começo e o da tela entra em crossfade, escalado pela largura.',
      'Voltar (botão ou gesto) faz o caminho inverso até o lugar do card; o card original fica escondido enquanto isso.',
      'Com menos movimento, só fade.',
    ],
    estados: [
      Estado('fechado', 'card na lista', (_) => _nav(_abreCard()), tamanho: const Size(360, 640)),
      Estado(
        'abrindo',
        'no meio da transformação',
        (_) => _nav(_abreCard(tocar: true)),
        tamanho: const Size(360, 640),
        aguarde: 190,
      ),
      Estado(
        'aberto',
        'tela de detalhe',
        (_) => _nav(_abreCard(tocar: true)),
        tamanho: const Size(360, 640),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-compare',
    'SsCompare',
    'Comparador antes/depois com alça arrastável (foto da planta, do treino).',
    comportamentos: [
      'Arraste a alça (linha + bolinha com setas) ou toque em qualquer ponto para mover a divisão.',
      'Rótulos "Antes" e "Depois" nos cantos, legíveis sobre qualquer foto.',
      'Leitor de tela: slider "Comparar Antes e Depois", 50%, que sobe e desce de 10 em 10.',
    ],
    estados: [
      Estado('meio', 'divisão no meio', (_) => _compare(.5), tamanho: const Size(360, 272)),
      Estado('trinta', 'divisão em 30%', (_) => _compare(.3), tamanho: const Size(360, 272)),
    ],
  ),
  Componente(
    'ss-kanban',
    'SsKanban',
    'Quadro kanban com colunas lado a lado e cards arrastáveis entre elas.',
    comportamentos: [
      'Colunas de 280 px; a rolagem horizontal para no começo de cada coluna.',
      'Cabeçalho com bolinha de cor, título e a contagem em DM Mono.',
      'Toque longo no card: haptic, o card levanta (escala 1,03, sombra) e inclina 2°; no lugar fica um fantasma.',
      'A coluna alvo destaca na cor da marca e o lugar do drop aparece como espaço tracejado.',
      'Perto da borda o quadro rola sozinho; soltar chama onMove(item, de, para, índice).',
    ],
    estados: [Estado('quadro', 'três colunas', (_) => _kanban(), tamanho: const Size(360, 420))],
  ),
  Componente(
    'ss-fly-to',
    'ssFlyTo',
    'Microinteração "valor que voa até o total": o clone de um chip voa num arco até o total.',
    comportamentos: [
      'O clone sai do chip e voa num arco (sobe e cai) até o total em 550 ms, encolhendo e sumindo no fim.',
      'Haptic leve ao chegar; quem chama atualiza o total no fim (o SsOdometer rola).',
      'Com menos movimento, ou se uma das chaves não estiver na tela, volta na hora.',
    ],
    estados: [
      Estado('voando', 'no meio do voo', (_) => _nav(const _Voo()), tamanho: const Size(360, 300), aguarde: 260),
      Estado('chegou', 'chegou: o total rola', (_) => _nav(const _Voo()), tamanho: const Size(360, 300), aguarde: 700),
    ],
  ),
];
