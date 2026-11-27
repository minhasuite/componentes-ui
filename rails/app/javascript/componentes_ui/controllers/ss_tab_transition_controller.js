import { Controller } from "@hotwired/stimulus"

// v1.14.0 · troca de aba da app_shell com View Transition (par do SsSharedAxisTransition): o clique numa aba da
// barra de baixo marca o <html> (data-ss-tab-nav) antes de o Turbo começar a transição; o CSS dá o nome ao
// conteúdo (fade through: sai esmaecendo, entra esmaecendo e crescendo de .96) e deixa a barra parada, e as peças
// com ss_tab_hero("x") voam de uma aba para a outra. A marca sai sozinha quando a transição acaba.
// Sem a meta (ss_view_transitions_head), sem suporte ou com reduzir movimento: corte normal.
export default class extends Controller {
  mark(e) {
    const a = e.target.closest?.("a.ss-shell-tab")
    if (!a || a.getAttribute("aria-current") === "page" || e.metaKey || e.ctrlKey || e.shiftKey) return
    const html = document.documentElement
    html.dataset.ssTabNav = ""
    clearTimeout(html._ssTabNavTimer)
    html._ssTabNavTimer = setTimeout(() => delete html.dataset.ssTabNav, 1200)
  }
}
