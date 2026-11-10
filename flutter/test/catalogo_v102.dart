// Entradas do catálogo da v0.10.2 (tela): barra de topo, botão de ícone,
// botão flutuante, carregando, abertura, linhas em card, lista de arrastar,
// zona de perigo, aviso em linha, bloco de código, grupo de comandos, passo
// numerado, divisor e a coluna da hora da agenda.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

class _Ordem extends StatefulWidget {
  const _Ordem();

  @override
  State<_Ordem> createState() => _OrdemState();
}

class _OrdemState extends State<_Ordem> {
  final _itens = [
    ('sala', Icons.weekend_outlined, 'Sala', '6 widgets'),
    ('cozinha', Icons.kitchen_outlined, 'Cozinha', '3 widgets'),
    ('quarto', Icons.bed_outlined, 'Quarto', '4 widgets'),
  ];

  @override
  Widget build(BuildContext context) => SsReorderableList(
    padding: const EdgeInsets.all(16),
    spacing: 10,
    itemCount: _itens.length,
    onReorder: (from, to) => setState(() => _itens.insert(to, _itens.removeAt(from))),
    itemBuilder: (context, i) {
      final (id, icone, titulo, sub) = _itens[i];
      return SsCard(
        key: ValueKey(id),
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
        child: Row(
          children: [
            SsDragHandle(index: i),
            SsIconTile(icone, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text(
                    sub,
                    style: TextStyle(color: SsColors.of(context).muted, fontSize: AppType.sub),
                  ),
                ],
              ),
            ),
            SsIconButton(
              icon: Icons.delete_outline_rounded,
              tooltip: 'Excluir',
              variant: SsIconButtonVariant.danger,
              onPressed: () {},
            ),
          ],
        ),
      );
    },
  );
}

final _hoje = DateTime(2026, 11, 5);

final catalogoV102 = <Componente>[
  Componente(
    'ss-top-bar',
    'SsTopBar',
    'Barra de topo compacta para a tela que não é lista com título grande (editor, mapa, painel com abas, foto em tela cheia).',
    comportamentos: [
      'Título que encolhe em vez de cortar (SsFitTitle) e subtitle menor.',
      'Voltar automático quando a tela pode voltar; onBack troca o pop (o PopScope continua valendo).',
      'actions: SsIconButton, SsButton.text e SsButton(small: true) alinhados à direita.',
      'style: surface (padrão), dark (foto, vídeo, câmera) e overlay (transparente com véu, sobre mapa/planta; use extendBodyBehindAppBar).',
      'Barra de status clara ou escura conforme o fundo.',
      'v0.10.3: título e subtítulo na fonte do tema (Manrope); no overlay, o véu cobre a barra inteira (antes ficava com altura zero).',
      'v0.17: eyebrow: linha pequena em caixa alta acima do título (local · data), o topo discreto de um painel.',
    ],
    estados: [
      Estado(
        'eyebrow',
        'painel com a linha de cima',
        (_) => SizedBox(
          height: 56,
          child: SsTopBar(
            eyebrow: 'Casa · 10 de novembro',
            title: 'Sala de estar',
            actions: [SsIconButton(icon: Icons.edit_outlined, tooltip: 'Editar painel', onPressed: () {})],
          ),
        ),
        tamanho: const Size(390, 56),
      ),
      Estado(
        'surface',
        'surface com ações',
        (_) => SizedBox(
          height: 56,
          child: SsTopBar(
            title: 'Editar painel',
            subtitle: 'Casa da praia',
            leading: SsIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: () {}),
            actions: [
              SsButton.text(label: 'Rascunho', onPressed: () {}),
              SsButton(label: 'Publicar', small: true, expand: false, onPressed: () {}),
            ],
          ),
        ),
        tamanho: const Size(390, 56),
      ),
      Estado(
        'dark',
        'dark (câmera)',
        (_) => SizedBox(
          height: 56,
          child: SsTopBar(
            title: 'Portão · Pessoa',
            style: SsTopBarStyle.dark,
            leading: SsIconButton(icon: Icons.arrow_back_rounded, tooltip: 'Voltar', onPressed: () {}),
          ),
        ),
        tamanho: const Size(390, 56),
      ),
      Estado(
        'overlay',
        'overlay sobre o mapa',
        (_) => Stack(
          children: [
            const Positioned.fill(child: ColoredBox(color: Color(0xFF7FB28A))),
            SizedBox(
              height: 56,
              child: SsTopBar(
                title: 'Mapa',
                style: SsTopBarStyle.overlay,
                actions: [SsIconButton(icon: Icons.my_location_rounded, tooltip: 'Centralizar', onPressed: () {})],
              ),
            ),
          ],
        ),
        tamanho: const Size(390, 120),
      ),
    ],
  ),
  Componente(
    'ss-icon-button',
    'SsIconButton',
    'Botão só de ícone: alvo de 48 dp, dica que também é o nome no leitor de tela.',
    comportamentos: [
      'variant: plain, tonal (fundo de campo), outline e danger (excluir).',
      'selected marca na cor da marca; badge põe o número ou o ponto.',
      'Sem onPressed fica apagado.',
    ],
    estados: [
      Estado(
        'variantes',
        'plain · tonal · outline · danger · selected · badge · apagado',
        (_) => _pad(
          Wrap(
            spacing: 4,
            children: [
              SsIconButton(icon: Icons.edit_outlined, tooltip: 'Editar', onPressed: () {}),
              SsIconButton(
                icon: Icons.mic_none_rounded,
                tooltip: 'Assistente',
                variant: SsIconButtonVariant.tonal,
                onPressed: () {},
              ),
              SsIconButton(
                icon: Icons.swap_horiz_rounded,
                tooltip: 'Trocar',
                variant: SsIconButtonVariant.outline,
                onPressed: () {},
              ),
              SsIconButton(
                icon: Icons.delete_outline_rounded,
                tooltip: 'Excluir',
                variant: SsIconButtonVariant.danger,
                onPressed: () {},
              ),
              SsIconButton(icon: Icons.star_rounded, tooltip: 'Favorito', selected: true, onPressed: () {}),
              SsIconButton(icon: Icons.notifications_none_rounded, tooltip: 'Avisos', badge: '3', onPressed: () {}),
              const SsIconButton(icon: Icons.lock_outline_rounded, tooltip: 'Bloqueado'),
            ],
          ),
        ),
        tamanho: const Size(390, 80),
      ),
    ],
  ),
  Componente(
    'ss-fab',
    'SsFab',
    'Botão flutuante: pílula na cor sólida da marca com rótulo, ou círculo só com o ícone.',
    comportamentos: [
      'Encolhe ao toque e volta com a mola.',
      'Sem heroTag: pode ficar em várias abas de um IndexedStack.',
      'Só ícone: tooltip vira a dica e o nome lido.',
      'v0.17: extended: false com label = círculo, e o label vira a dica e o nome lido; extendedFrom: 640 mostra o texto só na tela larga (Ss::FabComponent(extended: :wide)).',
    ],
    estados: [
      Estado(
        'estendido',
        'estendido e só ícone',
        (_) => _pad(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsFab(icon: Icons.add_rounded, label: 'Seção', onPressed: () {}),
              SsFab(icon: Icons.add_rounded, tooltip: 'Novo widget', onPressed: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 100),
      ),
      Estado(
        'so-icone-rotulo',
        'só ícone com rótulo (Falar com a casa)',
        (_) => _pad(
          Center(
            child: SsFab(icon: Icons.mic_none_rounded, label: 'Falar com a casa', extended: false, onPressed: () {}),
          ),
        ),
        tamanho: const Size(200, 100),
      ),
    ],
  ),
  Componente(
    'ss-spinner',
    'SsSpinner · SsSplash',
    'Carregando em anel na cor da marca e a tela de abertura do app (marca, nome, anel e mensagem).',
    comportamentos: [
      'O arco gira; com reduzir movimento fica parado.',
      'Lido como "Carregando" (SsStrings.loading).',
      'SsSplash: o anel e a mensagem só aparecem depois de delay (300 ms): abertura rápida não pisca.',
      'SsSplash funciona como home do MaterialApp (sem Scaffold).',
    ],
    estados: [
      Estado(
        'spinner',
        'tamanhos',
        (_) => _pad(
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [SsSpinner(size: 16), SsSpinner(), SsSpinner(size: 36)],
          ),
        ),
        tamanho: const Size(300, 80),
        aguarde: 200,
      ),
      Estado(
        'splash',
        'abertura',
        (_) => SsSplash(
          title: 'Minha Automação',
          message: 'Conectando ao servidor…',
          delay: Duration.zero,
          logo: Builder(builder: (context) => SsIconTile(Icons.home_rounded, size: 64, gradient: true)),
        ),
        tamanho: const Size(360, 400),
      ),
    ],
  ),
  Componente(
    'ss-rows',
    'SsRows',
    'Linhas de uma lista num card, separadas por um fio (o .ss-rows do web).',
    comportamentos: ['Fio só entre as linhas; indent recua o fio; card: false deixa só os fios.'],
    estados: [
      Estado(
        'padrao',
        'três linhas',
        (_) => _pad(
          const SsRows(
            children: [
              SsListItem(title: 'Servidor', subtitle: 'v2.4.1 · atualizado', icon: Icons.dns_outlined),
              SsListItem(title: 'Backup', subtitle: 'Ontem, 03:00', icon: Icons.backup_outlined),
              SsListItem(title: 'Acesso remoto', subtitle: 'Ligado', icon: Icons.public_rounded),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-reorderable-list',
    'SsReorderableList · SsDragHandle',
    'Lista de arrastar para mudar a ordem (seções do painel, favoritos, passos).',
    comportamentos: [
      'Arrasta pela alça (SsDragHandle, alvo de 48 e dica); longPress: true arrasta segurando a linha.',
      'A linha levantada ganha sombra na cor da marca e cresce 2% (sem crescer com reduzir movimento); vibra leve ao pegar.',
      'onReorder(de, para) já com o destino ajustado.',
      'Leitor de tela: "mover para cima/baixo" em cada linha.',
    ],
    estados: [Estado('lista', 'três seções (arraste)', (_) => const _Ordem(), tamanho: const Size(360, 280))],
  ),
  Componente(
    'ss-danger-zone',
    'SsDangerZone',
    'Ação perigosa separada do resto do card: fio tracejado vermelho, título e explicação.',
    comportamentos: ['Título padrão "Zona de perigo" no idioma (SsStrings.dangerZone).'],
    estados: [
      Estado(
        'padrao',
        'excluir local',
        (_) => _pad(
          SsDangerZone(
            message: 'Apaga o local, os aparelhos e o histórico. Não dá para desfazer.',
            child: SsButton(
              label: 'Excluir local',
              variant: SsButtonVariant.danger,
              small: true,
              expand: false,
              onPressed: () {},
            ),
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  Componente(
    'ss-callout',
    'SsCallout',
    'Aviso em linha dentro da tela (não some sozinho): tom, ícone, título, mensagem, lista e ações.',
    comportamentos: [
      'Tons do SsTone (info, accent, success, warning, danger), ícone padrão por tom.',
      'Aviso e perigo são lidos na hora (liveRegion).',
    ],
    estados: [
      Estado(
        'tons',
        'info · warning · danger',
        (_) => _pad(
          Column(
            spacing: 10,
            children: [
              const SsCallout(message: 'As mudanças valem depois de publicar.'),
              SsCallout(
                tone: SsTone.warning,
                title: 'Faltam campos',
                actions: [SsButton.text(label: 'Revisar', onPressed: () {})],
                child: const Text('• Escolha o aparelho\n• Defina o horário'),
              ),
              const SsCallout(tone: SsTone.danger, title: 'Automação crítica', message: 'Ela mexe no alarme.'),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
  Componente(
    'ss-code-block',
    'SsCodeBlock',
    'Texto técnico em DM Mono que dá para selecionar e copiar (log, YAML, chave de integração).',
    comportamentos: [
      'Botão de copiar no canto; o ✓ fica 2 s ("Copiado").',
      'terminal: fundo escuro fixo (log); maxHeight rola; wrap: false rola de lado.',
    ],
    estados: [
      Estado(
        'campo',
        'fundo de campo',
        (_) => _pad(const SsCodeBlock('alias: Luz da sala\ntrigger:\n  - platform: state\n    to: "on"')),
        tamanho: const Size(360, 140),
      ),
      Estado(
        'terminal',
        'terminal (log)',
        (_) => _pad(
          const SsCodeBlock(
            '14:02:11 INFO  conectado ao broker\n14:02:12 WARN  sala/sensor sem resposta\n14:02:15 INFO  automação "Bom dia" rodou',
            terminal: true,
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-button-group',
    'SsButtonGroup',
    'Botões de comando colados (abrir/parar/fechar, −/+): cada toque manda o comando na hora.',
    comportamentos: ['Alvo de 48 de largura, dica e nome em cada botão; label nomeia o grupo.', 'Sem ação, apagado.'],
    estados: [
      Estado(
        'cortina',
        'cortina',
        (_) => _pad(
          Center(
            child: SsButtonGroup(
              label: 'Cortina da sala',
              buttons: [
                SsGroupButton(icon: Icons.keyboard_arrow_up_rounded, tooltip: 'Abrir', onPressed: () {}),
                SsGroupButton(icon: Icons.stop_rounded, tooltip: 'Parar', onPressed: () {}),
                SsGroupButton(icon: Icons.keyboard_arrow_down_rounded, tooltip: 'Fechar', onPressed: () {}),
              ],
            ),
          ),
        ),
        tamanho: const Size(300, 80),
      ),
    ],
  ),
  Componente(
    'ss-step-heading',
    'SsStepHeading',
    'Título de passo numerado (Quando → Só se → Então; passo do assistente).',
    comportamentos: [
      'Número em círculo na cor sólida da marca; done vira ✓ verde.',
      'Lido como cabeçalho "1. Quando".',
    ],
    estados: [
      Estado(
        'passos',
        'feito e atual',
        (_) => _pad(
          Column(
            spacing: 14,
            children: [
              const SsStepHeading(1, 'Quando', subtitle: 'Ao chegar em casa', done: true),
              SsStepHeading(
                2,
                'Então',
                trailing: SsButton.text(label: 'Adicionar', onPressed: () {}),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-divider',
    'SsDivider',
    'Fio de separação, com texto no meio quando há label ("ou").',
    comportamentos: ['Fio na cor da linha do tema.'],
    estados: [Estado('rotulo', 'com "ou"', (_) => _pad(const SsDivider(label: 'ou')), tamanho: const Size(360, 60))],
  ),
  Componente(
    'ss-v102-params',
    'v0.10.2: parâmetros',
    'SsFilterChip(solid:), SsChipBar(fade:, wrapAbove:), SsBadge(dot:) e SsBadgeVariant.muted, SsIconTile(gradient:).',
    comportamentos: [
      'solid: o chip marcado na cor sólida com texto branco (o .ss-chip.is-solid do web).',
      'fade: a borda do fim some enquanto dá para rolar; wrapAbove quebra em linhas no largo.',
      'dot: ponto na cor do texto antes do rótulo (situação).',
    ],
    estados: [
      Estado(
        'chips',
        'chips sólidos com contagem e faixa esmaecida',
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SsChipBar(
            fade: true,
            children: [
              SsFilterChip('Todos', selected: true, solid: true, count: 24, onTap: () {}),
              SsFilterChip('Luzes', selected: false, count: 9, icon: Icons.lightbulb_outline_rounded, onTap: () {}),
              SsFilterChip('Clima', selected: false, count: 4, onTap: () {}),
              SsFilterChip('Câmeras', selected: false, count: 3, onTap: () {}),
              SsFilterChip('Sensores', selected: false, count: 8, onTap: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 70),
      ),
      Estado(
        'selos',
        'selos e ícone ligado',
        (_) => _pad(
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SsBadge('Online', variant: SsBadgeVariant.success, dot: true),
              SsBadge('Offline', variant: SsBadgeVariant.danger, dot: true),
              SsBadge('Rascunho', variant: SsBadgeVariant.muted),
              SsIconTile(Icons.lightbulb_rounded, gradient: true),
              SsIconTile(Icons.lightbulb_outline_rounded),
            ],
          ),
        ),
        tamanho: const Size(360, 90),
      ),
    ],
  ),
  Componente(
    'ss-agenda-list-hora',
    'SsAgendaList (v0.10.2: coluna da hora)',
    'A coluna da hora se ajusta ao texto mais largo da lista; end: põe o fim embaixo; allDay mostra "Dia todo".',
    comportamentos: [
      'Largura medida com a fonte e a escala de texto (48 a 136); todas as linhas alinhadas.',
      'Hora que não cabe encolhe numa linha (não quebra nem corta); "Dia todo" quebra em até 2.',
      'end: entra no nome lido ("15:00 – 16:00, Reunião").',
    ],
    estados: [
      Estado(
        'faixas',
        'intervalo, fim embaixo e dia todo',
        (_) => _pad(
          SsAgendaList(
            days: [
              SsAgendaDay(
                _hoje,
                label: 'Hoje',
                events: [
                  const SsAgendaItem(allDay: true, title: 'Feriado municipal'),
                  SsAgendaItem(time: '15:00–16:00', title: 'Reunião do condomínio', detail: 'Salão', onTap: () {}),
                  const SsAgendaItem(time: '18:30', end: '19:15', title: 'Academia', tone: SsTone.success),
                ],
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 300),
      ),
    ],
  ),
];
