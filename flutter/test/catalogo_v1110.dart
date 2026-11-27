// v1.11.0 ([comV1110]): as variantes do iOS das peças adaptativas (o estado força a plataforma com
// `plataforma: TargetPlatform.iOS`) e o botão de entrar com a Apple. As folhas e os alertas do iOS aparecem
// soltos (o desenho que o show* abre), para caberem na captura.
import 'package:componentes_ui/componentes_ui.dart';
// ignore: implementation_imports
import 'package:componentes_ui/src/v1110/cupertino.dart';
import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoDatePickerMode;
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

const _ios = TargetPlatform.iOS;

/// Fundo da página atrás da peça solta (a folha e o alerta do iOS são translúcidos).
Widget _palco(Widget w, {Alignment align = Alignment.bottomCenter}) => Builder(
  builder: (context) => ColoredBox(
    color: SsColors.of(context).page,
    child: Align(alignment: align, child: w),
  ),
);

/// A folha de baixo como o showModalBottomSheet a desenha (raio de cima e a superfície).
Widget _folha(Widget w) => Builder(
  builder: (context) => Material(
    color: SsColors.of(context).surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(26))),
    clipBehavior: Clip.antiAlias,
    child: w,
  ),
);

const _menu = SsSideMenu(
  title: 'Minhas Vendas',
  sections: [
    SsSideMenuSection([SsSideMenuItem(Icons.settings_outlined, 'Configurações')]),
  ],
);

Widget _tela(String titulo, {bool voltar = false}) => Builder(
  builder: (context) {
    final c = SsColors.of(context);
    return Scaffold(
      appBar: SsTopBar(title: titulo, automaticallyImplyLeading: voltar),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final p in ['Pedido 1042', 'Pedido 1041', 'Pedido 1040'])
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SsCard(
                child: Text(
                  p,
                  style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
                ),
              ),
            ),
        ],
      ),
    );
  },
);

/// Host do menu com um Navigator dentro: [empilhada] abre o detalhe por cima da raiz.
Widget _host({required bool empilhada}) => SsSideMenuHost(
  menu: _menu,
  peek: false,
  child: Navigator(
    pages: [
      MaterialPage<void>(child: _tela('Pedidos')),
      if (empilhada) MaterialPage<void>(child: _tela('Pedido 1042', voltar: true)),
    ],
    onDidRemovePage: (_) {},
  ),
);

List<Componente> comV1110(List<Componente> base) => [...base, ..._v1110];

final _v1110 = <Componente>[
  Componente(
    'ss-platform',
    'SsPlatform',
    'A plataforma das peças adaptativas (v1.11): lê a do tema e decide o desenho do iOS ou o da suíte; SsPlatformScope é a saída.',
    comportamentos: const [
      'SsPlatform.of(context) é o Theme.of(context).platform; iOS e macOS contam como Apple. Teste e catálogo trocam com ThemeData(platform:).',
      'Toda peça adaptativa tem adaptive: (padrão true); com false, fica no desenho da suíte no iPhone.',
      'SsPlatformScope(adaptive: false) acima do app desliga todas de uma vez, inclusive o elástico da rolagem.',
      'No iOS: chave do iOS, roda de data e hora, folha de ação, alerta do iOS, puxar do iOS, rolagem com elástico, o "‹" de voltar e a transição de página do iOS (voltar de arrastar).',
      'SsHaptics vai para os geradores do iOS (seleção, impacto e notificação de sucesso, aviso e erro).',
    ],
    estados: [
      Estado(
        'ios',
        'iOS: adaptativa e com o SsPlatformScope(adaptive: false)',
        (_) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsSwitchRow(title: 'Adaptativa', subtitle: 'a chave do iOS', value: true, onChanged: (_) {}),
              SsPlatformScope(
                adaptive: false,
                child: SsSwitchRow(
                  title: 'adaptive: false',
                  subtitle: 'a chave da suíte',
                  value: true,
                  onChanged: (_) {},
                ),
              ),
            ],
          ),
        ),
        tamanho: const Size(360, 170),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-switch-ios',
    'SsSwitch (iOS)',
    'A chave no iOS (v1.11): o desenho e o arrasto do CupertinoSwitch, com a trilha na cor da marca.',
    comportamentos: const [
      'Mesma API do SsSwitch e do SsSwitchRow; no Android segue a chave líquida da suíte.',
      'Alvo de 48 e o mesmo haptic de seleção; a linha inteira do SsSwitchRow alterna, sem a tinta do toque no iOS.',
      'onChanged nulo deixa apagada. adaptive: false fica com a da suíte.',
    ],
    estados: [
      Estado(
        'android',
        'Android: a chave da suíte',
        (_) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsSwitchRow(title: 'Lembrete diário', subtitle: 'às 08:00', value: true, onChanged: (_) {}),
              SsSwitchRow(title: 'Vibração', value: false, onChanged: (_) {}),
            ],
          ),
        ),
        tamanho: const Size(360, 180),
      ),
      Estado(
        'ios',
        'iOS: o CupertinoSwitch na cor da marca',
        (_) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SsSwitchRow(title: 'Lembrete diário', subtitle: 'às 08:00', value: true, onChanged: (_) {}),
              SsSwitchRow(title: 'Vibração', value: false, onChanged: (_) {}),
              const SsSwitchRow(title: 'Desligada', value: true, onChanged: null),
            ],
          ),
        ),
        tamanho: const Size(360, 232),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-date-wheel',
    'showSsDatePicker (iOS)',
    'Data e hora no iOS (v1.11): a roda do CupertinoDatePicker numa folha, com Cancelar, o título e Confirmar.',
    comportamentos: const [
      'showSsDatePicker, showSsTimePicker, SsDateField e SsTimeField abrem a roda no iOS; no Android, o calendário e o relógio da suíte.',
      'Mesma volta: o dia (sem hora) ou a hora, e nulo no Cancelar ou ao fechar.',
      'firstDate/lastDate e selectableDayPredicate valem na roda; dia/mês/ano na ordem do idioma; 24 h por padrão.',
      'Confirmar é a ação principal, na cor da marca, à direita. Com texto grande, a roda cresce até 1,4×.',
    ],
    estados: [
      Estado(
        'data-ios',
        'iOS: a roda de data',
        (_) => _palco(
          _folha(
            WheelSheetView(
              mode: CupertinoDatePickerMode.date,
              initial: DateTime(2026, 11, 27),
              minimum: DateTime(2000),
              maximum: DateTime(2100),
              use24h: true,
              title: 'Vencimento',
              confirmText: 'Confirmar',
              cancelText: 'Cancelar',
              selectableDayPredicate: null,
            ),
          ),
        ),
        tamanho: const Size(360, 330),
        plataforma: _ios,
      ),
      Estado(
        'hora-ios',
        'iOS: a roda de hora (24 h)',
        (_) => _palco(
          _folha(
            WheelSheetView(
              mode: CupertinoDatePickerMode.time,
              initial: DateTime(2026, 11, 27, 7, 30),
              minimum: null,
              maximum: null,
              use24h: true,
              title: 'Escolher hora',
              confirmText: 'Confirmar',
              cancelText: 'Cancelar',
              selectableDayPredicate: null,
            ),
          ),
        ),
        tamanho: const Size(360, 330),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-action-sheet',
    'Folha de ação (iOS)',
    'Menus e escolhas curtas no iOS (v1.11): a folha de ação do CupertinoActionSheet no SsOverflowMenu, no SsContextMenu e no showSsPicker curto.',
    comportamentos: const [
      'SsOverflowMenu: o ⋯ do iOS abre a folha; no Android, o menu ancorado da suíte.',
      'SsContextMenu: o toque longo abre a folha com as mesmas ações.',
      'showSsPicker com items: de até 8 (sem busca no servidor, escolha livre, "Sem…" ou ações) vira folha; o resto segue a folha de busca.',
      'A destrutiva em vermelho, o ✓ das marcadas e o Cancelar separado embaixo. Mesma volta (a escolha ou nulo).',
    ],
    estados: [
      Estado(
        'menu-ios',
        'iOS: o ⋯ de um pedido',
        (context) => _palco(
          Padding(
            padding: const EdgeInsets.all(8),
            child: ssActionSheetView<int>(
              context,
              choices: const [
                (label: 'Editar', value: 0, destructive: false, checked: false, icon: Icons.edit_outlined),
                (label: 'Duplicar', value: 1, destructive: false, checked: false, icon: Icons.copy_rounded),
                (label: 'Excluir pedido', value: 2, destructive: true, checked: false, icon: Icons.delete_outline),
              ],
              onDone: (_) {},
            ),
          ),
        ),
        tamanho: const Size(360, 300),
        plataforma: _ios,
      ),
      Estado(
        'picker-ios',
        'iOS: showSsPicker curto, com título',
        (context) => _palco(
          Padding(
            padding: const EdgeInsets.all(8),
            child: ssActionSheetView<String>(
              context,
              title: 'Ordenar por',
              choices: const [
                (label: 'Mais recentes', value: 'r', destructive: false, checked: true, icon: null),
                (label: 'Maior valor', value: 'v', destructive: false, checked: false, icon: null),
                (label: 'Cliente (A–Z)', value: 'c', destructive: false, checked: false, icon: null),
              ],
              onDone: (_) {},
            ),
          ),
        ),
        tamanho: const Size(360, 320),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-confirm-ios',
    'showSsConfirm (iOS)',
    'A confirmação no iOS (v1.11): o CupertinoAlertDialog, com Cancelar à esquerda e a destrutiva em vermelho.',
    comportamentos: const [
      'Mesma API e mesma volta do showSsConfirm (true só se confirmou); no Android, o diálogo da suíte.',
      'danger: true deixa a confirmação vermelha (destrutiva) e o Cancelar em negrito, a escolha segura.',
      'Sem danger, a confirmação é a ação padrão (negrito, na cor da marca). Tocar fora fecha como Cancelar.',
    ],
    estados: [
      Estado(
        'destrutiva-ios',
        'iOS: excluir, em vermelho',
        (context) => _palco(
          ssCupertinoConfirmView(
            context,
            title: 'Excluir o pedido 1042?',
            message: 'Os itens e as parcelas saem junto. Não dá para desfazer.',
            confirmLabel: 'Excluir',
            danger: true,
            onDone: (_) {},
          ),
          align: Alignment.center,
        ),
        tamanho: const Size(360, 260),
        plataforma: _ios,
      ),
      Estado(
        'normal-ios',
        'iOS: confirmar, na cor da marca',
        (context) => _palco(
          ssCupertinoConfirmView(
            context,
            title: 'Enviar o pedido?',
            message: 'O cliente recebe o resumo por e-mail.',
            confirmLabel: 'Enviar',
            onDone: (_) {},
          ),
          align: Alignment.center,
        ),
        tamanho: const Size(360, 240),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-sheet-ios',
    'SsSheet (iOS)',
    'A folha no iOS (v1.11): ganha o × de fechar no canto, porque lá não há voltar do sistema.',
    comportamentos: const [
      'showSsSheet e SsSheet: no iOS, o × no canto de cima (alvo de 48, "Fechar"); arrastar para baixo continua fechando.',
      'Com dismissible: false não há ×: quem fecha é o conteúdo. showClose: força ou tira o × em qualquer plataforma.',
      'A folha fica abaixo da ilha dinâmica (área segura de cima) e acima do home indicator.',
    ],
    estados: [
      Estado(
        'android',
        'Android: só a alça',
        (_) => _palco(
          _folha(
            SsSheet(
              title: 'Filtros',
              subtitle: 'Pedidos de novembro',
              icon: Icons.tune_rounded,
              child: SsButton(label: 'Mostrar 12 pedidos', onPressed: _nada),
            ),
          ),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'ios',
        'iOS: a alça e o ×',
        (_) => _palco(
          _folha(
            SsSheet(
              title: 'Filtros',
              subtitle: 'Pedidos de novembro',
              icon: Icons.tune_rounded,
              child: SsButton(label: 'Mostrar 12 pedidos', onPressed: _nada),
            ),
          ),
        ),
        tamanho: const Size(360, 220),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-side-menu-ios',
    'SsSideMenuHost (iOS)',
    'O menu lateral no iOS (v1.11): a alça fica nas telas principais e some na rota empilhada, onde arrastar da borda é o voltar do sistema.',
    comportamentos: const [
      'Rota empilhada = a tela do host foi empilhada por cima de outra, ou um Navigator de dentro (o ShellRoute do go_router) pode voltar.',
      'Empilhada no iOS: a alça e a faixa de arrastar saem e a dica ao abrir não roda; o voltar do sistema (CupertinoPageTransitionsBuilder) vence.',
      'Na raiz, a alça fica como no Android. adaptive: false (ou o SsPlatformScope) deixa a alça sempre.',
      'No Android nada muda.',
    ],
    estados: [
      Estado(
        'raiz-ios',
        'iOS, tela principal: a alça na borda',
        (_) => _host(empilhada: false),
        tamanho: const Size(360, 420),
        plataforma: _ios,
      ),
      Estado(
        'empilhada-ios',
        'iOS, rota empilhada: sem a alça, com o ‹ de voltar',
        (_) => _host(empilhada: true),
        tamanho: const Size(360, 420),
        plataforma: _ios,
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-nav-bar-ios',
    'SsNavBar (iOS)',
    'A barra de abas no iOS (v1.11): continua a da suíte (é a marca), acima do home indicator.',
    comportamentos: const [
      'O desenho e o pulo do círculo não mudam no iOS.',
      'A barra soma a área segura de baixo (MediaQuery.viewPadding.bottom, 34 no iPhone com home indicator): ícones e rótulos ficam acima dele.',
    ],
    estados: [
      Estado(
        'ios',
        'iOS: com o home indicator (34)',
        (context) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(padding: const EdgeInsets.only(bottom: 34), viewPadding: const EdgeInsets.only(bottom: 34)),
          child: Scaffold(
            extendBody: true,
            body: const SizedBox.expand(),
            bottomNavigationBar: SsNavBar(
              items: const [
                SsNavItem(Icons.home_outlined, 'Início', activeIcon: Icons.home_rounded),
                SsNavItem(Icons.receipt_long_outlined, 'Pedidos'),
                SsNavItem(Icons.people_alt_outlined, 'Clientes'),
              ],
              currentIndex: 0,
              onTap: (_) {},
            ),
          ),
        ),
        tamanho: const Size(360, 180),
        plataforma: _ios,
      ),
    ],
  ),
  Componente(
    'ss-apple-button',
    'SsAppleButton',
    'Entrar com a Apple (v1.11, par do Ss::AppleButtonComponent): o logo e o texto, preto, branco ou com contorno, como pedem as diretrizes da Apple.',
    comportamentos: const [
      '"Continuar com a Apple" (padrão) ou "Entrar com a Apple" (label:), em pt, en e es pelo SsStrings; text: troca.',
      'style: black (fundo claro), white (fundo escuro) ou outline; sem style, preto no tema claro e branco no escuro.',
      'Altura 50 e raio 14, os do SsGoogleButton; SsAppleButton.icon é o quadrado só com o logo, para ficar ao lado do G.',
      'SsAuthLayout(providers: [SsGoogleButton(...), SsAppleButton.icon(...)]) põe os dois lado a lado embaixo do formulário.',
      'Só o botão: a entrada com a Apple (sign_in_with_apple) é do app. onPressed nulo deixa apagado.',
    ],
    estados: [
      Estado(
        'estilos',
        'preto, contorno e branco',
        (context) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 12,
            children: [
              SsAppleButton(style: SsAppleButtonStyle.black, onPressed: _nada),
              SsAppleButton(style: SsAppleButtonStyle.outline, label: SsAppleButtonLabel.signIn, onPressed: _nada),
              SsAppleButton(style: SsAppleButtonStyle.white, onPressed: _nada),
            ],
          ),
        ),
        tamanho: const Size(360, 220),
      ),
      Estado(
        'ao-lado-do-google',
        'SsAuthProviders: o G e a Apple lado a lado',
        (context) => _pad(
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: SsButton(label: 'Entrar', onPressed: _nada),
                  ),
                  SsGoogleButton(onTap: _nada),
                  SsAppleButton.icon(onPressed: _nada),
                ],
              ),
              SsAuthProviders([SsAppleButton(onPressed: _nada)]),
            ],
          ),
        ),
        tamanho: const Size(360, 160),
        plataforma: _ios,
      ),
    ],
  ),
];
