// v1.9 · transições ([comV19Transicoes]): lista → detalhe (SsOpenContainer), voltar preditivo,
// ilustrações dos estados vazios, a regra de comemoração e a troca de dados nos gráficos.
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

Widget _pedido(BuildContext context, VoidCallback open) {
  final c = SsColors.of(context);
  return Material(
    color: c.surface,
    borderRadius: BorderRadius.circular(AppRadius.card),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: open,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.receipt_long_rounded, color: c.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pedido 1042',
                    style: TextStyle(fontWeight: FontWeight.w800, color: c.ink),
                  ),
                  Text(
                    'Mercado Bom Preço · 3 itens',
                    style: TextStyle(color: c.muted, fontSize: AppType.meta),
                  ),
                ],
              ),
            ),
            Text('R\$ 318,40', style: AppTheme.number(context, color: c.ink)),
          ],
        ),
      ),
    ),
  );
}

Widget _detalhe(BuildContext context) => Scaffold(
  appBar: AppBar(title: const Text('Pedido 1042')),
  body: const Center(child: Text('Detalhe do pedido')),
);

/// A tela no meio do gesto de voltar: a anterior por trás e a atual encolhida.
Widget _gesto(double v) => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(
          color: c.page,
          child: const Center(child: Text('Tela anterior')),
        ),
        SsBackShrink(
          animation: AlwaysStoppedAnimation(v),
          child: Scaffold(
            appBar: AppBar(title: const Text('Detalhe')),
            body: Center(
              child: Text('Arraste da borda para voltar', style: TextStyle(color: c.muted)),
            ),
          ),
        ),
      ],
    );
  },
);

final _novos = <Componente>[
  Componente(
    'ss-open-container',
    'SsOpenContainer',
    'Lista → detalhe (v1.9, container transform): o cartão cresce até virar a tela e volta encolhendo ao fechar. '
        'Par do ss_view_transition_name no web (View Transitions).',
    comportamentos: [
      'closedBuilder(context, open) desenha o cartão; open no toque abre o openBuilder numa SsOpenRoute.',
      'go_router: tag + onOpen (context.push) no cartão e SsOpenPage(tag:, child:) no pageBuilder da rota; sem cartão na tela (link direto), a tela sobe e aparece.',
      'Enquanto a tela está aberta, o cartão fica invisível no lugar (a lista não pula); onClosed recebe o resultado do pop.',
      'Raio do cartão (AppRadius.card) vai a 0, o fundo escurece e o conteúdo troca em crossfade; ida 460 ms, volta 380 ms.',
      'O gesto de voltar preditivo (Android 14+) leva a tela de volta ao cartão junto com o dedo; desistiu, volta a abrir.',
      'Reduzir movimento: a tela só aparece (200 ms). O SsOpenCard agora é este container com a casca de card.',
    ],
    estados: [
      Estado(
        'fechado',
        'cartão na lista',
        (_) => _pad(SsOpenContainer<void>(closedBuilder: _pedido, openBuilder: _detalhe)),
        tamanho: const Size(360, 110),
      ),
    ],
  ),
  Componente(
    'ss-predictive-back',
    'SsPredictiveBackPageTransitionsBuilder',
    'Voltar preditivo do Android 14+ (v1.9): durante o gesto, a página encolhe e mostra a anterior; soltou, fecha. '
        'Já vem no AppTheme.build; folhas e diálogos do pacote também reagem.',
    comportamentos: [
      'AppTheme.build liga no Android (pageTransitionsTheme); ida e volta pelo botão seguem a transição de sempre (subir e aparecer).',
      'Página: encolhe até 90%, cantos arredondados (28) e um passo para o lado do gesto; a anterior aparece por trás.',
      'Folha (SsSheet/showSsSheet): desce 48 px e encolhe por baixo; diálogo (SsRouteScale): encolhe no centro; soltar chama maybePop (respeita PopScope).',
      'Desistiu do gesto: volta ao lugar. Rota que não pode sair (PopScope(canPop: false), a primeira) não mostra prévia.',
      'Reduzir movimento: sem prévia; o sistema volta normal ao soltar.',
      'O app precisa de android:enableOnBackInvokedCallback="true" no <application> do AndroidManifest.xml.',
    ],
    estados: [Estado('gesto', 'no meio do gesto', (_) => _gesto(.6), tamanho: const Size(360, 640))],
  ),
  Componente(
    'ss-illustration',
    'SsIllustrationArt',
    'Ilustrações dos estados vazios (v1.9): vazio, sem conexão, sem resultado, tudo feito e erro, desenhadas em código na cor da marca. '
        'Use pelo SsEmptyState(illustration:); par do EmptyStateComponent(illustration:).',
    comportamentos: [
      'Bolha na cor suave da marca, chão, órbita, brilhos e o símbolo do caso; erro na cor de perigo da suíte.',
      'Entra crescendo com mola (620 ms); parada, flutua devagar e os brilhos piscam (ciclo de 3,6 s).',
      'Reduzir movimento: parada. Decorativa (o leitor de tela lê o título do estado vazio).',
    ],
    estados: [
      for (final i in SsIllustration.values)
        Estado(
          i.name,
          switch (i) {
            SsIllustration.empty => 'nada ainda',
            SsIllustration.offline => 'sem conexão',
            SsIllustration.noResults => 'sem resultado',
            SsIllustration.allDone => 'tudo feito',
            SsIllustration.error => 'erro',
          },
          (_) => Center(child: SsIllustrationArt(i, size: 120)),
          tamanho: const Size(160, 160),
          aguarde: 900,
        ),
    ],
  ),
];

final Map<String, (List<String>, List<Estado>)> _v19 = {
  'ss-empty-state': (
    ['v1.9: illustration: SsIllustration.empty/offline/noResults/allDone/error no lugar da ilustração com ícone.'],
    [
      Estado(
        'tudo-feito',
        'illustration: allDone (v1.9)',
        (_) => const SsEmptyState(
          illustration: SsIllustration.allDone,
          title: 'Tudo em dia',
          subtitle: 'Nenhuma tarefa para hoje.',
        ),
        tamanho: const Size(360, 340),
        aguarde: 900,
      ),
      Estado(
        'sem-conexao',
        'illustration: offline (v1.9)',
        (_) => SsEmptyState(
          illustration: SsIllustration.offline,
          title: 'Sem conexão',
          subtitle: 'Mostramos o que já estava salvo.',
          actionLabel: 'Tentar de novo',
          onAction: () {},
        ),
        tamanho: const Size(360, 380),
        aguarde: 900,
      ),
    ],
  ),
  'ss-celebrate': (
    [
      'v1.9: kind: SsCelebrationKind.goal/streak/firstUse liga a regra: no máximo uma comemoração por sessão por tipo (SsCelebrationGate, armazenamento injetado).',
      'v1.9: com kind, o leitor de tela anuncia ("Meta batida!", "Sequência mantida!", "Primeiro passo dado!").',
      'v1.9: streak não solta confete: dá o pulo e o estouro (SsBurst) em volta do número.',
    ],
    const [],
  ),
  'ss-open-card': (
    [
      'v1.9: é o SsOpenContainer com a casca de card; tag + onOpen para o go_router (SsOpenPage); o voltar preditivo leva a tela de volta ao card.',
    ],
    const [],
  ),
  for (final slug in ['ss-line-chart', 'ss-area-chart', 'ss-bar-chart', 'ss-time-chart'])
    slug: (
      [
        'v1.9: troca de dados animada: mudou o conjunto (outro mês, outro filtro), cada ponto vai do valor anterior ao novo (520 ms); outro número de pontos troca direto; reduzir movimento troca direto.',
      ],
      const [],
    ),
  'ss-exploded-donut': (
    [
      'v1.9: gira um quarto de volta enquanto varre ao entrar.',
      'v1.9: troca de dados animada: as fatias crescem e encolhem até o novo tamanho; reduzir movimento troca direto.',
    ],
    const [],
  ),
};

List<Componente> comV19Transicoes(List<Componente> base) => [
  for (final c in base)
    if (_v19[c.slug] case (final comp, final est))
      Componente(
        c.slug,
        c.nome,
        c.descricao,
        comportamentos: [...c.comportamentos, ...comp],
        estados: [...c.estados, ...est],
      )
    else
      c,
  ..._novos,
];
