// v1.9 · produto: central de notificações (ss-notification-center), assistente (ss-assistant) e formas de capturar
// (ss-capture-hub), pares do Ss::NotificationCenterComponent, Ss::AssistantComponent e Ss::CaptureHubComponent.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

final _agora = DateTime(2026, 11, 24, 15);

final _avisos = [
  SsNotificationItem(
    id: '1',
    title: 'Orçamento aprovado',
    body: 'Mercado Bom Preço aprovou o orçamento 1042.',
    createdAt: DateTime(2026, 11, 24, 14, 32),
    icon: Icons.check_circle_outline,
    tone: SsTone.success,
  ),
  SsNotificationItem(
    id: '2',
    title: 'Aprovação pendente',
    body: 'Desconto de 12% no pedido 881 espera a sua alçada.',
    createdAt: DateTime(2026, 11, 24, 9, 10),
    icon: Icons.hourglass_top_rounded,
    tone: SsTone.warning,
  ),
  SsNotificationItem(
    id: '3',
    title: 'Resumo do dia',
    body: '8 pedidos, R\$ 12.480,00 vendidos.',
    createdAt: DateTime(2026, 11, 23, 19),
    read: true,
    icon: Icons.wb_sunny_outlined,
  ),
];

Widget _central(List<SsNotificationItem> itens, {bool erro = false}) => SsNotificationCenter(
  load: (_) async {
    if (erro) throw Exception('rede');
    return SsNotificationPage(itens);
  },
  markRead: (_) async {},
  markAllRead: () async {},
  archive: (_) async {},
  errorText: (_) => 'Sem internet. Confira a conexão.',
  now: () => _agora,
);

void _nada() {}

const _atalhos = [
  SsAssistantShortcut('Resumo da semana', icon: Icons.insights_outlined),
  SsAssistantShortcut('Estou estagnado?'),
  SsAssistantShortcut('O que treinar hoje?'),
];

final _conversa = [
  const SsAssistantMessage(id: '1', text: 'Monte um treino de 4 dias para hipertrofia', fromMe: true, time: '14:02'),
  const SsAssistantMessage(
    id: '2',
    text: 'Posso montar **4 dias** (A/B/C/D) com foco em peito e costas. Quer que eu monte?',
    time: '14:02',
    action: SsAssistantAction(
      title: 'Montar este treino',
      description: '4 dias · 45 min · academia',
      confirmLabel: 'Montar treino',
      cancelLabel: 'Agora não',
      onConfirm: _nada,
      onCancel: _nada,
    ),
  ),
  const SsAssistantMessage(id: '3', text: 'E o cardio?', fromMe: true, time: '14:04'),
  const SsAssistantMessage(id: '4', status: SsAssistantStatus.pending),
];

final _opcoes = [
  const SsCaptureOption(
    kind: SsCaptureKind.camera,
    title: 'Foto do cupom',
    description: 'Cupom fiscal ou print do pedido. Comprido? Tire em partes.',
    highlighted: true,
    onTap: _nada,
  ),
  const SsCaptureOption(kind: SsCaptureKind.paste, group: 'Compra', onTap: _nada),
  const SsCaptureOption(kind: SsCaptureKind.file, group: 'Compra', description: 'XML da NF-e', onTap: _nada),
  const SsCaptureOption(kind: SsCaptureKind.barcode, group: 'Produto', onTap: _nada),
  const SsCaptureOption(
    kind: SsCaptureKind.gallery,
    group: 'Produto',
    disabledReason: 'No plano Pro ou Max',
    onDisabledTap: _nada,
  ),
];

const _tela = Size(360, 780);

// v1.9.2: aviso rico (nível, foto, respostas e silenciar), o que a minha-automacao mostra.
final _ricos = [
  SsNotificationItem(
    id: '11',
    title: 'Portão da garagem aberto',
    body: 'Aberto há 10 min, sem ninguém em casa.',
    createdAt: DateTime(2026, 11, 24, 14, 50),
    level: SsNotificationLevel.critical,
    // No app, a foto do aviso (SsNetImage); aqui, um quadro no lugar.
    image: Builder(
      builder: (context) {
        final c = SsColors.of(context);
        return ColoredBox(
          color: c.field,
          child: Center(child: Icon(Icons.videocam_outlined, size: 40, color: c.muted)),
        );
      },
    ),
    actions: const [SsNotificationAction('Fechar portão', _nada), SsNotificationAction('Deixar aberto', _nada)],
    onMute: _nada,
  ),
  SsNotificationItem(
    id: '12',
    title: 'Bateria fraca no sensor da sala',
    body: '12% de carga.',
    createdAt: DateTime(2026, 11, 24, 13),
    read: true,
    level: SsNotificationLevel.warning,
    onMute: _nada,
  ),
];

List<Componente> comV19Produto(List<Componente> base) => [
  ...base,
  Componente(
    'ss-notification-center',
    'SsNotificationCenter',
    'Central de notificações (v1.9, par do Ss::NotificationCenterComponent): lista paginada por dia, lida/não lida, marcar todas, deslizar para ler/arquivar, puxar para atualizar, vazio e erro. Fonte de dados do app (load(page), markRead(id), markAllRead()).',
    comportamentos: [
      'Grupos "Hoje", "Ontem", "segunda, 5 de outubro" (SsNotificationCenter.dayLabel); a hora em DM Mono na linha.',
      'Não lida: título em negrito, contorno na cor da marca e o ponto; lida apaga o ícone. Leitor de tela: "Título. Corpo. 14:32. não lida".',
      'Tocar: marca lida na hora (otimista; falha de marcar não impede) e chama onOpen com o item.',
      'Faixa de cima: "2 não lidas" e "Marcar todas como lidas" (otimista; volta e avisa se falhar). showHeader: false quando o app põe na barra (SsNotificationCenterController.markAllRead).',
      'Deslizar para a direita marca lida; para a esquerda arquiva (sai encolhendo e volta se falhar). Os dois são ações do leitor de tela.',
      'Pede a próxima página sozinha perto do fim (SsLoadMore, "Sem mais notificações"); aviso repetido entre páginas não duplica.',
      'Puxar para atualizar (SsPullToRefresh) também no vazio e no erro. O sino é o SsNotificationBell com controller.unreadCount.',
      'v1.9.2, aviso rico (opcional no SsNotificationItem): level (aviso/crítico: tom no quadradinho e no contorno, ícone e selo "AVISO"/"CRÍTICO", também no leitor de tela), image (16:9 embaixo do texto), actions (botões de resposta, o 1º cheio; responder marca lida) e onMute ("Silenciar"). Com botões, o topo continua o toque de abrir e cada botão é um nó próprio.',
    ],
    estados: [
      Estado('lista', 'hoje e ontem, com não lidas', (_) => _central(_avisos), tamanho: _tela, aguarde: 900),
      Estado('vazio', 'nenhuma notificação', (_) => _central(const []), tamanho: const Size(360, 420), aguarde: 900),
      Estado(
        'erro',
        'erro ao carregar',
        (_) => _central(const [], erro: true),
        tamanho: const Size(360, 420),
        aguarde: 900,
      ),
      Estado(
        'rico',
        'aviso rico: nível, foto, respostas e silenciar',
        (_) => _central(_ricos),
        tamanho: _tela,
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-assistant',
    'SsAssistantView',
    'Assistente com IA (v1.9, par do Ss::AssistantComponent): conversas, histórico em bolhas, atalhos em chips, cartão de ação sugerida, "respondendo", resposta por polling (o app troca a mensagem pending), plano sem direito e cota.',
    comportamentos: [
      'Mensagens de baixo para cima: a última sempre à vista. pending vira SsThinking; failed mostra o erro e "Tentar de novo" (onRetryMessage).',
      'action: o SsChatActionCard abaixo da bolha ("Montar treino" / "Agora não").',
      'Atalhos: no vazio, chips centrados abaixo de "Como posso ajudar?"; com a conversa aberta, faixa rolável acima do campo.',
      'quotaUsed/quotaLimit: SsQuota acima do campo; inputEnabled: false trava com "Mensagens do mês esgotadas".',
      'locked: SsPlanLocked no lugar da conversa, sem campo.',
      'conversations: ao lado a partir de 840 de largura (SsAssistantConversations: abrir, nova, apagar com confirmação); no celular, showSsAssistantConversations numa folha.',
      'Sem controller, o campo limpa ao enviar; enviar trava enquanto responde.',
      'v1.9.2: attachments (SsChatAttachment) em chips acima do campo, com o ✕ no onRemoveAttachment; com anexo, enviar vale sem texto (onSend recebe \'\').',
    ],
    estados: [
      Estado(
        'vazio',
        'vazio com atalhos e cota',
        (_) => SsAssistantView(
          messages: const [],
          onSend: (_) {},
          emptyText: 'Pergunte sobre o seu treino, peça um treino do seu jeito ou uma análise do histórico.',
          shortcuts: _atalhos,
          onShortcut: (_) {},
          quotaUsed: 2,
          quotaLimit: 10,
        ),
        tamanho: _tela,
        aguarde: 600,
      ),
      Estado(
        'conversa',
        'histórico, ação sugerida e respondendo',
        (_) => SsAssistantView(messages: _conversa, onSend: (_) {}, shortcuts: _atalhos, onShortcut: (_) {}),
        tamanho: _tela,
        aguarde: 900,
      ),
      Estado(
        'anexos',
        'anexo pendente, enviar sem texto',
        (_) => SsAssistantView(
          messages: _conversa.take(2).toList(),
          onSend: (_) {},
          attachments: const [
            SsChatAttachment('cupom-mercado.jpg', icon: Icons.image_outlined),
            SsChatAttachment('nota.pdf', icon: Icons.picture_as_pdf_outlined),
          ],
          onRemoveAttachment: (_) {},
          inputLeading: SsIconButton(icon: Icons.attach_file_rounded, tooltip: 'Anexar', onPressed: _nada),
        ),
        tamanho: _tela,
        aguarde: 900,
      ),
      Estado(
        'bloqueado',
        'plano sem direito',
        (_) => SsAssistantView(
          messages: const [],
          onSend: (_) {},
          locked: SsAssistantLock(
            feature: 'Assistente com IA',
            text: 'Converse com a IA sobre o seu treino e monte treinos conversando. Faz parte dos planos Pro e Max.',
            onUpgrade: _nada,
          ),
        ),
        tamanho: const Size(360, 320),
      ),
      Estado(
        'larga',
        'tela larga com as conversas ao lado',
        (_) => SsAssistantView(
          messages: _conversa.take(2).toList(),
          onSend: (_) {},
          conversations: [
            SsAssistantConversation(id: 'a', title: 'Treino de 4 dias', updatedAt: _agora),
            const SsAssistantConversation(id: 'b', title: 'Platô no supino', subtitle: 'ontem'),
          ],
          currentConversationId: 'a',
          onOpenConversation: (_) {},
          onNewConversation: _nada,
          onDeleteConversation: (_) {},
        ),
        tamanho: const Size(960, 600),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-capture-hub',
    'SsCaptureHub',
    'Formas de capturar (v1.9, par do Ss::CaptureHubComponent): opção destacada no gradiente, grade com ícone, título e descrição (câmera, galeria, colar, código de barras, arquivo) e a indisponível com o motivo.',
    comportamentos: [
      'kind dá o ícone, o título e a descrição padrão (pt/en/es); title/description/icon trocam.',
      'highlighted: bloco largo no gradiente da marca, no alto, com "Recomendado".',
      'disabledReason: apagada, com cadeado e o motivo no lugar da descrição; com onDisabledTap continua tocável (abrir os planos). Leitor de tela: "Título. Motivo. Indisponível".',
      'group: título da seção (SsSection) para opções seguidas do mesmo grupo.',
      '2 colunas; 1 com texto 1,15× ou largura abaixo de 300. Sem altura fixa.',
      'showSsCaptureHub abre numa folha e fecha antes de chamar o onTap.',
    ],
    estados: [
      Estado(
        'grade',
        'destaque, grupos e indisponível',
        (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: SsCaptureHub(options: _opcoes),
        ),
        tamanho: const Size(360, 640),
      ),
    ],
  ),
];
