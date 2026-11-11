# ruby -Ilib test/helpers_test.rb (precisa do activesupport)
require "minitest/autorun"
require "active_support"
require "active_support/core_ext/string/output_safety"
require "componentes_ui/helpers"

class HelpersTest < Minitest::Test
  include ComponentesUi::Helpers

  def test_amount_separa_centavos
    assert_equal '<span class="ss-amount">R$ 1.234<small>,56</small></span>', ss_amount("R$ 1.234,56")
    assert_equal '<span class="ss-amount">38</span>', ss_amount("38")
    assert_equal '<span class="ss-amount">1,5 mil</span>', ss_amount("1,5 mil")
    assert_includes ss_amount("<b>"), "&lt;b&gt;"
  end

  def test_avatar_iniciais_e_seed_igual_ao_flutter
    assert_equal "AS", ss_initials("ana maria souza")
    assert_equal "C", ss_initials("  Carla ")
    assert_equal "?", ss_initials("")
    assert_equal ss_seed("Ana Souza"), ss_seed(" ana souza")
    # Mesmo valor do SsAvatar.seed('Ana Souza') no Dart (mesma conta em UTF-16).
    assert_equal "ana souza".codepoints.reduce(7) { |h, u| (h * 31 + u) & 0x7fffffff }, ss_seed("Ana Souza")
    assert_includes ss_avatar("Ana <x>", status: "ok"), "&lt;x&gt;"
  end

  def test_sparkline_e_aneis
    svg = ss_sparkline([1, 3, 2, 5])
    assert_includes svg, 'class="ss-spark"'
    assert_equal 3, ss_sparkline([1, 3, 2, 5], area: false).scan(" C").size
    assert_equal "", ss_sparkline([1])
    rings = ss_rings([0.72, 1.4], center: "72%")
    assert_includes rings, "--v:72.0;--i:0"
    assert_includes rings, "--v:100.0;--i:1"
    assert_includes rings, "<span>72%</span>"
  end

  def test_odometro_gera_digitos
    html = ss_odometer("R$ 1.204")
    assert_equal 4, html.scan('class="ss-odo-digit"').size
    assert_includes html, "--d:2"
    assert_includes html, '<span class="ss-sr">R$ 1.204</span>'
    assert_includes ss_odometer("<1>"), "&lt;"
  end

  def test_gauge_e_countdown_limitam
    assert_includes ss_gauge(0.724, label: "da meta"), "--v:0.724"
    assert_includes ss_gauge(1.7, label: "x"), "<b>100%</b>"
    assert_includes ss_gauge(0.5, label: "x", text: "R$ 5"), "<b>R$ 5</b>"
    assert_includes ss_countdown(total: 10, left: 7, label: "dias"), "--n:10;--left:7"
    assert_includes ss_countdown(total: 10, left: 12), "--left:10"
    assert_includes ss_countdown(total: 365, left: 73), "--n:60;--left:12"
  end

  def test_heat_semanas_e_niveis
    today = Date.new(2026, 10, 31) # sábado
    html = ss_heat({ today => 4, "2026-10-30" => 1, Date.new(2026, 10, 29) => 2 }, weeks: 2, today: today)
    assert_equal 14, html.scan("<i ").size
    assert_includes html, 'data-level="4" title="31/10: 4"'
    assert_includes html, 'data-level="1" title="30/10: 1"'
    assert_includes html, 'data-level="0" title="18/10: 0"' # 1ª coluna começa no domingo
    assert_equal 0, ss_heat_level(0, [1, 2])
    assert_equal 4, ss_heat_level(5, [5, 5, 5])
    assert_equal 1, ss_heat_level(1, [1, 2, 3, 10])
    assert_equal 4, ss_heat_level(10, [1, 2, 3, 10])
  end

  def test_status_pelo_mapa
    map = { "pago" => ["Pago", :success], atrasado: ["Atrasado", :danger] }
    assert_equal '<span class="ss-status" data-tone="success">Pago</span>', ss_status(:pago, map)
    assert_includes ss_status("atrasado", map), 'data-tone="danger"'
    assert_equal '<span class="ss-status" data-tone="neutral">outro</span>', ss_status("outro", map)
    # v0.18: :warn e :warning dão o mesmo âmbar.
    assert_includes ss_status("a", { "a" => ["Atenção", :warn] }), 'data-tone="warning"'
    assert_includes ss_status("a", { "a" => ["Atenção", "warning"] }), 'data-tone="warning"'
  end

  def test_icone_svg_inline_e_apelido_da_v2
    svg = ss_icon("magnifying-glass")
    assert_includes svg, 'data-icon="search"'
    assert_includes svg, 'class="ss-icon"'
    assert_includes svg, 'aria-hidden="true"'
    assert_includes ss_icon("star", variant: :solid, size: :lg), 'viewBox="0 0 20 20"'
    assert_includes ss_icon("xyz"), 'data-icon="question-mark-circle"'
    assert_includes ss_icon("bell", title: "<b>"), "&lt;b&gt;"
  end

  def test_expressao_de_valor
    assert_equal BigDecimal("57"), ss_amount_expression("45+12")
    assert_nil ss_amount_expression("45+")
  end

  # ViewComponent 3.x tem um `format` sem argumentos (formato do request): o
  # helper dentro de componente chamava esse em vez do Kernel e quebrava.
  class ComFormatDoViewComponent
    include ComponentesUi::Helpers

    def format = :html
  end

  def test_numero_dentro_de_componente_com_format_proprio
    assert_includes ComFormatDoViewComponent.new.ss_number(1234.5, precision: 2), "1.234,50"
  end

  # v0.15.2: espaço não separável e ss_qty (fora do Rails: o default pt-BR do ss_t).
  def test_money_com_espaco_nao_separavel_e_moeda_iso
    assert_equal "R$\u00A01.234,50", ss_money(1234.5)
    assert_equal "US$\u00A012,00", ss_money(12, currency: "USD")
    assert_equal "CHF\u00A010,00", ss_money(10, currency: "CHF")
  end

  def test_qty_com_litro_maiusculo
    assert_equal "1,5 L", ss_qty(1.5, "l")
    assert_equal "2", ss_qty(2.0)
    assert_equal "0,25 kg", ss_qty(0.25, "kg")
  end

  def test_monograma_cor_de_dado_tamanho_e_rotulo
    m = ss_monogram("ML", color: "#2D3277", size: 24, label: "Mercado <Livre>")
    assert_includes m, 'class="ss-monogram"'
    assert_includes m, "--s:24px;--ss-mono:#2D3277;--ss-mono-scale:.42"
    assert_includes m, 'role="img" aria-label="Mercado &lt;Livre&gt;">ML</span>'
    # Cor que não é #rrggbb não entra (vira a cor da marca do produto); círculo; rótulo padrão = a sigla.
    c = ss_monogram("S", color: "red;background:url(x)", circle: true)
    refute_includes c, "--ss-mono:"
    assert_includes c, 'class="ss-monogram is-circle"'
    assert_includes c, 'aria-label="S"'
    assert_includes ss_monogram("<b>"), "&lt;b&gt;"
  end
end
