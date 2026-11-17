// v1.2.2 (achado 17 das videoaulas do minhas-vendas) ([comV122]): o rótulo visível dos campos é o nome
// do campo para o leitor de tela (dentro e fora de lista) e não é lido duas vezes. Só comportamento.
import 'catalogo.dart';

const Map<String, String> _v122 = {
  'ss-text-field': 'v1.2.2: o rótulo (label:) é o nome do próprio campo no leitor de tela, com ou sem hideLabel, dentro e fora de ListView; o rótulo visível acima fica fora da semântica (não é lido duas vezes).',
  'ss-money-field': 'v1.2.2: o rótulo é o nome do campo no leitor de tela (vem do SsTextField).',
  'ss-choice-field': 'v1.2.2: o rótulo visível fica fora da semântica; o botão já diz o rótulo e o valor.',
  'ss-time-field': 'v1.2.2: o rótulo visível fica fora da semântica; o botão já diz o rótulo e o valor.',
};

List<Componente> comV122(List<Componente> base) => [
  for (final c in base)
    if (_v122[c.slug] case final comp?)
      Componente(c.slug, c.nome, c.descricao, comportamentos: [...c.comportamentos, comp], estados: c.estados)
    else
      c,
];
