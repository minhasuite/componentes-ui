import { Controller } from "@hotwired/stimulus"

// v1.9 · mapa de vibração do web, o par do SsHaptics do Flutter (mesmos nomes):
//   selection  chave, segmentado, rádio            8 ms
//   limit      slider que chega no mínimo/máximo    14 ms
//   success    confirmação                          10, 60, 10
//   warning    confirmação perigosa, remoção        24 ms
//   error      aviso de erro (.ss-toast.is-bad)     30, 50, 30
// Usa navigator.vibrate, que é opcional: onde não existe (iOS, a maioria dos desktops) não faz nada.
// Desligado por padrão em desktop: só vibra com ponteiro de toque (pointer: coarse). O app força com
// <html data-ss-haptics="on"> ou desliga tudo com data-ss-haptics="off" (preferência "Vibração").
//
// Os controllers da gem chamam: import { haptic } from "componentes_ui/controllers/ss_haptics_controller"
// e este módulo liga sozinho a vibração de seleção na troca da chave e do rádio (change delegado no
// document). Com carregamento preguiçoso, ponha data-controller="ss-haptics" no <body>.
export const PATTERNS = { selection: 8, limit: 14, success: [10, 60, 10], warning: 24, error: [30, 50, 30] }

export function hapticsOn() {
  const pref = document.documentElement.dataset.ssHaptics
  if (pref === "off" || typeof navigator.vibrate !== "function") return false
  if (pref === "on") return true
  return matchMedia("(pointer: coarse)").matches
}

// Vibra o padrão do nome; devolve se pediu ao aparelho.
export function haptic(kind) {
  const p = PATTERNS[kind]
  if (p == null || !hapticsOn()) return false
  try { return navigator.vibrate(p) } catch { return false }
}

const SELECTION = '.ss-switch-row input, .ss-switch input, :is(.ss-check, .ss-option-card, .ss-seg) input:is([type="checkbox"], [type="radio"])'

function onChange(e) {
  if (e.target instanceof HTMLInputElement && e.target.matches(SELECTION)) haptic("selection")
}

// Segmentado de botões (Ss::SegmentedComponent sem href): o clique num item não escolhido.
function onClick(e) {
  const item = e.target.closest?.(".ss-seg > button")
  if (item && !item.disabled && item.getAttribute("aria-pressed") !== "true" && item.getAttribute("aria-selected") !== "true") haptic("selection")
}

if (!globalThis.__ssHapticsOn) {
  globalThis.__ssHapticsOn = true
  document.addEventListener("change", onChange, true)
  document.addEventListener("click", onClick, true)
}

// O módulo já liga tudo; o controller existe para o carregamento preguiçoso e para data-action:
//   data-action="click->ss-haptics#play" data-ss-haptics-kind-param="success"
export default class extends Controller {
  play({ params }) { haptic(params.kind || "selection") }
}
