// Telas montadas da v0.9 (lote b).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:flutter/material.dart';

import 'tela_demo.dart';

final telasB = <TelaDemo>[
  TelaDemo(
    'Dividir conta',
    'Total no card de luz, pessoas em pílulas, divisão com soma travada e arrastar para confirmar.',
    (_) => const _DividirConta(),
    icone: Icons.call_split_rounded,
  ),
  TelaDemo(
    'Minhas tarefas',
    'Faixa de dias com o mês no cabeçalho e a agenda do dia com blocos de status.',
    (_) => const _MinhasTarefas(),
    icone: Icons.event_note_outlined,
  ),
  TelaDemo(
    'Histórico',
    'Duo de valores, período, gráfico de área com o mês ativo e transações com saldo depois.',
    (_) => const _Historico(),
    icone: Icons.show_chart_rounded,
  ),
  TelaDemo(
    'IA ouvindo',
    'Avatar que pulsa enquanto a IA escuta, transcrição ao vivo e controles de chamada.',
    (_) => const _IaOuvindo(),
    icone: Icons.graphic_eq_rounded,
  ),
];

// ---------------------------------------------------------------------------
// Dividir conta
// ---------------------------------------------------------------------------

class _DividirConta extends StatefulWidget {
  const _DividirConta();

  @override
  State<_DividirConta> createState() => _DividirContaState();
}

class _DividirContaState extends State<_DividirConta> {
  static const _total = 75086;
  static const _amigos = ['Cauã Lima', 'Rita Souza', 'Lia Prado', 'Davi Torres', 'Bruno Reis'];
  var _com = <String>{'Cauã Lima', 'Rita Souza'};

  List<SsSplitEntry> get _entradas {
    final nomes = ['Eu', ..._amigos.where(_com.contains)];
    final parte = _total ~/ nomes.length;
    return [
      for (var i = 0; i < nomes.length; i++)
        SsSplitEntry(nomes[i], i == 0 ? _total - parte * (nomes.length - 1) : parte),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final entradas = _entradas;
    return Scaffold(
      appBar: AppBar(title: const Text('Dividir conta')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SsAuroraCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Jantar da equipe',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .8),
                      fontSize: AppType.sub,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SsAmount(money(_total), color: Colors.white),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${entradas.length} pessoas · ${money(_total ~/ entradas.length)} cada',
                          style: TextStyle(color: Colors.white.withValues(alpha: .85), fontSize: AppType.sub),
                        ),
                      ),
                      SsAvatarStack([for (final e in entradas) e.name], max: 3, size: 30),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 20, 16, 4), child: SsSectionHeader('Com quem')),
          SsPeoplePicker(
            people: _amigos,
            selected: _com,
            onAdd: () => showSsToast(context, 'Convite enviado'),
            onChanged: (s) => setState(() => _com = s),
          ),
          const Padding(padding: EdgeInsets.fromLTRB(16, 16, 16, 4), child: SsSectionHeader('Quanto cada um')),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SsCard(
              child: SsSplitSlider(
                key: ValueKey(entradas.map((e) => e.name).join('|')),
                total: _total,
                entries: entradas,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Text(
              'Mexa em uma parte e o resto se ajusta para fechar o total.',
              style: TextStyle(color: c.muted, fontSize: AppType.meta),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SsSwipeToConfirm(
          label: 'Arraste para dividir',
          doneLabel: 'Pedidos enviados',
          onConfirm: () => Future<void>.delayed(const Duration(milliseconds: 900)),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Minhas tarefas
// ---------------------------------------------------------------------------

class _MinhasTarefas extends StatefulWidget {
  const _MinhasTarefas();

  @override
  State<_MinhasTarefas> createState() => _MinhasTarefasState();
}

typedef _Tarefa = (String status, SsBadgeVariant, double progresso, List<String> pessoas);

class _MinhasTarefasState extends State<_MinhasTarefas> {
  late DateTime _dia = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<SsAgendaEvent> _eventos(SsColors c) {
    // Muda a agenda conforme o dia, só para a vitrine ter vida.
    final par = _dia.day.isEven;
    return [
      SsAgendaEvent(
        start: const TimeOfDay(hour: 8, minute: 30),
        end: const TimeOfDay(hour: 10, minute: 0),
        title: par ? 'Visitar a Padaria Sol' : 'Rota da Zona Sul',
        subtitle: 'Carteira',
        color: AppColors.success,
        data: ('Concluída', SsBadgeVariant.success, 1.0, ['Marina Costa', 'Cauã Lima']),
      ),
      SsAgendaEvent(
        start: const TimeOfDay(hour: 10, minute: 30),
        end: const TimeOfDay(hour: 12, minute: 0),
        title: 'Pedido do Mercado Bom Preço',
        subtitle: 'Pedidos',
        color: c.accent,
        data: ('Em andamento', SsBadgeVariant.accent, .72, ['Rita Souza', 'Lia Prado', 'Davi Torres', 'Bruno Reis']),
      ),
      SsAgendaEvent(
        start: const TimeOfDay(hour: 13, minute: 30),
        end: const TimeOfDay(hour: 14, minute: 0),
        title: 'Ligar para o financeiro',
        icon: Icons.call_outlined,
        color: AppColors.series[2],
      ),
      SsAgendaEvent(
        start: const TimeOfDay(hour: 15, minute: 0),
        end: const TimeOfDay(hour: 16, minute: 30),
        title: 'Reunião de metas',
        color: AppColors.series[4],
        data: ('A fazer', SsBadgeVariant.ghost, 0.0, ['Marina Costa', 'Cauã Lima', 'Rita Souza']),
      ),
    ];
  }

  Widget _bloco(BuildContext context, SsAgendaEvent e) {
    final c = SsColors.of(context);
    final t = e.data as _Tarefa?;
    final cor = e.color ?? c.accent;
    if (t == null) {
      // Sem dados de tarefa: um lembrete simples numa linha.
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Color.alphaBlend(cor.withValues(alpha: c.isDark ? .22 : .14), c.surface),
          borderRadius: BorderRadius.circular(AppRadius.field),
        ),
        child: Row(
          children: [
            Icon(e.icon ?? Icons.alarm_rounded, size: 16, color: cor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                e.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: AppType.sub),
              ),
            ),
          ],
        ),
      );
    }
    final (status, variante, progresso, pessoas) = t;
    return SsPressable(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border(left: BorderSide(color: cor, width: 4)),
          boxShadow: AppShadows.card,
        ),
        child: LayoutBuilder(
          builder: (context, box) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SsBadge(status, variant: variante, micro: true),
                  const Spacer(),
                  Text(
                    '${(progresso * 100).round()}%',
                    style: AppTheme.number(context, size: AppType.meta, color: c.muted),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                e.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: c.ink, fontSize: AppType.body, fontWeight: FontWeight.w800),
              ),
              if (box.maxHeight > 80) ...[
                const Spacer(),
                Row(
                  children: [
                    SsAvatarStack(pessoas, size: 26, onAdd: () {}),
                    const SizedBox(width: 12),
                    Expanded(child: SsProgress(progresso, height: 6, color: cor)),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final hoje = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas tarefas'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.add_rounded), tooltip: 'Nova tarefa')],
      ),
      body: Column(
        children: [
          SsDateStrip(
            selected: _dia,
            today: hoje,
            markers: {
              for (var d = 1; d <= 28; d += 3) DateTime(_dia.year, _dia.month, d): [c.accent],
              for (var d = 2; d <= 28; d += 5) DateTime(_dia.year, _dia.month, d): [AppColors.success, c.accent],
            },
            onChanged: (d) => setState(() => _dia = d),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: c.surface.withValues(alpha: c.isDark ? .5 : .6),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: SsDayAgenda(
                  key: ValueKey(_dia),
                  startHour: 8,
                  endHour: 17,
                  hourHeight: 80,
                  now: _dia == DateTime(hoje.year, hoje.month, hoje.day) ? TimeOfDay.fromDateTime(hoje) : null,
                  events: _eventos(c),
                  eventBuilder: _bloco,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Histórico
// ---------------------------------------------------------------------------

class _Historico extends StatefulWidget {
  const _Historico();

  @override
  State<_Historico> createState() => _HistoricoState();
}

class _HistoricoState extends State<_Historico> {
  var _periodo = 'mes';
  int _mes = 4;

  static const _rotulos = {
    'mes': ['Jan', 'Fev', 'Mar', 'Abr', 'Mai', 'Jun', 'Jul', 'Ago'],
    'semana': ['S1', 'S2', 'S3', 'S4', 'S5', 'S6'],
    'dia': ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'],
  };
  static const _valores = {
    'mes': [420000.0, 515000, 468000, 610000, 664000, 580000, 640000, 598000],
    'semana': [142000.0, 168000, 121000, 190000, 155000, 176000],
    'dia': [18000.0, 32000, 21000, 45000, 38000, 61000, 27000],
  };

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    final valores = [for (final v in _valores[_periodo]!) v.toDouble()];
    final rotulos = _rotulos[_periodo]!;
    final ativo = _mes.clamp(0, valores.length - 1);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico'),
        actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.more_horiz_rounded), tooltip: 'Mais')],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: SsStatCard(
                  label: 'Despesas',
                  value: money(664000),
                  icon: Icons.arrow_upward_rounded,
                  tone: AppColors.danger,
                  valueSize: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SsStatCard(
                  label: 'Receitas',
                  value: money(846000),
                  icon: Icons.arrow_downward_rounded,
                  tone: AppColors.success,
                  valueSize: 22,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SsSegmented<String>(
            segments: const [('mes', 'Mês'), ('semana', 'Semana'), ('dia', 'Dia')],
            value: _periodo,
            onChanged: (p) => setState(() {
              _periodo = p;
              _mes = _valores[p]!.length - 1;
            }),
          ),
          const SizedBox(height: 12),
          SsAreaChart(
            key: ValueKey(_periodo),
            values: valores,
            labels: rotulos,
            active: ativo,
            label: 'Despesas',
            format: (v) => money(v.round()),
            onSelect: (i) => setState(() => _mes = i),
          ),
          SsGroupHeader('Transações · ${rotulos[ativo]}', trailing: money(-(valores[ativo] * .06).round())),
          SsListItem(
            icon: Icons.shopping_bag_outlined,
            title: 'Loja de Roupas Centro',
            subtitle: '•••• 4821 · 14:32',
            value: money(-12950),
            valueCaption: 'saldo ${money(321000)}',
            tone: AppColors.series[2],
          ),
          SsListItem(
            leading: const SsAvatar('Joana Freitas', size: 42),
            title: 'Joana Freitas',
            subtitle: 'Pix enviado · 11:05',
            value: money(-8000),
            valueCaption: 'saldo ${money(333950)}',
          ),
          SsListItem(
            icon: Icons.work_outline_rounded,
            title: 'Salário',
            subtitle: 'Transferência · 08:00',
            value: '+${money(260000)}',
            valueColor: c.successText,
            valueCaption: 'saldo ${money(341950)}',
            tone: AppColors.success,
          ),
          SsListItem(
            icon: Icons.local_cafe_outlined,
            title: 'Café da Praça',
            subtitle: '•••• 4821 · ontem',
            value: money(-1890),
            valueCaption: 'saldo ${money(81950)}',
            tone: AppColors.series[4],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// IA ouvindo
// ---------------------------------------------------------------------------

class _IaOuvindo extends StatefulWidget {
  const _IaOuvindo();

  @override
  State<_IaOuvindo> createState() => _IaOuvindoState();
}

class _IaOuvindoState extends State<_IaOuvindo> {
  bool _ouvindo = true;
  bool _camera = false;

  @override
  Widget build(BuildContext context) {
    final c = SsColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Assistente')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const Spacer(),
              SsPulseAvatar(
                size: 104,
                active: _ouvindo,
                status: _ouvindo ? 'ouvindo' : 'pausado',
                child: AnimatedContainer(
                  duration: SsMotion.base,
                  width: 104,
                  height: 104,
                  decoration: BoxDecoration(
                    color: _ouvindo ? c.accent : c.field,
                    shape: BoxShape.circle,
                    boxShadow: _ouvindo ? c.activeShadow : null,
                  ),
                  child: Icon(
                    _ouvindo ? Icons.graphic_eq_rounded : Icons.mic_off_outlined,
                    size: 44,
                    color: _ouvindo ? Colors.white : c.muted,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              AnimatedSwitcher(
                duration: SsMotion.base,
                child: Text(
                  _ouvindo ? 'Estou ouvindo…' : 'Pausado',
                  key: ValueKey(_ouvindo),
                  style: TextStyle(color: c.ink, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -.3),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Diga o que gastou, por exemplo: "almoço, 32 reais no débito".',
                textAlign: TextAlign.center,
                style: TextStyle(color: c.muted, fontSize: AppType.body),
              ),
              const SizedBox(height: 24),
              const SsChatBubble(text: 'Almoço no restaurante da esquina, 32 reais no débito', fromMe: true),
              const SizedBox(height: 8),
              const Align(
                alignment: Alignment.centerLeft,
                child: SsThinking(text: 'Lançando despesa'),
              ),
              const Spacer(),
              SsAttachBar(
                items: [
                  SsAttachItem(Icons.photo_camera_outlined, 'Cupom', onTap: () {}),
                  SsAttachItem(Icons.description_outlined, 'Fatura', onTap: () {}),
                  SsAttachItem(Icons.place_outlined, 'Local', onTap: () {}),
                ],
              ),
              const SizedBox(height: 24),
              SsCallControls(
                actions: [
                  SsCallAction(
                    Icons.videocam_off_outlined,
                    'Câmera',
                    activeIcon: Icons.videocam_rounded,
                    active: _camera,
                    onTap: () => setState(() => _camera = !_camera),
                  ),
                  SsCallAction(Icons.close_rounded, 'Encerrar', danger: true, onTap: () => Navigator.maybePop(context)),
                  SsCallAction(
                    Icons.mic_off_outlined,
                    'Microfone',
                    activeIcon: Icons.mic_rounded,
                    active: _ouvindo,
                    onTap: () => setState(() => _ouvindo = !_ouvindo),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
