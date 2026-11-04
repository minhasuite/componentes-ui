import { Controller } from "@hotwired/stimulus"
import { ssFormat, ssLang } from "componentes_ui/controllers/ss_intl"

// Combobox: busca no servidor (url, GET ?q=, JSON ou HTML) ou local (options = JSON [{id,label,hint}]).
// Teclado: ↑ ↓ movem, Enter escolhe, Esc fecha. aria-activedescendant aponta a opção ativa.
export default class extends Controller {
  static targets = ["input", "list", "hidden", "created"]
  static values = { url: String, options: Array, create: Boolean, debounce: { type: Number, default: 250 }, min: { type: Number, default: 1 },
                    // Textos vindos do componente (I18n do Rails); %{q} = o que foi digitado.
                    createLabel: { type: String, default: "Criar “%{q}”" }, emptyLabel: { type: String, default: "Nada encontrado" },
                    hintLabel: { type: String, default: "Digite para buscar" } }

  connect() { this.active = -1; this.seq = 0; if (this.hiddenTarget.value) this.chosen = this.inputTarget.value.trim() }
  disconnect() { clearTimeout(this.timer); this.abort?.abort() }

  search() {
    clearTimeout(this.timer)
    const q = this.inputTarget.value.trim()
    if (this.hiddenTarget.value && q !== this.chosen) this.setValue("", "")
    if (q.length < this.minValue) { if (!this.optionsValue.length || q.length) return this.close(); }
    if (this.urlValue) this.timer = setTimeout(() => this.remote(q), this.debounceValue)
    else this.renderItems(this.localMatch(q), q)
  }

  localMatch(q) {
    const f = (s) => (s || "").toString().normalize("NFD").replace(/[̀-ͯ]/g, "").toLowerCase()
    const n = f(q)
    return this.optionsValue.filter((o) => f(o.label).includes(n) || f(o.hint).includes(n)).slice(0, 50)
  }

  async remote(q) {
    this.abort?.abort()
    this.abort = new AbortController()
    const seq = ++this.seq
    const url = new URL(this.urlValue, location.href)
    url.searchParams.set("q", q)
    this.inputTarget.setAttribute("aria-busy", "true")
    try {
      const res = await fetch(url, { headers: { Accept: "application/json, text/html" }, signal: this.abort.signal })
      if (seq !== this.seq) return
      const type = res.headers.get("content-type") || ""
      if (type.includes("json")) this.renderItems(await res.json(), q)
      else { this.listTarget.innerHTML = await res.text(); this.decorate(q) }
    } catch (e) {
      if (e.name !== "AbortError") this.renderItems([], q)
    } finally { this.inputTarget.removeAttribute("aria-busy") }
  }

  renderItems(items, q) {
    this.listTarget.replaceChildren(...items.map((o) => {
      const li = document.createElement("li")
      li.setAttribute("role", "option")
      li.dataset.value = o.id ?? o.value ?? ""
      li.dataset.label = o.label
      li.append(this.highlight(o.label, q))
      if (o.hint) { const s = document.createElement("small"); s.textContent = o.hint; li.append(s) }
      return li
    }))
    this.decorate(q)
  }

  // Ids, "Criar ‘x’" e vazio, valem para lista local, JSON ou HTML do servidor.
  decorate(q) {
    const base = this.inputTarget.id
    let opts = [...this.listTarget.querySelectorAll('[role="option"]')]
    if (this.createValue && q && !opts.some((o) => (o.dataset.label || "").toLocaleLowerCase(ssLang()) === q.toLocaleLowerCase(ssLang()))) {
      const li = document.createElement("li")
      li.setAttribute("role", "option"); li.dataset.create = q; li.className = "is-create"
      li.textContent = ssFormat(this.createLabelValue, { q })
      this.listTarget.append(li)
      opts = [...opts, li]
    }
    if (!opts.length) {
      const li = document.createElement("li"); li.className = "ss-combobox-empty"; li.textContent = q ? this.emptyLabelValue : this.hintLabelValue
      this.listTarget.append(li)
    }
    opts.forEach((o, i) => { o.id = `${base}-opt-${i}`; o.setAttribute("aria-selected", "false") })
    this.active = -1
    this.open()
    if (opts.length) this.move(0)
  }

  highlight(text, q) {
    const frag = document.createDocumentFragment()
    const span = document.createElement("span")
    const i = q ? text.toLowerCase().indexOf(q.toLowerCase()) : -1
    if (i < 0) { span.textContent = text; frag.append(span); return frag }
    const mark = document.createElement("mark"); mark.textContent = text.slice(i, i + q.length)
    span.append(text.slice(0, i), mark, text.slice(i + q.length))
    frag.append(span)
    return frag
  }

  get options() { return [...this.listTarget.querySelectorAll('[role="option"]')] }

  key(e) {
    const opts = this.options
    if (e.key === "ArrowDown") { e.preventDefault(); if (this.listTarget.hidden) return this.search(); this.move(Math.min(this.active + 1, opts.length - 1)) }
    else if (e.key === "ArrowUp") { e.preventDefault(); this.move(Math.max(this.active - 1, 0)) }
    else if (e.key === "Enter" && !this.listTarget.hidden && opts[this.active]) { e.preventDefault(); this.choose(opts[this.active]) }
    else if (e.key === "Escape" && !this.listTarget.hidden) { e.preventDefault(); this.close() }
  }

  move(i) {
    const opts = this.options
    opts.forEach((o, n) => o.setAttribute("aria-selected", n === i ? "true" : "false"))
    this.active = i
    const cur = opts[i]
    if (cur) { this.inputTarget.setAttribute("aria-activedescendant", cur.id); cur.scrollIntoView({ block: "nearest" }) }
    else this.inputTarget.removeAttribute("aria-activedescendant")
  }

  hold(e) { e.preventDefault() } // não perde o foco ao clicar na lista
  pick(e) { const li = e.target.closest('[role="option"]'); if (li) this.choose(li) }

  choose(li) {
    if (li.dataset.create !== undefined) {
      const text = li.dataset.create
      this.setValue("", text)
      if (this.hasCreatedTarget) this.createdTarget.value = text
      this.dispatch("create", { detail: { text } })
    } else {
      if (this.hasCreatedTarget) this.createdTarget.value = ""
      this.setValue(li.dataset.value, li.dataset.label || li.textContent.trim())
      this.dispatch("change", { detail: { value: li.dataset.value, label: this.chosen } })
    }
    this.close()
  }

  setValue(id, label) {
    this.hiddenTarget.value = id
    this.chosen = label
    if (label) this.inputTarget.value = label
    this.hiddenTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  open() { this.listTarget.hidden = false; this.inputTarget.setAttribute("aria-expanded", "true") }
  close() {
    this.listTarget.hidden = true
    this.inputTarget.setAttribute("aria-expanded", "false")
    this.inputTarget.removeAttribute("aria-activedescendant")
  }
}
