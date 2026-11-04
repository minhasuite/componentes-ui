module Ss
  # Arrastar e soltar arquivos: prévia de imagem, lista com tamanho e barra de progresso.
  # Com direct_upload_url: (ex. rails_direct_uploads_url) o input leva data-direct-upload-url e o
  # Active Storage (activestorage.js) sobe ao enviar o form; a barra acompanha os eventos direct-upload:*.
  #   render Ss::FileDropComponent.new(name: "nota[anexos][]", label: "Anexos", accept: "image/*,.pdf",
  #     direct_upload_url: rails_direct_uploads_url)
  class FileDropComponent < BaseComponent
    attr_reader :name, :label, :hint, :accept, :multiple, :direct_upload_url, :id

    def initialize(name:, label: nil, hint: nil, accept: nil, multiple: true,
                   direct_upload_url: nil, id: nil, **rest)
      super(**rest)
      @name, @label, @hint, @accept, @multiple, @direct_upload_url = name, label, hint, accept, multiple, direct_upload_url
      @label ||= ss_t("file_drop.label", default: "Arquivos")
      @hint ||= ss_t("file_drop.hint", default: "Arraste aqui ou clique para escolher")
      @id = id || "ss-drop-#{SecureRandom.hex(3)}"
    end

    def types_text = accept ? ss_t("file_drop.types", default: "Tipos: %{types}", types: accept) : ss_t("file_drop.any_type", default: "Qualquer tipo de arquivo")
  end
end
