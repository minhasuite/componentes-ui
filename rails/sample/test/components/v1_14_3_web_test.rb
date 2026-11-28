require "test_helper"

# v1.14.3: só Flutter (folhas pelo Navigator raiz e a chave do SsDeviceTile com 48); o web é igual à v1.14.2.
# v1.14.4: idem (o nó do SsDeviceTile e o SsPressable fora da árvore de acessibilidade); o web é igual.
# v1.14.5: idem (peças de medida e cartões de dado sem estourar com o texto em 1,6x); o web é igual.
# v1.14.6: idem (o campo do SsOtpField); a v1.14.7 (gráficos com tudo zero) tem o teste dela, v1_14_7_web_test.rb.
class V1143WebTest < ComponentTest
  REPO = Pathname(ComponentesUi::Engine.root).join("..")

  test "versão 1.14.7" do
    assert_equal "1.14.7", ComponentesUi::VERSION
    assert_includes REPO.join("flutter/pubspec.yaml").read, "version: 1.14.7"
    assert_includes REPO.join("README.md").read, "ref: v1.14.7"
  end
end
