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
end
