// v1.9 · paridade_app ([comV19ParidadeApp]): os pares no app das peças que só existiam no web.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Navegador dentro da captura: o que abre por cima (tour, folha) sai na imagem.
Widget _nav(Widget w) => Navigator(
  onGenerateRoute: (_) => MaterialPageRoute<void>(
    builder: (_) => Material(type: MaterialType.transparency, child: w),
  ),
);
Widget _rola(Widget w) => SingleChildScrollView(padding: const EdgeInsets.all(16), child: w);

final _hoje = DateTime(2026, 11, 24);

final _novidades = [
  SsWhatsNewItem(
    id: 'ia',
    date: DateTime(2026, 11, 20),
    title: 'Pergunte à IA',
    text: 'Pergunte sobre seus números em português.',
  ),
  SsWhatsNewItem(
    id: 'rel',
    date: DateTime(2026, 11, 4),
    title: 'Relatório por vendedor',
    text: 'Ranking do mês e metas.',
  ),
  SsWhatsNewItem(id: 'pix', date: DateTime(2026, 10, 12), title: 'Pix no caixa'),
];

/// O tour aberto no 1º passo (a captura pega o balão).
class _TourDemo extends StatefulWidget {
  const _TourDemo();
  @override
  State<_TourDemo> createState() => _TourDemoState();
}

class _TourDemoState extends State<_TourDemo> {
  final _a = GlobalKey(), _b = GlobalKey();

  @override
  Widget build(BuildContext context) => SsTour(
    id: 'catalogo',
    store: SsMemorySeenStore(),
    useRootNavigator: false,
    steps: [
      SsTourStep(target: _a, title: 'Seus números', text: 'Aqui ficam os indicadores do mês.'),
      SsTourStep(target: _b, title: 'Pedidos do dia'),
    ],
    child: _pad(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 16,
        children: [
          SizedBox(
            key: _a,
            child: const Row(
              spacing: 12,
              children: [
                Expanded(child: SsCard(child: Text('Vendido\nR\$ 48 mil'))),
                Expanded(child: SsCard(child: Text('Pedidos\n214'))),
              ],
            ),
          ),
          SsCard(key: _b, child: const Text('Pedido 1042 · Padaria Central')),
        ],
      ),
    ),
  );
}

Widget _wizard({int inicio = 0}) => SsWizard(
  initialStep: inicio,
  onSubmit: () async {},
  onSaveForLater: (_) {},
  onCancel: () {},
  summary: (_) => const Text('Ana Souza · Plano Pro · 12x'),
  steps: [
    SsWizardStep(
      title: 'Dados',
      builder: (_) => const SsTextField(label: 'Nome', initialValue: 'Ana Souza'),
    ),
    SsWizardStep(title: 'Plano', builder: (_) => const Text('Escolha o plano e as parcelas.')),
  ],
);

class _Periodo extends StatefulWidget {
  const _Periodo();
  @override
  State<_Periodo> createState() => _PeriodoState();
}

class _PeriodoState extends State<_Periodo> {
  late DateTimeRange? v = SsDateRangeShortcut.thisMonth.rangeFrom(_hoje);
  @override
  Widget build(BuildContext context) =>
      _pad(SsDateRangeField(today: _hoje, value: v, onChanged: (r) => setState(() => v = r)));
}

class _Tags extends StatefulWidget {
  const _Tags();
  @override
  State<_Tags> createState() => _TagsState();
}

class _TagsState extends State<_Tags> {
  var tags = ['doce', 'sem glúten', 'congelado'];
  @override
  Widget build(BuildContext context) => _pad(
    SsTagField(
      label: 'Etiquetas',
      values: tags,
      helperText: 'Vírgula ou confirmar no teclado separa.',
      onChanged: (v) => setState(() => tags = v),
    ),
  );
}

Widget _split({Widget? detalhe}) => SsSplitView(
  onBack: () {},
  list: ListView(
    children: [
      for (final (n, cli) in [('1042', 'Padaria Central'), ('1041', 'Mercado Boa Vista'), ('1040', 'Café do Largo')])
        ListTile(title: Text('Pedido $n'), subtitle: Text(cli), selected: detalhe != null && n == '1042'),
    ],
  ),
  detail: detalhe,
);

const _abas = [
  SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
  SsNavItem(Icons.receipt_long_outlined, 'Pedidos', activeIcon: Icons.receipt_long_rounded),
  SsNavItem(Icons.people_alt_outlined, 'Clientes', activeIcon: Icons.people_alt_rounded),
];

final _novos = <Componente>[
  Componente(
    'ss-gantt',
    'SsGantt',
    'Cronograma leve (v1.9, par do Ss::GanttComponent): uma barra por tarefa numa grade de dias, hoje marcado e o progresso dentro da barra.',
    comportamentos: [
      'SsGanttTask(label, from, to, progress 0..1, tone: SsTone): a barra vai de from a to (inclusive), recortada na janela start + days.',
      'Hoje: a coluna tingida da marca e o número num círculo; fim de semana com o número apagado.',
      'Os nomes ficam fixos à esquerda e os dias rolam de lado (dayWidth 36).',
      'A barra cresce da esquerda ao montar; com "reduzir movimento", aparece pronta.',
      'Leitor de tela: "Projeto, de 02/11 a 05/11, 60% feito" (SsStrings.ganttBar).',
    ],
    estados: [
      Estado(
        'padrao',
        '8 dias, hoje no meio',
        (_) => _pad(
          SsGantt(
            start: DateTime(2026, 11, 2),
            days: 8,
            today: DateTime(2026, 11, 4),
            tasks: [
              SsGanttTask(label: 'Projeto', from: DateTime(2026, 11, 2), to: DateTime(2026, 11, 5), progress: .6),
              SsGanttTask(
                label: 'Compras',
                from: DateTime(2026, 11, 5),
                to: DateTime(2026, 11, 8),
                progress: .1,
                tone: SsTone.warning,
              ),
              SsGanttTask(
                label: 'Entrega',
                from: DateTime(2026, 11, 7),
                to: DateTime(2026, 11, 9),
                tone: SsTone.success,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 270),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-tour',
    'SsTour',
    'Passeio guiado (v1.9, par do Ss::TourComponent): escurece a tela com recorte no alvo (GlobalKey) e o balão com n de total, Pular, Voltar e Próximo.',
    comportamentos: [
      'SsTourStep(target: GlobalKey, title, text); passo sem alvo montado é pulado, como no web.',
      'O recorte vai de um alvo ao outro com mola e o alvo rola para a vista (Scrollable.ensureVisible).',
      'Mostrar uma vez: store (SsSeenStore, o app injeta) com a chave ss-tour:<id> = "1", gravada ao concluir ou pular.',
      'autostart abre no 1º quadro se ainda não viu; GlobalKey<SsTourState>.start() ou SsTour.show() abre pelo botão.',
      'O voltar do sistema encerra (igual a Pular); toque no véu não faz nada; o balão recebe o foco.',
    ],
    estados: [
      Estado('balao', 'passo 1 de 2', (_) => _nav(const _TourDemo()), tamanho: const Size(360, 360), aguarde: 900),
    ],
  ),
  Componente(
    'ss-wizard',
    'SsWizard',
    'Passo a passo (v1.9, par do Ss::WizardComponent): topo com 2 / 4 e a barra minhoca (SsStepTopBar), o título numerado (SsStepHeading), Voltar/Avançar e a revisão.',
    comportamentos: [
      'Cada passo num Form próprio: os validator dos campos seguram o Avançar; validate: é a conferência extra.',
      'Os passos ficam montados (IndexedStack): voltar não perde o que foi digitado.',
      'summary: entra o passo "Revisão" antes de concluir; no último, o botão vira submitLabel e fica ocupado até onSubmit terminar.',
      'onSaveForLater: "Salvar e continuar depois" (recebe o passo); reabre com initialStep. No web: save_later_label: ou draft_key:.',
      'O passo novo entra do lado para onde se andou; com "reduzir movimento", troca direto.',
    ],
    estados: [
      Estado('passo1', 'passo 1 de 3', (_) => _wizard(), tamanho: const Size(360, 560), aguarde: 700),
      Estado(
        'revisao',
        'a revisão (último passo)',
        (_) => _wizard(inicio: 2),
        tamanho: const Size(360, 560),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-date-range',
    'SsDateRangeField',
    'Período com atalhos (v1.9, par do Ss::DateRangeComponent): Hoje, 7 dias, Este mês, Mês passado e a faixa De → Até que abre showSsDateRangePicker.',
    comportamentos: [
      'O atalho que bate com o período atual fica marcado (SsFilterChip).',
      'Este mês é o mês inteiro (1 ao último dia), 7 dias conta hoje, como o web.',
      'A faixa abre o calendário de período com os textos do SsStrings; devolve só dias.',
      'Leitor de tela: "Período: De segunda, 1 de novembro, Até …".',
    ],
    estados: [Estado('mes', 'este mês marcado', (_) => const _Periodo(), tamanho: const Size(360, 250))],
  ),
  Componente(
    'ss-otp',
    'SsOtpField',
    'Código de verificação (v1.9, par do Ss::OtpInputComponent): uma caixinha por dígito, colar o código inteiro preenche tudo, autofill do SMS.',
    comportamentos: [
      'Por baixo é um campo só: teclado numérico, colar e AutofillHints.oneTimeCode como campo comum.',
      'Só dígitos e no máximo length (6); "123-456" colado vira 123456.',
      'Completo: onCompleted(código) com um toque leve.',
      'errorText: caixas na cor do erro e o texto embaixo; controller.clear() recomeça.',
    ],
    estados: [
      Estado('vazio', 'vazio', (_) => _pad(const SsOtpField()), tamanho: const Size(360, 130)),
      Estado(
        'erro',
        'código errado',
        (_) => _pad(
          SsOtpField(
            controller: TextEditingController(text: '4821'),
            errorText: 'Código errado. Tente de novo.',
          ),
        ),
        tamanho: const Size(360, 150),
      ),
    ],
  ),
  Componente(
    'ss-tag-input',
    'SsTagField',
    'Etiquetas digitadas (v1.9, par do Ss::TagInputComponent): confirmar ou vírgula vira chip (SsInputChip), ✕ tira, colar "a, b" vira duas.',
    comportamentos: [
      'Repetida (sem diferenciar maiúsculas) não entra; maxTags esconde o campo ao chegar no limite.',
      'O teclado fica aberto entre uma etiqueta e outra; tocar fora confirma o que foi digitado.',
      'Apagar no campo vazio (teclado físico) tira a última.',
      'Leitor de tela: "Etiquetas escolhidas" no grupo e "Remover doce" no ✕.',
    ],
    estados: [Estado('padrao', 'três etiquetas', (_) => const _Tags(), tamanho: const Size(360, 200))],
  ),
  Componente(
    'ss-audit',
    'SsAuditTrail',
    'Histórico de alterações (v1.9, par do Ss::AuditTrailComponent): quem, quando, o quê e cada campo de → para com o trecho que mudou destacado.',
    comportamentos: [
      'SsAuditEntry(who, action, at, changes: [SsAuditChange(field, from:, to:)], note:).',
      'Mesma conta de diferença por palavra do web (SsAuditTrail.diff): riscado no de, verde no para; vazio em itálico.',
      'Avatares ligados por um fio; entram em cascata (SsReveal).',
      'Leitor de tela por campo: "Valor: R\$ 1.250,00 para R\$ 1.320,00".',
    ],
    estados: [
      Estado(
        'padrao',
        'duas alterações',
        (_) => _rola(
          SsAuditTrail(
            entries: [
              SsAuditEntry(
                who: 'Ana Souza',
                action: 'alterou o pedido 1042',
                at: DateTime(2026, 11, 2, 14, 30),
                changes: const [
                  SsAuditChange('Valor', from: 'R\$ 1.250,00', to: 'R\$ 1.320,00'),
                  SsAuditChange('Entrega', from: 'amanhã cedo', to: 'sexta cedo'),
                ],
              ),
              SsAuditEntry(
                who: 'Bruno Lima',
                action: 'criou o pedido 1042',
                at: DateTime(2026, 11, 2, 9, 5),
                note: 'Pelo app, na visita.',
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-review',
    'SsReviewCard',
    'Depoimento (v1.9, par do Ss::ReviewCardComponent): estrelas (aceita meia), o texto, avatar, nome e papel · data.',
    comportamentos: [
      'As estrelas são o SsRating (leitor de tela "Nota 4,5 de 5").',
      'Aspas grandes no canto na cor suave da marca.',
      'onTap opcional (abrir o depoimento).',
    ],
    estados: [
      Estado(
        'padrao',
        '4,5 estrelas',
        (_) => _pad(
          const SsReviewCard(
            name: 'Carla Mendes',
            role: 'Padaria Central',
            date: 'out/2026',
            rating: 4.5,
            text: 'Fechei o caixa em 5 minutos no primeiro dia. Nunca mais fiz conta no caderno.',
          ),
        ),
        tamanho: const Size(360, 230),
      ),
    ],
  ),
  Componente(
    'ss-person',
    'SsPersonCard',
    'Pessoa (v1.9, par do Ss::PersonCardComponent): avatar com status, nome, papel, métricas, a equipe empilhada e as ações.',
    comportamentos: [
      'status: SsTone pinta o ponto do avatar (ok = success).',
      'metrics: (rótulo, valor) em ladrilhos; borrados no modo privacidade (SsPrivate).',
      'team: até 4 avatares e "+N" (SsAvatarStack); actions dividem o rodapé por igual.',
    ],
    estados: [
      Estado(
        'padrao',
        'vendedora com equipe',
        (_) => _pad(
          SsPersonCard(
            name: 'Ana Souza',
            role: 'Vendedora · Zona Sul',
            status: SsTone.success,
            metrics: const [('Vendido', 'R\$ 48 mil'), ('Pedidos', '214')],
            team: const ['Bruno Lima', 'Caio Reis', 'Duda Melo', 'Eva Paz', 'Fábio Sá'],
            actions: [
              SsButton.ghost(label: 'Mensagem', onPressed: () {}),
              SsButton(label: 'Ver carteira', onPressed: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 340),
      ),
    ],
  ),
  Componente(
    'ss-bento',
    'SsBentoGrid',
    'Mosaico de blocos (v1.9, par do Ss::BentoGridComponent): 4 colunas em tela larga, 2 no tablet, 1 no celular; blocos com cols/rows.',
    comportamentos: [
      'Posicionamento como o CSS grid sem dense (SsBentoGrid.place).',
      'Tons: surface, soft, grad (gradiente da marca, texto claro), ink e image.',
      'No celular todos ocupam uma vaga e a altura segue o conteúdo.',
      'Entram em cascata (SsReveal); com onTap afundam ao toque.',
    ],
    estados: [
      Estado(
        'tablet',
        '2 colunas (800 de largura)',
        (_) => _rola(
          SsBentoGrid(
            blocks: [
              const SsBentoBlock(
                cols: 2,
                tone: SsBentoTone.grad,
                child: Text('Explore o Minhas Vendas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              ),
              SsBentoBlock(tone: SsBentoTone.soft, onTap: () {}, child: const Text('Pedidos')),
              const SsBentoBlock(child: Text('Relatórios')),
              const SsBentoBlock(tone: SsBentoTone.ink, cols: 2, child: Text('Pergunte à IA')),
            ],
          ),
        ),
        tamanho: const Size(800, 520),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-whats-new',
    'SsWhatsNew',
    'Novidades (v1.9, par do Ss::WhatsNewComponent): sino com ponto quando há não vistas; abre a folha com a lista e marca tudo como visto.',
    comportamentos: [
      'O "já vi" fica no SsSeenStore (o app injeta) em ss-whats-new:<id>, a lista de ids em JSON, como o localStorage do web.',
      'autoShow: a folha abre sozinha uma vez quando chega novidade.',
      'Selo "NOVO" nos itens ainda não vistos; item com onTap fecha a folha e abre.',
      'Leitor de tela: "Novidades, 2 novas".',
      'SsWhatsNewList é a lista da folha, pública (tela "Novidades" própria).',
    ],
    estados: [
      Estado(
        'sino',
        'com não vistas',
        (_) => _pad(
          Align(
            alignment: Alignment.topLeft,
            child: SsWhatsNew(id: 'cat', items: _novidades, store: SsMemorySeenStore()),
          ),
        ),
        tamanho: const Size(120, 80),
      ),
      Estado(
        'folha',
        'a folha aberta',
        (_) => Align(
          alignment: Alignment.bottomCenter,
          child: SsSheet(
            title: 'Novidades',
            child: SsWhatsNewList(items: _novidades, seen: const {'pix'}),
          ),
        ),
        tamanho: const Size(360, 480),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-skeleton',
    'SsSkeleton',
    'Esqueleto por forma (v1.9, par do Ss::SkeletonComponent): linhas, tabela, cartão ou lista, pulsando; ao lado do SkeletonList e do SkeletonBox.',
    comportamentos: [
      'shape: line (lines), table (rows × cols com cabeçalho), card (mídia, título, linhas) e list (ícone, 2 linhas, valor).',
      'As larguras variam como no web (SsSkeleton.widths).',
      'Leitor de tela: só "Carregando…"; com "reduzir movimento", parado.',
      'Serve de loading: do SsAsyncBody.',
    ],
    estados: [
      for (final s in SsSkeletonShape.values)
        Estado(
          s.name,
          s.name,
          (_) => _pad(SsSkeleton(shape: s, rows: 3)),
          tamanho: Size(360, s == SsSkeletonShape.line ? 110 : 360),
          aguarde: 0,
        ),
    ],
  ),
  Componente(
    'ss-split',
    'SsSplitView',
    'Lista e detalhe (v1.9, par do Ss::SplitViewComponent): lado a lado a partir de 840, empilha no celular com Voltar.',
    comportamentos: [
      'O app guarda o selecionado e monta detail; nulo = "Escolha um item da lista." (tela larga) ou a lista (celular).',
      'Celular com detalhe: o detalhe vira a tela, com Voltar no topo; o voltar do sistema chama onBack.',
      'A troca do detalhe sobe suave (dê uma key ao detalhe); com "reduzir movimento", troca direto.',
      'Com SsAdaptiveScaffold: no celular SsNavScaffold com a barra embaixo; acima de 840 o SsSideRail à esquerda.',
    ],
    estados: [
      Estado('largo', 'tela larga, nada escolhido', (_) => _split(), tamanho: const Size(900, 360)),
      Estado(
        'celular',
        'celular com o detalhe aberto',
        (_) => _split(
          detalhe: const Padding(padding: EdgeInsets.all(16), child: Text('Pedido 1042 · Padaria Central')),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'casca-larga',
        'SsAdaptiveScaffold acima de 840: o trilho lateral',
        (_) => SsAdaptiveScaffold(items: _abas, currentIndex: 1, onTap: (_) {}, body: _split()),
        tamanho: const Size(1000, 480),
        aguarde: 800,
      ),
    ],
  ),
];

/// v1.9 · paridade_app: encadeado no `catalogo` de catalogo.dart.
List<Componente> comV19ParidadeApp(List<Componente> base) => [...base, ..._novos];
