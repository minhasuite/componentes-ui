// v1.12.0 "Kit Brasil": os textos das peças do Brasil (Pix, boleto, CEP, CPF/CNPJ, NF-e e o colar inteligente).
// As peças são do Brasil: en e es só traduzem a interface (o formato do dado continua o brasileiro). As mesmas
// chaves estão no `componentes_ui.br.*` da gem. O idioma segue o do [SsStrings] do ponto da árvore.
import 'package:material_ui/material_ui.dart';

import '../ss_strings.dart';

/// Textos do Kit Brasil: `SsBrStrings.of(context)` (pt, en ou es pelo idioma do [SsStrings]).
class SsBrStrings {
  const SsBrStrings({
    required this.pixTitle,
    required this.pixCopy,
    required this.pixCopied,
    required this.pixCode,
    required this.pixQr,
    required this.pixHint,
    required this.pixReceiver,
    required this.pixAmount,
    required this.pixAnyAmount,
    required this.pixValidFor,
    required this.pixWaiting,
    required this.pixPaid,
    required this.pixPaidHint,
    required this.pixExpired,
    required this.pixExpiredHint,
    required this.pixRegenerate,
    required this.pixKey,
    required this.pixKeyHint,
    required this.pixKeyInvalid,
    required this.keyTypes,
    required this.boleto,
    required this.boletoHint,
    required this.boletoScan,
    required this.boletoInvalid,
    required this.boletoIncomplete,
    required this.boletoBank,
    required this.boletoCollection,
    required this.boletoDue,
    required this.boletoOverdue,
    required this.boletoNoDue,
    required this.boletoNoAmount,
    required this.cep,
    required this.cepLooking,
    required this.cepNotFound,
    required this.cepInvalid,
    required this.cepError,
    required this.document,
    required this.cpfInvalid,
    required this.cnpjInvalid,
    required this.documentLooking,
    required this.documentNotFound,
    required this.nfeTitle,
    required this.nfeKey,
    required this.nfeCopyKey,
    required this.nfeKeyCopied,
    required this.nfeKeyInvalid,
    required this.nfeIssuer,
    required this.nfeCnpj,
    required this.nfeDate,
    required this.nfeAmount,
    required this.nfeNumber,
    required this.nfeStatus,
    required this.nfeQr,
    required this.nfeOpen,
    required this.pasteLabel,
    required this.pasteHint,
    required this.pastePaste,
    required this.pasteClear,
    required this.pasteEmpty,
    required this.pasteActions,
    required this.pasteSummary,
    required this.pasteWhat,
    required this.pasteInvalid,
  });

  final String pixTitle;
  final String pixCopy;
  final String pixCopied;
  final String pixCode;
  final String pixQr;
  final String pixHint;
  final String pixReceiver;
  final String pixAmount;
  final String pixAnyAmount;

  /// "Vale por %{time}".
  final String pixValidFor;
  final String pixWaiting;
  final String pixPaid;
  final String pixPaidHint;
  final String pixExpired;
  final String pixExpiredHint;
  final String pixRegenerate;
  final String pixKey;
  final String pixKeyHint;
  final String pixKeyInvalid;

  /// cpf, cnpj, phone, email, random → o nome do tipo da chave.
  final Map<String, String> keyTypes;
  final String boleto;
  final String boletoHint;
  final String boletoScan;
  final String boletoInvalid;
  final String boletoIncomplete;
  final String boletoBank;
  final String boletoCollection;

  /// "Vence em %{date}".
  final String boletoDue;

  /// "Venceu em %{date}".
  final String boletoOverdue;
  final String boletoNoDue;
  final String boletoNoAmount;
  final String cep;
  final String cepLooking;
  final String cepNotFound;
  final String cepInvalid;
  final String cepError;
  final String document;
  final String cpfInvalid;
  final String cnpjInvalid;
  final String documentLooking;
  final String documentNotFound;
  final String nfeTitle;
  final String nfeKey;
  final String nfeCopyKey;
  final String nfeKeyCopied;
  final String nfeKeyInvalid;
  final String nfeIssuer;
  final String nfeCnpj;
  final String nfeDate;
  final String nfeAmount;

  /// "Nº %{number} · série %{series}".
  final String nfeNumber;

  /// authorized, canceled, denied, pending → o nome da situação.
  final Map<String, String> nfeStatus;
  final String nfeQr;
  final String nfeOpen;
  final String pasteLabel;
  final String pasteHint;
  final String pastePaste;
  final String pasteClear;
  final String pasteEmpty;
  final String pasteActions;

  /// Moldes do resumo por tipo (pix, pix_free, boleto, boleto_amount, boleto_due, boleto_plain, nfe, cpf, cnpj,
  /// cep, phone, email, pix_key, url, money, date, text), com %{amount}, %{name}, %{date}, %{value}, %{model},
  /// %{uf}, %{number}, %{domain}, %{count}. Os mesmos da gem e do Stimulus.
  final Map<String, String> pasteSummary;

  /// O que o tipo é, com o artigo ("um boleto"), para o [pasteInvalid].
  final Map<String, String> pasteWhat;

  /// "Parece %{what}, mas os dígitos verificadores não conferem."
  final String pasteInvalid;

  /// O texto com %{x} trocado pelos valores.
  static String fill(String template, Map<String, String> values) =>
      template.replaceAllMapped(RegExp(r'%\{(\w+)\}'), (m) => values[m.group(1)] ?? '');

  static SsBrStrings of(BuildContext context) => forLocale(SsStrings.of(context).locale);

  static SsBrStrings forLocale(Locale l) => switch (l.languageCode) {
    'en' => en,
    'es' => es,
    _ => pt,
  };

  static const pt = SsBrStrings(
    pixTitle: 'Pague com Pix',
    pixCopy: 'Copiar código',
    pixCopied: 'Código copiado',
    pixCode: 'Pix copia e cola',
    pixQr: 'QR Code do Pix',
    pixHint: 'Abra o app do banco, escolha Pix e leia o QR Code ou cole o código.',
    pixReceiver: 'Recebedor',
    pixAmount: 'Valor',
    pixAnyAmount: 'Valor livre',
    pixValidFor: 'Vale por %{time}',
    pixWaiting: 'Aguardando pagamento',
    pixPaid: 'Pagamento recebido',
    pixPaidHint: 'Pronto, o Pix caiu.',
    pixExpired: 'Código expirado',
    pixExpiredHint: 'Gere outro código para pagar.',
    pixRegenerate: 'Gerar outro código',
    pixKey: 'Chave Pix',
    pixKeyHint: 'CPF, CNPJ, telefone, e-mail ou chave aleatória',
    pixKeyInvalid: 'Chave Pix inválida. Use CPF, CNPJ, telefone com DDD, e-mail ou a chave aleatória.',
    keyTypes: {'cpf': 'CPF', 'cnpj': 'CNPJ', 'phone': 'Telefone', 'email': 'E-mail', 'random': 'Chave aleatória'},
    boleto: 'Linha digitável',
    boletoHint: 'Digite ou cole os números do boleto',
    boletoScan: 'Ler código de barras',
    boletoInvalid: 'Algum número não confere. Confira a linha digitável.',
    boletoIncomplete: 'Faltam números: a linha tem 47 dígitos (boleto) ou 48 (conta de consumo).',
    boletoBank: 'Boleto bancário',
    boletoCollection: 'Conta de consumo ou tributo',
    boletoDue: 'Vence em %{date}',
    boletoOverdue: 'Venceu em %{date}',
    boletoNoDue: 'Sem vencimento',
    boletoNoAmount: 'Valor a informar',
    cep: 'CEP',
    cepLooking: 'Buscando o endereço…',
    cepNotFound: 'CEP não encontrado. Preencha o endereço.',
    cepInvalid: 'O CEP tem 8 dígitos.',
    cepError: 'Não deu para buscar o CEP agora. Preencha o endereço.',
    document: 'CPF ou CNPJ',
    cpfInvalid: 'CPF inválido. Confira os 11 dígitos.',
    cnpjInvalid: 'CNPJ inválido. Confira os 14 caracteres.',
    documentLooking: 'Buscando a razão social…',
    documentNotFound: 'CNPJ não encontrado.',
    nfeTitle: 'Nota fiscal',
    nfeKey: 'Chave de acesso',
    nfeCopyKey: 'Copiar chave',
    nfeKeyCopied: 'Chave copiada',
    nfeKeyInvalid: 'O dígito verificador da chave não confere.',
    nfeIssuer: 'Emitente',
    nfeCnpj: 'CNPJ',
    nfeDate: 'Emissão',
    nfeAmount: 'Valor',
    nfeNumber: 'Nº %{number} · série %{series}',
    nfeStatus: {
      'authorized': 'Autorizada',
      'canceled': 'Cancelada',
      'denied': 'Denegada',
      'pending': 'Em processamento',
    },
    nfeQr: 'QR Code da consulta',
    nfeOpen: 'Consultar na Sefaz',
    pasteLabel: 'Colar e reconhecer',
    pasteHint: 'Cole um Pix, boleto, chave de nota, CPF, CEP, link…',
    pastePaste: 'Colar',
    pasteClear: 'Limpar',
    pasteEmpty: 'Cole algo e a gente diz o que é.',
    pasteActions: 'O que fazer com isso',
    pasteSummary: {
      'pix': 'Isso parece um Pix de %{amount} para %{name}',
      'pix_free': 'Isso parece um Pix para %{name}',
      'boleto': 'Isso parece um boleto de %{amount} com vencimento em %{date}',
      'boleto_amount': 'Isso parece um boleto de %{amount}',
      'boleto_due': 'Isso parece um boleto com vencimento em %{date}',
      'boleto_plain': 'Isso parece um boleto',
      'nfe': 'Isso parece a chave de uma %{model} de %{uf}, nº %{number}',
      'cpf': 'Isso parece um CPF: %{value}',
      'cnpj': 'Isso parece um CNPJ: %{value}',
      'cep': 'Isso parece um CEP: %{value}',
      'phone': 'Isso parece um telefone: %{value}',
      'email': 'Isso parece um e-mail: %{value}',
      'pix_key': 'Isso parece uma chave Pix aleatória',
      'url': 'Isso parece um link de %{domain}',
      'money': 'Isso parece um valor: %{amount}',
      'date': 'Isso parece uma data: %{date}',
      'text': 'Texto livre, %{count} caracteres',
    },
    pasteWhat: {
      'pix': 'um Pix',
      'boleto': 'um boleto',
      'nfe': 'uma chave de nota fiscal',
      'cpf': 'um CPF',
      'cnpj': 'um CNPJ',
      'cep': 'um CEP',
      'phone': 'um telefone',
      'email': 'um e-mail',
    },
    pasteInvalid: 'Parece %{what}, mas os números não conferem.',
  );

  static const en = SsBrStrings(
    pixTitle: 'Pay with Pix',
    pixCopy: 'Copy code',
    pixCopied: 'Code copied',
    pixCode: 'Pix copy and paste',
    pixQr: 'Pix QR code',
    pixHint: 'Open your bank app, choose Pix and scan the QR code or paste the code.',
    pixReceiver: 'Payee',
    pixAmount: 'Amount',
    pixAnyAmount: 'Any amount',
    pixValidFor: 'Valid for %{time}',
    pixWaiting: 'Waiting for payment',
    pixPaid: 'Payment received',
    pixPaidHint: 'Done, the Pix arrived.',
    pixExpired: 'Code expired',
    pixExpiredHint: 'Generate a new code to pay.',
    pixRegenerate: 'Generate a new code',
    pixKey: 'Pix key',
    pixKeyHint: 'CPF, CNPJ, phone, email or random key',
    pixKeyInvalid: 'Invalid Pix key. Use a CPF, CNPJ, phone with area code, email or random key.',
    keyTypes: {'cpf': 'CPF', 'cnpj': 'CNPJ', 'phone': 'Phone', 'email': 'Email', 'random': 'Random key'},
    boleto: 'Boleto number',
    boletoHint: 'Type or paste the boleto digits',
    boletoScan: 'Scan barcode',
    boletoInvalid: 'Some digits do not match. Check the boleto number.',
    boletoIncomplete: 'Digits missing: the number has 47 digits (boleto) or 48 (utility bill).',
    boletoBank: 'Bank boleto',
    boletoCollection: 'Utility bill or tax',
    boletoDue: 'Due on %{date}',
    boletoOverdue: 'Was due on %{date}',
    boletoNoDue: 'No due date',
    boletoNoAmount: 'Amount to be filled in',
    cep: 'CEP (postal code)',
    cepLooking: 'Looking up the address…',
    cepNotFound: 'CEP not found. Fill in the address.',
    cepInvalid: 'The CEP has 8 digits.',
    cepError: 'Could not look up the CEP now. Fill in the address.',
    document: 'CPF or CNPJ',
    cpfInvalid: 'Invalid CPF. Check the 11 digits.',
    cnpjInvalid: 'Invalid CNPJ. Check the 14 characters.',
    documentLooking: 'Looking up the company name…',
    documentNotFound: 'CNPJ not found.',
    nfeTitle: 'Invoice',
    nfeKey: 'Access key',
    nfeCopyKey: 'Copy key',
    nfeKeyCopied: 'Key copied',
    nfeKeyInvalid: 'The key check digit does not match.',
    nfeIssuer: 'Issuer',
    nfeCnpj: 'CNPJ',
    nfeDate: 'Issued',
    nfeAmount: 'Amount',
    nfeNumber: 'No. %{number} · series %{series}',
    nfeStatus: {'authorized': 'Authorized', 'canceled': 'Canceled', 'denied': 'Denied', 'pending': 'Processing'},
    nfeQr: 'Lookup QR code',
    nfeOpen: 'Look up at Sefaz',
    pasteLabel: 'Paste and recognize',
    pasteHint: 'Paste a Pix, boleto, invoice key, CPF, CEP, link…',
    pastePaste: 'Paste',
    pasteClear: 'Clear',
    pasteEmpty: 'Paste something and we will tell you what it is.',
    pasteActions: 'What to do with it',
    pasteSummary: {
      'pix': 'This looks like a Pix of %{amount} to %{name}',
      'pix_free': 'This looks like a Pix to %{name}',
      'boleto': 'This looks like a boleto of %{amount} due on %{date}',
      'boleto_amount': 'This looks like a boleto of %{amount}',
      'boleto_due': 'This looks like a boleto due on %{date}',
      'boleto_plain': 'This looks like a boleto',
      'nfe': 'This looks like the key of an %{model} from %{uf}, no. %{number}',
      'cpf': 'This looks like a CPF: %{value}',
      'cnpj': 'This looks like a CNPJ: %{value}',
      'cep': 'This looks like a CEP: %{value}',
      'phone': 'This looks like a phone number: %{value}',
      'email': 'This looks like an email: %{value}',
      'pix_key': 'This looks like a random Pix key',
      'url': 'This looks like a link to %{domain}',
      'money': 'This looks like an amount: %{amount}',
      'date': 'This looks like a date: %{date}',
      'text': 'Free text, %{count} characters',
    },
    pasteWhat: {
      'pix': 'a Pix',
      'boleto': 'a boleto',
      'nfe': 'an invoice key',
      'cpf': 'a CPF',
      'cnpj': 'a CNPJ',
      'cep': 'a CEP',
      'phone': 'a phone number',
      'email': 'an email',
    },
    pasteInvalid: 'Looks like %{what}, but the digits do not match.',
  );

  static const es = SsBrStrings(
    pixTitle: 'Paga con Pix',
    pixCopy: 'Copiar código',
    pixCopied: 'Código copiado',
    pixCode: 'Pix copiar y pegar',
    pixQr: 'Código QR del Pix',
    pixHint: 'Abre la app del banco, elige Pix y lee el código QR o pega el código.',
    pixReceiver: 'Beneficiario',
    pixAmount: 'Valor',
    pixAnyAmount: 'Valor libre',
    pixValidFor: 'Vale por %{time}',
    pixWaiting: 'Esperando el pago',
    pixPaid: 'Pago recibido',
    pixPaidHint: 'Listo, el Pix llegó.',
    pixExpired: 'Código vencido',
    pixExpiredHint: 'Genera otro código para pagar.',
    pixRegenerate: 'Generar otro código',
    pixKey: 'Clave Pix',
    pixKeyHint: 'CPF, CNPJ, teléfono, correo o clave aleatoria',
    pixKeyInvalid: 'Clave Pix inválida. Usa CPF, CNPJ, teléfono con código de área, correo o clave aleatoria.',
    keyTypes: {'cpf': 'CPF', 'cnpj': 'CNPJ', 'phone': 'Teléfono', 'email': 'Correo', 'random': 'Clave aleatoria'},
    boleto: 'Línea digitable',
    boletoHint: 'Escribe o pega los números del boleto',
    boletoScan: 'Leer código de barras',
    boletoInvalid: 'Algún número no coincide. Revisa la línea digitable.',
    boletoIncomplete: 'Faltan números: la línea tiene 47 dígitos (boleto) o 48 (factura de servicio).',
    boletoBank: 'Boleto bancario',
    boletoCollection: 'Factura de servicio o impuesto',
    boletoDue: 'Vence el %{date}',
    boletoOverdue: 'Venció el %{date}',
    boletoNoDue: 'Sin vencimiento',
    boletoNoAmount: 'Valor a informar',
    cep: 'CEP (código postal)',
    cepLooking: 'Buscando la dirección…',
    cepNotFound: 'CEP no encontrado. Completa la dirección.',
    cepInvalid: 'El CEP tiene 8 dígitos.',
    cepError: 'No se pudo buscar el CEP ahora. Completa la dirección.',
    document: 'CPF o CNPJ',
    cpfInvalid: 'CPF inválido. Revisa los 11 dígitos.',
    cnpjInvalid: 'CNPJ inválido. Revisa los 14 caracteres.',
    documentLooking: 'Buscando la razón social…',
    documentNotFound: 'CNPJ no encontrado.',
    nfeTitle: 'Factura',
    nfeKey: 'Clave de acceso',
    nfeCopyKey: 'Copiar clave',
    nfeKeyCopied: 'Clave copiada',
    nfeKeyInvalid: 'El dígito verificador de la clave no coincide.',
    nfeIssuer: 'Emisor',
    nfeCnpj: 'CNPJ',
    nfeDate: 'Emisión',
    nfeAmount: 'Valor',
    nfeNumber: 'N.º %{number} · serie %{series}',
    nfeStatus: {'authorized': 'Autorizada', 'canceled': 'Cancelada', 'denied': 'Denegada', 'pending': 'En proceso'},
    nfeQr: 'Código QR de la consulta',
    nfeOpen: 'Consultar en la Sefaz',
    pasteLabel: 'Pegar y reconocer',
    pasteHint: 'Pega un Pix, boleto, clave de factura, CPF, CEP, enlace…',
    pastePaste: 'Pegar',
    pasteClear: 'Borrar',
    pasteEmpty: 'Pega algo y te decimos qué es.',
    pasteActions: 'Qué hacer con esto',
    pasteSummary: {
      'pix': 'Esto parece un Pix de %{amount} para %{name}',
      'pix_free': 'Esto parece un Pix para %{name}',
      'boleto': 'Esto parece un boleto de %{amount} con vencimiento el %{date}',
      'boleto_amount': 'Esto parece un boleto de %{amount}',
      'boleto_due': 'Esto parece un boleto con vencimiento el %{date}',
      'boleto_plain': 'Esto parece un boleto',
      'nfe': 'Esto parece la clave de una %{model} de %{uf}, n.º %{number}',
      'cpf': 'Esto parece un CPF: %{value}',
      'cnpj': 'Esto parece un CNPJ: %{value}',
      'cep': 'Esto parece un CEP: %{value}',
      'phone': 'Esto parece un teléfono: %{value}',
      'email': 'Esto parece un correo: %{value}',
      'pix_key': 'Esto parece una clave Pix aleatoria',
      'url': 'Esto parece un enlace de %{domain}',
      'money': 'Esto parece un valor: %{amount}',
      'date': 'Esto parece una fecha: %{date}',
      'text': 'Texto libre, %{count} caracteres',
    },
    pasteWhat: {
      'pix': 'un Pix',
      'boleto': 'un boleto',
      'nfe': 'una clave de factura',
      'cpf': 'un CPF',
      'cnpj': 'un CNPJ',
      'cep': 'un CEP',
      'phone': 'un teléfono',
      'email': 'un correo',
    },
    pasteInvalid: 'Parece %{what}, pero los números no coinciden.',
  );
}
