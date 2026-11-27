// v1.12.0 "Kit Brasil": as contas brasileiras no navegador, para o retorno ao vivo (o mesmo que o
// ComponentesUi::Br e o ComponentesUi::PasteDetector do Ruby e o SsBr/SsPasteDetector do Flutter; os exemplos de
// docs/v1120/exemplos.json passam nos três). Puro: nada de DOM nem de rede.
//   import { ssDetect, ssBoleto, ssPixKeyType } from "componentes_ui/controllers/ss_br"

const DDDS = new Set("11 12 13 14 15 16 17 18 19 21 22 24 27 28 31 32 33 34 35 37 38 41 42 43 44 45 46 47 48 49 51 53 54 55 61 62 63 64 65 66 67 68 69 71 73 74 75 77 79 81 82 83 84 85 86 87 88 89 91 92 93 94 95 96 97 98 99".split(" "))
const UFS = { 11: "RO", 12: "AC", 13: "AM", 14: "RR", 15: "PA", 16: "AP", 17: "TO", 21: "MA", 22: "PI", 23: "CE", 24: "RN", 25: "PB", 26: "PE", 27: "AL", 28: "SE", 29: "BA", 31: "MG", 32: "ES", 33: "RJ", 35: "SP", 41: "PR", 42: "SC", 43: "RS", 50: "MS", 51: "MT", 52: "GO", 53: "DF" }
const MODELS = { 55: "NF-e", 65: "NFC-e", 57: "CT-e", 58: "MDF-e", 59: "CF-e SAT", 67: "CT-e OS" }
const SEGMENTS = { 1: "prefeitura", 2: "saneamento", 3: "energia", 4: "telecom", 5: "governo", 6: "carne", 7: "transito", 9: "banco" }
const EMAIL = /^[^@\s]+@[^@\s]+\.[^@\s.]{2,}$/
const EVP = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i

export const ssDigits = (t) => String(t ?? "").replace(/\D/g, "")
export const ssAlnum = (t) => String(t ?? "").toUpperCase().replace(/[^0-9A-Z]/g, "")

// ── CPF e CNPJ ──────────────────────────────────────────────────────
export function ssCpfValid(t) {
  const d = ssDigits(t)
  if (d.length !== 11 || /^(\d)\1{10}$/.test(d)) return false
  const dv = (n) => { let s = 0; for (let i = 0; i < n; i++) s += +d[i] * (n + 1 - i); const r = s % 11; return r < 2 ? 0 : 11 - r }
  return dv(9) === +d[9] && dv(10) === +d[10]
}

export function ssCnpjDv(base12) {
  const calc = (vals) => {
    let s = 0
    for (let i = 0; i < vals.length; i++) s += vals[vals.length - 1 - i] * (2 + (i % 8))
    const r = s % 11
    return r < 2 ? 0 : 11 - r
  }
  const v = [...base12].map((c) => c.charCodeAt(0) - 48)
  const d1 = calc(v)
  return `${d1}${calc([...v, d1])}`
}

export function ssCnpjValid(t) {
  const s = ssAlnum(t)
  if (!/^[0-9A-Z]{12}\d{2}$/.test(s) || /^(.)\1{13}$/.test(s)) return false
  return ssCnpjDv(s.slice(0, 12)) === s.slice(12)
}

export function ssDocumentKind(t) {
  const s = ssAlnum(t)
  if (!s) return null
  return s.length > 11 || /[A-Z]/.test(s) ? "cnpj" : "cpf"
}

export const ssDocumentValid = (t) => (ssDocumentKind(t) === "cnpj" ? ssCnpjValid(t) : ssCpfValid(t))

// ── Formatadores ────────────────────────────────────────────────────
const join = (raw, cuts, seps) => [...raw].map((ch, i) => (cuts.includes(i) ? seps[cuts.indexOf(i)] : "") + ch).join("")
export const ssFormatCpf = (t) => join(ssDigits(t).slice(0, 11), [3, 6, 9], [".", ".", "-"])
export function ssFormatCnpj(t) {
  let s = ssAlnum(t).slice(0, 14)
  s = s.slice(0, 12) + s.slice(12).replace(/\D/g, "")
  return join(s, [2, 5, 8, 12], [".", ".", "/", "-"])
}
export const ssFormatDocument = (t) => (ssDocumentKind(t) === "cnpj" ? ssFormatCnpj(t) : ssFormatCpf(t))
export const ssFormatCep = (t) => join(ssDigits(t).slice(0, 8), [5], ["-"])
export function ssFormatPhone(t) {
  let raw = ssDigits(t)
  const ddi = raw.length > 11 && raw.startsWith("55")
  if (ddi) raw = raw.slice(2)
  raw = raw.slice(0, 11)
  if (!raw) return ""
  const out = raw.length <= 2 ? `(${raw}` : `(${raw.slice(0, 2)}) ${join(raw.slice(2), [raw.length <= 10 ? 4 : 5], ["-"])}`
  return ddi ? `+55 ${out}` : out
}
export function ssFormatBoleto(t) {
  let d = ssDigits(t)
  if (d.length === 44) d = ssBoletoLineFromBarcode(d) || d
  if (d.startsWith("8")) return (d.slice(0, 48).match(/.{1,12}/g) || []).map((b) => (b.length === 12 ? `${b.slice(0, 11)}-${b[11]}` : b)).join(" ")
  return join(d.slice(0, 47), [5, 10, 15, 21, 26, 32, 33], [".", " ", ".", " ", ".", " ", " "])
}
export const ssFormatNfeKey = (t) => (ssDigits(t).slice(0, 44).match(/.{1,4}/g) || []).join(" ")

// ── CEP, telefone, e-mail e chave Pix ───────────────────────────────
export const ssCepValid = (t) => { const d = ssDigits(t); return d.length === 8 && d !== "00000000" }

export function ssPhoneNational(t) {
  const raw = String(t ?? "").trim()
  let d = ssDigits(raw)
  if ((raw.startsWith("+55") || raw.startsWith("55")) && d.length > 11) d = d.slice(2)
  if (d.length === 12 && d.startsWith("0")) d = d.slice(1)
  if (![10, 11].includes(d.length) || !DDDS.has(d.slice(0, 2))) return null
  if (d.length === 11 && d[2] !== "9") return null
  if (d.length === 10 && !/[2-5]/.test(d[2])) return null
  return d
}
export const ssPhoneValid = (t) => ssPhoneNational(t) !== null
export const ssPhoneE164 = (t) => { const n = ssPhoneNational(t); return n && `+55${n}` }
export const ssEmailValid = (t) => EMAIL.test(String(t ?? "").trim())
export const ssEvpValid = (t) => EVP.test(String(t ?? "").trim())

export function ssPixKeyType(text) {
  const t = String(text ?? "").trim()
  if (!t) return null
  if (t.includes("@")) return "email"
  if (EVP.test(t)) return "random"
  if (t.startsWith("+")) return ssPhoneValid(t) ? "phone" : null
  if (/[^\d.\-/\s()A-Za-z]/.test(t)) return null
  const a = ssAlnum(t)
  const d = ssDigits(t)
  if (/[A-Za-z]/.test(t)) return ssCnpjValid(t) ? "cnpj" : null
  if (d.length === 11 && ssCpfValid(d)) return "cpf"
  if (d.length === 14 && ssCnpjValid(d)) return "cnpj"
  if (ssPhoneValid(t) && a === d) return "phone"
  return null
}

export function ssPixKeyNormalize(text, type = ssPixKeyType(text)) {
  switch (type) {
    case "cpf": return ssDigits(text)
    case "cnpj": return ssAlnum(text)
    case "phone": return ssPhoneE164(text)
    case "email": case "random": return String(text).trim().toLowerCase()
    default: return null
  }
}

export function ssPixKeyDisplay(text, type = ssPixKeyType(text)) {
  switch (type) {
    case "cpf": return ssFormatCpf(text)
    case "cnpj": return ssFormatCnpj(text)
    case "phone": return ssFormatPhone(ssPhoneE164(text))
    default: return String(text ?? "").trim()
  }
}

// ── Módulos 10 e 11 ─────────────────────────────────────────────────
export function ssMod10(num) {
  let s = 0
  for (let i = 0; i < num.length; i++) {
    let p = +num[num.length - 1 - i] * (i % 2 === 0 ? 2 : 1)
    if (p > 9) p -= 9
    s += p
  }
  return (10 - (s % 10)) % 10
}
const mod11Sum = (num) => { let s = 0; for (let i = 0; i < num.length; i++) s += +num[num.length - 1 - i] * (2 + (i % 8)); return s }
export function ssMod11Bank(num) { const dv = 11 - (mod11Sum(num) % 11); return [0, 10, 11].includes(dv) ? 1 : dv }
export function ssMod11Dv(num) { const r = mod11Sum(num) % 11; return r < 2 ? 0 : 11 - r }

// ── Boleto ──────────────────────────────────────────────────────────
const DAY = 86400000
const utc = (y, m, d) => Date.UTC(y, m - 1, d)
const BASE_OLD = utc(1997, 10, 7)
const BASE_NEW = utc(2025, 2, 22)
const iso = (ms) => new Date(ms).toISOString().slice(0, 10)
const todayUtc = () => { const n = new Date(); return utc(n.getFullYear(), n.getMonth() + 1, n.getDate()) }
const parseIso = (s) => { const [y, m, d] = s.split("-").map(Number); return utc(y, m, d) }

export function ssBoletoDue(fator, today = todayUtc()) {
  const f = parseInt(fator, 10)
  if (!f) return null
  const old = BASE_OLD + f * DAY
  if (f < 1000) return iso(old)
  const novo = BASE_NEW + (f - 1000) * DAY
  return iso(Math.abs(novo - today) < Math.abs(old - today) ? novo : old)
}

export function ssBoletoLineFromBarcode(code) {
  const c = ssDigits(code)
  if (c.length !== 44) return null
  if (c.startsWith("8")) {
    const m = "67".includes(c[2]) ? ssMod10 : ssMod11Dv
    return c.match(/.{11}/g).map((b) => b + m(b)).join("")
  }
  const f1 = c.slice(0, 4) + c.slice(19, 24)
  const f2 = c.slice(24, 34)
  const f3 = c.slice(34, 44)
  return `${f1}${ssMod10(f1)}${f2}${ssMod10(f2)}${f3}${ssMod10(f3)}${c[4]}${c.slice(5, 19)}`
}

// → { kind: "bank"|"collection", line, barcode, valid, amountCents, dueDate ("aaaa-mm-dd"), bank, segment, errors } ou null.
export function ssBoleto(text, today = todayUtc()) {
  let d = ssDigits(text)
  if (d.length === 44) d = ssBoletoLineFromBarcode(d)
  if (!d) return null
  if (typeof today === "string") today = parseIso(today)
  if (d.length === 48 && d.startsWith("8")) {
    const errors = []
    const blocks = d.match(/.{12}/g)
    const barcode = blocks.map((b) => b.slice(0, 11)).join("")
    const m = "67".includes(barcode[2]) ? ssMod10 : ssMod11Dv
    if (!"6789".includes(barcode[2])) errors.push("value_id")
    if (!blocks.every((b) => String(m(b.slice(0, 11))) === b[11])) errors.push("field_dv")
    if (String(m(barcode.slice(0, 3) + barcode.slice(4))) !== barcode[3]) errors.push("general_dv")
    const valor = "68".includes(barcode[2]) ? parseInt(barcode.slice(4, 15), 10) : 0
    return { kind: "collection", line: d, barcode, valid: errors.length === 0, amountCents: valor || null, dueDate: null, bank: null, segment: SEGMENTS[barcode[1]] || null, errors }
  }
  if (d.length !== 47) return null
  const errors = []
  const fields = [[d.slice(0, 9), d[9]], [d.slice(10, 20), d[20]], [d.slice(21, 31), d[31]]]
  if (!fields.every(([f, dv]) => String(ssMod10(f)) === dv)) errors.push("field_dv")
  const barcode = d.slice(0, 4) + d[32] + d.slice(33, 47) + d.slice(4, 9) + d.slice(10, 20) + d.slice(21, 31)
  if (String(ssMod11Bank(barcode.slice(0, 4) + barcode.slice(5))) !== barcode[4]) errors.push("general_dv")
  const valor = parseInt(d.slice(37, 47), 10)
  return { kind: "bank", line: d, barcode, valid: errors.length === 0, amountCents: valor || null, dueDate: ssBoletoDue(d.slice(33, 37), today), bank: d.slice(0, 3), segment: null, errors }
}

// ── Chave de acesso ─────────────────────────────────────────────────
export function ssNfeKey(text) {
  const k = ssDigits(text)
  if (k.length !== 44) return null
  const uf = UFS[k.slice(0, 2)] || null
  const mes = parseInt(k.slice(4, 6), 10)
  const model = k.slice(20, 22)
  const valid = !!uf && mes >= 1 && mes <= 12 && String(ssMod11Dv(k.slice(0, 43))) === k[43] && !!MODELS[model]
  return { key: k, valid, uf, ufCode: k.slice(0, 2), year: 2000 + parseInt(k.slice(2, 4), 10), month: mes, cnpj: k.slice(6, 20), model, modelName: MODELS[model] || null, series: parseInt(k.slice(22, 25), 10), number: parseInt(k.slice(25, 34), 10), emission: k[34], code: k.slice(35, 43), dv: k[43] }
}

// ── Pix copia e cola (BR Code) ──────────────────────────────────────
export function ssCrc16(text) {
  let crc = 0xffff
  for (const b of new TextEncoder().encode(text)) {
    crc ^= b << 8
    for (let i = 0; i < 8; i++) crc = (crc & 0x8000 ? (crc << 1) ^ 0x1021 : crc << 1) & 0xffff
  }
  return crc.toString(16).toUpperCase().padStart(4, "0")
}

function emvFields(text) {
  const out = {}
  let i = 0
  while (i < text.length) {
    const id = text.slice(i, i + 2)
    const len = text.slice(i + 2, i + 4)
    if (!/^\d\d$/.test(id) || !/^\d\d$/.test(len)) return null
    const v = text.slice(i + 4, i + 4 + +len)
    if (v.length !== +len) return null
    out[id] = v
    i += 4 + +len
  }
  return out
}

export function ssAmountCents(text) {
  const m = String(text ?? "").trim().match(/^(\d+)(?:\.(\d{1,2}))?$/)
  return m ? parseInt(m[1], 10) * 100 + parseInt((m[2] || "").padEnd(2, "0"), 10) : null
}

export function ssPixCode(text) {
  const t = String(text ?? "").trim().replace(/[\r\n]/g, "")
  if (!t.startsWith("000201") || !t.toLowerCase().includes("br.gov.bcb.pix")) return null
  const f = emvFields(t)
  if (!f) return { payload: t, valid: false, errors: ["format"], dynamic: false }
  const mai = emvFields(f["26"] || "") || {}
  const extra = emvFields(f["62"] || "") || {}
  const errors = []
  if ((f["63"] || "").toUpperCase() !== ssCrc16(t.slice(0, -4))) errors.push("crc")
  const key = mai["01"] ?? null
  if (key === null && mai["25"] === undefined) errors.push("key")
  return { payload: t, valid: errors.length === 0, key, keyType: key && ssPixKeyType(key), name: f["59"] ?? null, city: f["60"] ?? null, amountCents: f["54"] ? ssAmountCents(f["54"]) : null, txid: extra["05"] ?? null, description: mai["02"] ?? null, url: mai["25"] ?? null, dynamic: f["01"] === "12" || mai["25"] !== undefined, errors }
}

// ── O que foi colado (ssDetect) ─────────────────────────────────────
const URL_RE = /^https?:\/\/[^\s/$.?#][^\s]*$/i
const DOMAIN = /^(?:www\.)?[a-z0-9](?:[a-z0-9-]*[a-z0-9])?(?:\.[a-z0-9](?:[a-z0-9-]*[a-z0-9])?)*\.[a-z]{2,}(?:\/\S*)?$/i
const DATE_BR = /^(\d{1,2})\/(\d{1,2})(?:\/(\d{2}|\d{4}))?$/
const DATE_ISO = /^(\d{4})-(\d{2})-(\d{2})$/
const NUMERIC = /^[\d\s.\-/()]+$/
const MONEY = /^(-)?\s*(R\$\s*)?(-)?(\d{1,3}(?:\.\d{3})+|\d+)(?:,(\d{1,2}))?$/i
const CEP = /^\d{2}\.?\d{3}-?\d{3}$/
const CNPJ_ALNUM = /^[0-9A-Z]{2}\.?[0-9A-Z]{3}\.?[0-9A-Z]{3}\/?[0-9A-Z]{4}-?\d{2}$/i

const match = (type, text, value, valid, fields = {}, also = []) => ({ type, text, value, valid, fields, also })
const compact = (o) => Object.fromEntries(Object.entries(o).filter(([, v]) => v !== null && v !== undefined))

function nfeMatch(t, k, url) {
  const f = { uf: k.uf, model: k.model, model_name: k.modelName, cnpj: k.cnpj, series: k.series, number: k.number, year: k.year, month: k.month }
  if (url) f.url = url
  return match("nfe", t, k.key, k.valid, f)
}
function boletoMatch(t, b) {
  if (!b) return null
  return match("boleto", t, b.line, b.valid, { kind: b.kind, amount_cents: b.amountCents, due_date: b.dueDate, bank: b.bank, segment: b.segment, barcode: b.barcode, display: ssFormatBoleto(b.line) })
}
function doc(type, t, raw) {
  const ok = type === "cpf" ? ssCpfValid(raw) : ssCnpjValid(raw)
  return match(type, t, raw, ok, { display: type === "cpf" ? ssFormatCpf(raw) : ssFormatCnpj(raw) }, ok ? ["pix_key"] : [])
}
function phone(t, valid = true) {
  const e = ssPhoneE164(t)
  if (!e || !valid) return match("phone", t, ssDigits(t), false, { display: t })
  return match("phone", t, e, true, { display: ssFormatPhone(e) }, ["pix_key"])
}
function validDate(y, m, d) { const x = new Date(Date.UTC(y, m - 1, d)); return x.getUTCFullYear() === y && x.getUTCMonth() === m - 1 && x.getUTCDate() === d }

// ssDetect(texto, hoje?) → { type, text, value, valid, fields, also } ou null (vazio). hoje: "aaaa-mm-dd" (padrão: hoje).
export function ssDetect(text, today = null) {
  const t = String(text ?? "").replace(/\r\n?/g, "\n").trim()
  if (!t) return null
  const todayMs = today ? parseIso(today) : todayUtc()
  const s = t.replace(/\s+/g, " ")
  const r = detectPix(t) || detectUrl(s) || detectDate(s, todayMs) || detectNumeric(s, todayMs) || detectPlus(s) || detectEmail(s) ||
    (ssEvpValid(s) ? match("pix_key", s, s.toLowerCase(), true, { key_type: "random" }) : null) ||
    (CNPJ_ALNUM.test(s) && /[A-Za-z]/.test(s) ? doc("cnpj", s, ssAlnum(s)) : null) || detectMoney(s) || detectDomain(s) ||
    match("text", t, t, true, { length: [...t].length, lines: t.split("\n").length })
  r.fields = compact(r.fields)
  return r
}

function detectPix(t) {
  const p = ssPixCode(t.replace(/\n/g, ""))
  if (!p) return null
  return match("pix", t, p.payload, p.valid, { amount_cents: p.amountCents, name: p.name, city: p.city, key: p.key, key_type: p.keyType, txid: p.txid, dynamic: p.dynamic })
}
function detectUrl(t) {
  if (!URL_RE.test(t)) return null
  const key = (t.match(/\d{44}/g) || []).find((k) => ssNfeKey(k)?.valid)
  if (key) return nfeMatch(t, ssNfeKey(key), t)
  const host = t.replace(/^https?:\/\//i, "").split(/[/?#:]/)[0].toLowerCase().replace(/^www\./, "")
  return match("url", t, t, true, { domain: host })
}
function detectDate(t, today) {
  let y, m, d, x
  if ((x = t.match(DATE_BR))) {
    d = +x[1]; m = +x[2]
    y = x[3] ? +x[3] : new Date(today).getUTCFullYear()
    if (x[3] && x[3].length === 2) y += 2000
  } else if ((x = t.match(DATE_ISO))) {
    y = +x[1]; m = +x[2]; d = +x[3]
  } else return null
  if (!validDate(y, m, d)) return null
  const v = iso(utc(y, m, d))
  return match("date", t, v, true, { date: v })
}
function detectNumeric(t, today) {
  if (!NUMERIC.test(t)) return null
  const d = ssDigits(t)
  switch (d.length) {
    case 47: case 48:
      return d.length === 47 || d.startsWith("8") ? boletoMatch(t, ssBoleto(d, today)) : null
    case 44: {
      const k = ssNfeKey(d)
      const b = ssBoleto(d, today)
      if (k.valid) return nfeMatch(t, k)
      if (b?.valid) return boletoMatch(t, b)
      if (d.startsWith("8") && b) return boletoMatch(t, b)
      return nfeMatch(t, k)
    }
    case 14: return doc("cnpj", t, d)
    case 11:
      if (ssCpfValid(d)) return doc("cpf", t, d)
      if (ssPhoneValid(d)) return phone(t)
      if (t.includes("(")) return phone(t, false)
      return doc("cpf", t, d)
    case 10: case 12: case 13:
      return ssPhoneValid(t) || t.includes("(") ? phone(t, ssPhoneValid(t)) : null
    case 8: return CEP.test(t) ? match("cep", t, d, ssCepValid(d), { display: ssFormatCep(d) }) : null
    default: return null
  }
}
function detectPlus(t) {
  if (!t.startsWith("+") || !/^[\d\s\-()]+$/.test(t.slice(1))) return null
  return ssPhoneValid(t) ? phone(t) : match("phone", t, ssDigits(t), false, { display: t })
}
function detectEmail(t) {
  if (!/^[^@\s]+@[^@\s]+$/.test(t)) return null
  const ok = ssEmailValid(t)
  return match("email", t, t.toLowerCase(), ok, {}, ok ? ["pix_key"] : [])
}
function detectMoney(t) {
  const x = t.match(MONEY)
  if (!x || !(x[2] || x[5])) return null
  let cents = parseInt(ssDigits(x[4]), 10) * 100 + parseInt((x[5] || "").padEnd(2, "0"), 10)
  if (x[1] || x[3]) cents = -cents
  return match("money", t, String(cents), true, { amount_cents: cents })
}
function detectDomain(t) {
  if (!DOMAIN.test(t) || /^[\d.]+$/.test(t)) return null
  const host = t.split("/")[0].toLowerCase().replace(/^www\./, "")
  return match("url", t, `https://${t}`, true, { domain: host })
}
