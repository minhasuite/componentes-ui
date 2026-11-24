import { Controller } from "@hotwired/stimulus"

// Ss::ConfettiComponent (v0.15): confete em canvas, sem biblioteca, nas cores da marca e das
// séries (--accent, --series-1..6 do tema da página). auto: dispara ao conectar; key: uma vez
// por navegador. Nada com prefers-reduced-motion. Também: window.ssConfetti().
const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches

export function ssConfetti() {
  if (reduced() || !document.body) return
  const css = getComputedStyle(document.documentElement)
  const colors = ["--accent", "--series-2", "--series-3", "--series-4", "--series-5", "--success"]
    .map((v) => css.getPropertyValue(v).trim()).filter(Boolean)
  if (!colors.length) colors.push("#5a45e8")
  const canvas = document.createElement("canvas")
  Object.assign(canvas.style, { position: "fixed", inset: "0", width: "100%", height: "100%", pointerEvents: "none", zIndex: 2147483000 })
  canvas.setAttribute("aria-hidden", "true")
  canvas.className = "ss-confetti-canvas"
  document.body.appendChild(canvas)
  const ctx = canvas.getContext("2d")
  const dpr = window.devicePixelRatio || 1
  canvas.width = innerWidth * dpr; canvas.height = innerHeight * dpr; ctx.scale(dpr, dpr)
  const parts = Array.from({ length: 150 }, (_, i) => ({
    x: innerWidth * (i % 2 ? 0.2 : 0.8), y: innerHeight * 0.65,
    vx: (Math.random() - 0.5) * 14 + (i % 2 ? 5 : -5), vy: -Math.random() * 16 - 6,
    s: Math.random() * 7 + 5, r: Math.random() * Math.PI, vr: (Math.random() - 0.5) * 0.3, c: colors[i % colors.length]
  }))
  const start = performance.now()
  const frame = (now) => {
    ctx.clearRect(0, 0, innerWidth, innerHeight)
    const fade = Math.min(1, Math.max(0, (2600 - (now - start)) / 600))
    ctx.globalAlpha = fade
    parts.forEach((p) => {
      p.vy += 0.42; p.vx *= 0.99; p.x += p.vx; p.y += p.vy; p.r += p.vr
      ctx.save(); ctx.translate(p.x, p.y); ctx.rotate(p.r)
      ctx.fillStyle = p.c; ctx.fillRect(-p.s / 2, -p.s / 4, p.s, p.s / 2); ctx.restore()
    })
    if (now - start < 2600) requestAnimationFrame(frame)
    else canvas.remove()
  }
  requestAnimationFrame(frame)
}

// v1.9 · regra de comemoração (par do SsCelebrationGate do Flutter): no máximo uma por sessão
// por tipo (goal, streak, first_use), guardada no sessionStorage ("ss-celebrate:<tipo>").
// Devolve true na primeira vez do tipo na sessão (e marca). Sem sessionStorage, deixa passar.
export function ssCelebrationClaim(kind) {
  if (!kind) return true
  const k = `ss-celebrate:${kind}`
  try {
    if (sessionStorage.getItem(k)) return false
    sessionStorage.setItem(k, "1")
  } catch (_) {}
  return true
}

export default class extends Controller {
  static values = { key: String, kind: String, auto: { type: Boolean, default: true } }

  connect() {
    window.ssConfetti = ssConfetti
    if (!this.autoValue) return
    if (this.keyValue) {
      const k = `ss-celebrated:${this.keyValue}`
      try {
        if (localStorage.getItem(k)) return
        localStorage.setItem(k, "1")
      } catch (_) {}
    }
    this.burst()
  }

  burst() {
    // v1.9: com kind:, só a primeira do tipo na sessão.
    if (this.kindValue && !ssCelebrationClaim(this.kindValue)) return
    ssConfetti()
  }
}
