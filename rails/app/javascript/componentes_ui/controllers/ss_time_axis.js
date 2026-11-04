// v0.10 (dados): conta compartilhada do gráfico no tempo (ss-time-chart) e das
// faixas de estado (ss-state-bands). Não é controller (não termina em
// _controller): só é importado por eles. A mesma conta do Flutter
// (dados_formato.dart), com o Intl do navegador no idioma da página.

const MIN = 60e3
const HORA = 60 * MIN
const DIA = 24 * HORA
export const PASSOS = [MIN, 2 * MIN, 5 * MIN, 10 * MIN, 15 * MIN, 30 * MIN, HORA, 2 * HORA, 3 * HORA, 6 * HORA, 12 * HORA,
  DIA, 2 * DIA, 7 * DIA, 14 * DIA, 30 * DIA, 91 * DIA, 182 * DIA, 365 * DIA]

// Idioma: o lang do elemento mais próximo (a página), senão o do navegador.
export function langOf(el, override) {
  return override || el?.closest?.("[lang]")?.getAttribute("lang") || document.documentElement.lang || navigator.language || "pt-BR"
}

const cache = new Map()

// Calendário do fuso: partes (ano, mês 0-11, dia, hora, minuto) de um instante e o instante
// de uma hora de parede. Sem fuso, o do navegador (Date); com fuso IANA (time_zone: do
// componente), pela conta do Intl: a "parede" vira um Date.UTC e volta pelo deslocamento.
const LOCAL = {
  parts(t) { const d = new Date(t); return { y: d.getFullYear(), m: d.getMonth(), d: d.getDate(), h: d.getHours(), mi: d.getMinutes() } },
  make: (y, m, d, h = 0, mi = 0) => new Date(y, m, d, h, mi).getTime()
}

function zoneCal(tz) {
  let dtf
  try { dtf = new Intl.DateTimeFormat("en-US", { timeZone: tz, hourCycle: "h23", year: "numeric", month: "numeric", day: "numeric", hour: "numeric", minute: "numeric", second: "numeric" }) } catch { return LOCAL }
  const wall = (t) => {
    const p = {}
    dtf.formatToParts(t).forEach((x) => { p[x.type] = +x.value })
    return Date.UTC(p.year, p.month - 1, p.day, p.hour % 24, p.minute, p.second)
  }
  const off = (t) => wall(t) - (t - (((t % 1000) + 1000) % 1000))
  return {
    parts(t) { const d = new Date(wall(t)); return { y: d.getUTCFullYear(), m: d.getUTCMonth(), d: d.getUTCDate(), h: d.getUTCHours(), mi: d.getUTCMinutes() } },
    make(y, m, d, h = 0, mi = 0) { const w = Date.UTC(y, m, d, h, mi); const t = w - off(w); return w - off(t) }
  }
}

// Formatadores no idioma `lang` (as mesmas saídas do SsTimeFormat do Flutter); `tz` (IANA,
// opcional) põe horas e datas nesse fuso em vez do do navegador.
export function formatter(lang, tz) {
  const key = `${lang}|${tz || ""}`
  if (cache.has(key)) return cache.get(key)
  const zone = tz ? { timeZone: tz } : {}
  const dt = (o) => { try { return new Intl.DateTimeFormat(lang, { ...o, ...zone }) } catch { return new Intl.DateTimeFormat("pt-BR", o) } }
  const nums = new Map()
  const short = lang.toLowerCase().slice(0, 2)
  // "15:05" / "02:10" (pt, es) e "3:05 PM" (en), como o Flutter.
  const hm = dt({ hour: short === "en" ? "numeric" : "2-digit", minute: "2-digit" })
  const dm = dt({ day: "2-digit", month: "2-digit" })
  const mon = dt({ month: "short" })
  const wd = dt({ weekday: "short" })
  const f = {
    lang,
    tz,
    cal: tz ? zoneCal(tz) : LOCAL,
    // Casas automáticas pelo tamanho: ≥ 100 → 0, ≥ 10 → 1, abaixo → 2.
    auto: (v) => (Math.abs(v) >= 100 ? 0 : Math.abs(v) >= 10 ? 1 : 2),
    number(v, decimals) {
      const d = decimals ?? f.auto(v)
      if (!nums.has(d)) nums.set(d, new Intl.NumberFormat(lang, { maximumFractionDigits: d }))
      const s = nums.get(d).format(v)
      return s.replace(/^-(0([.,]0*)?)$/, "$1") // "-0" vira "0"
    },
    // Valor com unidade: "21,5 °C", "48%" (o % vai colado).
    value(v, unit, decimals, empty = "—") {
      if (v == null || Number.isNaN(v)) return empty
      const n = f.number(v, decimals)
      if (!unit) return n
      return unit === "%" ? `${n}%` : `${n} ${unit}`
    },
    hm: (t) => hm.format(t),
    dm: (t) => dm.format(t),
    month: (t) => mon.format(t),
    weekday: (t) => wd.format(t),
    when: (t) => `${dm.format(t)} ${hm.format(t)}`,
    // Duração curta: "2 h 30 min", "3 d 4 h" (en: "2h 30m").
    duration(ms) {
      const en = short === "en"
      const u = (n, pt, e) => (en ? `${n}${e}` : `${n} ${pt}`)
      const min = Math.floor(ms / MIN)
      if (min < 1) return u(Math.floor(ms / 1000), "s", "s")
      if (min < 60) return u(min, "min", "m")
      const h = Math.floor(min / 60)
      if (h < 24) return min % 60 ? `${u(h, "h", "h")} ${u(min % 60, "min", "m")}` : u(h, "h", "h")
      const d = Math.floor(h / 24)
      return h % 24 ? `${u(d, "d", "d")} ${u(h % 24, "h", "h")}` : u(d, "d", "d")
    }
  }
  cache.set(key, f)
  return f
}

// Menor passo que cabe em maxTicks marcas.
export function passo(spanMs, maxTicks) {
  return PASSOS.find((p) => spanMs / p <= maxTicks) ?? PASSOS[PASSOS.length - 1]
}

// Marcas "inteligentes" de from a to (ms): horas num dia (a meia-noite vira a
// data e é "major"), dias numa semana, meses num ano. Hora do fuso do formatter
// (f.cal: o do navegador ou o time_zone: do componente).
export function ticks(from, to, maxTicks, f) {
  if (!(to > from)) return []
  const c = f.cal || LOCAL
  const p = passo(to - from, Math.max(2, maxTicks))
  const out = []
  const ini = c.parts(from)
  if (p < DIA) {
    const minutos = p / MIN
    let k = Math.ceil((ini.h * 60 + ini.mi) / minutos) * minutos
    const em = (k) => c.make(ini.y, ini.m, ini.d, 0, k)
    let t = em(k)
    if (t < from) t = em((k += minutos))
    while (t <= to) {
      const q = c.parts(t)
      const meia = q.h === 0 && q.mi === 0
      out.push({ at: t, label: meia ? f.dm(t) : f.hm(t), major: meia })
      k += minutos
      t = em(k)
    }
  } else if (p < 30 * DIA) {
    const dias = p / DIA
    let d0 = ini.d
    if (c.make(ini.y, ini.m, d0) < from) d0 += 1
    const curto = (to - from) / DIA <= 8
    for (let i = 0, t = c.make(ini.y, ini.m, d0); t <= to; i += dias, t = c.make(ini.y, ini.m, d0 + i)) {
      const q = c.parts(t)
      out.push({ at: t, label: curto ? `${f.weekday(t)} ${q.d}` : f.dm(t), major: q.d === 1 })
    }
  } else if (p < 365 * DIA) {
    const meses = Math.round(p / (30.44 * DIA))
    let M = ini.y * 12 + ini.m
    const em = (M) => c.make(Math.floor(M / 12), M % 12, 1)
    if (em(M) < from) M += 1
    while ((M % 12) % meses !== 0) M += 1
    for (let t = em(M); t <= to; M += meses, t = em(M)) {
      out.push({ at: t, label: M % 12 === 0 ? String(Math.floor(M / 12)) : f.month(t), major: M % 12 === 0 })
    }
  } else {
    let y = ini.y
    if (c.make(y, 0, 1) < from) y += 1
    for (let t = c.make(y, 0, 1); t <= to; y += 1, t = c.make(y, 0, 1)) out.push({ at: t, label: String(y), major: true })
  }
  return out
}

// Escala Y "redonda" (1, 2, 2,5, 5 × 10ⁿ) cobrindo lo..hi.
export function niceRange(lo, hi, count = 4) {
  if (lo === hi) { const d = lo === 0 ? 1 : Math.abs(lo) * 0.1; lo -= d; hi += d }
  const cru = (hi - lo) / Math.max(1, count)
  const mag = 10 ** Math.floor(Math.log10(cru))
  const n = cru / mag
  const step = (n <= 1 ? 1 : n <= 2 ? 2 : n <= 2.5 ? 2.5 : n <= 5 ? 5 : 10) * mag
  return { lo: Math.floor(lo / step) * step, hi: Math.ceil(hi / step) * step, step }
}

// Valor de uma série (pts = [[ms, v, min?, max?], …]) no instante t: degrau = última
// leitura até t; linha = reta entre as vizinhas; buraco (v nulo) = nulo; depois da
// última, a última; antes da primeira, nulo.
export function valueAt(pts, t, mode) {
  if (!pts.length || t < pts[0][0]) return null
  let lo = 0, hi = pts.length - 1, i = 0
  while (lo <= hi) { const mid = (lo + hi) >> 1; if (pts[mid][0] <= t) { i = mid; lo = mid + 1 } else hi = mid - 1 }
  const a = pts[i]
  if (mode === "step" || i === pts.length - 1 || a[1] == null) return a[1]
  const b = pts[i + 1]
  if (b[1] == null) return a[1]
  const span = b[0] - a[0]
  return span <= 0 ? b[1] : a[1] + (b[1] - a[1]) * ((t - a[0]) / span)
}

// Desenha as marcas do tempo num contêiner (spans posicionados em %), sem sair
// das bordas nem encostar uma na outra.
export function renderAxis(el, from, to, f) {
  const w = el.clientWidth
  if (!w) return
  const list = ticks(from, to, Math.max(2, Math.floor(w / 72)), f)
  el.replaceChildren(...list.map((k) => {
    const s = document.createElement("span")
    s.textContent = k.label
    if (k.major) s.className = "is-major"
    s.style.left = `${((k.at - from) / (to - from)) * 100}%`
    return s
  }))
  let ultimo = -Infinity
  for (const s of el.children) {
    const half = s.offsetWidth / 2
    let x = s.offsetLeft - half
    x = Math.max(0, Math.min(w - s.offsetWidth, x))
    if (x < ultimo + 6) { s.hidden = true; continue }
    s.style.left = `${x}px`
    s.style.translate = "0"
    ultimo = x + s.offsetWidth
  }
}

// Posiciona os trechos das faixas (data-from/data-to em ms) na janela from..to.
export function placeSegments(root, from, to) {
  root.querySelectorAll("[data-from][data-to]").forEach((s) => {
    const a = Math.max(from, +s.dataset.from), b = Math.min(to, +s.dataset.to)
    s.hidden = b <= a
    s.style.left = `${((a - from) / (to - from)) * 100}%`
    s.style.width = `max(1px, ${((b - a) / (to - from)) * 100}%)`
  })
}

export const escapeHtml = (s) => String(s).replace(/[&<>"']/g, (c) => `&#${c.charCodeAt(0)};`)
