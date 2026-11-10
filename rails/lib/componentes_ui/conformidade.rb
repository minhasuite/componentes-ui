# frozen_string_literal: true

require "pathname"
require "set"

module ComponentesUi
  # Conformidade de um produto Rails com a gem: tudo o que tem peça no componentes-ui
  # usa a peça. Feito para rodar num teste do produto (e portanto na CI), sem lista de
  # exceções:
  #
  #   RSpec.describe "componentes_ui" do
  #     it "o web é 100% componentes_ui" do
  #       problemas = ComponentesUi::Conformidade.verificar(Rails.root)
  #       expect(problemas).to be_empty, problemas.join("\n")
  #     end
  #   end
  #
  # O que reprova (em app/views, app/components, app/helpers, app/javascript e app/assets):
  # 1. `componentes_ui` no Gemfile fora de `tag: "vX.Y.Z"` (ou por path/branch/ref; ou por path no lock);
  # 2. a gem antiga (`minha_suite_ui`, `Ui::`) e classes do DaisyUI;
  # 3. cor da paleta do Tailwind (`text-white`, `bg-red-500`…) e cor literal (hex, rgb, hsl, oklch…);
  # 4. tag crua de controle (`<button>`, `<input>`, `<select>`, `<textarea>`, `<table>`, `<dialog>`),
  #    os helpers que as geram (`button_to`, `*_field_tag`, `form_with`…) e campos do FormBuilder fora do `ss_*`
  #    (`hidden_field` é livre: não é componente visual);
  # 5. gráfico fora da gem (Chart.js) e o hover do Tailwind 3 (`@custom-variant`, ações `md:opacity-0`);
  # 6. CSS próprio além de `@import`/`@source`, e JS do produto com classe que não é `ss-*`/`is-*` ou estilo inline.
  module Conformidade
    Violacao = Struct.new(:regra, :arquivo, :linha, :trecho) do
      def to_s = "#{arquivo}:#{linha} [#{regra}] #{trecho}"
    end

    PASTAS = %w[app/views app/components app/helpers app/javascript app/assets].freeze

    DAISY = %w[
      btn btn-primary btn-secondary btn-accent btn-ghost btn-link btn-outline btn-sm btn-xs btn-lg btn-circle
      btn-square btn-error btn-success btn-warning btn-info btn-neutral card card-body card-title card-actions badge
      badge-ghost badge-outline badge-primary badge-error badge-success badge-warning badge-info alert alert-error
      alert-success alert-warning alert-info modal modal-box modal-action modal-backdrop dropdown dropdown-content
      dropdown-end menu menu-title navbar drawer drawer-side drawer-content drawer-toggle drawer-overlay input-bordered
      select-bordered textarea-bordered file-input toggle toggle-primary checkbox checkbox-primary radio radio-primary
      tabs tabs-boxed tabs-bordered tab tab-active table table-zebra table-xs table-sm stat stats stat-title stat-value
      stat-desc join join-item loading loading-spinner divider collapse collapse-title collapse-content tooltip avatar
      steps step progress range swap kbd indicator mask base-100 base-200 base-300 base-content bg-base-100 bg-base-200
      bg-base-300 text-base-content primary-content text-primary-content link link-hover label-text form-control
      input-group rounded-box bg-neutral text-neutral-content footer hero hero-content join-vertical skeleton
    ].to_set.freeze

    PALETA = %w[slate gray zinc neutral stone red orange amber yellow lime green emerald teal cyan sky blue indigo violet
                purple fuchsia pink rose white black].freeze
    UTIL = %w[text bg border border-t border-b border-l border-r border-x border-y ring ring-offset from via to fill
              stroke outline divide placeholder decoration shadow accent caret].freeze
    PALETA_RE = /(?<![\w-])(?:[a-z0-9:\[\]&-]+:)?(?:#{UTIL.join('|')})-(?:#{PALETA.join('|')})(?:-\d{2,3})?(?:\/\d+)?(?![\w-])/
    LITERAL_RE = /(?<![&\w])#(?:\h{8}|\h{6}|\h{3,4})\b(?![\w-])|\b(?:rgba?|hsla?|oklch|oklab|lab|lch|hwb)\(/
    TAG_RE = /<(button|input|select|textarea|table|dialog)\b/i
    HELPER_RE = /\b(?:tag\.(?:button|input|select|textarea|table|dialog)\b|content_tag\(?\s*:(?:button|input|select|textarea|table|dialog)\b|button_tag\b|submit_tag\b|(?:text|email|number|password|telephone|url|search|date|datetime_local|time|month|file|color|range)_field_tag\b|select_tag\b|text_area_tag\b|check_box_tag\b|radio_button_tag\b|button_to\b|(?<!ss_)form_with\b|form_for\b|form_tag\b)/
    BUILDER_RE = /\b(?:f|form|ff|builder)\.(?:text_field|email_field|number_field|password_field|telephone_field|url_field|search_field|date_field|datetime_local_field|time_field|month_field|text_area|select|collection_select|check_box|radio_button|collection_radio_buttons|collection_check_boxes|submit|button|file_field|range_field|color_field)\b/
    JS_TAG_RE = /createElement\(\s*["'](button|input|select|textarea|table|dialog)["']/
    HOVER3_RE = /@custom-variant|(?:md|sm|lg):opacity-0|group-hover:opacity|group-focus-within:opacity/
    CHART_RE = /chart\.js|new Chart\(/i
    CLASSES_RE = /class(?:Name)?\s*[:=]\s*(?:"([^"]*)"|'([^']*)'|\[([^\]]*)\])|classList\.(?:add|remove|toggle|replace|contains)\(([^)]*)\)/
    COMENTARIO_RE = %r{\A\s*(#|//|/\*|\*|<%#)}

    module_function

    def verificar(raiz)
      raiz = Pathname(raiz.to_s)
      problemas = []
      gemfile(raiz, problemas)
      arquivos(raiz).each { |f| arquivo(raiz, f, problemas) }
      problemas
    end

    def gemfile(raiz, problemas)
      gem = raiz.join("Gemfile")
      return unless gem.exist?

      texto = gem.read
      linha = texto.lines.grep(/^\s*gem\s+["']componentes_ui["']/)
      if linha.size != 1 || linha.first !~ /tag:\s*["']v\d+\.\d+\.\d+["']/ || linha.first =~ /\b(path|branch|ref):/
        problemas << Violacao.new("gemfile", "Gemfile", 0, "componentes_ui precisa vir por tag: \"vX.Y.Z\"")
      end
      problemas << Violacao.new("gem-antiga", "Gemfile", 0, "minha_suite_ui") if texto.include?("minha_suite_ui")
      lock = raiz.join("Gemfile.lock")
      return unless lock.exist? && lock.read =~ /PATH\n\s+remote: .*\n\s+specs:\n\s+componentes_ui/

      problemas << Violacao.new("gemfile", "Gemfile.lock", 0, "componentes_ui por path no lock")
    end

    def arquivos(raiz)
      PASTAS.flat_map { |d| Dir.glob(raiz.join(d, "**", "*").to_s) }
            .select { |f| File.file?(f) && f !~ %r{app/assets/(builds|images)/} }
            .reject { |f| f =~ /\.(png|jpe?g|gif|webp|ico|svg|woff2?|ttf|otf)\z/ }
            .sort
    end

    def arquivo(raiz, caminho, problemas)
      rel = caminho.delete_prefix("#{raiz}/")
      ext = File.extname(caminho)
      texto = File.read(caminho)
      return css(rel, texto, problemas) if ext == ".css"

      ruby_ou_erb = caminho.end_with?(".erb") || ext == ".rb"
      texto.each_line.with_index(1) do |linha, n|
        add = ->(regra) { problemas << Violacao.new(regra, rel, n, linha.strip[0, 160]) }
        comentario = linha =~ COMENTARIO_RE
        add.("gem-antiga") if linha =~ /\bUi::|minha_suite_ui|MinhaSuiteUi/
        classes(linha).each { |c| add.("daisyui:#{c}") if DAISY.include?(c) } if ruby_ou_erb || ext == ".js"
        add.("cor-paleta") if linha =~ PALETA_RE && !comentario
        add.("cor-literal") if !comentario && cor_literal?(linha, ext)
        add.("tag-crua") if linha =~ TAG_RE
        add.("helper-tag-crua") if ruby_ou_erb && linha =~ HELPER_RE
        add.("campo-fora-do-ss") if ruby_ou_erb && linha =~ BUILDER_RE
        add.("js-tag-crua") if ext == ".js" && linha =~ JS_TAG_RE
        add.("hover-tailwind3") if linha =~ HOVER3_RE
        add.("grafico-fora-da-gem") if linha =~ CHART_RE
        js(linha, add) if ext == ".js"
      end
    end

    def classes(linha)
      linha.scan(CLASSES_RE).flat_map do |m|
        m.compact.join(" ").gsub(/<%.*?%>|#\{[^}]*\}/, " ").scan(%r{[\w:/\[\]-]+}).map { |c| c.split(":").last }
      end
    end

    def cor_literal?(linha, ext)
      sem = linha.gsub(/<%#.*?%>/, "")
      relevante = ext == ".js" || sem =~ /style\s*[:=]|style=|\bcolor\s*[:=]|background|fill|stroke/i || sem =~ /["']#\h{3,8}["']/
      relevante && sem =~ LITERAL_RE && sem !~ /href=["']#|&#\d+;/
    end

    def js(linha, add)
      linha.scan(/classList\.(?:add|remove|toggle|replace|contains)\(([^)]*)\)/).flatten.each do |args|
        args.scan(/["']([^"']+)["']/).flatten.flat_map(&:split).each do |c|
          add.("js-classe-fora-da-gem:#{c}") unless c.start_with?("ss-", "is-")
        end
      end
      add.("js-estilo-inline") if linha =~ /\.style\.(?!setProperty\(["']--)\w+\s*=|\.style\.cssText/
    end

    def css(rel, texto, problemas)
      texto.gsub(%r{/\*.*?\*/}m, "").lines.each_with_index do |l, i|
        l = l.strip
        next if l.empty? || l =~ /\A@(import|source)\s/

        problemas << Violacao.new("css-proprio", rel, i + 1, l[0, 120])
      end
    end
  end
end
