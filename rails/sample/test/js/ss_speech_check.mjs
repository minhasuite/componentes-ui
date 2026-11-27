// v1.13.0: o ssParseAmount do ss_speech.js (o microfone do Ss::MoneyInputComponent(voice: true)) contra os casos de
// docs/v1130/fala.json, os mesmos do Ruby e do Dart, e o ssHandoffEncode contra docs/v1130/handoff.json. Roda com
// node (o v1_13_0_web_test.rb chama quando há node no PATH):  node rails/sample/test/js/ss_speech_check.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import { ssParseAmount, ssHandoffEncode } from "../../../app/javascript/componentes_ui/controllers/ss_speech.js"

const here = dirname(fileURLToPath(import.meta.url))
const docs = join(here, "../../../../docs/v1130")
const { casos } = JSON.parse(readFileSync(join(docs, "fala.json"), "utf8"))
const handoff = JSON.parse(readFileSync(join(docs, "handoff.json"), "utf8"))
let erros = 0
for (const [texto, esperado] of casos) {
  const r = ssParseAmount(texto)
  if (r !== esperado) { erros++; console.log("DIFERE:", JSON.stringify(texto), "js", r, "esperado", esperado) }
}
if (ssHandoffEncode(handoff.state) !== handoff.encoded) { erros++; console.log("handoff difere:", ssHandoffEncode(handoff.state)) }
console.log(`${casos.length} casos, ${erros} erros`)
process.exit(erros ? 1 : 0)
