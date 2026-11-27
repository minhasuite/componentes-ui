// v1.12.0: o ssDetect do ss_br.js (o retorno ao vivo do Ss::SmartPasteComponent e dos campos do Kit Brasil) contra
// os exemplos de docs/v1120/exemplos.json, os mesmos do Ruby e do Dart. Roda com node (o v1_12_0_web_test.rb chama
// quando há node no PATH):  node rails/sample/test/js/ss_br_check.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { dirname, join } from "node:path"
import * as br from "../../../app/javascript/componentes_ui/controllers/ss_br.js"

const here = dirname(fileURLToPath(import.meta.url))
const { today, exemplos } = JSON.parse(readFileSync(join(here, "../../../../docs/v1120/exemplos.json"), "utf8"))
const sorted = (o) => JSON.stringify(Object.keys(o).sort().reduce((a, k) => ((a[k] = o[k]), a), {}))
let erros = 0
for (const e of exemplos) {
  const r = br.ssDetect(e.input, today)
  const got = { type: r.type, valid: r.valid, value: r.value, also: r.also, fields: sorted(r.fields) }
  const want = { type: e.type, valid: e.valid, value: e.value, also: e.also, fields: sorted(e.fields) }
  if (JSON.stringify(got) !== JSON.stringify(want)) {
    erros++
    console.log("DIFERE:", JSON.stringify(e.input).slice(0, 60), "\n  js  ", JSON.stringify(got), "\n  ruby", JSON.stringify(want))
  }
}
// Formatadores e contas soltas.
const casos = [
  [br.ssFormatCpf("60472138553"), "604.721.385-53"],
  [br.ssFormatCnpj("12abc34501de35"), "12.ABC.345/01DE-35"],
  [br.ssFormatCep("01310100"), "01310-100"],
  [br.ssFormatPhone("5511987654321"), "+55 (11) 98765-4321"],
  [br.ssFormatPhone("2134567890"), "(21) 3456-7890"],
  [br.ssFormatNfeKey("1".repeat(44)).split(" ").length, 11],
  [br.ssPixKeyType("+55 11 98765-4321"), "phone"],
  [br.ssPixKeyType("60472138553"), "cpf"],
  [br.ssPixKeyType("x@y.com"), "email"],
  [br.ssPixKeyType("abc"), null],
  [br.ssCrc16("123456789"), "29B1"],
]
casos.forEach(([a, b], i) => { if (a !== b) { erros++; console.log("caso", i, JSON.stringify(a), "!=", JSON.stringify(b)) } })
console.log(`${exemplos.length} exemplos, ${casos.length} casos, ${erros} erros`)
process.exit(erros ? 1 : 0)
