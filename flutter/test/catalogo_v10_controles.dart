// Entradas do catálogo da v0.10 (controles da casa): tile de aparelho,
// slider, termostato, teclado de código e dias da semana.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

/// Guarda um valor para os controles controlados da vitrine.
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

/// Tile de luz que liga e desliga de verdade (com o comando "demorando" 600 ms).
class _LuzDemo extends StatefulWidget {
  const _LuzDemo({this.on = false, this.status = SsDeviceStatus.ready, this.wide = false, this.footer = false});
  final bool on;
  final SsDeviceStatus status;
  final bool wide;
  final bool footer;

  @override
  State<_LuzDemo> createState() => _LuzDemoState();
}

class _LuzDemoState extends State<_LuzDemo> {
  late bool on = widget.on;
  late SsDeviceStatus st = widget.status;
  double brilho = 80;

  Future<void> _toggle(bool v) async {
    setState(() => st = SsDeviceStatus.pending);
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) {
      setState(() {
        on = v;
        st = SsDeviceStatus.ready;
      });
    }
  }

  @override
  Widget build(BuildContext context) => SsDeviceTile(
    icon: Icons.lightbulb_outline_rounded,
    name: 'Luz da sala',
    state: on ? 'Ligada · ${brilho.round()}%' : 'Desligada',
    on: on,
    status: st,
    wide: widget.wide,
    onTap: () {},
    onToggle: _toggle,
    footer: widget.footer
        ? SsSlider(
            value: brilho,
            label: 'Brilho',
            track: SsSliderTrack.brightness,
            format: (v) => '${v.round()}%',
            onChanged: on ? (v) => setState(() => brilho = v) : null,
          )
        : null,
  );
}

Widget _grade(List<Widget> tiles) => Padding(
  padding: const EdgeInsets.all(16),
  child: GridView.count(
    crossAxisCount: 2,
    mainAxisSpacing: 12,
    crossAxisSpacing: 12,
    childAspectRatio: 1.05,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    children: tiles,
  ),
);

final List<Componente> catalogoV10Controles = [
  Componente(
    'ss-device-tile',
    'SsDeviceTile',
    'Tile de aparelho da casa numa linha (v0.12): o ícone é a chave rápida (onToggle), e à direita dele o nome e o estado em texto ("Ligada · 80%"); rodapé opcional (slider ou chips).',
    comportamentos: [
      'Tocar no tile abre os detalhes (onTap); tocar no ícone liga e desliga sem abrir (onToggle; interruptor no leitor de tela, Enter/Espaço com foco, alvo de 48 dp).',
      'v0.12: desligado com chave, o quadrado do ícone fica claro com contorno na cor do aparelho; ligado, cheio na cor.',
      'Ligado: fundo tinge com a cor do aparelho (color, padrão a marca), ícone cheio em gradiente e brilho na mesma cor.',
      'Indisponível: apagado, borda tracejada e "Indisponível"; a chave trava.',
      'Enviando (pending): anel girando em volta do ícone e a chave travada até a resposta.',
      'Erro: borda e texto em vermelho com o motivo (errorText); a chave volta a funcionar para tentar de novo.',
      'Sem permissão (locked): o ícone deixa de ser chave e o cadeado vai no fim; não liga nem desliga.',
      'Leitor de tela lê "nome: estado" e a dica de abrir detalhes; a chave tem alvo de 48 dp. Menos movimento tira as transições.',
      'Modo ação (onPress): tocar executa o comando (portão, cena, botão), com confirmação opcional (confirm/confirmTitle → showSsConfirm); dica "Acionar".',
      'color aceita a cor real da luz: em cor clara (amarelo-claro, branco quente) o ícone vira tinta escura para continuar legível.',
      'v0.10.3: onLongPress (menu, detalhes no modo ação; vibração média; ação "Mais opções" no leitor de tela, longPressLabel troca) e onDoubleTap (atalho; o toque simples espera o tempo do duplo). Valem até indisponível.',
    ],
    estados: [
      Estado(
        'compactos',
        'desligado · ligado (marca) · ligado (âmbar) · sem permissão',
        (_) => _grade([
          const _LuzDemo(),
          const _LuzDemo(on: true),
          SsDeviceTile(
            icon: Icons.local_fire_department_outlined,
            name: 'Aquecedor',
            state: 'Ligado · 24 °C',
            on: true,
            color: AppColors.aquecFg,
            onTap: () {},
            onToggle: (_) {},
          ),
          SsDeviceTile(
            icon: Icons.garage_outlined,
            name: 'Portão da garagem',
            state: 'Fechado',
            status: SsDeviceStatus.locked,
            onTap: () {},
          ),
        ]),
        tamanho: const Size(360, 380),
      ),
      Estado(
        'situacoes',
        'indisponível · enviando · erro',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              _LuzDemo(wide: true, status: SsDeviceStatus.unavailable),
              _LuzDemo(wide: true, on: true, status: SsDeviceStatus.pending),
              _LuzDemo(wide: true, status: SsDeviceStatus.error),
            ],
          ),
        ),
        tamanho: const Size(360, 300),
        aguarde: 200,
      ),
      Estado(
        'largo-rodape',
        'largo com slider de brilho no rodapé',
        (_) => const Padding(padding: EdgeInsets.all(16), child: _LuzDemo(wide: true, on: true, footer: true)),
        tamanho: const Size(360, 180),
      ),
      Estado(
        'acao-cor-luz',
        'ação (portão, cena) · luz em cor clara real',
        (_) => _grade([
          SsDeviceTile(
            icon: Icons.garage_outlined,
            name: 'Portão',
            state: 'Toque para abrir',
            onPress: () {},
            confirm: 'Abrir o portão da garagem?',
          ),
          SsDeviceTile(icon: Icons.movie_outlined, name: 'Cena cinema', state: 'Cena', onPress: () {}),
          SsDeviceTile(
            icon: Icons.lightbulb_outline_rounded,
            name: 'Abajur',
            state: 'Ligada · 2700 K',
            on: true,
            color: const Color(0xFFFFE9A8),
            onToggle: (_) {},
          ),
          SsDeviceTile(
            icon: Icons.lightbulb_outline_rounded,
            name: 'Fita LED',
            state: 'Ligada · branco',
            on: true,
            color: const Color(0xFFF5F5F0),
            onToggle: (_) {},
          ),
        ]),
        tamanho: const Size(360, 380),
      ),
    ],
  ),
  Componente(
    'ss-slider',
    'SsSlider',
    'Slider horizontal: trilha cheia na cor da marca ou em gradiente (brilho, kelvin, matiz), bolha com o valor no arrasto e a variante "fill" de tile (barra grossa em que a parte cheia é o valor).',
    comportamentos: [
      'Arrastar ou tocar muda o valor no passo (step), com tique de haptic; onChangeEnd vem ao soltar (a hora de mandar o comando).',
      'Arrastando, o seletor cresce com a mola (SsMotion.bounce) e a bolha com o valor sobe; ao soltar, somem.',
      'Trilha em gradiente: o seletor pega a cor do ponto (a cor da lâmpada no kelvin e no matiz).',
      'Teclado: setas sobem e descem um passo, Home e End vão às pontas; leitor de tela também.',
      'Sem onChanged fica apagado. Menos movimento tira a mola e o deslizar.',
      'decimals e unit: formato padrão com casas fixas e a vírgula ou o ponto do idioma (o %.1f do Rails sai "21,5 °C").',
      'helperText: dica fixa embaixo da trilha (SsFieldHelper).',
    ],
    estados: [
      Estado(
        'trilhas',
        'cheio · brilho · kelvin · matiz',
        (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
          child: Column(
            spacing: 6,
            children: [
              _Holder<double>(
                40,
                (v, set) => SsSlider(
                  value: v,
                  label: 'Volume',
                  showValue: true,
                  format: (x) => '${x.round()}%',
                  onChanged: set,
                ),
              ),
              _Holder<double>(
                70,
                (v, set) => SsSlider(
                  value: v,
                  label: 'Brilho',
                  showValue: true,
                  track: SsSliderTrack.brightness,
                  color: AppColors.aquecFg,
                  format: (x) => '${x.round()}%',
                  onChanged: set,
                ),
              ),
              _Holder<double>(
                3000,
                (v, set) => SsSlider(
                  value: v,
                  min: 2000,
                  max: 6500,
                  step: 100,
                  label: 'Temperatura de cor',
                  showValue: true,
                  track: SsSliderTrack.kelvin,
                  format: (x) => '${x.round()} K',
                  onChanged: set,
                ),
              ),
              _Holder<double>(
                200,
                (v, set) => SsSlider(
                  value: v,
                  max: 360,
                  label: 'Cor',
                  showValue: true,
                  track: SsSliderTrack.hue,
                  format: (x) => '${x.round()}°',
                  onChanged: set,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
      Estado(
        'fill',
        'variante fill (tile de brilho) · apagado',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              _Holder<double>(
                65,
                (v, set) => SsSlider(
                  value: v,
                  fill: true,
                  icon: Icons.lightbulb_outline_rounded,
                  label: 'Luz da cozinha',
                  format: (x) => '${x.round()}%',
                  onChanged: set,
                ),
              ),
              _Holder<double>(
                20,
                (v, set) => SsSlider(
                  value: v,
                  fill: true,
                  track: SsSliderTrack.brightness,
                  color: AppColors.aquecFg,
                  icon: Icons.light_outlined,
                  label: 'Abajur',
                  format: (x) => '${x.round()}%',
                  onChanged: set,
                ),
              ),
              SsSlider(value: 30, label: 'Sem permissão', format: (x) => '${x.round()}%', onChanged: null),
            ],
          ),
        ),
        tamanho: const Size(360, 230),
      ),
      Estado(
        'decimais-e-dica',
        'decimals + unit (vírgula do idioma) e helperText',
        (_) => _pad(
          SsSlider(
            label: 'Temperatura',
            value: 21.5,
            min: 16,
            max: 30,
            step: .5,
            decimals: 1,
            unit: '°C',
            showValue: true,
            helperText: 'O ar volta a esta temperatura ao ligar.',
            onChanged: (_) {},
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
  Componente(
    'ss-thermostat',
    'SsThermostat',
    'Termostato: anel de 270° com o alvo grande no centro, a temperatura atual embaixo e um tracinho no anel, botões −/+ e chips de modo. A cor do anel segue o modo.',
    comportamentos: [
      '−/+ andam um passo (step) na hora; onChanged só sai depois de debounce parado (vários toques = um comando).',
      'Arrastar no anel também muda (draggable); na "boca" de baixo gruda na ponta mais perto.',
      'Cor: aquecer âmbar, resfriar azul, desligado cinza, auto na marca; modo próprio passa o tone.',
      'Legenda no anel: Aquecendo, Resfriando, No alvo ou Desligado (action, ou deduzido do modo e da temperatura).',
      'pending mostra "Enviando…" com um anelzinho; sem onChanged, apagado. Nos limites (min/max) o botão trava.',
      'Teclado (setas) e leitor de tela sobem e descem; o seletor desliza com a mola (desliga com menos movimento).',
      'color (cor livre) ou tone (tom da suíte) pintam o anel sem precisar de modo; showModes: false esconde os chips.',
      'Linha da atual: "Agora 21,5°" (com espaço), currentText (texto pronto) ou currentFormat (monta a partir da atual).',
      'adjustWhenOff: desligado, o anel fica cinza mas o alvo ainda muda (programar antes de ligar).',
    ],
    estados: [
      Estado(
        'aquecendo',
        'aquecendo · 22,5° (agora 20°)',
        (_) => _pad(
          _Holder<double>(
            22.5,
            (v, set) => _Holder<String>(
              'heat',
              (m, setM) => SsThermostat(
                target: v,
                current: 20,
                mode: m,
                debounce: Duration.zero,
                onChanged: set,
                onModeChanged: setM,
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 480),
      ),
      Estado(
        'resfriando',
        'resfriando · no alvo · enviando',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsThermostat(target: 23, current: 26, mode: 'cool', size: 150, modes: [], onChanged: _nadaD),
              SsThermostat(
                target: 21,
                current: 21,
                mode: 'auto',
                size: 150,
                modes: [],
                pending: true,
                onChanged: _nadaD,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'desligado',
        'desligado · apagado (sem permissão)',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsThermostat(target: 21, current: 19, mode: 'off', size: 150, modes: [], onChanged: _nadaD),
              SsThermostat(target: 24, current: 23.5, mode: 'heat', size: 150, modes: [], onChanged: null),
            ],
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'desligado-ajustavel',
        'desligado, mas ajustável (adjustWhenOff)',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: Center(
            child: SsThermostat(
              target: 20,
              current: 18,
              mode: 'off',
              size: 170,
              adjustWhenOff: true,
              onChanged: _nadaD,
            ),
          ),
        ),
        tamanho: const Size(360, 400),
      ),
      Estado(
        'cor-sem-modos',
        'cor própria sem chips de modo · texto da atual pronto',
        (_) => Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              const SsThermostat(
                target: 22,
                current: 22,
                mode: 'auto',
                size: 150,
                showModes: false,
                color: Color(0xFF14B8A6),
                currentText: 'Sala 22°',
                onChanged: _nadaD,
              ),
              SsThermostat(
                target: 19,
                current: 24,
                mode: 'auto',
                size: 150,
                showModes: false,
                tone: SsTone.danger,
                currentFormat: (v) => 'Fora ${v.round()}°',
                onChanged: _nadaD,
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 240),
      ),
    ],
  ),
  Componente(
    'ss-code-keypad',
    'SsCodeKeypad',
    'Teclado de código do alarme: bolinhas dos dígitos, teclado 3×4 com apagar, envio ao completar (length) ou por botão, e botões extras ("Armar ausente", "Armar em casa").',
    comportamentos: [
      'Cada dígito estala a bolinha (mola solta); com length, envia sozinho ao completar.',
      'onSubmit devolve se valeu: esperando fica ocupado (teclado travado e anelzinho); falso treme as bolinhas em vermelho e limpa; verdadeiro mostra o ✓.',
      'obscure falso mostra os dígitos no lugar das bolinhas.',
      'Teclado físico: números, Backspace e Enter. Teclas de 64 dp; leitor de tela anuncia quantos dígitos.',
      'status força a situação vinda de fora (ex.: o servidor ainda armando). Menos movimento tira o tremor e a mola.',
      'onChanged avisa cada dígito; controller lê e troca o código de fora (clear() limpa e recomeça depois do ✓).',
      'actionsNeedCode: false deixa os botões de ações valerem com o código vazio (ex.: Desarmar sem senha).',
    ],
    estados: [
      Estado(
        'digitando',
        'digitando (2 de 4) com ações de armar',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsCodeKeypad(
            length: null,
            initialCode: '12',
            title: 'Código do alarme',
            actions: [
              SsCodeAction('Armar ausente', (_) async => true, icon: Icons.shield_outlined, primary: true),
              SsCodeAction('Armar em casa', (_) async => true, icon: Icons.home_outlined),
            ],
          ),
        ),
        tamanho: const Size(360, 580),
      ),
      Estado(
        'erro',
        'código errado (treme e limpa)',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsCodeKeypad(length: 4, initialCode: '1234', status: SsCodeStatus.error, onSubmit: (_) async => false),
        ),
        tamanho: const Size(360, 420),
        aguarde: 120,
      ),
      Estado(
        'ocupado-sucesso',
        'enviando · sucesso',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            children: [
              Expanded(
                child: SsCodeKeypad(
                  length: 4,
                  initialCode: '1234',
                  status: SsCodeStatus.busy,
                  onSubmit: (_) async => true,
                ),
              ),
              Expanded(
                child: SsCodeKeypad(
                  length: 4,
                  initialCode: '1234',
                  status: SsCodeStatus.success,
                  onSubmit: (_) async => true,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 420),
      ),
      Estado(
        'livre',
        'sem tamanho fixo, com botão de confirmar e dígitos à mostra',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsCodeKeypad(initialCode: '908', obscure: false, onSubmit: (c) async => c == '9081'),
        ),
        tamanho: const Size(360, 490),
      ),
      Estado(
        'acoes-sem-codigo',
        'vazio com ações que não pedem código',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsCodeKeypad(
            actionsNeedCode: false,
            actions: [
              SsCodeAction('Desarmar', (_) async => true, icon: Icons.lock_open_rounded, primary: true),
              SsCodeAction('Pânico', (_) async => true, icon: Icons.warning_amber_rounded),
            ],
          ),
        ),
        tamanho: const Size(360, 540),
      ),
    ],
  ),
  Componente(
    'ss-weekday-picker',
    'SsWeekdayPicker',
    'Dias da semana: sete bolinhas (S T Q Q S S D) que marcam e desmarcam, com os atalhos "Todos os dias", "Dias úteis" e "Fim de semana".',
    comportamentos: [
      'Tocar marca ou desmarca o dia (vários ao mesmo tempo), com estalo de mola e tique de haptic.',
      'Atalho troca tudo de uma vez e fica marcado enquanto a escolha bate com ele.',
      'Dias como no DateTime.weekday (1 = segunda … 7 = domingo); firstDay: 7 começa no domingo.',
      'Leitor de tela lê o nome inteiro do dia e se está marcado; alvo de 48 dp. Sem onChanged, apagado.',
    ],
    estados: [
      Estado(
        'uteis',
        'dias úteis (atalho marcado)',
        (_) => _pad(_Holder<Set<int>>({1, 2, 3, 4, 5}, (v, set) => SsWeekdayPicker(value: v, onChanged: set))),
        tamanho: const Size(360, 150),
      ),
      Estado(
        'livre',
        'escolha livre, começando no domingo · apagado',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              _Holder<Set<int>>({
                1,
                3,
                6,
              }, (v, set) => SsWeekdayPicker(value: v, firstDay: 7, shortcuts: false, onChanged: set)),
              const SsWeekdayPicker(value: {6, 7}, shortcuts: false, onChanged: null),
            ],
          ),
        ),
        tamanho: const Size(360, 160),
      ),
    ],
  ),
];

void _nadaD(double _) {}
