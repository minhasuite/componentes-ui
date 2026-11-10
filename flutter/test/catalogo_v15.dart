// Entradas do catálogo da v0.15: a fase 0 do meu-financeiro (ícones por nome,
// barras com negativos e linha, dinheiro com conta e sinal, privacidade dos
// valores, linha de progresso e o cartão de ação do chat).
import 'package:flutter/material.dart';
import 'package:componentes_ui/componentes_ui.dart';

import 'catalogo.dart';

void _nada() {}

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

String _reais(double v) => money((v * 100).round());
String _reaisInteiro(double v) => 'R\$ ${SsFormats.brl.integer(v.round())}';

const _meses = ['jun', 'jul', 'ago', 'set', 'out', 'nov'];

final catalogoV15 = <Componente>[
  Componente(
    'ss-icons',
    'SsIcons.named',
    'Ícone por nome com os mesmos nomes do ss_icon da gem (Heroicons v1 e os da v2 por apelido): o nome guardado na API desenha o mesmo ícone no web e no app.',
    comportamentos: [
      'Nome da v2 vira o da v1 (magnifying-glass → search); o que não existe vira o ponto de interrogação.',
      'solid: true usa a versão cheia quando há (estrela, check, avisos).',
      'SsIcons.names lista o conjunto (o mesmo da gem, gerado de rails/icones).',
    ],
    estados: [
      Estado(
        'conjunto',
        'contorno · cheio · reserva',
        (context) => _pad(
          SsCard(
            child: Wrap(
              spacing: 14,
              runSpacing: 12,
              children: [
                for (final n in const [
                  'credit-card',
                  'banknotes',
                  'office-building',
                  'chart-pie',
                  'arrow-trending-up',
                  'calendar-days',
                  'magnifying-glass',
                  'bell-alert',
                  'eye-slash',
                  'sparkles',
                  'globe-alt',
                  'bolt',
                ])
                  Icon(SsIcons.named(n), color: SsColors.of(context).ink2),
                Icon(SsIcons.named('star', solid: true), color: AppColors.aquecFg),
                Icon(SsIcons.named('check-circle', solid: true), color: AppColors.success),
                Icon(SsIcons.named('nao-existe'), color: SsColors.of(context).muted),
              ],
            ),
          ),
        ),
        tamanho: const Size(390, 150),
      ),
    ],
  ),
  Componente(
    'ss-bar-chart',
    'SsBarChart',
    'Barras agrupadas ou empilhadas, com negativos (a linha do zero separa) e linha combinada por cima. Par do Ss::BarChartComponent.',
    comportamentos: [
      'Empilhado: positivos sobem e negativos descem da linha do zero.',
      'line: desenha uma série como linha com pontos (ex. saldo).',
      'Tocar ou arrastar escolhe o grupo: fundo realçado e balão com o rótulo e cada valor (haptic a cada troca); tocar fora some.',
      'As barras crescem da linha do zero com a mola quando entram na tela.',
      'Cores: a da série ou a paleta da suíte começando pela marca; legenda com mais de uma série.',
    ],
    estados: [
      Estado(
        'empilhado',
        'empilhado com negativos e linha',
        (context) => _pad(
          SsCard(
            child: SsBarChart(
              labels: _meses,
              stacked: true,
              active: 5,
              format: _reaisInteiro,
              series: [
                SsSeries(const [5200, 4800, 5100, 5300, 4900, 5600], name: 'Receitas', color: AppColors.success),
                SsSeries(const [-4100, -5200, -3900, -4700, -5000, -4300], name: 'Despesas', color: AppColors.danger),
              ],
              line: const SsSeries([1100, -400, 1200, 600, -100, 1300], name: 'Saldo'),
            ),
          ),
        ),
        tamanho: const Size(390, 300),
        aguarde: 900,
      ),
      Estado(
        'agrupado',
        'agrupado (3 séries)',
        (_) => _pad(
          const SsCard(
            child: SsBarChart(
              labels: ['ago', 'set', 'out', 'nov'],
              height: 170,
              format: _reaisInteiro,
              series: [
                SsSeries([1200, 980, 1430, 1100], name: 'Nubank'),
                SsSeries([600, 720, 410, 830], name: 'Inter'),
                SsSeries([300, 0, 250, 190], name: 'C6'),
              ],
            ),
          ),
        ),
        tamanho: const Size(390, 270),
        aguarde: 900,
      ),
    ],
  ),
  Componente(
    'ss-money-field-expression',
    'SsMoneyField(expression:, signed:, formats:)',
    'Dinheiro com conta (45+12,50), sinal e moeda da conta. Par do Ss::MoneyInputComponent(expression:, signed:, currency:).',
    comportamentos: [
      'expression: o campo fica livre e embaixo aparece "= R\$ 57,50"; onChanged recebe o resultado; ao sair, o texto vira o valor.',
      'Conta que não fecha é erro de validação ("Conta ou valor inválido").',
      'O botão de calculadora (ou keypad: true) abre o teclado 4×4 com + − × ÷ e vírgula.',
      'signed: "-" na frente (e a tecla ± no teclado); formats: a moeda (US\$, €).',
    ],
    estados: [
      Estado(
        'campos',
        'com conta · negativo · em dólar',
        (_) => _pad(
          Column(
            spacing: 12,
            children: [
              SsMoneyField(label: 'Valor', cents: 5750, onChanged: (_) {}, expression: true),
              SsMoneyField(label: 'Saldo inicial', cents: -12050, onChanged: (_) {}, signed: true),
              SsMoneyField(label: 'Em dólar', cents: 9990, onChanged: (_) {}, formats: SsFormats.usd),
            ],
          ),
        ),
        tamanho: const Size(390, 300),
      ),
      Estado(
        'teclado',
        'teclado com conta',
        (_) => _pad(const SsAmountKeypad(initial: 4500, expression: true)),
        tamanho: const Size(390, 420),
      ),
    ],
  ),
  Componente(
    'ss-privacy',
    'SsPrivacyScope · SsPrivacyToggle · SsPrivate',
    'Esconder valores: dentro do escopo, todo SsAmount vira "R\$ •••" e o SsPrivate borra gráficos. Par do [data-privacy="on"] / ss-privacy do web.',
    comportamentos: [
      'O leitor de tela ouve "valor oculto" no lugar do número.',
      'O sinal some junto (não entrega se é entrada ou saída).',
      'SsPrivacyToggle é o olho (dica Mostrar/Esconder valores, troca com escala); guardar a escolha é do app.',
    ],
    estados: [
      Estado(
        'escondido',
        'visível · escondido',
        (_) => _pad(
          Row(
            spacing: 12,
            children: [
              for (final oculto in [false, true])
                Expanded(
                  child: SsPrivacyScope(
                    hidden: oculto,
                    child: SsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('Saldo')),
                              SsPrivacyToggle(hidden: oculto, onChanged: (_) {}),
                            ],
                          ),
                          SsAmount(money(1234567), size: 20),
                          const SizedBox(height: 8),
                          const SsPrivate(child: SsSparkline([3, 5, 4, 7, 6, 8])),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        tamanho: const Size(390, 200),
      ),
    ],
  ),
  Componente(
    'ss-progress-row',
    'SsProgressRow',
    'Linha de progresso: rótulo, gasto de limite, % e a barra no tom do estado (orçamento, limite do cartão, meta). Par do Ss::ProgressRowComponent.',
    comportamentos: [
      'Limite: até 80% (warnAt) na marca ou em color, de 80% a 100% aviso, acima de 100% estouro em vermelho ("R\$ 240,00 acima").',
      'Meta (kind: goal): 100% é sucesso, verde ("Meta batida").',
      'A barra enche com a mola quando entra na tela; onTap vira toque com o ripple.',
      'Com SsPrivacyScope escondendo, os valores e o % viram •••.',
    ],
    estados: [
      Estado(
        'tons',
        'ok · aviso · estouro · meta',
        (_) => _pad(
          const SsCard(
            child: Column(
              spacing: 16,
              children: [
                SsProgressRow(
                  label: 'Mercado',
                  value: 520,
                  limit: 1000,
                  format: _reais,
                  icon: Icons.shopping_cart_outlined,
                ),
                SsProgressRow(label: 'Lazer', value: 870, limit: 1000, format: _reais, icon: Icons.movie_outlined),
                SsProgressRow(
                  label: 'Restaurantes',
                  value: 1240,
                  limit: 1000,
                  format: _reais,
                  icon: Icons.restaurant_outlined,
                ),
                SsProgressRow(
                  label: 'Reserva',
                  value: 6000,
                  limit: 6000,
                  kind: SsProgressKind.goal,
                  format: _reais,
                  icon: Icons.verified_user_outlined,
                ),
              ],
            ),
          ),
        ),
        tamanho: const Size(390, 380),
        aguarde: 1000,
      ),
    ],
  ),
  Componente(
    'ss-chat-action-card',
    'SsChatActionCard',
    'Cartão de ação a confirmar no chat: o que o assistente propõe, os dados em linhas e Confirmar/Cancelar. Par do Ss::ChatActionComponent.',
    comportamentos: [
      'busy trava os dois botões e põe o carregando no Confirmar (não confirma duas vezes).',
      'Resolvido, os botões dão lugar à frase: feito (verde), cancelado (apagado) ou não deu certo (vermelho), em região viva.',
      'danger: Confirmar vermelho. Entra subindo com a mola (0,35 s).',
    ],
    estados: [
      Estado(
        'pendente',
        'dentro da bolha do assistente',
        (_) => _pad(
          const SsChatBubble(
            fromMe: false,
            child: SsChatActionCard(
              title: 'Lançar despesa',
              icon: Icons.credit_card_rounded,
              rows: [('Valor', 'R\$ 45,00'), ('Cartão', 'Nubank'), ('Categoria', 'Mercado')],
              onConfirm: _nada,
              onCancel: _nada,
            ),
          ),
        ),
        tamanho: const Size(390, 340),
        aguarde: 700,
      ),
      Estado(
        'resolvido',
        'confirmado · cancelado · erro',
        (_) => _pad(
          const Column(
            spacing: 10,
            children: [
              SsChatActionCard(
                title: 'Lançar despesa',
                rows: [('Valor', 'R\$ 45,00')],
                state: SsChatActionState.confirmed,
              ),
              SsChatActionCard(title: 'Lançar receita', state: SsChatActionState.cancelled),
              SsChatActionCard(
                title: 'Excluir conta',
                state: SsChatActionState.failed,
                result: 'Sem permissão',
                danger: true,
              ),
            ],
          ),
        ),
        tamanho: const Size(390, 420),
        aguarde: 700,
      ),
    ],
  ),
];
