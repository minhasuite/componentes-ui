// v1.7: tela de entrada "Cartaz + papel" ([catalogoV170]: ss-auth-cartaz), par do Ss::AuthLayoutComponent(variant: :cartaz).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

List<Widget> _entrar() => [
  const SsTextField(label: 'E-mail', hint: 'voce@exemplo.com', keyboardType: TextInputType.emailAddress),
  const SizedBox(height: 16),
  const SsTextField(label: 'Senha', obscureText: true),
  const SizedBox(height: 24),
  SsButton(label: 'Entrar', onPressed: () {}),
];

Widget _vendas() => SsAuthLayout.cartaz(
  product: 'Minhas Vendas',
  tagline: 'A venda não para.',
  word: 'vendas',
  facts: const ['Web', 'Windows', 'Caixa', 'App'],
  icon: Icons.bar_chart_rounded,
  title: 'Entrar',
  subtitle: 'no Minhas Vendas',
  footer: const [Text('Termos'), Text('Privacidade')],
  children: _entrar(),
);

final catalogoV170 = <Componente>[
  Componente(
    'ss-auth-cartaz',
    'SsAuthLayout.cartaz',
    'Tela de entrada "Cartaz + papel": metade cartaz na cor funda da marca (brandDeep) com o produto, a frase grande e a palavra gigante cortada pela borda; metade papel com o formulário. Par do Ss::AuthLayoutComponent(variant: :cartaz).',
    comportamentos: [
      'layout: SsCartazLayout.split. A partir de 840 de largura, cartaz (6/11) e papel (5/11) lado a lado; abaixo, o cartaz vira uma faixa em cima (sem a linha de dados) e o papel desce.',
      'Cor: brandDeep no claro; no escuro e no OLED, brandDeep a 52% com a página. Texto branco ≥ 7:1 e secundário ≥ 4,5:1 em todas as paletas (gerar.py confere).',
      'word: a palavra gigante, decorativa e fora do leitor de tela; padrão é a última palavra do produto em minúsculas.',
      'Ao abrir, a passada de cor varre o cartaz uma vez (1 s) e a palavra entra deslizando; reduzir movimento desliga.',
      'O formulário é do app (SsGoogleButton, SsTextField, SsButton, SsCallout); título em AppTheme.display, "Parte da MinhaSuite" e dados em AppTheme.number.',
    ],
    estados: [
      Estado('celular', 'celular (390)', (_) => _vendas(), tamanho: const Size(390, 844), aguarde: 2600),
      Estado('computador', 'computador (1440)', (_) => _vendas(), tamanho: const Size(1440, 900), aguarde: 2600),
    ],
  ),
];
