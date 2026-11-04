Rails.application.routes.draw do
  root "vitrine#show", pagina: "inicio"
  get "vitrine/:pagina" => "vitrine#show", as: :vitrine
  # Formulários de exemplo postam aqui (devolve o que veio, para ver o erro inline).
  post "vitrine/:pagina" => "vitrine#show"
  get "up" => "rails/health#show", as: :rails_health_check
end
