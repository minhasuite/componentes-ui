import { Controller } from "@hotwired/stimulus"

// Ss::CommandPaletteComponent: Ctrl/⌘ + atalho abre; filtra ignorando acento e caixa,
// destaca o trecho com <mark>; ↑/↓ andam, Enter abre, Esc fecha (o próprio <dialog>).
// src: busca no servidor (GET src?q=) que devolve HTML com a.ss-command-item.
const norm = (s) => (s || "").normalize("NFD").replace(/\p{M}/gu, "").toLowerCase()

export default class extends Controller {
  static targets = ["input", "list", "item", "group", "remote", "empty"]
  static values = { shortcut: String, src: String }

  connect() {
    this.onKey = (e) => {
      if (!this.shortcutValue || !(e.ctrlKey || e.metaKey) || e.altKey || e.shiftKey || e.key?.toLowerCase() !== this.shortcutValue) return
      // Duas paletas com o mesmo atalho: só a primeira da página responde.
      const first = [...document.querySelectorAll('[data-controller~="ss-command"]')].find((el) => el.dataset.ssCommandShortcutValue === this.shortcutValue)
      if (first !== this.element) return
      e.preventDefault()
      this.element.open ? this.element.close() : this.open()
    }
    this.onClick = (e) => {
      const opener = e.target.closest?.("[data-ss-command-open]")
      if (opener && opener.dataset.ssCommandOpen === this.element.id) { e.preventDefault(); this.open() }
    }
    window.addEventListener("keydown", this.onKey)
    document.addEventListener("click", this.onClick)
  }

  disconnect() {
    window.removeEventListener("keydown", this.onKey)
    document.removeEventListener("click", this.onClick)
    clearTimeout(this.timer)
    this.abort?.abort()
  }

  open() {
    if (this.element.open) { this.inputTarget.select(); return }
    this.inputTarget.value = ""
    this.filter()
    this.element.showModal()
    this.inputTarget.focus()
  }

  closed() { clearTimeout(this.timer) }

  backdrop(event) {
    if (event.target === this.element) this.element.close()
  }

  // Item escolhido (clique ou Enter): fecha antes de navegar, para o cache do Turbo não guardar aberta.
  picked(event) {
    if (event.target.closest(".ss-command-item")) this.element.close()
  }

  hover(event) {
    const it = event.target.closest(".ss-command-item")
    if (it && !it.hidden && it.getAttribute("aria-selected") !== "true") this.select(it)
  }

  get items() { return [...this.listTarget.querySelectorAll(".ss-command-item")] }
  get visible() { return this.items.filter((i) => !i.hidden) }

  filter() {
    const q = norm(this.inputTarget.value.trim())
    this.itemTargets.forEach((it) => {
      const ok = !q || norm(`${it.dataset.text} ${it.dataset.keywords || ""}`).includes(q)
      it.hidden = !ok
      this.mark(it, q)
    })
    this.groupTargets.forEach((g) => { g.hidden = !g.querySelector(".ss-command-item:not([hidden])") })
    if (this.srcValue) this.fetchRemote(this.inputTarget.value.trim())
    this.refresh()
  }

  refresh() {
    const vis = this.visible
    this.emptyTarget.hidden = vis.length > 0
    this.select(vis[0])
  }

  // Destaque sem innerHTML (o texto é do app): reconstrói o rótulo em nós de texto + <mark>.
  mark(it, q) {
    const span = it.querySelector("[data-ss-command-label]")
    if (!span) return
    const text = it.dataset.text ?? span.textContent
    if (it.dataset.text == null) it.dataset.text = text
    span.textContent = ""
    // NFD + tirar marcas mantém o comprimento das letras acentuadas compostas (á → a).
    const i = q ? norm(text).indexOf(q) : -1
    if (i < 0) { span.textContent = text; return }
    const m = document.createElement("mark")
    m.textContent = text.slice(i, i + q.length)
    span.append(text.slice(0, i), m, text.slice(i + q.length))
  }

  fetchRemote(q) {
    clearTimeout(this.timer)
    if (!q) { this.remoteTarget.replaceChildren(); return }
    this.timer = setTimeout(async () => {
      this.abort?.abort()
      this.abort = new AbortController()
      const url = new URL(this.srcValue, location.href)
      url.searchParams.set("q", q)
      try {
        const res = await fetch(url, { headers: { Accept: "text/html" }, signal: this.abort.signal })
        if (!res.ok) return
        const doc = new DOMParser().parseFromString(await res.text(), "text/html")
        const found = [...doc.querySelectorAll(".ss-command-item")]
        found.forEach((a, n) => {
          a.id ||= `${this.element.id}-r${n}`
          a.setAttribute("role", "option"); a.tabIndex = -1
          a.dataset.text ??= a.querySelector("[data-ss-command-label]")?.textContent ?? ""
          this.mark(a, norm(q))
        })
        this.remoteTarget.replaceChildren(...found)
        this.remoteTarget.hidden = !found.length
        this.refresh()
      } catch (_) { /* abortada ou sem rede: fica o que já tinha */ }
    }, 160)
  }

  select(it) {
    this.items.forEach((o) => o.setAttribute("aria-selected", String(o === it)))
    if (it) {
      this.inputTarget.setAttribute("aria-activedescendant", it.id)
      it.scrollIntoView({ block: "nearest" })
    } else this.inputTarget.removeAttribute("aria-activedescendant")
  }

  nav(event) {
    const vis = this.visible
    const i = vis.findIndex((o) => o.getAttribute("aria-selected") === "true")
    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      if (!vis.length) return
      const next = event.key === "ArrowDown" ? (i + 1) % vis.length : (i <= 0 ? vis.length - 1 : i - 1)
      this.select(vis[next])
    } else if (event.key === "Enter" && !event.isComposing) {
      const cur = vis[i]
      if (!cur) return
      event.preventDefault()
      cur.click()
    }
  }
}
