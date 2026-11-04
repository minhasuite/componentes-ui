import { Controller } from "@hotwired/stimulus"

// Arrastar e soltar: põe os arquivos no <input type=file>, mostra prévia, tamanho e progresso.
// Com Active Storage (data-direct-upload-url), a barra segue os eventos direct-upload:*.
export default class extends Controller {
  static targets = ["zone", "input", "list"]

  connect() {
    this.onUpload = this.upload.bind(this)
    ;["direct-upload:initialize", "direct-upload:start", "direct-upload:progress", "direct-upload:error", "direct-upload:end"]
      .forEach((t) => this.element.addEventListener(t, this.onUpload))
  }

  disconnect() {
    ;["direct-upload:initialize", "direct-upload:start", "direct-upload:progress", "direct-upload:error", "direct-upload:end"]
      .forEach((t) => this.element.removeEventListener(t, this.onUpload))
    this.urls?.forEach((u) => URL.revokeObjectURL(u))
  }

  over(e) { e.preventDefault(); this.zoneTarget.classList.add("is-over") }
  leave(e) { if (!this.zoneTarget.contains(e.relatedTarget)) this.zoneTarget.classList.remove("is-over") }

  drop(e) {
    e.preventDefault()
    this.zoneTarget.classList.remove("is-over")
    const dt = new DataTransfer()
    const keep = this.inputTarget.multiple ? [...this.inputTarget.files] : []
    const incoming = [...e.dataTransfer.files].filter((f) => this.accepts(f))
    ;[...keep, ...(this.inputTarget.multiple ? incoming : incoming.slice(0, 1))].forEach((f) => dt.items.add(f))
    this.inputTarget.files = dt.files
    this.inputTarget.dispatchEvent(new Event("change", { bubbles: true }))
  }

  accepts(file) {
    const accept = this.inputTarget.accept
    if (!accept) return true
    return accept.split(",").map((s) => s.trim().toLowerCase()).some((a) =>
      a.startsWith(".") ? file.name.toLowerCase().endsWith(a) : a.endsWith("/*") ? file.type.startsWith(a.slice(0, -1)) : file.type === a)
  }

  render() {
    this.urls?.forEach((u) => URL.revokeObjectURL(u))
    this.urls = []
    this.listTarget.replaceChildren(...[...this.inputTarget.files].map((f, i) => {
      const li = document.createElement("li")
      li.className = "ss-file"
      li.dataset.key = `${f.name}|${f.size}`
      const thumb = document.createElement("span"); thumb.className = "ss-file-thumb"; thumb.setAttribute("aria-hidden", "true")
      if (f.type.startsWith("image/")) {
        const img = document.createElement("img"); const u = URL.createObjectURL(f); this.urls.push(u); img.src = u; img.alt = ""
        thumb.append(img)
      } else thumb.textContent = (f.name.split(".").pop() || "?").slice(0, 4).toUpperCase()
      const main = document.createElement("span"); main.className = "ss-file-main"
      const name = document.createElement("b"); name.textContent = f.name
      const size = document.createElement("small"); size.className = "num"; size.textContent = this.size(f.size)
      const bar = document.createElement("span"); bar.className = "ss-progress ss-file-progress"
      const fill = document.createElement("span"); fill.className = "ss-progress-bar"; fill.style.width = "0%"; bar.append(fill)
      main.append(name, size, bar)
      const rm = document.createElement("button")
      rm.type = "button"; rm.className = "ss-file-remove"; rm.textContent = "×"; rm.setAttribute("aria-label", `Remover ${f.name}`)
      rm.addEventListener("click", () => this.remove(i))
      li.append(thumb, main, rm)
      return li
    }))
    this.dispatch("change", { detail: { files: [...this.inputTarget.files] } })
  }

  remove(index) {
    const dt = new DataTransfer()
    ;[...this.inputTarget.files].forEach((f, i) => { if (i !== index) dt.items.add(f) })
    this.inputTarget.files = dt.files
    this.render()
  }

  // Eventos do Active Storage: detail = { id, file, progress, error }.
  upload(e) {
    const { file, progress, error } = e.detail || {}
    if (!file) return
    const li = this.listTarget.querySelector(`[data-key="${CSS.escape(`${file.name}|${file.size}`)}"]`)
    if (!li) return
    const bar = li.querySelector(".ss-progress-bar")
    if (e.type === "direct-upload:start") li.classList.add("is-uploading")
    if (e.type === "direct-upload:progress") bar.style.width = `${progress}%`
    if (e.type === "direct-upload:error") { e.preventDefault(); li.classList.add("is-error"); li.querySelector("small").textContent = error }
    if (e.type === "direct-upload:end") { bar.style.width = "100%"; li.classList.remove("is-uploading"); li.classList.add("is-done") }
  }

  size(b) {
    if (b < 1024) return `${b} B`
    if (b < 1048576) return `${(b / 1024).toFixed(0)} KB`
    return `${(b / 1048576).toFixed(1).replace(".", ",")} MB`
  }
}
