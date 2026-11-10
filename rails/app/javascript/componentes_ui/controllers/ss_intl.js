// Idioma dos controllers da gem (v0.10). Não é controller (não termina em _controller):
// o eagerLoadControllersFrom não registra, mas o pin_all_from publica, então os
// controllers importam daqui:
//   import { ssLang, ssNumber, ssMoney } from "componentes_ui/controllers/ss_intl"
//
// Textos: nenhum controller tem texto fixo; o componente manda o texto já traduzido
// em data-*-value (Rails I18n). Números, dinheiro e datas: Intl com o <html lang>
// da página, pt-BR de reserva.

const FALLBACK = "pt-BR"

// Idioma da página ("pt-BR", "en", "es"…); inválido ou vazio → pt-BR.
export function ssLang() {
  const lang = document.documentElement.lang || FALLBACK
  try { return Intl.NumberFormat.supportedLocalesOf([lang]).length ? lang : FALLBACK } catch { return FALLBACK }
}

// 1234.5 → "1.234,5" (pt/es) ou "1,234.5" (en), com `decimals` casas fixas.
export function ssNumber(value, decimals = 0, lang = ssLang()) {
  return new Intl.NumberFormat(lang, { minimumFractionDigits: decimals, maximumFractionDigits: decimals }).format(value)
}

// Dinheiro na moeda do componente (padrão BRL): "R$ 1.234,50", "R$1,234.50", "1234,50 R$".
export function ssMoney(value, currency = "BRL", lang = ssLang(), decimals = 2) {
  try {
    return new Intl.NumberFormat(lang, { style: "currency", currency: currency || "BRL", minimumFractionDigits: decimals, maximumFractionDigits: decimals }).format(value)
  } catch {
    return new Intl.NumberFormat(FALLBACK, { style: "currency", currency: "BRL" }).format(value)
  }
}

// Separadores do idioma: { decimal: ",", group: "." }.
export function ssSeparators(lang = ssLang()) {
  const parts = new Intl.NumberFormat(lang).formatToParts(12345.6)
  return { decimal: parts.find((p) => p.type === "decimal")?.value || ",", group: parts.find((p) => p.type === "group")?.value || "." }
}

// Texto com número no formato do idioma → Number ("R$ 1.234,50" → 1234.5). NaN se não há número.
export function ssParseNumber(text, lang = ssLang()) {
  const { decimal, group } = ssSeparators(lang)
  const t = String(text).replace(/\u2212/g, "-")
  const m = t.match(/\d[\d\s.,\u00a0\u202f]*/)
  if (!m) return NaN
  const raw = m[0].replace(/[\s\u00a0\u202f]/g, "").replace(/[.,]$/, "")
  const n = parseFloat(raw.split(group).join("").replace(decimal, "."))
  return t.slice(0, m.index).includes("-") ? -n : n
}

// Separa os centavos para o <small>: "R$ 1.234,56" → ["R$ 1.234", ",56", ""];
// "1.234,56 R$" → ["1.234", ",56", " R$"]. Sem centavos: [texto, "", ""].
export function ssSplitCents(text, lang = ssLang()) {
  const { decimal } = ssSeparators(lang)
  const i = text.lastIndexOf(decimal)
  if (i < 0 || !/^\d{2}/.test(text.slice(i + 1))) return [text, "", ""]
  return [text.slice(0, i), text.slice(i, i + 3), text.slice(i + 3)]
}

// Texto com %{nome} → valor: ssFormat("Remover %{name}", { name: "x" }).
export function ssFormat(template, vars = {}) {
  return String(template ?? "").replace(/%\{(\w+)\}/g, (_, k) => (k in vars ? vars[k] : ""))
}

// v0.15: valor digitado como conta ("45+12,50-3", "3×19,90", "(10+5)/3"), o mesmo
// ComponentesUi::AmountExpression do servidor e o ssEvalAmount do Flutter. Só números,
// + − × ÷ e parênteses; devolve centavos inteiros ou null se não fecha. decimal: "," (pt/es)
// ou "." (en). Número: vírgula decimal (1–2 casas), ponto + 3 dígitos é milhar ("1.500").
export function ssAmountNumber(text, decimal = ",") {
  let s = String(text).trim()
  if (decimal === ".") s = s.replace(/[.,]/g, (c) => (c === "." ? "," : "."))
  if (/^[1-9]\d{0,2}(\.\d{3})+(,\d{1,2})?$/.test(s)) return Number(s.replace(/\./g, "").replace(",", "."))
  if (/^\d+(,\d{1,2})?$/.test(s)) return Number(s.replace(",", "."))
  if (/^\d+\.\d{1,2}$/.test(s)) return Number(s)
  if (/^,\d{1,2}$/.test(s)) return Number(`0${s.replace(",", ".")}`)
  return null
}

export function ssAmountExpression(text, decimal = ssSeparators().decimal) {
  const s = String(text ?? "").replace(/×/g, "*").replace(/÷/g, "/").replace(/−/g, "-").replace(/[^\d.,+\-*/()\s]/g, "").replace(/\s+/g, "")
  if (!s) return null
  const tokens = s.match(/[\d.,]+|[-+*/()]/g) || []
  if (tokens.join("") !== s) return null
  let i = 0
  const fail = () => { throw new Error("expr") }
  // Em centésimos de centavo para não acumular erro de ponto flutuante na soma.
  const factor = () => {
    const t = tokens[i++]
    if (t === "-") return -factor()
    if (t === "(") { const v = expr(); if (tokens[i++] !== ")") fail(); return v }
    if (t === undefined) fail()
    const n = ssAmountNumber(t, decimal)
    return n === null ? fail() : n
  }
  const term = () => {
    let v = factor()
    while (tokens[i] === "*" || tokens[i] === "/") {
      const op = tokens[i++], b = factor()
      if (op === "/" && b === 0) fail()
      v = op === "*" ? v * b : v / b
    }
    return v
  }
  const expr = () => {
    let v = term()
    while (tokens[i] === "+" || tokens[i] === "-") { const op = tokens[i++]; const b = term(); v = op === "+" ? v + b : v - b }
    return v
  }
  try {
    const v = expr()
    if (i !== tokens.length || !Number.isFinite(v)) return null
    return Math.round(Math.round(v * 1e6) / 1e4)
  } catch (_) { return null }
}

// Tem operador (é conta, não só um número)?
export function ssIsExpression(text) { return /[-+*/×÷−()]/.test(String(text ?? "").trim().replace(/^[-−]/, "")) }
