import { Controller } from "@hotwired/stimulus"

// Movimento de seleção e ajudantes de mola compartilhados.
//
// 1) Chave, caixinha e rádio desenhados (.ss-switch-row input, .ss-check > input,
//    .ss-option-card > input). O ESTADO (cor, ✓, ponto) é CSS puro e fica parado no
//    carregamento. O que só faz sentido quando a pessoa troca (antecipação, estouro de
//    partículas, halo, ondinha, balanço ao desmarcar) toca pelo atributo data-ss-anim="on|off",
//    que este módulo põe num `change` delegado no document e tira ao fim (uma vez por troca).
//    Liga sozinho quando o arquivo é carregado (eagerLoadControllersFrom); com carregamento
//    preguiçoso, ponha data-controller="ss-motion" em qualquer elemento (o <body>, por exemplo).
//    Trocar por script (input.checked = …) não dispara change: só muda o estado, sem festa.
//
// 2) Ajudantes usados pelo ss-indicator (minhoca do sublinhado) e pelo ss-wizard (linha que
//    enche): reduced(), spring(el) (a curva --ss-bounce lida do CSS) e easeOut/easeOutBack.
//
// Menos movimento: nada disso toca (o CSS para as animações e aqui não se marca nada).

export const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export const clamp01 = (t) => Math.min(1, Math.max(0, t))
export const easeOut = (t) => 1 - (1 - clamp01(t)) ** 3
// Passa do alvo (s ≈ 1,2 → ~8%) e volta: a "cabeça" que corre na frente.
export const easeOutBack = (t, s = 1.2) => { const x = clamp01(t) - 1; return 1 + (s + 1) * x ** 3 + s * x ** 2 }

// A mola da suíte (--ss-bounce, um linear() com pontos igualmente espaçados) como função 0..1.
const springCache = new Map()
export function spring(el = document.documentElement) {
  const v = getComputedStyle(el).getPropertyValue("--ss-bounce").trim()
  if (springCache.has(v)) return springCache.get(v)
  const m = v.match(/linear\(([^)]*)\)/)
  const pts = m ? m[1].split(",").map((s) => parseFloat(s)).filter(Number.isFinite) : []
  const fn = pts.length > 2
    ? (t) => { const x = clamp01(t) * (pts.length - 1), i = Math.floor(x); return i >= pts.length - 1 ? pts[pts.length - 1] : pts[i] + (pts[i + 1] - pts[i]) * (x - i) }
    : (t) => { const x = clamp01(t); return x >= 1 ? 1 : 1 - Math.exp(-7 * x) * Math.cos(10 * x) }
  springCache.set(v, fn)
  return fn
}

// Interpola uma tabela [[p, a, b…], …] em p (0..1): usada para o achatar/afinar da minhoca.
export function table(rows, p) {
  const x = clamp01(p)
  for (let i = 1; i < rows.length; i++) {
    const [p1, ...v1] = rows[i]
    if (x <= p1) {
      const [p0, ...v0] = rows[i - 1]
      const k = p1 === p0 ? 1 : (x - p0) / (p1 - p0)
      const s = k * k * (3 - 2 * k) // suave nas pontas
      return v0.map((a, j) => a + (v1[j] - a) * s)
    }
  }
  return rows[rows.length - 1].slice(1)
}

const SEL = '.ss-switch-row input, :is(.ss-check, .ss-option-card) > input:is([type="checkbox"], [type="radio"])'
const timers = new WeakMap()

// Toca a festa da troca uma vez no input (on = acabou de marcar).
export function play(input) {
  if (reduced()) return
  input.removeAttribute("data-ss-anim")
  void input.offsetWidth // recomeça a animação se trocar de novo no meio
  input.setAttribute("data-ss-anim", input.checked ? "on" : "off")
  clearTimeout(timers.get(input))
  timers.set(input, setTimeout(() => input.removeAttribute("data-ss-anim"), 800))
}

function onChange(e) {
  const el = e.target
  if (el instanceof HTMLInputElement && el.matches(SEL)) play(el)
}

if (!globalThis.__ssMotionOn) {
  globalThis.__ssMotionOn = true
  document.addEventListener("change", onChange, true)
}

// O módulo já liga tudo; o controller existe para o carregamento preguiçoso.
export default class extends Controller {}
