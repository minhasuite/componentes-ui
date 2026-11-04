import { Controller } from "@hotwired/stimulus"
import { spring, easeOut, table } from "componentes_ui/controllers/ss_motion_controller"

// Indicador que desliza: UM elemento posicionado (pílula, sublinhado ou anel) que vai do item
// ativo antigo ao novo com a mola (--ss-bounce) e estica no sentido do movimento no meio do
// caminho, achatando ao pousar (como o círculo do menu do app). Serve para abas, segmentado,
// atalhos, menu lateral, passos, paginação…
//
//   <nav data-controller="ss-indicator" data-ss-indicator-kind-value="pill|line|ring">
//     <a href="/a" aria-current="page">A</a><a href="/b">B</a>
//   </nav>
//
// - Item ativo: aria-current (≠ false), aria-pressed="true", aria-selected="true", .is-active
//   ou com um input marcado dentro (radio). Troque com active-value (seletor CSS).
// - Itens: selector-value (padrão "a, button, label, [role=tab]").
// - Indicador: o target "ink" (se houver) ou um <span class="ss-ind is-pill|is-line|is-ring">
//   criado no fim do contêiner. A posição sai em --ind-x/--ind-y/--ind-w/--ind-h/--ind-r no
//   contêiner; o CSS (.ss-ind em v09_fundacao.css) faz a transição.
// - key-value: lembra a posição entre páginas (sessionStorage) e continua o deslize depois
//   de uma visita do Turbo (menu lateral, visões salvas, paginação por link).
// - Clique num item move na hora (otimista); o atributo de verdade corrige se for o caso.
// - toggle-value: o próprio controller marca o item clicado (escolha única sem outro JS):
//   "aria-pressed", "aria-selected" ou "aria-current" (aceita valor: "aria-current:page").
//   Dispara ss-indicator:change com detail.item.
// - kind "line" anda como MINHOCA (WAAPI, 520 ms): a borda da frente dispara para o alvo, a de
//   trás vem ~90 ms depois com a mola; no meio cobre as duas abas e afina (3 → 2 px), ao pousar
//   achata (~8% mais largo e mais grosso) e assenta. Durante o voo, data-ss-ind-move="r|l" no
//   contêiner acende o rastro de brilho (::after do sublinhado, no CSS).
// - motion-value="pop": não desliza; o indicador surge no item novo estalando (0,6 → 1,15 → 1)
//   e marca data-ss-ind-pop no indicador uma vez (o CSS solta uma ondinha). É o do passo a passo.
// Menos movimento: sem esticar (aqui) e sem transição (regra global do engine.css).
export default class extends Controller {
  static targets = ["ink"]
  static values = {
    kind: { type: String, default: "pill" },
    selector: { type: String, default: "a, button, label, [role=tab]" },
    active: { type: String, default: "" },
    toggle: { type: String, default: "" },
    motion: { type: String, default: "slide" },
    key: String
  }

  connect() {
    const el = this.element
    el.setAttribute("data-ss-ind", "still")
    if (!this.hasInkTarget) {
      const tag = /^(UL|OL)$/.test(el.tagName) ? "li" : "span"
      const ink = document.createElement(tag)
      ink.className = `ss-ind is-${this.kindValue}`
      ink.setAttribute("aria-hidden", "true")
      if (tag === "li") ink.setAttribute("role", "presentation")
      ink.setAttribute("data-ss-indicator-target", "ink")
      el.append(ink)
      this.created = ink
    }
    this.current = null
    this.storeKey = this.computeKey()
    this.resume() || this.place(this.activeItem(), false)
    requestAnimationFrame(() => requestAnimationFrame(() => { if (this.element.getAttribute("data-ss-ind") === "still") this.element.setAttribute("data-ss-ind", "") }))

    this.mo = new MutationObserver((list) => {
      const layoutOnly = list.every((m) => m.attributeName === "open" || m.attributeName === "hidden")
      this.refresh(!layoutOnly)
    })
    this.mo.observe(el, { subtree: true, attributes: true, attributeFilter: ["aria-current", "aria-pressed", "aria-selected", "class", "open", "hidden"] })
    this.ro = new ResizeObserver(() => this.refresh(false))
    this.ro.observe(el)
    this.onChange = () => this.refresh(true)
    this.onClick = (e) => this.optimistic(e)
    this.onToggle = () => this.refresh(false)
    this.save = () => this.remember()
    el.addEventListener("change", this.onChange)
    el.addEventListener("click", this.onClick)
    el.addEventListener("toggle", this.onToggle, true)
    window.addEventListener("pagehide", this.save)
    document.fonts?.ready.then(() => this.element.isConnected && this.refresh(false))
  }

  disconnect() {
    this.remember()
    this.mo?.disconnect(); this.ro?.disconnect()
    this.element.removeEventListener("change", this.onChange)
    this.element.removeEventListener("click", this.onClick)
    this.element.removeEventListener("toggle", this.onToggle, true)
    window.removeEventListener("pagehide", this.save)
    this.created?.remove()
    clearTimeout(this.moveTimer); clearTimeout(this.popTimer)
    this.element.removeAttribute("data-ss-ind")
    this.element.removeAttribute("data-ss-ind-move")
  }

  get ink() { return this.hasInkTarget ? this.inkTarget : this.created }

  get items() {
    return [...this.element.querySelectorAll(this.selectorValue)].filter((i) => i !== this.ink && !this.ink?.contains(i))
  }

  isActive(item) {
    try {
      if (this.activeValue) return item.matches(this.activeValue)
      const cur = item.getAttribute("aria-current")
      return (cur && cur !== "false") || item.getAttribute("aria-pressed") === "true" || item.getAttribute("aria-selected") === "true" ||
        item.classList.contains("is-active") || !!item.querySelector(":scope > input:checked")
    } catch (_) { return false }
  }

  activeItem() { return this.items.find((i) => this.isActive(i)) || null }

  // Retângulo do item no sistema do contêiner (contando a rolagem dele).
  rect(item) {
    const c = this.element, a = c.getBoundingClientRect(), b = item.getBoundingClientRect()
    if (!b.width && !b.height) return null
    return { x: b.left - a.left - c.clientLeft + c.scrollLeft, y: b.top - a.top - c.clientTop + c.scrollTop, w: b.width, h: b.height,
             r: getComputedStyle(item).borderTopLeftRadius }
  }

  write(r) {
    const s = this.element.style
    s.setProperty("--ind-x", `${r.x}px`); s.setProperty("--ind-y", `${r.y}px`)
    s.setProperty("--ind-w", `${r.w}px`); s.setProperty("--ind-h", `${r.h}px`)
    if (r.r) s.setProperty("--ind-r", r.r)
    this.last = r
  }

  refresh(animate) {
    if (this.resuming) return
    const item = this.activeItem()
    this.place(item, animate && item !== this.current)
  }

  optimistic(e) {
    if (e.defaultPrevented || e.button > 0 || e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return
    const item = e.target.closest?.(this.selectorValue)
    if (!item || !this.element.contains(item) || item.matches(":disabled, [aria-disabled=true]")) return
    if (this.toggleValue) return this.mark(item, e)
    if (item === this.current) return
    // Rádio/checkbox: espera o change (o clique no label dispara dois eventos).
    if (item.tagName === "LABEL" || e.target.matches("input")) return
    this.place(item, true)
  }

  mark(item, e) {
    const [attr, on = "true"] = this.toggleValue.split(":")
    if (item.tagName === "A" && (item.getAttribute("href") || "#") === "#") e.preventDefault()
    if (item.getAttribute(attr) === on) return
    this.items.forEach((i) => {
      if (i === item) i.setAttribute(attr, on)
      else if (attr === "aria-current") i.removeAttribute(attr)
      else i.setAttribute(attr, "false")
    })
    this.dispatch("change", { detail: { item } })
  }

  // Coloca o indicador no item; animate = desliza com mola (e estica).
  place(item, animate) {
    const el = this.element
    const r = item && this.rect(item)
    const was = this.current
    this.current = item
    if (!r) { el.setAttribute("data-ss-ind-empty", ""); return }
    const from = this.last
    // Nada mudou (o ResizeObserver avisa no começo, a fonte carrega…): não interrompe um deslize em curso.
    if (!animate && item === was && from && !el.hasAttribute("data-ss-ind-empty") &&
        ["x", "y", "w", "h"].every((k) => Math.abs(from[k] - r[k]) < 0.5)) return
    const appearing = el.hasAttribute("data-ss-ind-empty") || !from || (animate && !this.visible(from))
    if (!animate || appearing) {
      const prev = el.getAttribute("data-ss-ind")
      el.setAttribute("data-ss-ind", "still")
      this.write(r)
      el.removeAttribute("data-ss-ind-empty")
      void this.ink?.offsetWidth
      if (prev !== "still") el.setAttribute("data-ss-ind", prev ?? "")
      if (animate && appearing && was !== undefined) this.pop()
      return
    }
    el.removeAttribute("data-ss-ind-empty")
    if (this.motionValue === "pop") { this.still(() => this.write(r)); this.popIn(); return }
    if (this.wormy(from, r)) {
      const live = this.wormNow() || from
      this.still(() => this.write(r))
      this.movedAt = performance.now()
      this.from = from
      this.worm(live, r)
      return
    }
    this.ease(Math.hypot(r.x - from.x, r.y - from.y))
    this.write(r)
    this.movedAt = performance.now()
    this.from = from
    this.stretch(r.x - from.x, r.y - from.y)
  }

  // O ponto de partida está fora da área visível do contêiner (rolado)? Então surge no destino.
  visible(r) {
    const c = this.element
    return r.y + r.h > c.scrollTop && r.y < c.scrollTop + c.clientHeight && r.x + r.w > c.scrollLeft && r.x < c.scrollLeft + c.clientWidth
  }

  // Salto longo: a mola cheia passaria longe do alvo; usa uma mola mais curta (--ind-ease).
  ease(dist) {
    if (dist > 320) this.element.style.setProperty("--ind-ease", "cubic-bezier(.22, 1.1, .36, 1)")
    else this.element.style.removeProperty("--ind-ease")
  }

  get reduced() { return matchMedia("(prefers-reduced-motion: reduce)").matches }

  get duration() {
    const v = getComputedStyle(this.element).getPropertyValue("--ss-dur-indicator").trim()
    const n = parseFloat(v)
    return Number.isFinite(n) ? (v.endsWith("ms") ? n : n * 1000) : 460
  }

  // Esticar no meio do caminho e achatar ao pousar (WAAPI no `scale`, que soma com o translate do CSS).
  stretch(dx, dy, delay = 0) {
    const ink = this.ink
    const dist = Math.hypot(dx, dy)
    if (!ink || this.reduced || dist < 2 || !ink.animate) return
    const k = Math.min(0.24, 0.07 + dist / 900)
    const across = Math.abs(dx) >= Math.abs(dy)
    const s = (along, other) => (across ? `${along} ${other}` : `${other} ${along}`)
    this.anim?.cancel()
    this.anim = ink.animate([
      { scale: s(1, 1) },
      { scale: s(1 + k, 1 - k * 0.45), offset: 0.3 },
      { scale: s(1 - k * 0.32, 1 + k * 0.26), offset: 0.62 },
      { scale: s(1 + k * 0.08, 1 - k * 0.06), offset: 0.82 },
      { scale: s(1, 1) }
    ], { duration: this.duration, delay, easing: "ease-out" })
  }

  // Grava sem transição (a animação WAAPI é quem mostra o caminho).
  still(fn) {
    const el = this.element, prev = el.getAttribute("data-ss-ind")
    el.setAttribute("data-ss-ind", "still")
    fn()
    void this.ink?.offsetWidth
    el.setAttribute("data-ss-ind", prev === "still" ? "" : (prev ?? ""))
  }

  // Sublinhado na horizontal anda como minhoca.
  wormy(a, b) {
    return this.kindValue === "line" && !this.reduced && !!this.ink?.animate && Math.abs(a.y - b.y) < 1 && Math.abs(a.x - b.x) + Math.abs(a.w - b.w) > 1
  }

  // Onde a minhoca está agora (se interromperem no meio, recomeça dali, sem pulo).
  wormNow() {
    const w = this.wormState
    if (!w || this.anim?.playState !== "running") return null
    const t = Math.max(0, (this.anim.currentTime ?? 0))
    const { L, R } = this.wormEdges(w.a, w.b, t)
    return { ...w.b, x: L, w: R - L }
  }

  static WORM = { T: 520, LEAD: 300, LAG: 90 }

  // Bordas no tempo t (ms): a da frente (no sentido do movimento) corre com ease-out; a de trás
  // sai LAG ms depois com a mola. Nunca fica mais curta que metade da menor aba.
  wormEdges(a, b, t) {
    const { T, LEAD, LAG } = this.constructor.WORM
    const sp = this.spring ||= spring(this.element)
    const lead = easeOut(t / LEAD), trail = sp((t - LAG) / (T - LAG))
    const right = b.x + b.w / 2 >= a.x + a.w / 2
    const aL = a.x, aR = a.x + a.w, bL = b.x, bR = b.x + b.w
    let L = aL + (bL - aL) * (right ? trail : lead)
    let R = aR + (bR - aR) * (right ? lead : trail)
    const min = Math.min(a.w, b.w) * 0.5
    if (R - L < min) { if (right) L = R - min; else R = L + min }
    return { L, R }
  }

  worm(a, b, delay = 0) {
    const ink = this.ink
    const { T } = this.constructor.WORM
    // Folga do .ss-ind (--ind-out): a largura desenhada é a medida + 2·o.
    const o = (ink.offsetWidth - b.w) / 2
    // [p, scaleX, scaleY]: afina no voo (3 → 2 px), achata ao pousar e assenta.
    const shape = [[0, 1, 1], [0.12, 1, 0.67], [0.4, 1, 0.67], [0.55, 1.08, 1.3], [0.7, 0.98, 0.92], [0.85, 1.01, 1.03], [1, 1, 1]]
    const N = 32, frames = []
    for (let i = 0; i <= N; i++) {
      const p = i / N
      const { L, R } = this.wormEdges(a, b, p * T)
      const [sx, sy] = table(shape, p)
      frames.push({ offset: p, translate: `${(L - o).toFixed(2)}px 0px`, width: `${(R - L + 2 * o).toFixed(2)}px`, scale: `${sx.toFixed(3)} ${sy.toFixed(3)}` })
    }
    this.anim?.cancel()
    this.wormState = { a, b }
    ink.style.transformOrigin = "50% 100%"
    this.anim = ink.animate(frames, { duration: T, delay, easing: "linear" })
    // Rastro de brilho (CSS): reinicia a cada voo.
    const el = this.element
    el.removeAttribute("data-ss-ind-move")
    void el.offsetWidth
    el.setAttribute("data-ss-ind-move", b.x + b.w / 2 >= a.x + a.w / 2 ? "r" : "l")
    clearTimeout(this.moveTimer)
    this.moveTimer = setTimeout(() => el.removeAttribute("data-ss-ind-move"), T + Math.max(0, delay))
    this.anim.finished.then(() => { if (this.wormState?.b === b) this.wormState = null }, () => {})
  }

  // Surge no item novo estalando (motion "pop") e solta uma ondinha (data-ss-ind-pop, no CSS).
  popIn() {
    const ink = this.ink
    if (!ink || this.reduced || !ink.animate) return
    this.anim?.cancel()
    this.anim = ink.animate([
      { scale: 0.6, easing: "cubic-bezier(.3, .7, .4, 1)" },
      { scale: 1.15, offset: 0.45, easing: this.bounce },
      { scale: 1 }
    ], { duration: 520, delay: 120, fill: "backwards" })
    ink.removeAttribute("data-ss-ind-pop")
    void ink.offsetWidth
    ink.setAttribute("data-ss-ind-pop", "")
    clearTimeout(this.popTimer)
    this.popTimer = setTimeout(() => ink.removeAttribute("data-ss-ind-pop"), 900)
  }

  // Surgir onde não havia item ativo: cresce com mola.
  pop() {
    const ink = this.ink
    if (!ink || this.reduced || !ink.animate) return
    this.anim?.cancel()
    this.anim = ink.animate([{ scale: 0.6, opacity: 0 }, { scale: 1, opacity: 1 }], { duration: this.duration * 0.8, easing: this.bounce })
  }

  get bounce() {
    const v = getComputedStyle(this.element).getPropertyValue("--ss-bounce").trim()
    return v && CSS.supports?.("transition-timing-function", v) ? v : "cubic-bezier(.34, 1.56, .64, 1)"
  }

  // ── Entre páginas (Turbo/link): guarda onde estava e de onde vinha. ──
  // Mesma key em mais de um grupo na página (a moldura e uma cópia dela): separa pela ordem.
  computeKey() {
    if (!this.keyValue) return null
    const same = [...document.querySelectorAll("[data-ss-indicator-key-value]")].filter((e) => e.dataset.ssIndicatorKeyValue === this.keyValue)
    return `ss-ind:${this.keyValue}:${Math.max(0, same.indexOf(this.element))}`
  }

  remember() {
    if (!this.storeKey || !this.last) return
    const data = { to: this.last, from: this.from || null, movedAt: this.movedAt ? Date.now() - (performance.now() - this.movedAt) : 0, t: Date.now() }
    try { sessionStorage.setItem(this.storeKey, JSON.stringify(data)) } catch (_) {}
  }

  resume() {
    if (!this.storeKey) return false
    let d
    try { d = JSON.parse(sessionStorage.getItem(this.storeKey) || "null"); sessionStorage.removeItem(this.storeKey) } catch (_) { return false }
    const item = this.activeItem()
    const r = item && this.rect(item)
    if (!d || !r || Date.now() - d.t > 4000) return false
    const same = Math.abs(d.to.x - r.x) < 2 && Math.abs(d.to.y - r.y) < 2
    const elapsed = d.movedAt ? Date.now() - d.movedAt : Infinity
    let start, delay = 0
    if (same && d.from && elapsed < this.duration) { start = d.from; delay = -elapsed } // continua o deslize do clique
    else if (!same) start = d.to // veio de outra página sem clique aqui: desliza do antigo
    else return false
    if (!this.visible(start)) { this.place(item, false); this.pop(); return true } // longe/fora da vista: surge no lugar
    this.current = item
    this.write({ ...start, r: r.r })
    void this.ink?.offsetWidth
    // O Turbo desenha dentro de um rAF: até o próximo, o ResizeObserver não pode recolocar na hora.
    this.resuming = true
    requestAnimationFrame(() => {
      this.resuming = false
      if (!this.element.isConnected) return
      if (this.wormy(start, r)) {
        this.element.setAttribute("data-ss-ind", "")
        this.still(() => this.write(r))
        this.movedAt = performance.now() + delay
        this.from = start
        this.worm({ ...start }, r, delay)
        return
      }
      this.element.setAttribute("data-ss-ind", "")
      if (delay) this.ink?.style.setProperty("transition-delay", `${delay}ms`)
      this.ease(Math.hypot(r.x - start.x, r.y - start.y))
      this.write(r)
      this.movedAt = performance.now() + delay
      this.from = start
      this.stretch(r.x - start.x, r.y - start.y, delay)
      if (delay) setTimeout(() => this.ink?.style.removeProperty("transition-delay"), 50)
    })
    return true
  }
}
