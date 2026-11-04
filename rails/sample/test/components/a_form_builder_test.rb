require "test_helper"

class AFormBuilderTest < ComponentTest
  class Cliente
    include ActiveModel::Model
    include ActiveModel::Attributes
    def self.model_name = ActiveModel::Name.new(self, nil, "Cliente")
    attribute :nome, :string
    attribute :email, :string
    attribute :obs, :string
    attribute :plano, :string
    attribute :ativo, :boolean
    attribute :tipo, :string
    validates :nome, presence: true
    validates :email, presence: true, if: -> { false }
  end

  def form_html(model, &block)
    view = vc_test_controller.view_context
    Nokogiri::HTML.fragment(view.ss_form_with(model:, url: "/clientes", &block))
  end

  def render_form(model, &block)
    @page = Capybara.string(form_html(model, &block).to_html)
  end

  def page = @page

  test "ss_form_with usa o FormBuilder da suíte e a classe .ss-form" do
    render_form(Cliente.new) { |f| f.ss_text_field(:nome) }
    assert_selector "form.ss-form .ss-field label[for=cliente_nome]"
    assert_selector "form .ss-field input.ss-input#cliente_nome"
  end

  test "obrigatório: * no rótulo e required no input só com presence incondicional" do
    render_form(Cliente.new) { |f| f.ss_text_field(:nome) + f.ss_email_field(:email) }
    assert_selector "label[for=cliente_nome] abbr.ss-req", text: "*"
    assert_selector "input#cliente_nome[required]"
    assert_no_selector "label[for=cliente_email] abbr.ss-req"
    assert_no_selector "input#cliente_email[required]"
  end

  test "erro do model inline, sem field_with_errors" do
    c = Cliente.new(nome: "")
    c.valid?
    render_form(c) { |f| f.ss_text_field(:nome, help: "Como aparece no pedido") }
    # A vitrine é pt-BR (errors.messages em config/locales/pt-BR.yml).
    assert_selector ".ss-field.is-invalid .ss-field-error#cliente_nome_error", text: "Não pode ficar em branco"
    assert_selector "input#cliente_nome[aria-invalid=true][aria-describedby='cliente_nome_help cliente_nome_error']"
    assert_no_selector ".field_with_errors"
  end

  test "textos do builder seguem o idioma (en)" do
    I18n.with_locale(:en) do
      render_form(Cliente.new) { |f| f.ss_text_field(:nome) + f.ss_submit }
    end
    assert_selector "small.ss-field-error", text: "Please fill in this field."
    assert_selector "abbr.ss-req[title=required]"
    assert_selector "input[type=submit][value=Save][data-turbo-submits-with='Saving…']"
  end

  test "prefixo, sufixo e contador" do
    render_form(Cliente.new) { |f| f.ss_text_field(:obs, prefix: "R$", suffix: "/mês", counter: 80) }
    assert_selector ".ss-field[data-controller=ss-counter] .ss-affix .ss-affix-pre", text: "R$"
    assert_selector ".ss-affix .ss-affix-suf", text: "/mês"
    assert_selector "input#cliente_obs[maxlength='80'][data-ss-counter-target=input]"
    assert_selector "small.ss-counter", text: "0/80"
  end

  test "select, check_box, radio, text_area e submit" do
    render_form(Cliente.new) do |f|
      f.ss_select(:plano, [["Mensal", "m"]], include_blank: "Escolha…") + f.ss_check_box(:ativo, label: "Ativo") +
        f.ss_radio_buttons(:tipo, [["PF", "pf"], ["PJ", "pj"]]) + f.ss_text_area(:obs) + f.ss_submit
    end
    assert_selector ".ss-field select.ss-input#cliente_plano option", text: "Escolha…"
    assert_selector ".ss-field label.ss-check input[type=checkbox]#cliente_ativo"
    assert_selector "fieldset.ss-fieldset legend", text: "Tipo"
    assert_selector "fieldset input[type=radio]#cliente_tipo_pj"
    assert_selector "textarea.ss-input#cliente_obs"
    assert_selector "input[type=submit].ss-btn.ss-btn-primary[value=Salvar]"
  end

  test "fora do ss_form o field_with_errors do Rails continua" do
    c = Cliente.new(nome: "")
    c.valid?
    view = vc_test_controller.view_context
    html = view.form_with(model: c, url: "/x") { |f| f.text_field(:nome) }
    assert_includes html, "field_with_errors"
  end
end
