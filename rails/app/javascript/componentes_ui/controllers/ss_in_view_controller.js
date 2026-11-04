import { Controller } from "@hotwired/stimulus"

// Entrada ao aparecer na tela. Marca data-in-view (uma vez) quando ~25% do
// elemento fica visível; o CSS anima a partir daí (gráficos, números, cards).
//
//   <div data-controller="ss-in-view">…</div>                       (o elemento entra)
//   <ul data-controller="ss-in-view" data-ss-in-view-stagger-value="true">  (filhos com --i: 0, 1, 2…)
//
// Como funciona sem esconder nada à toa:
// - Sem JS, sem IntersectionObserver ou com menos movimento, nada é escondido:
//   as animações de CSS tocam no carregamento (ou nem tocam) e o conteúdo fica lá.
// - O que já está na tela quando o JS liga só ganha data-in-view (a animação de
//   carregamento segue). O que está fora ganha .ss-iv ("armado"): o CSS segura o
//   estado inicial (.ss-iv:not([data-in-view])) até entrar na tela.
// - Quem entra junto (mesmo lote do observer) ganha --ss-iv-i 0, 1, 2… para cascatear.
//
// Outros controllers usam a função: import { inView } from "componentes_ui/controllers/ss_in_view_controller"
// Repetir (vitrine, depuração): el.dispatchEvent(new CustomEvent("ss:replay")) ou replay(el).

const reduced = () => matchMedia("(prefers-reduced-motion: reduce)").matches
const watched = new Map() // elemento → { onEnter, seen }
let observer = null

function enter(el, i, initial) {
  const st = watched.get(el)
  if (!st || st.seen) return
  st.seen = true
  el.style.setProperty("--ss-iv-i", Math.min(i, 8))
  el.setAttribute("data-in-view", "")
  st.onEnter?.({ initial })
  observer?.unobserve(el)
}

function onEntries(entries) {
  const batch = entries
    .filter((e) => {
      const st = watched.get(e.target)
      if (!st || st.seen) return false
      const root = e.rootBounds?.height || innerHeight
      const visible = e.intersectionRatio >= 0.25 || e.intersectionRect.height >= root * 0.25
      if (!st.checked) {
        st.checked = true
        // 1ª leitura: já na tela entra agora; fora dela, arma (segura o estado inicial).
        if (e.isIntersecting) return true
        e.target.classList.add("ss-iv")
        return false
      }
      return visible
    })
    .map((e) => e.target)
    .sort((a, b) => (a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1))
  batch.forEach((el, i) => enter(el, i, !el.classList.contains("ss-iv")))
}

// Observa `el` e chama onEnter({ initial }) uma vez quando ele aparece. Devolve o "parar".
export function inView(el, { onEnter } = {}) {
  if (el.hasAttribute("data-in-view") && !watched.has(el)) { onEnter?.({ initial: true }); return () => {} }
  watched.set(el, { onEnter, seen: false, checked: false })
  if (reduced() || !("IntersectionObserver" in window)) { enter(el, 0, true); return () => watched.delete(el) }
  observer ||= new IntersectionObserver(onEntries, { threshold: [0, 0.1, 0.25] })
  observer.observe(el)
  return () => { observer?.unobserve(el); watched.delete(el) }
}

// Toca de novo a entrada de `root` e de tudo que é observado dentro dele.
export function replay(root) {
  if (reduced()) return
  const els = [...watched.keys()].filter((el) => root === el || root.contains(el))
  els.forEach((el) => { el.removeAttribute("data-in-view"); el.classList.add("ss-iv"); watched.get(el).seen = false })
  void root.offsetWidth // aplica o estado inicial antes de soltar (a animação recomeça)
  requestAnimationFrame(() => els.forEach((el, i) => enter(el, i, false)))
}

document.addEventListener("ss:replay", (e) => replay(e.target), true)

// Peças de helper (ss_gauge, ss_rings, ss_sparkline, .ss-bars) não passam por
// componente: ganham o controller sozinhas quando a página carrega.
const AUTO = ".ss-gauge, .ss-rings, .ss-spark, .ss-bars"
function autoAttach(root = document) {
  root.querySelectorAll?.(AUTO).forEach((el) => {
    const list = (el.getAttribute("data-controller") || "").split(/\s+/)
    if (list.includes("ss-in-view")) return
    el.setAttribute("data-controller", [...list, "ss-in-view"].filter(Boolean).join(" "))
    if (el.classList.contains("ss-bars")) el.setAttribute("data-ss-in-view-stagger-value", "true")
  })
}
if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", () => autoAttach())
else autoAttach()
document.addEventListener("turbo:load", () => autoAttach())
document.addEventListener("turbo:frame-load", (e) => autoAttach(e.target))

export default class extends Controller {
  static values = { stagger: Boolean }

  connect() {
    if (this.staggerValue) [...this.element.children].forEach((c, i) => c.style.setProperty("--i", i))
    this.stop = inView(this.element, { onEnter: ({ initial }) => this.dispatch("enter", { detail: { initial } }) })
  }

  disconnect() { this.stop?.() }

  replay() { replay(this.element) }
}
