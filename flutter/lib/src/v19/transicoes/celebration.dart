import 'package:flutter/semantics.dart' show SemanticsService;
import 'package:material_ui/material_ui.dart';

import '../../ss_strings.dart';

/// Os tipos de comemoração da suíte (v1.9), os mesmos do web
/// (`Ss::CelebrateComponent(kind: :goal/:streak/:first_use)`).
///
/// A regra: só comemora conquista de verdade, e no máximo **uma vez por
/// sessão por tipo** ([SsCelebrationGate]). Meta e primeiro uso soltam o
/// confete; sequência dá o estouro em volta do número (sem confete).
enum SsCelebrationKind {
  /// Meta batida (orçamento, treino, vendas do mês).
  goal('goal'),

  /// Sequência mantida (dias seguidos).
  streak('streak'),

  /// Primeiro uso (primeiro lançamento, primeiro pedido).
  firstUse('first_use');

  const SsCelebrationKind(this.key);

  /// O nome do tipo no web e na chave guardada (`ss-celebrate:first_use`).
  final String key;

  /// O que o leitor de tela anuncia.
  String announcement(SsStrings s) => switch (this) {
    goal => s.celebrateGoal,
    streak => s.celebrateStreak,
    firstUse => s.celebrateFirstUse,
  };
}

/// Onde o [SsCelebrationGate] guarda o que já comemorou. O padrão
/// ([SsMemoryCelebrationStore]) vale enquanto o app está aberto (a sessão);
/// o app pode guardar por mais tempo (ex.: preferências com o dia na chave).
abstract interface class SsCelebrationStore {
  bool contains(String key);
  void add(String key);
  void remove(String key);
}

/// Guarda na memória: uma sessão = o app aberto.
class SsMemoryCelebrationStore implements SsCelebrationStore {
  final _chaves = <String>{};

  @override
  bool contains(String key) => _chaves.contains(key);

  @override
  void add(String key) => _chaves.add(key);

  @override
  void remove(String key) => _chaves.remove(key);
}

/// A porta da comemoração: no máximo uma por sessão por tipo. O
/// [SsCelebrate] com `kind:` passa por ela; para comemorar à mão (ex.: um
/// [SsBurst] próprio), pergunte antes com [claim].
///
/// ```dart
/// if (SsCelebrationGate.instance.claim(SsCelebrationKind.goal)) showSsConfetti(context);
/// ```
/// O web faz o mesmo no `sessionStorage` (`ss-celebrate:<tipo>`).
class SsCelebrationGate {
  SsCelebrationGate({SsCelebrationStore? store, this.scope = ''}) : store = store ?? SsMemoryCelebrationStore();

  /// A porta padrão do app (memória). Troque no `main` para outro armazenamento.
  static SsCelebrationGate instance = SsCelebrationGate();

  final SsCelebrationStore store;

  /// Prefixo opcional (ex.: o id do usuário, para quem troca de conta).
  final String scope;

  String keyOf(SsCelebrationKind kind) => 'ss-celebrate:${scope.isEmpty ? '' : '$scope:'}${kind.key}';

  /// Ainda pode comemorar este tipo nesta sessão.
  bool canCelebrate(SsCelebrationKind kind) => !store.contains(keyOf(kind));

  /// Pega a vez: verdadeiro na primeira chamada do tipo na sessão (e marca).
  bool claim(SsCelebrationKind kind) {
    final k = keyOf(kind);
    if (store.contains(k)) return false;
    store.add(k);
    return true;
  }

  /// Libera de novo (todos os tipos sem [kind]); para testes e troca de conta.
  void reset([SsCelebrationKind? kind]) {
    for (final k in kind == null ? SsCelebrationKind.values : [kind]) {
      store.remove(keyOf(k));
    }
  }
}

/// Anuncia a comemoração no leitor de tela (o confete é só visual).
void ssAnnounceCelebration(BuildContext context, SsCelebrationKind kind) {
  final texto = kind.announcement(SsStrings.of(context));
  SemanticsService.sendAnnouncement(View.of(context), texto, Directionality.maybeOf(context) ?? TextDirection.ltr);
}
