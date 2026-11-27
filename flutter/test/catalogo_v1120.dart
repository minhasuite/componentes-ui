// v1.12.0 "Kit Brasil" ([comV1120]): o cartão do Pix, a nota fiscal, o QR puro-Dart, os campos brasileiros e o
// colar inteligente. Dados de exemplo com DV calculado, sem pessoas reais (os mesmos da vitrine web).
import 'package:componentes_ui/componentes_ui.dart';
import 'package:material_ui/material_ui.dart';

import 'catalogo.dart';

Widget _pad(Widget w) => Padding(padding: const EdgeInsets.all(16), child: w);

final _agora = DateTime(2026, 11, 27, 10);
final _hoje = DateTime(2026, 11, 27);
final _pix = SsPixCode.build(
  key: 'loja@exemplo.com.br',
  name: 'Loja Exemplo',
  city: 'São Paulo',
  amountCents: 12345,
  txid: 'PEDIDO1042',
);
const _k43 = '3526111122233300018155001000012345112345678';
final _nfe = '$_k43${SsNfeKey.dvFor(_k43)}';
const _n43 = '3526111122233300018165002000000789187654321';
final _nfce = '$_n43${SsNfeKey.dvFor(_n43)}';
const _linha = '34191.09008 00012.345674 89012.345677 1 16560000012345';

final _acoes = <SsPasteType, List<SsPasteAction>>{
  SsPasteType.boleto: [
    SsPasteAction('Pagar boleto', (_) {}, icon: Icons.payments_outlined, primary: true),
    SsPasteAction('Agendar', (_) {}),
  ],
  SsPasteType.pix: [SsPasteAction('Pagar Pix', (_) {}, icon: Icons.pix)],
  SsPasteType.pixKey: [SsPasteAction('Enviar Pix', (_) {})],
  SsPasteType.nfe: [SsPasteAction('Importar nota', (_) {}, icon: Icons.description_outlined)],
};

List<Componente> comV1120(List<Componente> base) => [...base, ..._v1120];

final _v1120 = <Componente>[
  Componente(
    'ss-pix-card',
    'SsPixCard',
    'Pix de uma cobrança (v1.12, par do Ss::PixCardComponent): QR gerado do copia e cola, valor, recebedor, validade com contagem, copiar e o estado.',
    comportamentos: const [
      'O QR sai do próprio copia e cola (SsQrImage, gerador puro-Dart do pacote); qr: aceita a imagem pronta do PSP.',
      'Sem amountCents/receiver, lê os campos 54 e 59 do BR Code. Sem valor: "Valor livre".',
      'Aguardando: contagem regressiva; ao zerar, passa a expirado sozinho e chama onExpired.',
      '"Copiar código" põe o código na área de transferência, vira "Código copiado" por 2 s (leitor de tela anuncia) e dá o toque de seleção.',
      'Pago: o ✓ cresce com a mola (SsMotion.spring) e o toque de sucesso; reduzir movimento: já cheio. Expirado: QR apagado e "Gerar outro código" com onRegenerate.',
      'O fundo do QR é sempre claro (o leitor do banco precisa), também no escuro. O pagamento é do app.',
    ],
    estados: [
      Estado(
        'aguardando',
        'aguardando, com contagem',
        (_) => _pad(
          SsPixCard(code: _pix, expiresAt: _agora.add(const Duration(minutes: 14, seconds: 32)), now: () => _agora),
        ),
        tamanho: const Size(360, 620),
      ),
      Estado(
        'pago',
        'pago (animação de sucesso)',
        (_) => _pad(SsPixCard(code: _pix, status: SsPixStatus.paid)),
        tamanho: const Size(360, 400),
        aguarde: 900,
      ),
      Estado(
        'expirado',
        'expirado, com gerar outro',
        (_) => _pad(SsPixCard(code: _pix, status: SsPixStatus.expired, onRegenerate: () {})),
        tamanho: const Size(360, 560),
      ),
    ],
  ),
  Componente(
    'ss-qr-image',
    'SsQrImage',
    'QR Code puro-Dart (v1.12, par do ss_qr_svg): modo byte, versões 1 a 40, correção M e a máscara de menor penalidade, a mesma matriz da gem.',
    comportamentos: const [
      'SsQrCode.encode(texto) dá a matriz; SsQrImage(data:) desenha, do tamanho que o pai der.',
      'Módulos na tinta escura e fundo claro em qualquer tema (o leitor precisa de contraste); margin: a zona de silêncio.',
      'semanticLabel: o nome no leitor de tela; sem ele, o QR fica fora da semântica.',
    ],
    estados: [
      Estado(
        'pix',
        'o QR de um Pix copia e cola',
        (_) => Center(
          child: SsQrImage(data: _pix, size: 200, semanticLabel: 'QR Code do Pix'),
        ),
        tamanho: const Size(240, 240),
      ),
    ],
  ),
  Componente(
    'ss-nfe-card',
    'SsNfeCard',
    'Nota fiscal (v1.12, par do Ss::NfeCardComponent): chave de acesso em blocos com copiar e o DV conferido, emitente, CNPJ, data, valor, situação e o QR da consulta.',
    comportamentos: const [
      'Da chave (44 dígitos) saem o modelo (NF-e, NFC-e, CT-e), número, série e o CNPJ do emitente.',
      'DV errado: aviso no cartão. status: authorized, canceled, denied ou pending.',
      '"Copiar chave" com retorno; qrUrl põe o QR da consulta ao lado da chave; onOpen mostra "Consultar na Sefaz".',
    ],
    estados: [
      Estado(
        'nfe',
        'NF-e autorizada',
        (_) => _pad(
          SsNfeCard(
            accessKey: _nfe,
            issuer: 'Loja Exemplo Comércio Ltda',
            issuedAt: DateTime(2026, 11, 20),
            amountCents: 48990,
            status: SsNfeStatus.authorized,
          ),
        ),
        tamanho: const Size(380, 420),
      ),
      Estado(
        'nfce-qr',
        'NFC-e com o QR da consulta',
        (_) => _pad(
          SsNfeCard(
            accessKey: _nfce,
            issuer: 'Mercado Exemplo',
            issuedAt: DateTime(2026, 11, 26),
            amountCents: 8990,
            status: SsNfeStatus.pending,
            qrUrl: 'https://www.exemplo.gov.br/nfce?p=$_nfce|2|1|1',
            onOpen: () {},
          ),
        ),
        tamanho: const Size(380, 440),
      ),
      Estado(
        'dv-errado',
        'chave com DV errado',
        (_) => _pad(
          SsNfeCard(
            accessKey: '${_nfe.substring(0, 43)}${(int.parse(_nfe[43]) + 1) % 10}',
            status: SsNfeStatus.canceled,
          ),
        ),
        tamanho: const Size(380, 340),
      ),
    ],
  ),
  Componente(
    'ss-smart-paste',
    'SsSmartPaste',
    'Colar inteligente (v1.12, par do Ss::SmartPasteComponent): reconhece o que foi colado e mostra as ações que o app registrou para o tipo.',
    comportamentos: const [
      'Tipos: Pix copia e cola e chave, boleto (47/48), chave de NF-e (solta ou na URL da NFC-e), CPF/CNPJ, CEP, telefone, e-mail, link e domínio, valor em R\$, data e texto livre.',
      'SsPasteDetector.detect é puro e igual nos três lados (Ruby, JS e Dart), conferido pelos exemplos de docs/v1120/exemplos.json.',
      'A frase: "Isso parece um boleto de R\$ 123,45 com vencimento em 10/12/2026"; com o DV errado, "Parece um boleto, mas os números não conferem."',
      'actions: {SsPasteType.boleto: [SsPasteAction(...)]}; CPF, CNPJ, telefone e e-mail válidos também mostram as de pixKey.',
      'DV errado: o aviso e nenhuma ação. O botão Colar lê a área de transferência; o ✕ limpa; o cartão entra com SsMotion.medium e é região viva do leitor de tela.',
    ],
    estados: [
      Estado(
        'boleto',
        'boleto com ações',
        (_) => _pad(SsSmartPaste(initialValue: _linha, actions: _acoes, today: _hoje)),
        tamanho: const Size(380, 420),
      ),
      Estado(
        'pix',
        'Pix copia e cola',
        (_) => _pad(SsSmartPaste(initialValue: _pix, actions: _acoes, today: _hoje)),
        tamanho: const Size(380, 420),
      ),
      Estado(
        'cpf',
        'CPF (também chave Pix)',
        (_) => _pad(SsSmartPaste(initialValue: '604.721.385-53', actions: _acoes, today: _hoje)),
        tamanho: const Size(380, 360),
      ),
      Estado(
        'invalido',
        'dígito errado',
        (_) => _pad(
          SsSmartPaste(
            initialValue: '34191.09008 00012.345674 89012.345677 1 16560001012345',
            actions: _acoes,
            today: _hoje,
          ),
        ),
        tamanho: const Size(380, 320),
      ),
      Estado('vazio', 'vazio', (_) => _pad(SsSmartPaste(actions: _acoes)), tamanho: const Size(380, 160)),
    ],
  ),
  Componente(
    'ss-pix-key-field',
    'SsPixKeyField',
    'Campo de chave Pix (v1.12, par do f.ss_pix_key): detecta o tipo enquanto digita, mostra embaixo e formata ao sair.',
    comportamentos: const [
      'CPF, CNPJ, telefone (+55), e-mail ou aleatória; 11 dígitos com CPF válido é CPF, senão celular com DDD.',
      'onChanged recebe a chave normalizada (a da API) e o tipo; type prende num tipo só.',
      'Inválida: "Chave Pix inválida…" embaixo do campo, ao sair.',
    ],
    estados: [
      Estado(
        'telefone',
        'telefone detectado',
        (_) => _pad(const SsPixKeyField(initialValue: '+55 11 98765-4321')),
        tamanho: const Size(360, 140),
      ),
      Estado(
        'cpf',
        'CPF detectado',
        (_) => _pad(const SsPixKeyField(initialValue: '604.721.385-53')),
        tamanho: const Size(360, 140),
      ),
    ],
  ),
  Componente(
    'ss-boleto-field',
    'SsBoletoField',
    'Linha digitável do boleto (v1.12, par do f.ss_boleto): máscara de 47/48 dígitos, DV e o tipo, valor e vencimento embaixo.',
    comportamentos: const [
      'Bancário (47, 5 blocos) ou conta de consumo (48, 4 blocos, começa com 8); colar o código de barras (44) vira a linha.',
      'DV dos campos (módulo 10) e geral (módulo 11); errado ou incompleto: a mensagem embaixo, ao sair.',
      'onScan: o botão "Ler código de barras" no campo; a câmera é do app, que devolve o código.',
      'Vencido: a linha embaixo em âmbar ("Venceu em …").',
    ],
    estados: [
      Estado(
        'bancario',
        'bancário com valor e vencimento',
        (_) => _pad(SsBoletoField(initialValue: _linha, onScan: () async => null, today: _hoje)),
        tamanho: const Size(380, 170),
      ),
      Estado(
        'arrecadacao',
        'conta de consumo',
        (_) => _pad(SsBoletoField(initialValue: '836900000016234500481234456789012345567890123456', today: _hoje)),
        tamanho: const Size(380, 170),
      ),
    ],
  ),
  Componente(
    'ss-cep-field',
    'SsCepField',
    'CEP (v1.12, par do f.ss_cep): máscara e, pelo onLookup do app, o endereço nos campos ligados.',
    comportamentos: const [
      'Com os 8 dígitos chama onLookup(cep) (o endpoint do app; o pacote não chama serviço externo).',
      'Achou: preenche street, district, city e state e mostra o endereço embaixo; não achou ou falhou: diz e deixa preencher à mão.',
      'Resposta velha não passa por cima da nova.',
    ],
    estados: [
      Estado('achou', 'endereço preenchido', (_) => _pad(_CepDemo()), tamanho: const Size(360, 150), aguarde: 600),
    ],
  ),
  Componente(
    'ss-document-field',
    'SsDocumentField',
    'CPF ou CNPJ (v1.12, par do f.ss_document): máscara (o CNPJ alfanumérico também), DV e a razão social pelo onLookup.',
    comportamentos: const [
      'Detecta CPF (até 11) ou CNPJ (12+ ou com letra); kind prende num só.',
      'DV errado: "CPF inválido…"/"CNPJ inválido…" embaixo, ao sair.',
      'onLookup(cnpj) → razão social embaixo do campo.',
    ],
    estados: [
      Estado(
        'cnpj',
        'CNPJ com a razão social',
        (_) =>
            _pad(SsDocumentField(initialValue: '11222333000181', onLookup: (_) async => 'Loja Exemplo Comércio Ltda')),
        tamanho: const Size(360, 140),
        aguarde: 600,
      ),
    ],
  ),
];

/// O CEP já com o endereço buscado (o lookup responde na hora).
class _CepDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SsCepField(
    initialValue: '01310100',
    onLookup: (_) async =>
        const SsAddress(street: 'Avenida Paulista', district: 'Bela Vista', city: 'São Paulo', state: 'SP'),
    autoLookup: true,
  );
}
