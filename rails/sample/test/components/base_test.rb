require "test_helper"

class BaseComponentTest < ComponentTest
  test "a gem carrega o ViewComponent e o form builder" do
    assert defined?(Ss::BaseComponent)
    assert defined?(ComponentesUi::FormBuilder)
  end
end
