require "test_helper"

# v1.14.3: só Flutter (folhas pelo Navigator raiz e a chave do SsDeviceTile com 48); o web é igual à v1.14.2.
class V1143WebTest < ComponentTest
  REPO = Pathname(ComponentesUi::Engine.root).join("..")

  test "versão 1.14.3" do
    assert_equal "1.14.3", ComponentesUi::VERSION
    assert_includes REPO.join("flutter/pubspec.yaml").read, "version: 1.14.3"
    assert_includes REPO.join("README.md").read, "ref: v1.14.3"
  end
end
