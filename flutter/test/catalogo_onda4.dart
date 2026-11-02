// Entradas do catálogo da onda4.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);
const _tela = Size(360, 780);

Widget _cabecalho({double rolado = 0, bool voltar = false}) => SsScreenHeader(
  title: 'Lançamentos',
  leading: voltar ? const SsHeaderAction(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: _nada) : null,
  subtitle: 'Outubro de 2026',
  controller: ScrollController(initialScrollOffset: rolado),
  summary: Builder(
    builder: (context) => Text(
      'R\$ 4.210,90',
      style: AppTheme.number(context, size: AppType.set, weight: FontWeight.w700),
    ),
  ),
  actions: const [
    SsHeaderAction(icon: Icons.search_rounded, tooltip: 'Buscar', onPressed: _nada),
    SsHeaderAction(icon: Icons.notifications_none_rounded, tooltip: 'Avisos', onPressed: _nada, badge: '3'),
  ],
  bottom: const Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        Chip(label: Text('Todos')),
        SizedBox(width: 8),
        Chip(label: Text('Despesas')),
        SizedBox(width: 8),
        Chip(label: Text('Receitas')),
      ],
    ),
  ),
  slivers: [
    SliverList.builder(
      itemCount: 30,
      itemBuilder: (_, i) => ListTile(title: Text('Lançamento ${i + 1}'), subtitle: const Text('Mercado')),
    ),
  ],
);

const _paginas = [
  SsOnboardingPage(
    icon: Icons.receipt_long_outlined,
    title: 'Tudo num lugar só',
    text: 'Lance gastos e receitas em segundos, até sem internet.',
  ),
  SsOnboardingPage(
    icon: Icons.insights_outlined,
    title: 'Veja para onde vai',
    text: 'Gráficos do mês e alertas antes de estourar o orçamento.',
  ),
  SsOnboardingPage(
    icon: Icons.auto_awesome_outlined,
    title: 'Pergunte à IA',
    text: 'Quanto gastei com mercado? A resposta vem na hora.',
  ),
];

List<SsChecklistItem> _passos(int feitos) => [
  for (final (i, l) in ['Criar a primeira conta', 'Lançar um gasto', 'Definir um orçamento', 'Convidar alguém'].indexed)
    SsChecklistItem(l, done: i < feitos, onTap: _nada),
];

/// Monta com [de] e troca para [para] no quadro seguinte (pega a animação).
class _Troca<T> extends StatefulWidget {
  const _Troca(this.de, this.para, this.build);
  final T de;
  final T para;
  final Widget Function(T) build;

  @override
  State<_Troca<T>> createState() => _TrocaState<T>();
}

class _TrocaState<T> extends State<_Troca<T>> {
  late T v = widget.de;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => v = widget.para);
    });
  }

  @override
  Widget build(BuildContext context) => widget.build(v);
}

class _Chat extends StatelessWidget {
  const _Chat({this.pensando = false});
  final bool pensando;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(12),
    children: [
      const SsChatBubble(
        text: 'Quanto gastei com mercado este mês?',
        fromMe: true,
        time: '14:30',
        status: SsChatStatus.sent,
      ),
      const SsChatBubble(
        text: 'Foram **R\$ 812,40** em 9 compras, 12% a menos que setembro.',
        fromMe: false,
        time: '14:30',
      ),
      if (pensando) ...[
        const SsChatBubble(text: 'E com farmácia?', fromMe: true, time: '14:31', status: SsChatStatus.sending),
        const SsThinking(text: 'Pensando…'),
      ] else
        const SsChatBubble(text: 'E com farmácia?', fromMe: true, time: '14:31', status: SsChatStatus.failed),
    ],
  );
}

final catalogoOnda4 = <Componente>[
  Componente(
    'ss-screen-header',
    'SsScreenHeader / SsSliverHeader',
    'Topo de tela com título grande que encolhe para uma barra compacta ao rolar. SsScreenHeader monta o CustomScrollView; SsSliverHeader vai num CustomScrollView seu.',
    comportamentos: [
      'Ao rolar, o título grande some embaixo e o pequeno entra na barra crescendo de leve.',
      'O resumo (ex.: total do mês) fica sempre na barra; o bottom (chips, segmentado) fica preso embaixo.',
      'Linha fina embaixo aparece só quando encolhido.',
      'Respeita a área segura de cima. Título marcado como cabeçalho no leitor de tela.',
      'SsHeaderAction: botão redondo de 40 px (alvo de 48) com tooltip e selo opcional.',
      'Tela aberta por cima de outra ganha o voltar sozinha (como a AppBar); leading troca o botão.',
      'onRefresh liga o puxar para atualizar por fora da rolagem.',
    ],
    estados: [
      Estado('aberto', 'aberto', (_) => _cabecalho(), tamanho: const Size(360, 360)),
      Estado('encolhido', 'rolado', (_) => _cabecalho(rolado: 200), tamanho: const Size(360, 360)),
      Estado(
        'voltar',
        'com voltar, rolado',
        (_) => _cabecalho(rolado: 200, voltar: true),
        tamanho: const Size(360, 360),
      ),
    ],
  ),
  Componente(
    'ss-onboarding',
    'SsOnboarding',
    'Boas-vindas em páginas com ilustração, título e texto.',
    comportamentos: [
      'Desliza entre as páginas; o indicador em pílula estica na atual com mola.',
      '"Pular" no topo (some na última); o botão "Continuar" vira "Começar" na última.',
      'Pular e terminar chamam onDone (o app grava que já viu).',
      'Haptic de seleção ao trocar de página; leitor de tela diz "Página 2 de 3".',
    ],
    estados: [
      Estado(
        'primeira',
        'primeira página',
        (_) => SsOnboarding(pages: _paginas, onDone: _nada),
        tamanho: _tela,
      ),
      Estado(
        'ultima',
        'última página',
        (_) => SsOnboarding(pages: _paginas, onDone: _nada, initialPage: 2),
        tamanho: _tela,
      ),
    ],
  ),
  Componente(
    'ss-checklist-card',
    'SsChecklistCard',
    'Card de "primeiros passos" com progresso e itens que levam à tela do passo.',
    comportamentos: [
      'Item feito ganha ✓ verde com mola e o texto é riscado da esquerda para a direita.',
      'Contador "2 de 4" e barra de progresso (verde em 100%).',
      'Ao completar o último passo: confete, vibração de sucesso e "Tudo pronto!" com "Fechar".',
    ],
    estados: [
      Estado('inicio', 'nenhum feito', (_) => _pad(SsChecklistCard(items: _passos(0))), tamanho: const Size(360, 300)),
      Estado(
        'riscando',
        'passo sendo riscado',
        (_) => _pad(_Troca<int>(1, 2, (v) => SsChecklistCard(items: _passos(v)))),
        tamanho: const Size(360, 300),
        aguarde: 140,
      ),
      Estado(
        'pronto',
        'tudo feito',
        (_) => _pad(SsChecklistCard(items: _passos(4), onDismiss: _nada)),
        tamanho: const Size(360, 340),
      ),
    ],
  ),
  Componente(
    'ss-tip',
    'SsTip',
    'Dica dispensável no tom da marca. O app grava que foi fechada e não monta de novo.',
    comportamentos: [
      'Entra com fade e cresce; no ×, encolhe e some, e só então chama onDismiss.',
      'Título e ação opcionais.',
      'Com menos movimento, aparece e some direto.',
    ],
    estados: [
      Estado(
        'simples',
        'só texto',
        (_) => _pad(const SsTip(text: 'Deslize um lançamento para a esquerda para excluir.', onDismiss: _nada)),
        tamanho: const Size(360, 120),
      ),
      Estado(
        'completa',
        'com título e ação',
        (_) => _pad(
          const SsTip(
            icon: Icons.auto_awesome_outlined,
            title: 'Novo: pergunte à IA',
            text: 'Pergunte quanto gastou com qualquer coisa, do jeito que falaria.',
            actionLabel: 'Experimentar',
            onAction: _nada,
            onDismiss: _nada,
          ),
        ),
        tamanho: const Size(360, 190),
      ),
    ],
  ),
  Componente(
    'ss-plan',
    'showSsPlanLimit / SsPlanLocked / SsQuota',
    'Limites do plano: folha de limite atingido, card de recurso bloqueado e a cota de uso.',
    comportamentos: [
      'showSsPlanLimit abre a folha com cadeado; "Ver planos" fecha e chama onUpgrade, "Agora não" só fecha.',
      'SsPlanLocked fica no lugar do recurso, com o que se ganha e "Ver planos".',
      'SsQuota: gomos + "2 de 3 este mês"; aviso (laranja, ⚠) quando falta 1, erro (vermelho, bloqueio) no limite.',
      'Acima de 10, barra contínua no lugar dos gomos.',
    ],
    estados: [
      Estado(
        'folha',
        'folha de limite',
        (context) => Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: SsColors.of(context).surface,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
            ),
            child: const SsSheet(
              child: SsPlanLimit(
                title: 'Você usou as 3 leituras do mês',
                message: 'No plano Pro a leitura de cupom é ilimitada.',
                onUpgrade: _nada,
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 460),
      ),
      Estado(
        'bloqueado',
        'recurso bloqueado',
        (_) => _pad(
          const SsPlanLocked(
            feature: 'Relatórios por categoria',
            text: 'Veja para onde vai cada real, mês a mês, e exporte em PDF.',
            onUpgrade: _nada,
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'cotas',
        'cota: folga, falta 1, acabou, barra',
        (_) => _pad(
          const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SsQuota(used: 1, limit: 5),
              SizedBox(height: 12),
              SsQuota(used: 2, limit: 3),
              SizedBox(height: 12),
              SsQuota(used: 3, limit: 3),
              SizedBox(height: 12),
              SsQuota(used: 18, limit: 30, label: 'fotos'),
            ],
          ),
        ),
        tamanho: const Size(360, 150),
      ),
    ],
  ),
  Componente(
    'ss-chat',
    'SsChatBubble / SsThinking / SsChatInput',
    'Conversa com a IA: bolhas, o "pensando" e o campo de envio.',
    comportamentos: [
      'Bolha da pessoa na cor da marca à direita; da IA em superfície à esquerda com o ✦; cauda sutil no canto de baixo.',
      'Entra com mola a partir do canto da cauda. **Negrito** no texto vira negrito.',
      'Situação da mensagem: relógio (enviando), ✓ (enviada), "Não enviada" em vermelho.',
      'SsThinking: três pontos que ondulam (única animação contínua), texto opcional; avisa o leitor de tela.',
      'SsChatInput: botão de enviar redondo que acende quando há texto; carregando trava o envio; Enter envia.',
    ],
    estados: [
      Estado('conversa', 'conversa', (_) => const _Chat(), tamanho: const Size(360, 300)),
      Estado(
        'pensando',
        'IA pensando',
        (_) => const _Chat(pensando: true),
        tamanho: const Size(360, 300),
        aguarde: 250,
      ),
      Estado(
        'campo-vazio',
        'campo vazio',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsChatInput(controller: TextEditingController(), onSend: (_) {}),
        ),
        tamanho: const Size(360, 80),
      ),
      Estado(
        'campo-texto',
        'com texto',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsChatInput(
            controller: TextEditingController(text: 'E com farmácia?'),
            onSend: (_) {},
          ),
        ),
        tamanho: const Size(360, 80),
      ),
      Estado(
        'campo-enviando',
        'enviando',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsChatInput(
            controller: TextEditingController(text: 'E com farmácia?'),
            onSend: (_) {},
            sending: true,
          ),
        ),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  Componente(
    'ss-shareable',
    'SsShareable',
    'Área que vira PNG para compartilhar (resumo do mês, conquista). O app manda os bytes para o share_plus.',
    comportamentos: [
      'SsShareController.capture(pixelRatio: 3) devolve o PNG do que está na tela.',
      'Pinta o fundo da página atrás do conteúdo (PNG transparente fica preto em apps de mensagem).',
    ],
    estados: [
      Estado(
        'card',
        'card compartilhável',
        (_) => _pad(
          SsShareable(
            controller: SsShareController(),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: SsTip(
                icon: Icons.emoji_events_outlined,
                title: '30 dias seguidos!',
                text: 'Você lançou todos os gastos do mês.',
                onDismiss: _nada,
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 180),
      ),
    ],
  ),
  Componente(
    'ss-sync',
    'SsSyncStatus / SsSyncDot',
    'Sincronização de quem salva no aparelho e envia depois (UI otimista).',
    comportamentos: [
      'SsSyncStatus: ponto + texto curto ("Tudo salvo", "3 a enviar", "Enviando…", "Sem conexão").',
      'Enviando pulsa (indicador de carregamento); falhou fica vermelho com "Tentar de novo" e ícone de refazer.',
      'SsSyncDot no canto do item: ponto pulsando, relógio, nuvem cortada ou ! vermelho; ao sincronizar, ✓ que some sozinho.',
      'Cor nunca sozinha: sempre texto ou ícone; leitor de tela lê o estado.',
    ],
    estados: [
      Estado(
        'status',
        'os cinco estados',
        (_) => _pad(
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in SsSyncState.values)
                SsSyncStatus(state: s, pendingCount: 3, onTap: s == SsSyncState.failed ? _nada : null),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
      Estado(
        'pontos',
        'no canto do item',
        (_) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final s in [SsSyncState.sending, SsSyncState.pending, SsSyncState.offline, SsSyncState.failed])
                ListTile(title: Text('Pedido ${s.index + 101}'), trailing: SsSyncDot(s)),
              ListTile(
                title: const Text('Pedido 106'),
                trailing: _Troca(SsSyncState.sending, SsSyncState.synced, (v) => SsSyncDot(v)),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 320),
      ),
    ],
  ),
  Componente(
    'ss-overflow-menu',
    'SsOverflowMenu',
    'Ações secundárias num ⋮ com ícone e texto. Com uma ação só, vira o ícone dela com tooltip.',
    comportamentos: [
      'Abre ancorado embaixo do ⋮, raio 14, sombra no claro e borda no escuro.',
      'Ação destrutiva em vermelho (ícone e texto).',
      'Haptic de seleção ao abrir. Sem ações, não aparece.',
    ],
    estados: [
      Estado(
        'fechado',
        'na barra',
        (_) => const Align(
          alignment: Alignment.topRight,
          child: SsOverflowMenu(
            items: [
              SsMenuAction(Icons.edit_outlined, 'Editar', _nada),
              SsMenuAction(Icons.delete_outline_rounded, 'Excluir', _nada, destructive: true),
            ],
          ),
        ),
        tamanho: const Size(360, 64),
      ),
      Estado('aberto', 'aberto', (_) => const _MenuAberto(), tamanho: const Size(360, 250)),
    ],
  ),
  Componente(
    'ss-motion',
    'SsMotion / SsReveal / SsDrawIn / showSsConfetti / SsHaptics',
    'O movimento da suíte: a mesma mola (easeOutBack) e tempos (180/280/400 ms, cascata de 40 ms) em todo lugar.',
    comportamentos: [
      'SsReveal: entra uma vez com fade e sobe 12 px, com atraso de índice × 40 ms (até o 8º).',
      'SsDrawIn: revela da esquerda para a direita (gráfico se desenhando).',
      'showSsConfetti: confete por cima de tudo por 1,2 s nas cores da marca e do sucesso, e some sozinho.',
      'SsHaptics: tick (seleção), threshold (cruzou limite), success (dois toques leves), error.',
      'Com menos movimento, tudo aparece direto e não há confete.',
    ],
    estados: [
      Estado(
        'reveal',
        'SsReveal em cascata (no meio)',
        (_) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (var i = 0; i < 4; i++)
              SsReveal(
                index: i,
                child: Card(child: ListTile(title: Text('Item ${i + 1}'))),
              ),
          ],
        ),
        tamanho: const Size(360, 300),
        aguarde: 200,
      ),
      Estado(
        'draw-in',
        'SsDrawIn (no meio)',
        (context) => _pad(
          SsDrawIn(
            child: Container(
              height: 60,
              decoration: BoxDecoration(
                color: SsColors.of(context).accentSoft,
                borderRadius: BorderRadius.circular(AppRadius.field),
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 100),
        aguarde: 450,
      ),
    ],
  ),
];

/// O painel do menu aberto desenhado no lugar (a rota do PopupMenu fica fora da captura).
class _MenuAberto extends StatelessWidget {
  const _MenuAberto();

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    const acoes = [
      SsMenuAction(Icons.edit_outlined, 'Editar', _nada),
      SsMenuAction(Icons.copy_rounded, 'Duplicar', _nada),
      SsMenuAction(Icons.share_outlined, 'Compartilhar', _nada),
      SsMenuAction(Icons.delete_outline_rounded, 'Excluir', _nada, destructive: true),
    ];
    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Material(
          color: c.surface,
          elevation: c.isDark ? 0 : 8,
          shadowColor: const Color(0x66141628),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.field),
            side: c.isDark ? BorderSide(color: c.line) : BorderSide.none,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: IntrinsicWidth(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final a in acoes)
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: SsMenuActionRow(a),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
