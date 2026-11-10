// v0.15: valor digitado como conta ("45+12,50"), a mesma conta do
// ComponentesUi::AmountExpression (servidor) e do ssAmountExpression (web).
import '../ss_strings.dart';

/// Número de um token no formato de [decimal] (pt: vírgula decimal com 1–2
/// casas; ponto + 3 dígitos é milhar, "1.500"; ponto com 1–2 casas também é
/// decimal, "12.5"). Nulo se não é número desse jeito.
double? ssAmountNumber(String text, {String decimal = ','}) {
  var s = text.trim();
  if (decimal == '.') s = s.replaceAllMapped(RegExp('[.,]'), (m) => m[0] == '.' ? ',' : '.');
  if (RegExp(r'^[1-9]\d{0,2}(\.\d{3})+(,\d{1,2})?$').hasMatch(s)) {
    return double.parse(s.replaceAll('.', '').replaceAll(',', '.'));
  }
  if (RegExp(r'^\d+(,\d{1,2})?$').hasMatch(s)) return double.parse(s.replaceAll(',', '.'));
  if (RegExp(r'^\d+\.\d{1,2}$').hasMatch(s)) return double.parse(s);
  if (RegExp(r'^,\d{1,2}$').hasMatch(s)) return double.parse('0${s.replaceAll(',', '.')}');
  return null;
}

/// "45+12,50-3" → 5450 (centavos). Só números, + − × ÷ (ou * /) e parênteses,
/// com × ÷ antes de + −; "R$" e espaços são ignorados. Nulo se a conta não
/// fecha (termina em operador, divisão por zero, número malformado).
int? ssEvalAmount(String text, [SsFormats? formats]) {
  final decimal = (formats ?? SsFormats.brl).decimalSeparator;
  final s = text
      .replaceAll('×', '*')
      .replaceAll('÷', '/')
      .replaceAll('−', '-')
      .replaceAll(RegExp(r'[^\d.,+\-*/()\s]'), '')
      .replaceAll(RegExp(r'\s+'), '');
  if (s.isEmpty) return null;
  final tokens = RegExp(r'[\d.,]+|[-+*/()]').allMatches(s).map((m) => m[0]!).toList();
  if (tokens.join() != s) return null;
  final p = _Conta(tokens, decimal);
  try {
    final v = p.soma();
    if (p.i != tokens.length || !v.isFinite) return null;
    return ((v * 1e6).round() / 1e4).round();
  } on FormatException {
    return null;
  }
}

class _Conta {
  _Conta(this.tokens, this.decimal);

  final List<String> tokens;
  final String decimal;
  var i = 0;

  double fator() {
    if (i >= tokens.length) throw const FormatException();
    final t = tokens[i++];
    if (t == '-') return -fator();
    if (t == '(') {
      final v = soma();
      if (i >= tokens.length || tokens[i++] != ')') throw const FormatException();
      return v;
    }
    return ssAmountNumber(t, decimal: decimal) ?? (throw const FormatException());
  }

  double termo() {
    var v = fator();
    while (i < tokens.length && (tokens[i] == '*' || tokens[i] == '/')) {
      final op = tokens[i++];
      final b = fator();
      if (op == '/' && b == 0) throw const FormatException();
      v = op == '*' ? v * b : v / b;
    }
    return v;
  }

  double soma() {
    var v = termo();
    while (i < tokens.length && (tokens[i] == '+' || tokens[i] == '-')) {
      final op = tokens[i++];
      final b = termo();
      v = op == '+' ? v + b : v - b;
    }
    return v;
  }
}

/// Tem operador (é conta, não só um número com sinal)?
bool ssIsAmountExpression(String text) =>
    RegExp(r'[-+*/×÷−()]').hasMatch(text.trim().replaceFirst(RegExp(r'^[-−]'), ''));
