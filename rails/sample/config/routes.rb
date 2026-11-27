Rails.application.routes.draw do
  root "vitrine#show", pagina: "inicio"
  get "vitrine/:pagina" => "vitrine#show", as: :vitrine
  # Formulários de exemplo postam aqui (devolve o que veio, para ver o erro inline).
  post "vitrine/:pagina" => "vitrine#show"
  # v1.12.0: os endpoints de exemplo do Kit Brasil (o f.ss_cep e o f.ss_document chamam o do produto).
  get "demo/cep/:cep" => "vitrine#cep", as: :demo_cep
  get "demo/cnpj/:cnpj" => "vitrine#cnpj", as: :demo_cnpj
  # v1.13.0: a explicação da IA (Ss::ExplainComponent) e o rascunho que vai para o outro aparelho (Ss::ContinueOnComponent).
  post "demo/explicar" => "vitrine#explicar", as: :demo_explicar
  post "demo/continuar" => "vitrine#continuar", as: :demo_continuar
  get "up" => "rails/health#show", as: :rails_health_check
end
