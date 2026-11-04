// Entradas do catálogo da v0.9 (lote b).
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

/// Guarda um valor para os controles controlados (slider, dial) da vitrine.
class _Holder<T> extends StatefulWidget {
  const _Holder(this.inicial, this.builder);
  final T inicial;
  final Widget Function(T valor, ValueChanged<T> set) builder;

  @override
  State<_Holder<T>> createState() => _HolderState<T>();
}

class _HolderState<T> extends State<_Holder<T>> {
  late T v = widget.inicial;

  @override
  Widget build(BuildContext context) => widget.builder(v, (n) => setState(() => v = n));
}

/// Quadrado colorido no lugar de uma foto (o pacote não tem imagens).
class _Foto extends StatelessWidget {
  const _Foto(this.i, {this.icon = Icons.image_outlined});
  final int i;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final cor = SsColors.of(context).series[i % 6];
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cor.withValues(alpha: .85), cor.withValues(alpha: .45)],
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Center(child: Icon(icon, color: Colors.white, size: 36)),
    );
  }
}

const _meses = ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago'];
const _gastos = [420000.0, 515000, 468000, 610000, 664000, 580000, 640000, 598000];
final _dia = DateTime(2026, 11, 12);

final catalogoV09B = <Componente>[
  // ------------------------------------------------------------- campos
  Componente(
    'ss-split-slider',
    'SsSplitSlider',
    'Divide um valor entre pessoas: uma linha por pessoa com avatar, nome, valor em DM Mono e um slider de marcas pontilhadas.',
    comportamentos: [
      'Soma travada (padrão): mexer numa linha redistribui o resto nas outras, na proporção que tinham, e a soma fecha no centavo.',
      'Modo livre (locked: false): cada linha vai de 0 ao total e o rodapé mostra quanto falta ou passou.',
      'Arrasto e toque na trilha; passo de R\$ 1,00 (step); tique de haptic a cada marca.',
      'As outras linhas deslizam até o novo valor com mola curta; leitor de tela sobe e desce o passo.',
    ],
    estados: [
      Estado(
        'travada',
        'soma travada em R\$ 750,86',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsSplitSlider(
            total: 75086,
            entries: [SsSplitEntry('Eu', 20086), SsSplitEntry('Cauã Lima', 45000), SsSplitEntry('Rita Souza', 10000)],
          ),
        ),
        tamanho: const Size(360, 370),
      ),
      Estado(
        'livre',
        'livre, faltando valor',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsSplitSlider(
            total: 30000,
            locked: false,
            entries: [SsSplitEntry('Ana Paula', 12000), SsSplitEntry('Bruno Reis', 9000)],
          ),
        ),
        tamanho: const Size(360, 270),
      ),
    ],
  ),
  Componente(
    'ss-vertical-slider',
    'SsVerticalSlider',
    'Slider vertical tipo termostato: trilha alta que enche de baixo e o valor escrito no seletor.',
    comportamentos: [
      'Arrastar ou tocar na trilha muda o valor, com tique por passo.',
      'Setas do teclado e o leitor de tela sobem e descem um passo (step).',
      'format escreve o valor ("25°", "80%"); sem onChanged fica apagado.',
    ],
    estados: [
      Estado(
        'valores',
        'temperatura, luz e desligado',
        (_) => _pad(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 24,
            children: [
              _Holder<double>(
                24,
                (v, set) => SsVerticalSlider(
                  value: v,
                  min: 16,
                  max: 30,
                  label: 'Temperatura',
                  format: (x) => '${x.round()}°',
                  onChanged: set,
                ),
              ),
              _Holder<double>(
                70,
                (v, set) => SsVerticalSlider(
                  value: v,
                  step: 5,
                  label: 'Luz',
                  format: (x) => '${x.round()}%',
                  color: AppColors.series[4],
                  onChanged: set,
                ),
              ),
              const SsVerticalSlider(value: 30, label: 'Desligado', onChanged: null),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-dial',
    'SsDial',
    'Botão giratório: arco de 270° com marcações, progresso na cor da marca e o valor grande no centro.',
    comportamentos: [
      'Arrasto circular em volta do centro; na "boca" de baixo gruda na ponta mais perto.',
      'Haptic de tique a cada passo; setas do teclado e o leitor de tela também mudam.',
      'O progresso e o seletor deslizam até o valor novo (desliga com menos movimento).',
    ],
    estados: [
      Estado(
        'termostato',
        '22 °C',
        (_) => _pad(
          _Holder<double>(
            22,
            (v, set) => SsDial(
              value: v,
              min: 10,
              max: 32,
              step: .5,
              label: 'Temperatura',
              caption: 'Sala',
              format: (x) => '${qty(x)}°',
              onChanged: set,
            ),
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-hold-to-confirm',
    'SsHoldToConfirm',
    'Segurar para confirmar uma ação séria (excluir, encerrar): o fundo enche enquanto o dedo fica em cima.',
    comportamentos: [
      'Segurou até o fim (1,2 s): vibra o "deu certo", mostra ✓ e chama onConfirmed.',
      'Soltou antes: o preenchimento volta rápido e nada acontece.',
      'danger: vermelho de erro; o leitor de tela confirma com um toque (não dá para segurar).',
    ],
    estados: [
      Estado(
        'normal',
        'marca e perigo',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              SsHoldToConfirm(label: 'Segure para transferir', onConfirmed: () {}),
              SsHoldToConfirm(
                label: 'Segure para excluir',
                icon: Icons.delete_outline_rounded,
                danger: true,
                onConfirmed: () {},
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  Componente(
    'ss-swipe-to-confirm',
    'SsSwipeToConfirm',
    'Arrastar a bolinha até o fim para pagar ou fechar o pedido, sem toque sem querer.',
    comportamentos: [
      'Passou de 85%: tique; soltou ali, gruda no fim e mostra carregando enquanto onConfirm roda.',
      'Terminou: trilha verde com ✓ e doneLabel. Se onConfirm lançar erro, a bolinha volta.',
      'Soltou antes: volta com mola. O leitor de tela confirma com um toque.',
    ],
    estados: [
      Estado(
        'parado',
        'pronto para arrastar',
        (_) => _pad(SsSwipeToConfirm(label: 'Arraste para pagar R\$ 750,86', onConfirm: () async {})),
        tamanho: const Size(360, 96),
      ),
      Estado(
        'pronto',
        'concluído',
        (_) =>
            _pad(SsSwipeToConfirm(label: 'Arraste para pagar', doneLabel: 'Pago', done: true, onConfirm: () async {})),
        tamanho: const Size(360, 96),
      ),
    ],
  ),
  Componente(
    'ss-morph-button',
    'SsMorphButton',
    'Botão em pílula que vira um círculo com progresso e termina em ✓ ou ✗ (o resultado fica visível).',
    comportamentos: [
      'Toque: encolhe até o círculo e mostra o anel (determinado com progress, ex.: envio de arquivo).',
      'Deu certo: verde com ✓; lançou erro: vermelho com ✗; volta à pílula em 1,6 s.',
      'Diferente do SsActionButton (mantém o tamanho e só sacode no erro).',
    ],
    estados: [
      Estado(
        'normal',
        'pílula',
        (_) => _pad(SsMorphButton(label: 'Enviar comprovante', icon: Icons.upload_rounded, onPressed: () async {})),
        tamanho: const Size(360, 90),
      ),
    ],
  ),
  Componente(
    'ss-people-picker',
    'SsPeoplePicker',
    'Fileira horizontal de pessoas em pílulas altas para escolher várias (com quem dividir, quem convidar).',
    comportamentos: [
      'Tocar alterna a pessoa: a escolhida ganha anel, fundo da marca e o "+" vira ✓ com mola.',
      'onAdd põe a pílula "Novo" no começo.',
      'Rola de lado; cada pílula é um alvo de toque alto, com estado marcado para o leitor de tela.',
    ],
    estados: [
      Estado(
        'escolhidas',
        'duas escolhidas e o "Novo"',
        (_) => Center(
          child: _Holder<Set<String>>(
            {'Cauã Lima', 'Rita Souza'},
            (v, set) => SsPeoplePicker(
              people: const ['Cauã Lima', 'Rita Souza', 'Lia Prado', 'Davi Torres'],
              selected: v,
              onChanged: set,
              onAdd: () {},
            ),
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  Componente(
    'ss-date-strip',
    'SsDateStrip',
    'Faixa horizontal de dias do mês: o escolhido numa pílula alta na cor da marca e o cabeçalho do mês que abre o calendário.',
    comportamentos: [
      'Tocar num dia escolhe; a pílula desliza até ele esticando no caminho, assenta com mola e a faixa rola até centralizar.',
      'Pontinhos marcam dias com evento (até 3 cores); hoje tem contorno.',
      'O cabeçalho "Novembro 2026 ⌄" abre o SsMonthGrid numa folha para pular de mês.',
    ],
    estados: [
      Estado(
        'dia',
        'dia 12 escolhido, com eventos',
        (context) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _Holder<DateTime>(
            _dia,
            (v, set) => SsDateStrip(
              selected: v,
              today: DateTime(2026, 11, 11),
              markers: {
                DateTime(2026, 11, 11): [SsColors.of(context).accent],
                DateTime(2026, 11, 12): [AppColors.series[2], AppColors.series[3]],
                DateTime(2026, 11, 14): [AppColors.series[1]],
              },
              onChanged: set,
            ),
          ),
        ),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
  Componente(
    'ss-day-agenda',
    'SsDayAgenda',
    'Agenda de um dia: horas à esquerda, linhas tracejadas e blocos com altura proporcional à duração.',
    comportamentos: [
      'Blocos que se sobrepõem dividem a largura; entram em cascata.',
      'eventBuilder troca o bloco padrão por qualquer widget (um card de status), que recebe a altura pelas restrições.',
      'now desenha a linha do "agora" na cor da marca.',
    ],
    estados: [
      Estado(
        'dia',
        'manhã com sobreposição e o agora',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsDayAgenda(
            startHour: 8,
            endHour: 13,
            hourHeight: 64,
            now: const TimeOfDay(hour: 10, minute: 20),
            events: [
              SsAgendaEvent(
                start: const TimeOfDay(hour: 8, minute: 30),
                end: const TimeOfDay(hour: 9, minute: 30),
                title: 'Visita à Padaria Sol',
                subtitle: 'Centro',
                icon: Icons.storefront_outlined,
                onTap: () {},
              ),
              const SsAgendaEvent(
                start: TimeOfDay(hour: 10, minute: 0),
                end: TimeOfDay(hour: 11, minute: 30),
                title: 'Reunião de metas',
                icon: Icons.groups_outlined,
              ),
              const SsAgendaEvent(
                start: TimeOfDay(hour: 10, minute: 30),
                end: TimeOfDay(hour: 11, minute: 0),
                title: 'Ligação',
                icon: Icons.call_outlined,
              ),
              const SsAgendaEvent(
                start: TimeOfDay(hour: 12, minute: 0),
                end: TimeOfDay(hour: 12, minute: 45),
                title: 'Almoço',
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 380),
      ),
    ],
  ),
  Componente(
    'ss-agenda-list',
    'SsAgendaList',
    'Agenda de vários dias em lista: cabeçalho de cada dia ("Hoje · quarta, 4 de novembro"), compromissos com a hora em DM Mono e a barrinha de cor, e "Nada neste dia" no dia vazio. Faixa de dias opcional em cima.',
    comportamentos: [
      'SsAgendaDay(date, label:, events:) e SsAgendaItem(time:, title:, detail:, color:/tone:, onTap:); a hora vem formatada pelo app.',
      'Dia sem compromisso mostra emptyLabel (padrão "Nada neste dia", em pt/en/es).',
      'weekStrip: SsDateStrip em cima (sem o cabeçalho do mês) com pontinho nos dias com compromisso; tocar num dia (faixa ou cabeçalho) chama onSelectDay.',
      'selected destaca o dia na faixa e no cabeçalho (ponto e texto na cor da marca).',
      'Linha com onTap encolhe ao toque e ganha a seta; leitor de tela lê "hora, título, detalhe".',
      'SsAgendaList.sliver: a mesma lista como sliver, para um CustomScrollView.',
    ],
    estados: [
      Estado(
        'dias',
        'hoje cheio · amanhã vazio · sexta',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsAgendaList(
            days: [
              SsAgendaDay(
                DateTime(2026, 11, 4),
                label: 'Hoje',
                events: [
                  SsAgendaItem(time: '08:30', title: 'Visita à Padaria Sol', detail: 'Centro', onTap: () {}),
                  const SsAgendaItem(time: '10:00', title: 'Reunião de metas', detail: 'Sala 3', tone: SsTone.info),
                  const SsAgendaItem(time: '12:00', title: 'Almoço com fornecedor', tone: SsTone.warning),
                  const SsAgendaItem(time: '15:30', title: 'Entrega do pedido 4521', tone: SsTone.success),
                  const SsAgendaItem(time: 'Dia todo', title: 'Inventário do depósito', tone: SsTone.danger),
                ],
              ),
              SsAgendaDay(DateTime(2026, 11, 5), label: 'Amanhã'),
              SsAgendaDay(
                DateTime(2026, 11, 6),
                events: const [SsAgendaItem(time: '09:00', title: 'Dentista', color: Color(0xFF14B8A6))],
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 560),
      ),
      Estado(
        'vazio',
        'dia vazio',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsAgendaList(days: [SsAgendaDay(DateTime(2026, 11, 7), label: 'Sábado')]),
        ),
        tamanho: const Size(360, 110),
      ),
      Estado(
        'faixa',
        'com a faixa de dias (toque escolhe o dia)',
        (_) => _Holder<DateTime>(
          DateTime(2026, 11, 4),
          (sel, set) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: SsAgendaList(
              weekStrip: true,
              today: DateTime(2026, 11, 4),
              selected: sel,
              onSelectDay: set,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              days: [
                SsAgendaDay(
                  sel,
                  label: sel.day == 4 ? 'Hoje' : null,
                  events: sel.day.isEven
                      ? const [
                          SsAgendaItem(time: '09:00', title: 'Rota zona sul', detail: '6 clientes'),
                          SsAgendaItem(time: '14:00', title: 'Reunião com a gerente', tone: SsTone.info),
                        ]
                      : const [],
                ),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
  Componente(
    'ss-attach-bar',
    'SsAttachBar',
    'Fileira de botões quadrados coloridos para anexar foto, documento, contato ou local.',
    comportamentos: [
      'Cores da paleta da suíte, na ordem (a primeira é a marca); ícone escuro quando o fundo é claro.',
      'Entram em cascata crescendo com mola (desliga com menos movimento).',
      'Cada botão encolhe ao toque com haptic leve.',
    ],
    estados: [
      Estado(
        'anexos',
        'quatro anexos',
        (_) => _pad(
          SsAttachBar(
            items: [
              SsAttachItem(Icons.photo_camera_outlined, 'Câmera', onTap: () {}),
              SsAttachItem(Icons.description_outlined, 'Documento', onTap: () {}),
              SsAttachItem(Icons.person_outline_rounded, 'Contato', onTap: () {}),
              SsAttachItem(Icons.place_outlined, 'Local', onTap: () {}),
              SsAttachItem(Icons.receipt_long_outlined, 'Cupom', onTap: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 120),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-snap-carousel',
    'SsSnapCarousel',
    'Carrossel que para em cada item: o do meio maior e os vizinhos cortados e encolhidos.',
    comportamentos: [
      'Desliza de um em um, com tique a cada troca.',
      'Indicador de bolinhas (a ativa vira pílula), contador "2/5" ou nenhum.',
      'Os vizinhos encolhem e apagam conforme se afastam do meio.',
    ],
    estados: [
      Estado(
        'bolinhas',
        'bolinhas',
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SsSnapCarousel(itemCount: 5, height: 160, itemBuilder: (_, i) => _Foto(i)),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'contador',
        'contador',
        (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: SsSnapCarousel(
            itemCount: 5,
            height: 160,
            initialPage: 1,
            indicator: SsCarouselIndicator.counter,
            itemBuilder: (_, i) => _Foto(i, icon: Icons.landscape_outlined),
          ),
        ),
        tamanho: const Size(360, 230),
      ),
    ],
  ),
  Componente(
    'ss-thumb-rail',
    'SsThumbRail',
    'Miniaturas em coluna ao lado da foto grande: a ativa destacada e setas para rolar.',
    comportamentos: [
      'Tocar numa miniatura chama onSelect; a ativa ganha borda da marca e as outras ficam apagadas.',
      'Setas em cima e embaixo rolam uma miniatura e somem nas pontas.',
      'Ao mudar a ativa por fora, o trilho rola até ela.',
    ],
    estados: [
      Estado(
        'detalhe',
        'trilho com o detalhe',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: _Holder<int>(
            1,
            (v, set) => Row(
              spacing: 12,
              children: [
                SsThumbRail(count: 6, selected: v, onSelect: set, thumbBuilder: (_, i) => _Foto(i)),
                Expanded(child: _Foto(v)),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 320),
      ),
    ],
  ),
  // ------------------------------------------------------------- dados
  Componente(
    'ss-area-chart',
    'SsAreaChart',
    'Gráfico de área suave com gradiente vertical da marca e um ponto ativo com o valor numa pílula.',
    comportamentos: [
      'Arrastar ou tocar troca o ponto ativo (tique por ponto) e chama onSelect; o rótulo dele no eixo fica destacado.',
      'Linha tracejada do ponto até o eixo e marcador com halo.',
      'Cresce de baixo ao aparecer; o leitor de tela anda pelos pontos (aumentar/diminuir).',
      'Várias séries ou meta: use o SsLineChart.',
    ],
    estados: [
      Estado(
        'ativo',
        'mês de maio ativo',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsAreaChart(
            values: [for (final v in _gastos) v.toDouble()],
            labels: _meses,
            active: 4,
            label: 'Despesas',
            format: (v) => money(v.round()),
          ),
        ),
        tamanho: const Size(360, 260),
        aguarde: 1000,
      ),
    ],
  ),
  Componente(
    'ss-exploded-donut',
    'SsExplodedDonut',
    'Rosca com fatias de espessuras diferentes, a selecionada destacada e o total no centro.',
    comportamentos: [
      'A maior fatia é a mais grossa; a selecionada sai para fora com mola e as outras apagam.',
      'Tocar na fatia ou na legenda seleciona; tocar de novo volta ao total.',
      'O centro mostra o valor e o percentual da selecionada.',
    ],
    estados: [
      Estado(
        'total',
        'sem seleção',
        (_) => _pad(
          SsExplodedDonut(
            size: 190,
            format: (v) => money(v.round()),
            slices: const [
              SsDonutSlice('Mercado', 128000),
              SsDonutSlice('Casa', 90000),
              SsDonutSlice('Transporte', 42000),
              SsDonutSlice('Lazer', 25000),
            ],
          ),
        ),
        tamanho: const Size(360, 320),
        aguarde: 1000,
      ),
      Estado(
        'selecionada',
        'Casa selecionada',
        (_) => _pad(
          SsExplodedDonut(
            size: 190,
            selected: 1,
            format: (v) => money(v.round()),
            slices: const [
              SsDonutSlice('Mercado', 128000),
              SsDonutSlice('Casa', 90000),
              SsDonutSlice('Transporte', 42000),
              SsDonutSlice('Lazer', 25000),
            ],
          ),
        ),
        tamanho: const Size(360, 320),
        aguarde: 1000,
      ),
    ],
  ),
  Componente(
    'ss-level-card',
    'SsLevelCard',
    'Programa de pontos: saldo grande, nível num selo, barra até o próximo nível e a lista "gastou → ganhou".',
    comportamentos: [
      'O saldo conta de 0 até o valor ao aparecer (DM Mono, milhar com ponto).',
      'A barra e o texto dizem quanto falta para o próximo nível.',
      'Cada linha mostra o valor gasto e os pontos ganhos em verde.',
    ],
    estados: [
      Estado(
        'ouro',
        'nível Ouro',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsLevelCard(
            points: 12480,
            level: 'Ouro',
            nextLevel: 'Platina',
            progress: .72,
            pointsToNext: 2520,
            entries: [
              SsLevelEntry('Supermercado Boa Vista', 34590, 345, icon: Icons.shopping_cart_outlined),
              SsLevelEntry('Posto Avenida', 21000, 210, icon: Icons.local_gas_station_outlined),
            ],
          ),
        ),
        tamanho: const Size(360, 360),
        aguarde: 800,
      ),
    ],
  ),
  Componente(
    'ss-price-board',
    'SsPriceBoard',
    'Quadro de cotações compra/venda com ícone, nome, duas colunas em DM Mono e a variação colorida pelo sentido.',
    comportamentos: [
      'Variação verde quando é boa e vermelha quando é ruim (goodWhenUp: false inverte para quem compra).',
      'highlighted destaca uma linha no tom da marca.',
      'Tocar numa linha chama onTap com o índice.',
    ],
    estados: [
      Estado(
        'cotacoes',
        'moedas, com o dólar destacado',
        (_) => Padding(
          padding: const EdgeInsets.all(12),
          child: SsPriceBoard(
            highlighted: 0,
            onTap: (_) {},
            rows: const [
              SsPriceRow(
                name: 'Dólar',
                code: 'USD',
                buy: 'R\$ 5,42',
                sell: 'R\$ 5,61',
                change: .84,
                goodWhenUp: false,
                icon: Icons.attach_money_rounded,
              ),
              SsPriceRow(
                name: 'Euro',
                code: 'EUR',
                buy: 'R\$ 5,88',
                sell: 'R\$ 6,09',
                change: -.32,
                goodWhenUp: false,
                icon: Icons.euro_rounded,
              ),
              SsPriceRow(
                name: 'Saca de soja',
                code: '60 kg',
                buy: 'R\$ 128,40',
                sell: 'R\$ 131,10',
                change: 1.2,
                icon: Icons.grass_outlined,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-big-ring',
    'SsBigRing',
    'Percentual grande num anel fino com marcações em volta, estilo termostato.',
    comportamentos: [
      'As marcações até o valor acendem na cor da marca; a ponta do arco tem um ponto.',
      'Enche e conta de 0 ao valor ao aparecer (desliga com menos movimento).',
      'caption vai embaixo do número ("da meta", "umidade").',
    ],
    estados: [
      Estado(
        'meta',
        '52% da meta',
        (_) => _pad(const SsBigRing(.52, caption: 'da meta', size: 190)),
        tamanho: const Size(360, 230),
        aguarde: 1100,
      ),
    ],
  ),
  Componente(
    'ss-floating-bars',
    'SsFloatingBars',
    'Barras verticais grandes dentro de um card na cor da marca; a selecionada branca com o valor em cima.',
    comportamentos: [
      'Tocar numa barra seleciona (tique) e chama onSelect.',
      'As barras crescem de baixo com mola ao aparecer.',
      'Fundo na cor da marca do tema claro nos dois temas (texto branco com contraste AA).',
    ],
    estados: [
      Estado(
        'semana',
        'semana com quinta selecionada',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsFloatingBars(
            title: 'Vendas da semana',
            value: money(1843000),
            labels: const ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
            values: const [210000, 260000, 190000, 420000, 330000, 280000, 153000],
            selected: 3,
            format: (v) => money(v.round()),
          ),
        ),
        tamanho: const Size(360, 300),
        aguarde: 900,
      ),
    ],
  ),
  // ------------------------------------------------------------- social e IA
  Componente(
    'ss-pulse-avatar',
    'SsPulseAvatar',
    'Avatar com ondas concêntricas pulsando: IA ouvindo, chamando, sincronizando.',
    comportamentos: [
      'Ativo: três ondas saem do avatar e somem, em ciclo de 2,2 s.',
      'Inativo: as ondas param. Com menos movimento: dois anéis parados no lugar das ondas.',
      'child troca o avatar (ícone da IA); status vai para o leitor de tela.',
    ],
    estados: [
      Estado(
        'ativo',
        'ouvindo e parado',
        (context) => _pad(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              SsPulseAvatar(
                size: 64,
                status: 'ouvindo',
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: SsColors.of(context).accent, shape: BoxShape.circle),
                  child: const Icon(Icons.graphic_eq_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SsPulseAvatar(name: 'Marina Costa', size: 64, active: false, status: 'em espera'),
            ],
          ),
        ),
        tamanho: const Size(360, 170),
        aguarde: 700,
      ),
    ],
  ),
  Componente(
    'ss-story-ring',
    'SsStoryRing',
    'Avatar com anel de status em gomos: novos no gradiente da marca, vistos numa linha neutra.',
    comportamentos: [
      'Um gomo por novidade; as primeiras seen ficam finas e neutras.',
      'onAdd põe um "+" no canto (adicionar o seu).',
      'caption (o nome) fica forte enquanto houver novidade.',
    ],
    estados: [
      Estado(
        'fileira',
        'seu, novos, parcial e visto',
        (_) => _pad(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 10,
            children: [
              SsStoryRing('Você', segments: 0, caption: 'Você', onAdd: () {}),
              SsStoryRing('Cauã Lima', caption: 'Cauã', onTap: () {}),
              SsStoryRing('Rita Souza', segments: 3, seen: 1, caption: 'Rita', onTap: () {}),
              SsStoryRing('Lia Prado', segments: 2, seen: 2, caption: 'Lia', onTap: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-avatar-extras',
    'SsAvatar e SsAvatarStack (v0.9)',
    'Parâmetros novos: contagem de não lidas e anel no SsAvatar; botão "+" no fim do SsAvatarStack.',
    comportamentos: [
      'SsAvatar(unread:) põe a contagem no canto de cima (99+ acima de 99) e o leitor de tela diz "n não lidas".',
      'SsAvatar(ring:) desenha um anel colorido em volta (selecionado, conversa nova).',
      'SsAvatarStack(onAdd:) fecha a fileira com um "+" de alvo de 48 dp (convidar, dividir com mais alguém).',
    ],
    estados: [
      Estado(
        'extras',
        'não lidas, anel e pilha com "+"',
        (context) => _pad(
          Row(
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: [
              const SsAvatar('Marina Costa', size: 44, unread: 3),
              const SsAvatar('Davi Torres', size: 44, unread: 128),
              SsAvatar('Lia Prado', size: 44, ring: SsColors.of(context).accent),
              SsAvatarStack(const ['Ana', 'Bruno Reis', 'Caio', 'Duda'], onAdd: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 100),
      ),
    ],
  ),
  Componente(
    'ss-profile-hero',
    'SsProfileHero',
    'Cabeçalho de perfil: foto grande arredondada, nome, status e métricas em destaque, com a borda de baixo curva.',
    comportamentos: [
      'Sem foto, usa o SsAvatar com a cor estável do nome.',
      'online põe o ponto verde ao lado do status.',
      'Até três métricas (valor em DM Mono e rótulo); actions e leading vão no topo.',
    ],
    estados: [
      Estado(
        'perfil',
        'com duas métricas',
        (context) => Align(
          alignment: Alignment.topCenter,
          child: SsProfileHero(
            name: 'Marina Costa',
            status: 'Vendedora · Zona Sul',
            online: true,
            metrics: const [('128', 'pedidos'), ('R\$ 84 mil', 'no mês')],
            leading: IconButton(onPressed: () {}, icon: const Icon(Icons.arrow_back_rounded), tooltip: 'Voltar'),
            actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded), tooltip: 'Mais')],
          ),
        ),
        tamanho: const Size(360, 380),
      ),
    ],
  ),
  Componente(
    'ss-celebrate',
    'SsCelebrate',
    'Envolve o que comemora: quando achieved vira verdadeiro, confete da suíte, haptic e um pulo de escala.',
    comportamentos: [
      'Só dispara na virada de falso para verdadeiro (não a cada rebuild).',
      'Usa o showSsConfetti existente; com menos movimento, só vibra.',
      'O filho dá um pulo até 1,08 e volta.',
    ],
    estados: [
      Estado(
        'meta',
        'meta batida (estado final)',
        (_) => _pad(const SsCelebrate(achieved: true, child: SsBigRing(1, caption: 'meta batida', size: 150))),
        tamanho: const Size(360, 190),
        aguarde: 1100,
      ),
    ],
  ),
  Componente(
    'ss-call-controls',
    'SsCallControls',
    'Fileira de botões redondos grandes de chamada ou ação ao vivo (vídeo, encerrar, microfone).',
    comportamentos: [
      'danger: vermelho e 20% maior (encerrar).',
      'active: fundo da marca e activeIcon (câmera ligada); o leitor de tela diz ligado/desligado.',
      'Sem onTap fica apagado; com labels, o nome vai embaixo.',
      'Segurar para falar (onHoldStart/onHoldEnd): encostar vibra, acende na cor da marca, cresce com halo e chama onHoldStart; soltar chama onHoldEnd.',
    ],
    estados: [
      Estado(
        'chamada',
        'vídeo ligado, encerrar e microfone',
        (_) => _pad(
          SsCallControls(
            labels: true,
            actions: [
              SsCallAction(
                Icons.videocam_off_outlined,
                'Vídeo',
                activeIcon: Icons.videocam_rounded,
                active: true,
                onTap: () {},
              ),
              SsCallAction(Icons.call_end_rounded, 'Encerrar', danger: true, onTap: () {}),
              SsCallAction(Icons.mic_none_rounded, 'Microfone', onTap: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 150),
      ),
      Estado(
        'segurar',
        'interfone: segure para falar',
        (_) => _pad(
          SsCallControls(
            labels: true,
            actions: [
              SsCallAction(Icons.lock_open_rounded, 'Abrir', onTap: () {}),
              SsCallAction(
                Icons.mic_none_rounded,
                'Falar',
                activeIcon: Icons.mic_rounded,
                onHoldStart: () {},
                onHoldEnd: () {},
              ),
              SsCallAction(Icons.call_end_rounded, 'Encerrar', danger: true, onTap: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
];
