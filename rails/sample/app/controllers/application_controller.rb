class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  # Idioma da vitrine: ?locale=en|es|pt-BR troca e fica na sessão (a navegação continua
  # no idioma escolhido); valor fora da lista é ignorado.
  around_action :com_idioma

  private

  def com_idioma(&)
    pedido = params[:locale].to_s
    session[:locale] = pedido if I18n.available_locales.map(&:to_s).include?(pedido)
    locale = session[:locale].presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    I18n.with_locale(locale, &)
  end
end
