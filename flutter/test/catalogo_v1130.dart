// v1.13.0 "confiança na IA e suíte" ([comV1130]): explicar o valor, a prévia da ação da IA, desde a última visita,
// continuar no outro aparelho, os apps da suíte, o conflito, o valor falado e o modo discreto automático. Dados de
// exemplo, sem pessoas reais (os mesmos da vitrine web).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final _agora = DateTime(2026, 11, 27, 10);

final _itens = [
  SsExplainItem('Mercado Bom Preço', r'R$ 412,30', subtitle: '6 compras', onTap: () {}),
  SsExplainItem('Posto Avenida', r'R$ 280,00', subtitle: '3 abastecimentos', onTap: () {}),
  SsExplainItem('Farmácia Central', r'R$ 96,40', onTap: () {}),
];

const _mudancas = [
  SsAiChange(
    id: 'l1',
    title: 'Mercado Bom Preço',
    subtitle: 'Lançamento de 26/11 · R\$ 214,90',
    fields: [
      SsFieldDiff('Categoria', before: 'Outros', after: 'Mercado'),
      SsFieldDiff('Etiqueta', after: 'Casa'),
    ],
  ),
  SsAiChange(
    id: 'l2',
    title: 'Posto Avenida',
    subtitle: 'Lançamento de 25/11 · R\$ 80,00',
    fields: [SsFieldDiff('Observação', before: 'duplicado?')],
  ),
  SsAiChange(
    id: 'l3',
    title: 'Farmácia Central',
    fields: [SsFieldDiff('Categoria', before: 'Outros', after: 'Saúde')],
    selected: false,
  ),
];

final _desde = [
  SsSinceItem(value: '3', label: 'pedidos novos', icon: Icons.receipt_long_outlined, onTap: () {}),
  SsSinceItem(
    value: r'R$ 1.240,00',
    label: 'recebidos',
    icon: Icons.payments_outlined,
    tone: SsTone.success,
    onTap: () {},
  ),
  SsSinceItem(value: '1', label: 'tarefa atrasada', icon: Icons.schedule_rounded, tone: SsTone.warning, onTap: () {}),
];

final _produtos = [
  SsSuiteProduct(id: 'vendas', name: 'Minhas Vendas', icon: Icons.storefront_outlined, current: true),
  SsSuiteProduct(
    id: 'fin',
    name: 'Meu Financeiro',
    icon: Icons.account_balance_wallet_outlined,
    color: ssColorFromHex('#0F9D7A'),
    lastUsedAt: DateTime(2026, 11, 24, 10),
    badge: 3,
    onOpen: () {},
  ),
  SsSuiteProduct(
    id: 'gestor',
    name: 'Meu Gestor',
    icon: Icons.insights_outlined,
    color: ssColorFromHex('#2563EB'),
    lastUsedAt: DateTime(2026, 11, 27, 8),
    onOpen: () {},
  ),
  SsSuiteProduct(
    id: 'cultivo',
    name: 'Meu Cultivo',
    icon: Icons.eco_outlined,
    color: ssColorFromHex('#4D7C0F'),
    active: false,
    description: 'Plantas, rega e jardim',
    onDiscover: () {},
  ),
];

const _campos = [
  SsConflictField(key: 'qtd', label: 'Quantidade', mine: '12', theirs: '10'),
  SsConflictField(key: 'obs', label: 'Observação', mine: 'Entregar de manhã', theirs: ''),
  SsConflictField(key: 'cliente', label: 'Cliente', mine: 'Loja Centro', theirs: 'Loja Centro'),
];

const _link = 'https://vendas.exemplo.com.br/pedidos?s=eyJ0ZWxhIjoicGVkaWRvcyIsInN0YXR1cyI6ImFiZXJ0byJ9';

List<Componente> comV1130(List<Componente> base) => [...base, ..._v1130];

final _v1130 = <Componente>[
  Componente(
    'ss-explain',
    'SsExplain',
    'De onde vem este valor (v1.13, par do Ss::ExplainComponent): toque longo num KPI, total ou ponto de gráfico abre o valor, a fórmula, o que compõe e o "Explicar com IA".',
    comportamentos: const [
      'SsExplain(child:) envolve qualquer valor; o toque longo (com o toque de seleção) abre a folha. No leitor de tela, a dica "Toque e segure" e a ação "Ver de onde vem este valor".',
      'A folha (SsExplainPanel) mostra o valor em DM Mono, a fórmula numa frase, a lista do que compõe (cada linha abre o registro) e "e mais N" com "Ver todos".',
      '"Explicar com IA" chama onAskAi (do app); enquanto espera, o SsThinking com Cancelar (a resposta que chegar depois é descartada). Erro: a frase e "Tentar de novo".',
      'A resposta fica num quadro com a marca da IA e a nota "confira com os números acima". aiAnswer: abre com uma explicação guardada.',
      'O pacote só apresenta: os dados, os links e a IA são do produto.',
    ],
    estados: [
      Estado(
        'folha',
        'o que compõe o valor',
        (_) => _pad(
          SsExplainPanel(
            value: r'R$ 1.240,00',
            formula: 'Soma dos 23 lançamentos de novembro',
            items: _itens,
            more: 20,
            onMore: () {},
            onAskAi: () async => '',
          ),
        ),
        tamanho: const Size(360, 470),
      ),
      Estado(
        'resposta-ia',
        'com a explicação da IA',
        (_) => _pad(
          SsExplainPanel(
            value: '72%',
            formula: 'Pedidos entregues no prazo em novembro',
            aiAnswer:
                'Caiu 6 pontos porque duas rotas atrasaram na semana do feriado. Sem elas, o prazo ficaria em 81%.',
          ),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'gatilho',
        'o KPI envolvido (toque longo)',
        (_) => _pad(
          SsExplain(
            value: r'R$ 1.240,00',
            items: _itens,
            child: const SsKpiCard(label: 'Gastos de novembro', value: r'R$ 1.240,00'),
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  Componente(
    'ss-ai-action-preview',
    'SsAiActionPreview',
    'Antes de a IA aplicar (v1.13, par do Ss::AiActionPreviewComponent): o antes e depois campo a campo, com marcar e desmarcar cada alteração, Aplicar, Ajustar e Cancelar.',
    comportamentos: const [
      'Cada alteração é um cartão com a caixa de marcar (o cartão desmarcado fica apagado); campos iguais não aparecem.',
      'Removido em vermelho e riscado, novo em verde, alterado em âmbar, e o nome escrito (Novo, Removido, Alterado): a cor nunca é o único sinal. O leitor de tela fala "Categoria. Alterado. Antes: Outros. Depois: Mercado".',
      '"2 de 3 marcadas" ao vivo, Marcar/Desmarcar todas; sem nenhuma, Aplicar desliga e aparece o aviso.',
      'Aplicar chama onApply com as marcadas (carregando até voltar); com onUndo, o aviso "N alterações aplicadas · Desfazer" (showSsUndo).',
      'showSsAiActionPreview abre na folha; SsChatActionCard(onReview:) põe "Ver alterações" na ação que o assistente sugeriu.',
    ],
    estados: [
      Estado(
        'padrao',
        'três alterações, duas marcadas',
        (_) => _pad(SsAiActionPreview(changes: _mudancas, onApply: (_) async {}, onAdjust: () {}, onCancel: () {})),
        tamanho: const Size(360, 720),
      ),
      Estado(
        'chat',
        'a ação do assistente com "Ver alterações"',
        (_) => _pad(
          SsChatActionCard(
            title: 'Recategorizar 3 lançamentos',
            icon: Icons.auto_awesome_outlined,
            rows: const [('Período', 'novembro'), ('Lançamentos', '3')],
            onConfirm: () {},
            onCancel: () {},
            onReview: () {},
          ),
        ),
        tamanho: const Size(360, 300),
      ),
    ],
  ),
  Componente(
    'ss-since-last-visit',
    'SsSinceLastVisit',
    'Desde a última visita (v1.13, par do Ss::SinceLastVisitComponent): "Desde ontem às 18h" com os números rolando e uma ação em cada item.',
    comportamentos: const [
      'Título pelo tempo: hoje, ontem, dia da semana (até 6 dias) ou a data; o relógio no jeito do idioma (18h, 6 PM, 18:00).',
      'Cada número entra rolando do zero (SsOdometer(rollIn:)); reduzir movimento: já parado.',
      'Some sozinho em 12 s (autoHide:) ou no "Entendi", recolhendo com SsMotion.medium; com o leitor de tela ligado não some sozinho.',
      'Ao sumir, grava a visita no SsLastVisit(read:, write:) que o app injeta; sem itens, não desenha nada.',
      'showSsSinceLastVisit: o mesmo resumo numa folha.',
    ],
    estados: [
      Estado(
        'cartao',
        'desde ontem às 18h',
        (_) => _pad(SsSinceLastVisit(since: DateTime(2026, 11, 26, 18), now: _agora, items: _desde, autoHide: null)),
        tamanho: const Size(360, 300),
        aguarde: 900,
      ),
      Estado(
        'semana',
        'desde segunda, só um item',
        (_) => _pad(
          SsSinceLastVisit(since: DateTime(2026, 11, 23, 9, 30), now: _agora, items: [_desde[1]], autoHide: null),
        ),
        tamanho: const Size(360, 180),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-continue-on',
    'SsContinueOn',
    'Continuar no outro aparelho (v1.13, par do Ss::ContinueOnComponent): o link profundo da tela atual, com o estado (filtros, rascunho) que o app serializa, e o QR.',
    comportamentos: const [
      'SsHandoff.link(base, estado) põe o estado no link (JSON em base64url, o mesmo do ComponentesUi::Handoff do web); SsHandoff.decode lê na volta.',
      'No app ("Continuar no computador") o link vem primeiro e o QR depois; no web ("Continuar no celular"), o QR primeiro.',
      '"Copiar link" vira "Link copiado" por 2 s (leitor de tela anuncia); onShare põe "Compartilhar" (a folha do sistema é do app).',
      'Link acima de 300 caracteres: aviso para usar o link (QR denso demais). O QR tem fundo claro em qualquer tema.',
    ],
    estados: [
      Estado(
        'computador',
        'continuar no computador',
        (_) => _pad(SsContinueOn(url: _link, onShare: () {}, qrSize: 160)),
        tamanho: const Size(360, 420),
      ),
      Estado(
        'celular',
        'continuar no celular (QR primeiro)',
        (_) => _pad(const SsContinueOn(url: _link, target: SsContinueTarget.phone, qrSize: 160)),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
  Componente(
    'ss-suite-switcher',
    'SsSuiteSwitcher',
    'Os apps da suíte (v1.13, par do Ss::SuiteSwitcherComponent): os que a conta usa, com o último acesso e o selo de avisos, e "Conhecer" os outros.',
    comportamentos: const [
      'A lista vem do app (products:); o pacote não sabe quais produtos existem. A cor de cada um é dado (ssColorFromHex).',
      'O atual fica marcado ("Você está aqui"); os outros dizem "Usado há 3 dias" ou "Ainda não usado".',
      'O selo de avisos é lido como "3 avisos"; "Conheça também" mostra a linha do produto e "Conhecer".',
      'No menu lateral: SsSuiteSwitcher.section(context, products:, onDiscover:); numa folha: showSsSuiteSwitcher.',
    ],
    estados: [
      Estado(
        'lista',
        'seus apps e conheça também',
        (_) => _pad(SsSuiteSwitcher(products: _produtos, now: _agora)),
        tamanho: const Size(360, 420),
      ),
    ],
  ),
  Componente(
    'ss-conflict-resolver',
    'SsConflictResolver',
    'Conflito de versões (v1.13, par do Ss::ConflictResolverComponent): o mesmo registro mudou aqui e no servidor; a pessoa escolhe campo a campo.',
    comportamentos: const [
      'Só os campos diferentes aparecem; os iguais viram "1 campo igual nas duas versões".',
      'Cada campo tem as duas opções ("Sua versão", "Versão do servidor · há 1 h · por Ana"); começa com a sua marcada.',
      '"Ficar com a minha" e "Ficar com a do servidor" marcam tudo de um lado; "Salvar escolha" devolve o mapa campo → lado.',
      'Abre do SsSyncPanel(conflictCount:, onResolveConflicts:), que mostra "2 registros em conflito · Resolver".',
    ],
    estados: [
      Estado(
        'campos',
        'dois campos em conflito',
        (_) => _pad(
          SsConflictResolver(
            title: 'Pedido 1042',
            fields: _campos,
            mineAt: DateTime(2026, 11, 27, 9, 40),
            theirsAt: DateTime(2026, 11, 27, 9),
            theirsBy: 'Ana',
            now: _agora,
            onResolve: (_) {},
            onCancel: () {},
          ),
        ),
        tamanho: const Size(360, 660),
      ),
      Estado(
        'painel',
        'o aviso no SsSyncPanel',
        (_) => _pad(
          SsSyncPanel(
            state: SsSyncState.pending,
            pendingCount: 4,
            conflictCount: 2,
            lastSyncedAt: DateTime(2026, 11, 27, 9, 12),
            now: _agora,
            onResolveConflicts: () {},
            onSyncNow: () {},
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-spoken-amount',
    'SsSpokenAmount',
    'Valor falado (v1.13, par do ss-spoken-amount do web): SsMoneyField(onVoice:) mostra o microfone, o app reconhece a fala e o SsSpeech.parseAmountPtBr converte em centavos.',
    comportamentos: const [
      '"cento e vinte e três e cinquenta" → 123,50; "mil e duzentos reais" → 1.200,00; "dois mil e quinhentos e noventa centavos" → 2.500,90; "doze e meio" → 12,50; "R\$ 12,50" → 12,50.',
      'Os mesmos 86 casos (docs/v1130/fala.json) passam no Dart, no Ruby e no JS.',
      'Embaixo do campo, "Ouvi “…” · R\$ 123,50" (região viva); sem entender, o aviso em âmbar e o valor fica como estava.',
      'O reconhecimento de voz é do app (plugin dele); o pacote só converte o texto.',
    ],
    estados: [
      Estado(
        'ouvido',
        'entendeu',
        (_) => _pad(const SsSpokenAmount(text: 'cento e vinte e três e cinquenta', cents: 12350)),
        tamanho: const Size(360, 80),
      ),
      Estado(
        'nao-entendeu',
        'não entendeu',
        (_) => _pad(const SsSpokenAmount(text: 'banana')),
        tamanho: const Size(360, 96),
      ),
      Estado(
        'campo',
        'o campo com o microfone',
        (_) => _pad(SsMoneyField(label: 'Valor', cents: 12350, onChanged: (_) {}, onVoice: () async => null)),
        tamanho: const Size(360, 120),
      ),
    ],
  ),
  Componente(
    'ss-privacy-auto',
    'SsPrivacyScope(auto:)',
    'Modo discreto automático (v1.13, par do ss-privacy com auto no web): esconde os valores por sinais do app (celular virado, tela compartilhada) e com o app fora da frente.',
    comportamentos: const [
      'SsPrivacyAuto(signals: [SsPrivacySignal("face_down")]): o app liga o sinal pelos sensores dele; enquanto ligado, os valores viram "R\$ •••".',
      'background: o app fora da frente (AppLifecycleState) também esconde; blurSnapshot: desfoca o app inteiro, para a miniatura dos recentes não mostrar os valores.',
      'SsPrivacyScope.autoReasonsOf(context) diz por que escondeu; a escolha da pessoa (o olho) continua valendo por cima.',
      'No web, esconde no visibilitychange e quando a página compartilha a tela (getDisplayMedia).',
    ],
    estados: [
      Estado(
        'sinal',
        'celular virado para baixo',
        (_) => _pad(
          SsPrivacyScope(
            hidden: false,
            auto: SsPrivacyAuto(signals: [SsPrivacySignal('face_down', true)]),
            child: const SsKpiCard(label: 'Saldo', value: r'R$ 3.482,10'),
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
];
