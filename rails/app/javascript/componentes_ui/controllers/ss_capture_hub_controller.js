import { Controller } from "@hotwired/stimulus"

// Ss::CaptureHubComponent (v1.9): as opções câmera/galeria/arquivo abrem o seletor do envio (a câmera com
// capture="environment") e enviam ao escolher; "Colar texto" abre o campo; Ctrl+V em qualquer ponto manda o
// arquivo colado (print) para o envio e o texto para o campo de colar.
export default class extends Controller {
  static targets = ["uploadForm", "drop", "pasteForm", "text"]

  input() { return this.hasUploadFormTarget ? this.uploadFormTarget.querySelector("input[type=file]") : null }

  choose({ params: { kind } }) {
    const input = this.input()
    if (!input) return
    if (this.accept === undefined) this.accept = input.getAttribute("accept")
    if (kind === "camera" || kind === "gallery") input.setAttribute("accept", "image/*")
    else if (this.accept) input.setAttribute("accept", this.accept)
    else input.removeAttribute("accept")
    if (kind === "camera") input.setAttribute("capture", "environment")
    else input.removeAttribute("capture")
    const once = () => { input.removeEventListener("change", once); if (input.files.length) this.uploadFormTarget.requestSubmit() }
    input.addEventListener("change", once)
    input.click()
  }

  showPaste() {
    if (!this.hasPasteFormTarget) return
    this.pasteFormTarget.hidden = false
    this.textTarget.focus()
  }

  hidePaste() {
    if (!this.hasPasteFormTarget) return
    this.pasteFormTarget.hidden = true
  }

  paste(e) {
    const data = e.clipboardData
    if (!data) return
    const files = [...data.files]
    const input = this.input()
    if (files.length && input) {
      e.preventDefault()
      const dt = new DataTransfer()
      ;(input.multiple ? files : files.slice(0, 1)).forEach((f) => dt.items.add(f))
      input.files = dt.files
      input.dispatchEvent(new Event("change", { bubbles: true }))
      return
    }
    const text = data.getData("text/plain")
    // Colando dentro do próprio campo, o navegador cuida.
    if (!text || !this.hasPasteFormTarget || e.target === this.textTarget) return
    e.preventDefault()
    this.showPaste()
    this.textTarget.value = text
  }
}
