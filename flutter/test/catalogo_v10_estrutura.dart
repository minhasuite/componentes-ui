// Entradas do catálogo da v0.10 (estrutura): seletor de ícone, seletor de
// idioma, lista de blocos (editor de automação) e grupo recolhível.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

/// Estado local para a vitrine ser interativa.
class _Vivo<T> extends StatefulWidget {
  const _Vivo(this.inicio, this.build);
  final T inicio;
  final Widget Function(T valor, ValueChanged<T> muda) build;

  @override
  State<_Vivo<T>> createState() => _VivoState<T>();
}

class _VivoState<T> extends State<_Vivo<T>> {
  late T v = widget.inicio;

  @override
  Widget build(BuildContext context) => widget.build(v, (n) => setState(() => v = n));
}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

/// Fichas de cor de luz do catálogo (cores de lâmpada, não da marca).
const _coresLuz = [
  Color(0xFFFFB74D),
  Color(0xFFFFE8C2),
  Color(0xFFF4F8FF),
  Color(0xFFFF8FB1),
  Color(0xFFB39DFF),
  Color(0xFF64B5F6),
];

const _icones = [
  ('lightbulb', Icons.lightbulb_outline_rounded),
  ('lamp', Icons.light_outlined),
  ('power-socket', Icons.power_outlined),
  ('fan', Icons.mode_fan_off_outlined),
  ('thermometer', Icons.thermostat_rounded),
  ('air-conditioner', Icons.ac_unit_rounded),
  ('door', Icons.sensor_door_outlined),
  ('window', Icons.window_outlined),
  ('lock', Icons.lock_outline_rounded),
  ('camera', Icons.videocam_outlined),
  ('television', Icons.tv_rounded),
  ('speaker', Icons.speaker_outlined),
  ('water', Icons.water_drop_outlined),
  ('garage', Icons.garage_outlined),
  ('sofa', Icons.weekend_outlined),
  ('bed', Icons.bed_outlined),
  ('kitchen', Icons.kitchen_outlined),
  ('car', Icons.directions_car_outlined),
  ('sun', Icons.wb_sunny_outlined),
  ('moon', Icons.nightlight_outlined),
  ('bell', Icons.notifications_none_rounded),
  ('home', Icons.home_outlined),
  ('robot-vacuum', Icons.cleaning_services_outlined),
  ('plant', Icons.local_florist_outlined),
];

Widget _campo(String rotulo, String valor) => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(color: c.field, borderRadius: BorderRadius.circular(AppRadius.field)),
      child: Row(
        children: [
          Text(
            rotulo,
            style: TextStyle(color: c.muted, fontSize: AppType.meta),
          ),
          const Spacer(),
          Text(
            valor,
            style: TextStyle(color: c.ink, fontWeight: FontWeight.w700, fontSize: AppType.sub),
          ),
        ],
      ),
    );
  },
);

List<SsBlock> _automacao() => [
  SsBlock(
    id: 'g1',
    title: 'Quando',
    summary: 'A porta da frente abrir',
    icon: Icons.bolt_rounded,
    tone: SsTone.warning,
    initiallyExpanded: true,
    body: _campo('Sensor', 'Porta da frente'),
  ),
  SsBlock(
    id: 'c1',
    title: 'Se',
    summary: 'Depois das 22:00 e alguém em casa',
    icon: Icons.rule_rounded,
    tone: SsTone.info,
    body: _campo('Horário', 'Depois das 22:00'),
  ),
  SsBlock(
    id: 'a1',
    title: 'Então',
    summary: '2 ações',
    icon: Icons.play_arrow_rounded,
    tone: SsTone.success,
    initiallyExpanded: true,
    children: [
      SsBlock(
        id: 'a1.1',
        title: 'Acender luz',
        summary: 'Hall de entrada, 60%',
        icon: Icons.lightbulb_outline_rounded,
        body: _campo('Brilho', '60%'),
      ),
      const SsBlock(
        id: 'a1.2',
        title: 'Avisar no celular',
        summary: 'Sem destino escolhido',
        icon: Icons.notifications_none_rounded,
        error: 'Escolha para quem avisar.',
      ),
    ],
  ),
  const SsBlock(id: 'a2', title: 'Tocar música', summary: 'Desligado', icon: Icons.music_note_outlined, enabled: false),
];

/// Editor de mentira: guarda a lista e aplica mover/ligar/duplicar/excluir.
class _Editor extends StatefulWidget {
  const _Editor({this.focusedId});
  final String? focusedId;

  @override
  State<_Editor> createState() => _EditorState();
}

class _EditorState extends State<_Editor> {
  late List<SsBlock> blocos = _automacao();

  List<SsBlock> _troca(List<SsBlock> lista, SsBlock alvo, List<SsBlock> Function(List<SsBlock>, int) f) {
    final i = lista.indexWhere((b) => b.id == alvo.id);
    if (i >= 0) return f([...lista], i);
    return [
      for (final b in lista)
        SsBlock(
          id: b.id,
          title: b.title,
          summary: b.summary,
          icon: b.icon,
          enabled: b.enabled,
          error: b.error,
          tone: b.tone,
          body: b.body,
          initiallyExpanded: b.initiallyExpanded,
          children: _troca(b.children, alvo, f),
        ),
    ];
  }

  SsBlock _com(SsBlock b, {bool? enabled, String? id}) => SsBlock(
    id: id ?? b.id,
    title: b.title,
    summary: b.summary,
    icon: b.icon,
    enabled: enabled ?? b.enabled,
    error: b.error,
    tone: b.tone,
    body: b.body,
    initiallyExpanded: b.initiallyExpanded,
    children: b.children,
  );

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const EdgeInsets.all(12),
    child: SsBlockList(
      blocks: blocos,
      focusedId: widget.focusedId,
      onToggle: (b, v) => setState(() => blocos = _troca(blocos, b, (l, i) => l..[i] = _com(b, enabled: v))),
      onMove: (b, para) => setState(
        () => blocos = _troca(blocos, b, (l, i) {
          final x = l.removeAt(i);
          return l..insert(para, x);
        }),
      ),
      onDuplicate: (b) =>
          setState(() => blocos = _troca(blocos, b, (l, i) => l..insert(i + 1, _com(b, id: '${b.id}+${l.length}')))),
      onDelete: (b) => setState(() => blocos = _troca(blocos, b, (l, i) => l..removeAt(i))),
    ),
  );
}

final catalogoV10Estrutura = <Componente>[
  Componente(
    'ss-icon-picker',
    'SsIconPicker',
    'Grade de ícones com busca e anel no escolhido. Os ícones vêm do app como (nome, IconData) (o produto usa a fonte MDI); devolve o nome.',
    comportamentos: [
      'Busca sem acento e sem caixa; "-" e "_" valem espaço.',
      'Escolhido: anel e fundo na cor da marca, com o pulinho da mola (SsPop).',
      'allowNone põe "Sem ícone" no começo; busca sem resultado mostra a mensagem com o termo.',
      'Cada célula tem o nome no tooltip e no leitor de tela (selected).',
      'labels (nome → rótulo): o rótulo vai na dica e no leitor de tela no lugar do nome cru, e a busca acha pelos dois.',
    ],
    estados: [
      Estado(
        'selecionado',
        'escolhido (toque troca)',
        (_) => _Vivo<String?>(
          'lightbulb',
          (v, muda) => Padding(
            padding: const EdgeInsets.all(16),
            child: SsIconPicker(icons: _icones, value: v, onChanged: muda, height: 230),
          ),
        ),
        tamanho: const Size(360, 330),
      ),
      Estado(
        'nenhum',
        'nenhum (com "Sem ícone")',
        (_) => _Vivo<String?>(
          null,
          (v, muda) => Padding(
            padding: const EdgeInsets.all(16),
            child: SsIconPicker(icons: _icones, value: v, onChanged: muda, allowNone: true, height: 230),
          ),
        ),
        tamanho: const Size(360, 330),
      ),
      Estado(
        'busca-vazia',
        'busca sem resultado',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsIconPicker(icons: _icones, value: null, onChanged: (_) {}, initialQuery: 'piscina', height: 120),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'com-rotulos',
        'labels: nome legível na dica, no leitor de tela e na busca ("lâmpada")',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsIconPicker(
            icons: _icones,
            value: 'lightbulb',
            onChanged: (_) {},
            labels: const {'lightbulb': 'Lâmpada'},
            initialQuery: 'lâmpada',
            height: 120,
          ),
        ),
        tamanho: const Size(360, 220),
      ),
    ],
  ),
  Componente(
    'ss-color-picker',
    'SsColorPicker',
    'Escolha de cor por fichas redondas, com a cor livre opcional (free): matiz, saturação, brilho e código hex numa folha. '
        'No Rails: Ss::SwatchPickerComponent(free: true).',
    comportamentos: [
      'Ficha escolhida ganha anel na cor da marca e ✓ no contraste da cor; cor clara tem fio na borda.',
      'free: a última ficha é a "Personalizada" (arco-íris, ou a cor livre escolhida) e abre a folha (showSsColorSheet).',
      'Na folha, os sliders e o hex se acompanham; hex inválido mostra "Use o formato #RRGGBB".',
      'names dá o nome de cada cor para a dica e o leitor de tela.',
    ],
    estados: [
      Estado(
        'fichas',
        'fichas com a escolhida',
        (_) => _pad(
          SsColorPicker(
            label: 'Cor da luz',
            colors: _coresLuz,
            names: const ['Âmbar', 'Branco quente', 'Branco frio', 'Rosa', 'Lilás', 'Azul'],
            value: _coresLuz[1],
            onChanged: (_) {},
            free: true,
          ),
        ),
        tamanho: const Size(360, 160),
      ),
      Estado(
        'livre-escolhida',
        'cor livre escolhida (fora das fichas)',
        (_) => _pad(SsColorPicker(colors: _coresLuz, value: const Color(0xFF2EC4B6), onChanged: (_) {}, free: true)),
        tamanho: const Size(360, 110),
      ),
      Estado(
        'folha',
        'folha da cor livre',
        (_) => _pad(const SsColorPickerSheet(initial: Color(0xFFFF8A3D))),
        tamanho: const Size(360, 470),
      ),
    ],
  ),
  Componente(
    'ss-locale-picker',
    'SsLocalePicker',
    'Escolha de idioma: lista com o atual marcado ou segmented. Nome no próprio idioma (Português, English, Español) e a bandeira ou o código.',
    comportamentos: [
      'Lista: o ✓ se desenha no escolhido (SsCheckMark) e o nome fica em negrito.',
      'segmented: true usa o SsSegmented com a pílula que desliza.',
      'showFlag: false (ou sem bandeira) mostra o código ("PT", "EN", "ES").',
      'Leitor de tela: grupo exclusivo com "checked" no atual.',
      'systemOption: true + onSystem: a opção "Seguir o sistema" (no segmented, "Auto") no começo, marcada quando value é nulo.',
    ],
    estados: [
      Estado(
        'lista',
        'lista (toque troca)',
        (_) => _Vivo<String>(
          'pt-BR',
          (v, muda) => Padding(
            padding: const EdgeInsets.all(16),
            child: SsLocalePicker(value: v, onChanged: muda, showFlag: false),
          ),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'segmented',
        'segmented',
        (_) => _Vivo<String>(
          'en',
          (v, muda) => Padding(
            padding: const EdgeInsets.all(16),
            child: SsLocalePicker(value: v, onChanged: muda, segmented: true, showFlag: false),
          ),
        ),
        tamanho: const Size(360, 80),
      ),
      Estado(
        'sistema',
        'systemOption: "Seguir o sistema" no começo (marcada com value nulo)',
        (_) => _Vivo<String?>(
          null,
          (v, muda) => Padding(
            padding: const EdgeInsets.all(16),
            child: SsLocalePicker(value: v, onChanged: muda, systemOption: true, onSystem: () => muda(null)),
          ),
        ),
        tamanho: const Size(360, 280),
      ),
      Estado(
        'sistema-segmented',
        'systemOption no segmented ("Auto")',
        (_) => _Vivo<String?>(
          null,
          (v, muda) => Padding(
            padding: const EdgeInsets.all(16),
            child: SsLocalePicker(
              value: v,
              onChanged: muda,
              segmented: true,
              showFlag: false,
              systemOption: true,
              onSystem: () => muda(null),
            ),
          ),
        ),
        tamanho: const Size(360, 80),
      ),
    ],
  ),
  Componente(
    'ss-block-list',
    'SsBlockList',
    'Lista ordenada de blocos recolhíveis: o núcleo genérico de um editor de automação. Cabeçalho com ícone, resumo, liga/desliga, ⋮ (mover, duplicar, excluir), seta; corpo do app; aninha.',
    comportamentos: [
      'Toque no cabeçalho abre/fecha com a mola; a seta gira junto.',
      'Alça ⠿ arrasta para reordenar; no ⋮, "Mover para cima/baixo" (onMove recebe o bloco e o índice novo).',
      'Desligado: ícone, texto e corpo apagados. Com erro: borda vermelha e a mensagem (região viva).',
      'focusedId: anel na cor da marca no bloco em foco.',
      'Blocos filhos aparecem no corpo, com um fio na cor do tom do pai.',
      'SsBlock(duplicable: false) tira "Duplicar" do ⋮ só daquele bloco.',
      'deleteConfirm: pergunta antes de excluir (diálogo de perigo com o título do bloco); vale nos aninhados.',
    ],
    estados: [
      Estado('editor', 'editor completo (interativo)', (_) => const _Editor(), tamanho: const Size(360, 720)),
      Estado('foco', 'em foco · recolhidos', (_) => const _Editor(focusedId: 'c1'), tamanho: const Size(360, 720)),
    ],
  ),
  Componente(
    'ss-collapsible',
    'SsCollapsible',
    'Grupo recolhível: cabeçalho com seta, contagem e selo colorido opcional; o corpo abre com a mola.',
    comportamentos: [
      'Abre com a mola (passa um tiquinho e assenta); fecha rápido sem mola; direto com "reduzir movimento".',
      'A seta gira 90° com a mola.',
      'Leitor de tela: botão com "expanded".',
      'Selo usa os tons da suíte (SsTone).',
    ],
    estados: [
      Estado(
        'grupos',
        'aberto · fechado (toque abre)',
        (_) => SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SsCollapsible(
                title: 'Sala de estar',
                icon: Icons.weekend_outlined,
                count: 3,
                label: '2 ligados',
                labelTone: SsTone.success,
                initiallyExpanded: true,
                child: Column(
                  spacing: 8,
                  children: [_campo('Luz do teto', 'Ligada'), _campo('Abajur', 'Ligado'), _campo('TV', 'Desligada')],
                ),
              ),
              SsCollapsible(
                title: 'Garagem',
                icon: Icons.garage_outlined,
                count: 2,
                label: 'Offline',
                labelTone: SsTone.danger,
                child: _campo('Portão', 'Sem sinal'),
              ),
              SsCollapsible(title: 'Cozinha', count: 5, child: _campo('Geladeira', '4 °C')),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
    ],
  ),
];
