// Entradas do catálogo da v0.10 (casa): câmera, player, aviso com ações,
// microfone, bloqueio, fluxo de energia, controle remoto, clima, relógio e radar.
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}
Widget _pad(Widget w) => Padding(
  padding: const EdgeInsets.all(16),
  child: Center(child: w),
);

/// Estado local para a vitrine ser interativa (toque muda o estado).
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

/// Quadro de mentira (o app põe a imagem ou o <video> dele).
class _Cena extends StatelessWidget {
  const _Cena();

  @override
  Widget build(BuildContext context) => CustomPaint(painter: _CenaPainter(), child: const SizedBox.expand());
}

class _CenaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6E8BA8), Color(0xFFA9B9C6)],
        ).createShader(Offset.zero & size),
    );
    canvas.drawRect(Rect.fromLTWH(0, h * .62, w, h * .38), Paint()..color = const Color(0xFF5C6B57));
    canvas.drawRect(Rect.fromLTWH(w * .12, h * .3, w * .38, h * .36), Paint()..color = const Color(0xFFD9CBB4));
    canvas.drawPath(
      Path()
        ..moveTo(w * .08, h * .32)
        ..lineTo(w * .31, h * .12)
        ..lineTo(w * .54, h * .32)
        ..close(),
      Paint()..color = const Color(0xFF8A4B3C),
    );
    canvas.drawRect(Rect.fromLTWH(w * .26, h * .46, w * .09, h * .2), Paint()..color = const Color(0xFF5B4636));
    canvas.drawRect(Rect.fromLTWH(w * .62, h * .52, w * .3, h * .16), Paint()..color = const Color(0xFF2F3A4A));
  }

  @override
  bool shouldRepaint(_CenaPainter old) => false;
}

List<Widget> _acoesCamera() => [
  IconButton(tooltip: 'Áudio', onPressed: _nada, icon: const Icon(Icons.volume_off_rounded, size: 20)),
  IconButton(tooltip: 'Tela cheia', onPressed: _nada, icon: const Icon(Icons.fullscreen_rounded, size: 20)),
];

const _casa = SsFlowNode('casa', kind: SsFlowKind.home, label: 'Casa', value: '2,4 kW');
const _rede = SsFlowNode('rede', kind: SsFlowKind.grid, label: 'Rede', value: '1,1 kW');
const _solar = SsFlowNode('solar', kind: SsFlowKind.solar, label: 'Solar', value: '3,8 kW');
const _bat = SsFlowNode('bat', kind: SsFlowKind.battery, label: 'Bateria', value: '1,4 kW', caption: '72%');
const _carro = SsFlowNode(
  'carro',
  kind: SsFlowKind.custom,
  label: 'Carro',
  value: '0 kW',
  icon: Icons.ev_station_rounded,
);

const _previsaoHoras = [
  SsForecast('Agora', SsWeatherCondition.partlyCloudy, 27, precip: 10),
  SsForecast('15h', SsWeatherCondition.cloudy, 28, precip: 20),
  SsForecast('16h', SsWeatherCondition.rain, 25, precip: 70),
  SsForecast('17h', SsWeatherCondition.storm, 23, precip: 90),
  SsForecast('18h', SsWeatherCondition.rain, 22, precip: 60),
  SsForecast('19h', SsWeatherCondition.clearNight, 21, precip: 5),
];

const _previsaoDias = [
  SsForecast('Qui', SsWeatherCondition.clear, 31, min: 19),
  SsForecast('Sex', SsWeatherCondition.partlyCloudy, 29, min: 18),
  SsForecast('Sáb', SsWeatherCondition.rain, 24, min: 17),
  SsForecast('Dom', SsWeatherCondition.fog, 22, min: 15),
  SsForecast('Seg', SsWeatherCondition.wind, 25, min: 16),
];

const _achados = [
  SsScanItem('Lâmpada sala', icon: Icons.lightbulb_outline_rounded),
  SsScanItem('Tomada TV', icon: Icons.power_outlined),
  SsScanItem('Sensor porta', icon: Icons.sensor_door_outlined),
  SsScanItem('Câmera garagem', icon: Icons.videocam_outlined),
];

final catalogoV10Casa = <Componente>[
  Componente(
    'ss-camera-tile',
    'SsCameraTile',
    'Tile de câmera: quadro (imagem parada ou o player WebRTC do app em child), título, selo AO VIVO, idade do quadro parado e ações por cima. Não faz WebRTC.',
    comportamentos: [
      'loading: o quadro vira esqueleto com brilho que passa (parado com "reduzir movimento").',
      'live: selo vermelho AO VIVO; stale: quadro apagado e selo com a idade ("há 12 s").',
      'error e offline: fundo escuro, ícone, mensagem e "Tentar de novo" (onRetry).',
      'Véu escuro em cima e embaixo: título e ações leem sobre qualquer imagem.',
      'Leitor de tela: "Garagem, AO VIVO" / "Garagem, há 12 s".',
      'status (ou statusWidget): selo de situação no canto de baixo ("Gravando"), também lido pelo leitor de tela.',
      'Offline e erro nunca escondem o título: a mensagem fica entre o título e o selo e encolhe para caber em tile pequeno.',
    ],
    estados: [
      Estado(
        'live',
        'ao vivo com ações',
        (_) => _pad(SsCameraTile(title: 'Garagem', actions: _acoesCamera(), onTap: _nada, child: const _Cena())),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'stale',
        'quadro parado (há 12 s)',
        (_) => _pad(
          const SsCameraTile(title: 'Quintal', state: SsCameraState.stale, age: Duration(seconds: 12), child: _Cena()),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'loading',
        'carregando (brilho)',
        (_) => _pad(const SsCameraTile(title: 'Entrada', state: SsCameraState.loading)),
        tamanho: const Size(360, 240),
        aguarde: 500,
      ),
      Estado(
        'offline',
        'offline com tentar de novo (toque volta ao vivo)',
        (_) => _Vivo<SsCameraState>(
          SsCameraState.offline,
          (s, muda) => _pad(
            SsCameraTile(
              title: 'Portão',
              state: s,
              child: const _Cena(),
              onRetry: () => muda(SsCameraState.live),
              onTap: () => muda(SsCameraState.offline),
            ),
          ),
        ),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'error',
        'erro',
        (_) => _pad(const SsCameraTile(title: 'Cozinha', state: SsCameraState.error, onRetry: _nada)),
        tamanho: const Size(360, 240),
      ),
      Estado(
        'status-pequeno',
        'selo de situação · offline em tile pequeno (título visível)',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            spacing: 12,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SsCameraTile(title: 'Garagem', status: 'Gravando', child: _Cena()),
              ),
              Expanded(
                child: SsCameraTile(
                  title: 'Portão da frente',
                  state: SsCameraState.offline,
                  status: 'Visto há 2 h',
                  onRetry: _nada,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 140),
      ),
    ],
  ),
  Componente(
    'ss-media-player',
    'SsMediaPlayer',
    'Player de mídia: capa, título, subtítulo, anterior/tocar/próxima, progresso com tempos, volume e a fonte. O app manda os comandos ao aparelho.',
    comportamentos: [
      'Tocar/pausar troca o ícone com a mola; buffering mostra um carregando no botão.',
      'idle mostra "Nada tocando"; unavailable apaga tudo e trava os botões.',
      'Progresso e volume são sliders na cor da marca (onSeek, onVolume) com rótulo para leitor de tela.',
      'Tempos em DM Mono (3:07, 1:02:03).',
      'onVolumeEnd manda o volume só ao soltar o dedo; onVolumeUp/onVolumeDown põem − e + (a linha aparece mesmo sem volume absoluto).',
      'muted + onMute: botão de mudo (vermelho quando mudo, trilha apagada).',
      'power não nulo mostra o botão de ligar no canto (onPower), na cor da marca quando ligado; mediaPicker fica embaixo (escolher o que tocar).',
    ],
    estados: [
      Estado(
        'playing',
        'tocando (toque pausa)',
        (_) => _Vivo<(SsMediaState, double)>(
          (SsMediaState.playing, .45),
          (v, muda) => _pad(
            SsMediaPlayer(
              title: 'Águas de Março',
              subtitle: 'Elis Regina & Tom Jobim',
              source: 'Spotify · Sala de estar',
              state: v.$1,
              position: const Duration(seconds: 97),
              duration: const Duration(minutes: 3, seconds: 32),
              volume: v.$2,
              onPlayPause: () =>
                  muda((v.$1 == SsMediaState.playing ? SsMediaState.paused : SsMediaState.playing, v.$2)),
              onPrevious: _nada,
              onNext: _nada,
              onSeek: (_) {},
              onVolume: (x) => muda((v.$1, x)),
            ),
          ),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'paused',
        'pausado',
        (_) => _pad(
          const SsMediaPlayer(
            title: 'Podcast da Casa',
            subtitle: 'Episódio 42',
            source: 'Chromecast · Quarto',
            state: SsMediaState.paused,
            position: Duration(minutes: 12, seconds: 5),
            duration: Duration(hours: 1, minutes: 2, seconds: 3),
            volume: .2,
            onPlayPause: _nada,
          ),
        ),
        tamanho: const Size(360, 300),
      ),
      Estado(
        'buffering',
        'carregando',
        (_) => _pad(
          const SsMediaPlayer(
            title: 'Rádio Eldorado',
            source: 'Echo · Cozinha',
            state: SsMediaState.buffering,
            onPlayPause: _nada,
          ),
        ),
        tamanho: const Size(360, 200),
      ),
      Estado(
        'idle',
        'parado · indisponível',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            spacing: 12,
            children: [
              SsMediaPlayer(source: 'Sonos · Varanda', state: SsMediaState.idle, onPlayPause: _nada),
              SsMediaPlayer(source: 'TV do quarto', state: SsMediaState.unavailable),
            ],
          ),
        ),
        tamanho: const Size(360, 400),
      ),
      Estado(
        'tv-controles',
        'TV: ligar, mudo, − e + do volume e escolher o que tocar',
        (_) => _Vivo<(bool, bool)>(
          (true, false),
          (v, muda) => _pad(
            SsMediaPlayer(
              title: 'Jornal da noite',
              source: 'TV da sala · HDMI 1',
              state: v.$1 ? SsMediaState.playing : SsMediaState.idle,
              power: v.$1,
              onPower: () => muda((!v.$1, v.$2)),
              muted: v.$2,
              onMute: () => muda((v.$1, !v.$2)),
              onVolumeUp: _nada,
              onVolumeDown: _nada,
              onPlayPause: _nada,
              mediaPicker: SsChipBar(
                padding: EdgeInsets.zero,
                children: [
                  SsFilterChip('Globo', selected: true, onTap: _nada),
                  SsFilterChip('Netflix', selected: false, onTap: _nada),
                  SsFilterChip('YouTube', selected: false, onTap: _nada),
                ],
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 290),
      ),
      Estado(
        'volume-mudo',
        'volume no mudo (trilha apagada, solta = onVolumeEnd)',
        (_) => _pad(
          SsMediaPlayer(
            title: 'Águas de Março',
            source: 'Sonos · Varanda',
            state: SsMediaState.paused,
            volume: .6,
            muted: true,
            onMute: _nada,
            onVolumeEnd: (_) {},
            onPlayPause: _nada,
            power: false,
            onPower: _nada,
          ),
        ),
        tamanho: const Size(360, 260),
      ),
    ],
  ),
  Componente(
    'ss-notice-card',
    'SsNoticeCard',
    'Aviso com ações: ícone, título, texto, tom (info/warn/critical/success), hora e N botões (o 1º cheio, os outros fantasma), mais o dispensar opcional.',
    comportamentos: [
      'Tom pinta o ícone, a borda e um véu leve no fundo (cores semânticas da suíte).',
      'critical é região viva: o leitor de tela anuncia quando aparece.',
      'Botões quebram linha quando não cabem; o X chama onDismiss.',
      'onTap torna o cartão tocável (as ações e o X continuam com o próprio toque).',
      'image: foto na largura do cartão, 16:9, embaixo do texto (instantâneo da câmera).',
      'unread: ponto na cor do tom antes do título e borda mais forte e grossa.',
      'footer: rodapé com fio em cima e texto apagado ("Respondido: Sim").',
    ],
    estados: [
      for (final (tom, titulo, texto) in const [
        (SsNoticeTone.info, 'Atualização disponível', 'O hub tem uma versão nova do firmware.'),
        (SsNoticeTone.warn, 'Porta da frente aberta', 'Está aberta há 10 minutos.'),
        (SsNoticeTone.critical, 'Vazamento na lavanderia', 'O sensor de água detectou umidade.'),
        (SsNoticeTone.success, 'Backup concluído', 'Tudo salvo às 03:00.'),
      ])
        Estado(
          tom.name,
          '${tom.name} com ações',
          (_) => _Vivo<bool>(
            true,
            (visivel, muda) => Padding(
              padding: const EdgeInsets.all(16),
              child: visivel
                  ? SsNoticeCard(
                      title: titulo,
                      text: texto,
                      tone: tom,
                      time: '14:32',
                      actions: [
                        SsNoticeAction(tom == SsNoticeTone.critical ? 'Fechar registro' : 'Resolver', _nada),
                        const SsNoticeAction('Depois', _nada),
                      ],
                      onDismiss: () => muda(false),
                    )
                  : TextButton(onPressed: () => muda(true), child: const Text('Mostrar de novo')),
            ),
          ),
          tamanho: const Size(360, 250),
        ),
      Estado(
        'sem-acoes',
        'sem ações',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsNoticeCard(title: 'Modo férias ligado', text: 'As luzes acendem sozinhas à noite.', time: 'há 2 h'),
        ),
        tamanho: const Size(360, 110),
      ),
      Estado(
        'nao-lido-com-foto',
        'unread + image + onTap (instantâneo da câmera)',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: SsNoticeCard(
            title: 'Movimento na garagem',
            text: 'A câmera da garagem viu alguém.',
            tone: SsNoticeTone.warn,
            time: '14:32',
            unread: true,
            onTap: _nada,
            image: const SsNetImage(null, fallbackIcon: Icons.videocam_outlined, radius: 0),
            actions: const [SsNoticeAction('Ver ao vivo', _nada)],
          ),
        ),
        tamanho: const Size(360, 330),
      ),
      Estado(
        'respondido',
        'footer: respondido (lido, sem ações)',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsNoticeCard(
            title: 'Alguém em casa?',
            text: 'O alarme vai ligar em 5 minutos.',
            time: '08:10',
            onTap: _nada,
            footer: Row(
              children: [
                Icon(Icons.check_circle_outline_rounded),
                SizedBox(width: 6),
                Expanded(child: Text('Respondido: Sim · Ana, 08:12')),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 200),
      ),
    ],
  ),
  Componente(
    'ss-mic-button',
    'SsMicButton',
    'Botão de microfone. Ouvindo, os anéis crescem com o nível do áudio (level 0..1) que o app manda, como um medidor.',
    comportamentos: [
      'idle: botão claro; listening: cheio na cor da marca com 3 anéis que reagem ao nível (suavizado em 120 ms).',
      'processing: um arco gira em volta (parado com "reduzir movimento").',
      'error: vermelho com o microfone cortado.',
      'Toque afunda e volta com a mola; rótulo do leitor de tela muda por estado.',
      'v0.10.3 holdToTalk: encostar começa (onHoldStart, vibração leve), soltar termina (onHoldEnd), arrastar para longe cancela (onHoldCancel); o botão cresce enquanto segura. Leitor de tela: um toque começa, outro termina ("Segure para falar" / "Ouvindo, solte para enviar").',
      'v0.10.3 compact: caixa do tamanho do botão (alvo de 48) e anéis por fora, para caber no SsChatInput.',
    ],
    estados: [
      Estado(
        'ciclo',
        'toque: ouvindo → processando → parado',
        (_) => _Vivo<SsMicState>(
          SsMicState.idle,
          (s, muda) => _pad(
            SsMicButton(
              state: s,
              level: .6,
              onPressed: () => muda(switch (s) {
                SsMicState.idle => SsMicState.listening,
                SsMicState.listening => SsMicState.processing,
                _ => SsMicState.idle,
              }),
            ),
          ),
        ),
        tamanho: const Size(360, 170),
      ),
      Estado(
        'segurar',
        'segurar para falar (compacto): parado · ouvindo 0,7 · processando',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsMicButton(holdToTalk: true, compact: true, size: 44, onHoldStart: () {}, onHoldEnd: () {}),
              SsMicButton(
                holdToTalk: true,
                compact: true,
                size: 44,
                state: SsMicState.listening,
                level: .7,
                onHoldStart: () {},
                onHoldEnd: () {},
              ),
              SsMicButton(holdToTalk: true, compact: true, size: 44, state: SsMicState.processing, onHoldStart: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 100),
      ),
      Estado(
        'niveis',
        'ouvindo: nível 0,15 · 0,5 · 0,95',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsMicButton(state: SsMicState.listening, level: .15, size: 56, onPressed: _nada),
              SsMicButton(state: SsMicState.listening, level: .5, size: 56, onPressed: _nada),
              SsMicButton(state: SsMicState.listening, level: .95, size: 56, onPressed: _nada),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
      Estado(
        'processing-error',
        'processando · erro',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SsMicButton(state: SsMicState.processing, size: 56, onPressed: _nada),
              SsMicButton(state: SsMicState.error, size: 56, onPressed: _nada),
            ],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
    ],
  ),
  Componente(
    'ss-lock-screen',
    'SsLockScreen',
    'Tela de bloqueio (só app): fundo da marca desfocado, ícone do app, mensagem, "Desbloquear" (o app chama a biometria em onUnlock) e o PIN do app como alternativa.',
    comportamentos: [
      'busy: o botão mostra o carregando enquanto a biometria responde.',
      'error: pílula vermelha anunciada pelo leitor de tela.',
      '"Usar PIN" troca o botão pelo widget de PIN do app com a mola; "Usar biometria" volta.',
      'Cores do fundo vêm da paleta (SsBrand.gradient).',
    ],
    estados: [
      Estado(
        'padrao',
        'bloqueado (toque: esperando biometria)',
        (_) => _Vivo<bool>(
          false,
          (busy, muda) => SsLockScreen(
            title: 'Minha Automação',
            message: 'Desbloqueie para ver a casa',
            busy: busy,
            onUnlock: () => muda(true),
            pinFallback: const _PinDemo(),
          ),
        ),
        tamanho: const Size(360, 640),
      ),
      Estado(
        'erro-pin',
        'erro · no PIN',
        (_) => const SsLockScreen(
          title: 'Minha Automação',
          error: 'Biometria não reconhecida',
          onUnlock: _nada,
          pinFallback: _PinDemo(),
          showPin: true,
        ),
        tamanho: const Size(360, 640),
      ),
    ],
  ),
  Componente(
    'ss-flow-diagram',
    'SsFlowDiagram',
    'Fluxo de energia: nó central (casa) e até 4 em volta (rede, solar, bateria, outro). Pontos correm na ligação no sentido da energia, mais rápido quanto maior a potência.',
    comportamentos: [
      'power > 0 corre de from para to; < 0 ao contrário; 0 fica só o trilho.',
      'Velocidade proporcional a |power| / maxPower; a cor é a de quem manda a energia.',
      'É o único laço contínuo: para com animate: false e com "reduzir movimento" (aí mostra uma seta parada).',
      'Cores semânticas por tipo (rede azul, solar âmbar, bateria verde); a casa usa a marca.',
      'Responsivo: abaixo de ~400 px os discos encolhem, os nós dos lados encostam na borda e os nomes ganham só a largura que cabe (reticências), sem se sobrepor.',
    ],
    estados: [
      Estado(
        'importando',
        'importando da rede (toque alterna exportar)',
        (_) => _Vivo<bool>(
          true,
          (importa, muda) => GestureDetector(
            onTap: () => muda(!importa),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SsFlowDiagram(
                center: _casa,
                around: [_solar, _rede, _bat],
                links: importa
                    ? const [SsFlowLink('rede', 'casa', 2400), SsFlowLink('solar', 'casa', 0)]
                    : const [
                        SsFlowLink('solar', 'casa', 2400),
                        SsFlowLink('casa', 'rede', 1400),
                        SsFlowLink('solar', 'casa', 0),
                      ],
              ),
            ),
          ),
        ),
        tamanho: const Size(360, 320),
        aguarde: 700,
      ),
      Estado(
        'exportando',
        'exportando o excedente do solar',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: SsFlowDiagram(
            center: _casa,
            around: [_solar, _rede, _bat],
            links: [SsFlowLink('solar', 'casa', 3800), SsFlowLink('casa', 'rede', 1400)],
          ),
        ),
        tamanho: const Size(360, 320),
        aguarde: 700,
      ),
      Estado(
        'carregando-bateria',
        'bateria carregando (4 em volta)',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: SsFlowDiagram(
            center: _casa,
            around: [_solar, _rede, _carro, _bat],
            links: [
              SsFlowLink('solar', 'casa', 3800),
              SsFlowLink('casa', 'bat', 1400),
              SsFlowLink('rede', 'casa', 0),
              SsFlowLink('carro', 'casa', 0),
            ],
          ),
        ),
        tamanho: const Size(360, 320),
        aguarde: 700,
      ),
      Estado(
        'parado',
        'sem fluxo · animate: false (setas paradas)',
        (_) => const Padding(
          padding: EdgeInsets.all(8),
          child: Column(
            children: [
              Expanded(
                child: SsFlowDiagram(
                  center: _casa,
                  around: [_solar, _rede],
                  links: [SsFlowLink('solar', 'casa', 0), SsFlowLink('rede', 'casa', 0)],
                  height: 200,
                ),
              ),
              Expanded(
                child: SsFlowDiagram(
                  center: _casa,
                  around: [_solar, _rede],
                  links: [SsFlowLink('solar', 'casa', 1200), SsFlowLink('rede', 'casa', 800)],
                  animate: false,
                  height: 200,
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 440),
      ),
      Estado(
        'estreito',
        'card de 330 px (nomes sem encostar)',
        (_) => const Center(
          child: SizedBox(
            width: 330,
            child: SsFlowDiagram(
              center: _casa,
              around: [_solar, _rede, _carro, _bat],
              links: [
                SsFlowLink('solar', 'casa', 3800),
                SsFlowLink('casa', 'bat', 1400),
                SsFlowLink('rede', 'casa', 600),
                SsFlowLink('carro', 'casa', 0),
              ],
              animate: false,
            ),
          ),
        ),
        tamanho: const Size(360, 320),
      ),
    ],
  ),
  Componente(
    'ss-dpad',
    'SsDPad',
    'Controle remoto: cruz com OK no meio, voltar/início/menu e, opcional, gangorras de volume e canal.',
    comportamentos: [
      'Cada tecla afunda e volta com a mola, com tique de vibração; onKey recebe a tecla (SsDPadKey).',
      'Com foco, setas do teclado, Enter (OK) e Esc (voltar) também apertam.',
      'Rótulos para leitor de tela em SsDPadLabels (pt-BR por padrão).',
      'enabled: false apaga e trava (aparelho offline).',
      'showNavRow: false tira voltar/início/menu (câmera PTZ).',
      'onCommand recebe o nome do comando: o de keys para a tecla (padrão o nome do enum) ou o name dos extraButtons (botões aprendidos em pílula, numa grade embaixo).',
    ],
    estados: [
      Estado(
        'completo',
        'com volume e canal (toque mostra a tecla)',
        (_) => _Vivo<String>(
          '—',
          (ultima, muda) => _pad(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SsDPad(showVolume: true, showChannel: true, size: 160, onKey: (k) => muda(k.name)),
                const SizedBox(height: 10),
                Text('última: $ultima'),
              ],
            ),
          ),
        ),
        tamanho: const Size(360, 380),
      ),
      Estado(
        'simples',
        'só a cruz · desligado',
        (_) => const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            spacing: 16,
            children: [
              SsDPad(onKey: _ignora, size: 150),
              SsDPad(onKey: _ignora, size: 150, enabled: false),
            ],
          ),
        ),
        tamanho: const Size(360, 560),
      ),
      Estado(
        'ptz-extras',
        'câmera PTZ sem a linha de navegação · botões aprendidos',
        (_) => const Padding(
          padding: EdgeInsets.all(12),
          child: Column(
            spacing: 16,
            children: [
              SsDPad(onKey: _ignora, size: 130, showNavRow: false),
              SsDPad(
                size: 130,
                showNavRow: false,
                onCommand: _ignoraCmd,
                keys: {SsDPadKey.ok: 'KEY_ENTER'},
                extraButtons: [
                  SsDPadButton('netflix', 'Netflix', icon: Icons.movie_outlined),
                  SsDPadButton('input', 'Entrada', icon: Icons.input_rounded),
                  SsDPadButton('zoom_in', 'Zoom +'),
                  SsDPadButton('zoom_out', 'Zoom −'),
                ],
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 470),
      ),
    ],
  ),
  Componente(
    'ss-weather-card',
    'SsWeatherCard',
    'Clima: temperatura, ícone e texto da condição, mín/máx, umidade, vento e a faixa de previsão por hora ou por dia. Só dados, sem rede.',
    comportamentos: [
      'Ícones Material com as cores semânticas (sol âmbar, chuva azul, nuvem neutra).',
      'Previsão por hora mostra a chance de chuva; por dia, a mínima.',
      'Faixa rola na horizontal; cada ponto tem rótulo completo para o leitor de tela.',
      'Textos (condições, Umidade, Vento, Mín/Máx) são parâmetros.',
      'rainChance: gota azul com a chance de chuva ao lado da condição atual; feelsLike: "Sensação 24°" embaixo da temperatura.',
      'Previsão por dia com precip (rainChance) mostra a gota com a % embaixo da mínima.',
    ],
    estados: [
      Estado(
        'horas',
        'previsão por hora',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsWeatherCard(
            location: 'São Paulo',
            temperature: 27,
            condition: SsWeatherCondition.partlyCloudy,
            min: 19,
            max: 29,
            humidity: 62,
            wind: 14,
            forecast: _previsaoHoras,
          ),
        ),
        tamanho: const Size(360, 360),
      ),
      Estado(
        'dias',
        'previsão por dia (chuva)',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsWeatherCard(
            temperature: 21,
            condition: SsWeatherCondition.rain,
            min: 17,
            max: 24,
            humidity: 88,
            forecast: _previsaoDias,
          ),
        ),
        tamanho: const Size(360, 360),
      ),
      Estado(
        'icones',
        'todas as condições',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Wrap(
            spacing: 18,
            runSpacing: 12,
            children: [for (final c in SsWeatherCondition.values) SsWeatherIcon(c, size: 40)],
          ),
        ),
        tamanho: const Size(360, 130),
      ),
      Estado(
        'agora-chuva',
        'chance de chuva e sensação agora · chuva por dia',
        (_) => const Padding(
          padding: EdgeInsets.all(16),
          child: SsWeatherCard(
            location: 'Curitiba',
            temperature: 18,
            feelsLike: 15,
            rainChance: 70,
            condition: SsWeatherCondition.rain,
            min: 14,
            max: 21,
            humidity: 91,
            forecast: [
              SsForecast('Qui', SsWeatherCondition.rain, 21, min: 14, precip: 80),
              SsForecast('Sex', SsWeatherCondition.cloudy, 22, min: 15, precip: 40),
              SsForecast('Sáb', SsWeatherCondition.partlyCloudy, 25, min: 16, precip: 10),
              SsForecast('Dom', SsWeatherCondition.clear, 27, min: 17),
              SsForecast('Seg', SsWeatherCondition.storm, 23, min: 17, precip: 90),
            ],
          ),
        ),
        tamanho: const Size(360, 400),
      ),
    ],
  ),
  Componente(
    'ss-clock',
    'SsClock',
    'Relógio digital grande com data e o ponto dos segundos opcional. Anda de segundo em segundo (Timer cancelado ao sair); now fixo para teste.',
    comportamentos: [
      'Horas em DM Mono tabular (não dançam).',
      'showSeconds: o ponto acende nos segundos pares (fica aceso com "reduzir movimento").',
      'Data em pt-BR por padrão; weekdays, months e dateFormat para en/es.',
      'use24h: false mostra AM/PM.',
      'seconds: SsClockSeconds.digits mostra os segundos em dígitos menores no lugar do ponto.',
      'Em caixa estreita (card de grade de ~160 px) as horas encolhem para caber e a data quebra em até 2 linhas.',
    ],
    estados: [
      Estado(
        'padrao',
        '24 h com ponto dos segundos',
        (_) => _pad(SsClock(now: DateTime(2026, 11, 4, 14, 32, 10), showSeconds: true)),
        tamanho: const Size(360, 150),
      ),
      Estado(
        'ampm',
        '12 h, sem data',
        (_) => _pad(SsClock(now: DateTime(2026, 11, 4, 21, 5), use24h: false, showDate: false, size: 48)),
        tamanho: const Size(360, 100),
      ),
      Estado(
        'digitos',
        'segundos em dígitos',
        (_) => _pad(SsClock(now: DateTime(2026, 11, 4, 14, 32, 10), showSeconds: true, seconds: SsClockSeconds.digits)),
        tamanho: const Size(360, 150),
      ),
      Estado(
        'estreito',
        'card de grade de 160 px (encolhe)',
        (_) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            spacing: 12,
            children: [
              for (final seg in [false, true])
                SizedBox(
                  width: 160,
                  child: SsCard(
                    child: SsClock(
                      now: DateTime(2026, 11, 4, 14, 32, 10),
                      showSeconds: seg,
                      seconds: SsClockSeconds.digits,
                    ),
                  ),
                ),
            ],
          ),
        ),
        tamanho: const Size(360, 170),
      ),
    ],
  ),
  Componente(
    'ss-scan-radar',
    'SsScanRadar',
    'Radar de busca: ondas saem do ícone central enquanto procura; os itens achados pulam em volta como chips.',
    comportamentos: [
      'searching: 3 ondas e um arco que gira (param com animate: false e com "reduzir movimento").',
      'Cada item novo entra com a mola solta (pop); até 6 em volta.',
      'found: ondas param e o texto conta ("4 encontrados"); empty: cinza, mensagem e "Procurar de novo".',
      'O texto de situação é região viva para o leitor de tela.',
      'compact: em linha (card, lista): radar pequeno (até 72 px) à esquerda e o texto, os achados em chips e o "procurar de novo" ao lado.',
    ],
    estados: [
      Estado(
        'buscando',
        'procurando, 2 achados',
        (_) => _pad(SsScanRadar(items: _achados.take(2).toList(), size: 220)),
        tamanho: const Size(360, 300),
        aguarde: 600,
      ),
      Estado(
        'achou',
        'achou 4 (toque num chip)',
        (_) => _Vivo<String>(
          '',
          (toque, muda) =>
              _pad(SsScanRadar(state: SsScanState.found, items: _achados, size: 220, onItemTap: (i) => muda(i.label))),
        ),
        tamanho: const Size(360, 300),
        aguarde: 600,
      ),
      Estado(
        'nada',
        'nada achado (toque procura de novo)',
        (_) => _Vivo<SsScanState>(
          SsScanState.empty,
          (s, muda) => _pad(SsScanRadar(state: s, size: 200, onRetry: () => muda(SsScanState.searching))),
        ),
        tamanho: const Size(360, 330),
      ),
      Estado(
        'compacto',
        'em linha: procurando · achou · nada',
        (_) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            spacing: 14,
            children: [
              SsScanRadar(compact: true, items: _achados.take(1).toList()),
              SsScanRadar(compact: true, state: SsScanState.found, items: _achados.take(3).toList()),
              SsScanRadar(compact: true, state: SsScanState.empty, onRetry: () {}),
            ],
          ),
        ),
        tamanho: const Size(360, 330),
        aguarde: 600,
      ),
    ],
  ),
];

void _ignora(SsDPadKey _) {}

void _ignoraCmd(String _) {}

/// PIN de mentira (o app passa o dele).
class _PinDemo extends StatelessWidget {
  const _PinDemo();

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: 12,
    children: [
      for (var i = 0; i < 4; i++)
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i < 2 ? AppColors.onDark : Colors.transparent,
            border: Border.all(color: AppColors.onDark, width: 2),
          ),
        ),
    ],
  );
}
