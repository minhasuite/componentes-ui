module Ss
  # Liga o controller ss-in-view (entrada ao aparecer na tela) no elemento raiz sem
  # perder o data-controller que o app passou. Uso nos componentes:
  #   tag.div(**root_attrs(class: …, data: in_view_data(stagger: true)))
  module InView
    private

    def in_view_data(stagger: false, controller: "ss-in-view", **extra)
      own = @attrs.to_h[:data].to_h
      ctrl = [own[:controller] || own["controller"], controller].compact.join(" ")
      { controller: ctrl, **(stagger ? { ss_in_view_stagger_value: true } : {}), **extra }
    end
  end
end
