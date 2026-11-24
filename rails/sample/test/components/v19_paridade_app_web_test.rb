require "test_helper"

# v1.9 · paridade_app: o web ganha o que o app (SsWizard) tem — o passo de revisão e o
# "Salvar e continuar depois" — e cada peça só-web agora tem o par no Flutter com o mesmo nome.
class V19ParidadeAppWebTest < ComponentTest
  ROOT = Pathname(ComponentesUi::Engine.root)
  CSS = ROOT.join("app/assets/tailwind/componentes_ui")

  def wizard(**opts, &blk)
    render_inline(Ss::WizardComponent.new(**opts)) do |w|
      w.with_step(title: "Dados") { "<input name='nome' required>".html_safe }
      w.with_step(title: "Plano") { "plano" }
      blk&.call(w)
    end
  end

  test "summary: vira o último passo (Revisão), com o ponto e o progresso contando ele" do
    wizard { |w| w.with_summary { "Ana · Plano Pro" } }
    assert_selector ".ss-wizard-steps[style='--n:3'] li", count: 3
    assert_selector ".ss-wizard-steps li:last-child b", text: "Revisão"
    assert_selector "section.ss-wizard-summary[hidden][aria-label='Passo 3: Revisão']", text: "Ana · Plano Pro", visible: :all
    assert_selector "section[data-ss-wizard-target='panel']", count: 3, visible: :all
    assert_selector "[role=progressbar][aria-valuemax='3']"
  end

  test "sem summary nada muda" do
    wizard
    assert_selector ".ss-wizard-steps li", count: 2
    assert_no_selector ".ss-wizard-summary", visible: :all
    assert_no_selector ".ss-wizard-later"
  end

  test "save_later_label: submit sem validação com name/value para o controller do app" do
    wizard(save_later_label: true)
    assert_selector "button.ss-wizard-later[type=submit][name=save_later][value='1'][formnovalidate]", text: "Salvar e continuar depois"
    wizard(save_later_label: "Terminar depois", save_later_name: "rascunho")
    assert_selector "button.ss-wizard-later[name=rascunho]", text: "Terminar depois"
  end

  test "modo servidor ignora summary e save_later (o form é do app)" do
    render_inline(Ss::WizardComponent.new(current: 0, save_later_label: true)) do |w|
      w.with_step(title: "A")
      w.with_summary { "resumo" }
      "corpo"
    end
    assert_selector ".ss-wizard.is-server"
    assert_no_selector ".ss-wizard-later"
    assert_no_selector ".ss-wizard-summary", visible: :all
  end

  test "textos novos em pt/en/es" do
    { "pt-BR": %w[Revisão Salvar], en: %w[Review Save], es: %w[Revisión Guardar] }.each do |loc, (rev, later)|
      assert_equal rev, I18n.t("componentes_ui.wizard.review", locale: loc)
      assert I18n.t("componentes_ui.wizard.save_later", locale: loc).start_with?(later)
    end
  end

  test "CSS próprio importado e o botão desce no celular" do
    css = CSS.join("v19_paridade_app.css").read
    assert_includes css, ".ss-wizard-nav .ss-wizard-later"
    assert_includes css, "@media (max-width: 520px)"
    assert_includes CSS.join("engine.css").read, '@import "./v19_paridade_app.css";'
  end

  test "atalhos do período iguais aos do app (SsDateRangeShortcut)" do
    assert_equal %w[today 7d month last_month], Ss::DateRangeComponent::SHORTCUTS.keys
  end

  test "cada peça só-web tem o par no Flutter com o mesmo nome" do
    lib = ROOT.join("../flutter/lib/src/v19/paridade_app")
    skip "sem a pasta do Flutter ao lado" unless lib.exist?
    dart = Dir[lib.join("*.dart")].map { File.read(_1) }.join
    { "Gantt" => "SsGantt", "Tour" => "SsTour", "Wizard" => "SsWizard", "DateRange" => "SsDateRangeField", "OtpInput" => "SsOtpField",
      "TagInput" => "SsTagField", "AuditTrail" => "SsAuditTrail", "ReviewCard" => "SsReviewCard", "PersonCard" => "SsPersonCard",
      "BentoGrid" => "SsBentoGrid", "WhatsNew" => "SsWhatsNew", "Skeleton" => "SsSkeleton", "SplitView" => "SsSplitView" }.each do |web, app|
      assert Ss.const_defined?("#{web}Component"), "falta Ss::#{web}Component"
      assert_includes dart, "class #{app} ", "falta #{app} no Flutter"
    end
  end
end
