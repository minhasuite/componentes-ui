import { Controller } from "@hotwired/stimulus"

// Tema, paleta e OLED no <html>, lembrados no navegador:
//   data-theme="light|dark" (sem = segue o sistema), data-palette="eucalipto…", data-oled.
//   <div data-controller="ss-theme">
//     <button data-action="ss-theme#set" data-ss-theme-theme-param="dark">Escuro</button>
//     <button data-action="ss-theme#set" data-ss-theme-theme-param="dark" data-ss-theme-oled-param="true">OLED</button>
//     <button data-action="ss-theme#set" data-ss-theme-theme-param="system">Auto</button>
//     <button data-action="ss-theme#set" data-ss-theme-palette-param="eucalipto">Eucalipto</button>
// Escolher claro ou escuro sem oled-param desliga o OLED. Várias instâncias na
// página ficam marcadas juntas (evento ss-theme:change na window).
// Qualquer slug vale (sem lista fixa): as paletas vêm de paletas/paletas.json. O target
// "name" (opcional) mostra o nome da paleta marcada (o title do botão dela).
export default class extends Controller {
  static targets = ["name"]

  connect() {
    try {
      const t = localStorage.getItem("ss-theme"); if (t) this.write("theme", t)
      const p = localStorage.getItem("ss-palette"); if (p) this.write("palette", p)
      const o = localStorage.getItem("ss-oled"); if (o) this.write("oled", o === "true" ? "" : null)
    } catch (_) {}
    this.remark = () => this.mark()
    window.addEventListener("ss-theme:change", this.remark)
    this.mark()
  }

  disconnect() { window.removeEventListener("ss-theme:change", this.remark) }

  set({ params }) {
    const run = () => {
      if (params.theme) {
        this.write("theme", params.theme === "system" ? null : params.theme)
        this.store("theme", params.theme === "system" ? "none" : params.theme)
        if (params.oled === undefined) this.setOled(false)
      }
      if (params.oled !== undefined) this.setOled(params.oled === true || params.oled === "true")
      if (params.palette !== undefined) {
        const p = params.palette && params.palette !== "none" ? params.palette : null
        this.write("palette", p); this.store("palette", p || "none")
      }
    }
    // A troca vai num view transition (cruzamento suave); o callback roda depois, então
    // as marcas (aria-pressed) só são refeitas quando o DOM já mudou.
    const changed = () => window.dispatchEvent(new CustomEvent("ss-theme:change"))
    if (document.startViewTransition && !matchMedia("(prefers-reduced-motion: reduce)").matches) {
      document.startViewTransition(run).updateCallbackDone.then(changed, changed)
    } else { run(); changed() }
  }

  setOled(on) { this.write("oled", on ? "" : null); this.store("oled", on ? "true" : "false") }

  write(kind, value) {
    const root = document.documentElement
    if (value === null || value === undefined || value === "none") delete root.dataset[kind]
    else root.dataset[kind] = value
  }

  store(kind, value) { try { localStorage.setItem(`ss-${kind}`, value) } catch (_) {} }

  mark() {
    const root = document.documentElement
    const theme = root.dataset.theme || "system"
    const oled = root.dataset.oled !== undefined
    const palette = root.dataset.palette || "none"
    this.element.querySelectorAll("[data-ss-theme-theme-param],[data-ss-theme-palette-param],[data-ss-theme-oled-param]").forEach((b) => {
      const d = b.dataset
      let on = false
      if (d.ssThemeThemeParam) {
        const wantsOled = d.ssThemeOledParam === "true"
        on = d.ssThemeThemeParam === theme && (theme !== "dark" || wantsOled === oled)
      } else if (d.ssThemeOledParam !== undefined) {
        on = (d.ssThemeOledParam === "true") === oled
      }
      if (d.ssThemePaletteParam !== undefined) {
        on = d.ssThemePaletteParam === palette || (palette === "none" && d.ssThemePaletteParam === "violeta")
        if (on && this.hasNameTarget) this.nameTarget.textContent = b.title || b.getAttribute("aria-label") || ""
      }
      b.setAttribute("aria-pressed", on ? "true" : "false")
    })
    // Faixa rolável (compacto): traz a paleta marcada para a vista, sem rolar a página.
    const chip = this.element.querySelector('.ss-pal-chip[aria-pressed="true"]')
    const strip = chip?.closest(".ss-theme-pal-grid")
    if (strip && strip.scrollWidth > strip.clientWidth) {
      const x = chip.offsetLeft - (strip.clientWidth - chip.offsetWidth) / 2
      if (x < strip.scrollLeft || x > strip.scrollLeft + strip.clientWidth - chip.offsetWidth) strip.scrollLeft = Math.max(0, x)
    }
  }
}
