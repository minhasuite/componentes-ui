import 'package:flutter/widgets.dart';

/// Uma tela montada só com peças do pacote (mostra os componentes juntos, como num produto).
class TelaDemo {
  const TelaDemo(this.titulo, this.descricao, this.build, {this.icone});
  final String titulo;
  final String descricao;
  final WidgetBuilder build;
  final IconData? icone;
}
