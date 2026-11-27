module ComponentesUi
  # v1.12.0: gerador de QR Code pequeno e puro (sem gem), para o Pix copia e cola e o QR da consulta da NF-e.
  # Modo byte (UTF-8), versões 1 a 40, correção L/M/Q/H (padrão M, a do Pix) e a máscara de menor penalidade,
  # como a especificação ISO/IEC 18004 (a mesma conta do gerador de Nayuki). O SsQrCode do Flutter faz a mesma
  # matriz para o mesmo texto (o teste dos dois lados confere).
  #
  #   ComponentesUi::Qr.encode("000201…")       # => [[true, false, …], …] (linhas; true = escuro)
  #   ComponentesUi::Qr.svg("000201…")          # => "<svg …>" (um <path> só, com a margem de 4 módulos)
  module Qr
    ECC = { l: 1, m: 0, q: 3, h: 2 }.freeze
    ECC_INDEX = { l: 0, m: 1, q: 2, h: 3 }.freeze
    ECC_CODEWORDS_PER_BLOCK = [
      [-1, 7, 10, 15, 20, 26, 18, 20, 24, 30, 18, 20, 24, 26, 30, 22, 24, 28, 30, 28, 28, 28, 28, 30, 30, 26, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
      [-1, 10, 16, 26, 18, 24, 16, 18, 22, 22, 26, 30, 22, 22, 24, 24, 28, 28, 26, 26, 26, 26, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28, 28],
      [-1, 13, 22, 18, 26, 18, 24, 18, 22, 20, 24, 28, 26, 24, 20, 30, 24, 28, 28, 26, 30, 28, 30, 30, 30, 30, 28, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
      [-1, 17, 28, 22, 16, 22, 28, 26, 26, 24, 28, 24, 28, 22, 24, 24, 30, 28, 28, 26, 28, 30, 24, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30]
    ].freeze
    NUM_BLOCKS = [
      [-1, 1, 1, 1, 1, 1, 2, 2, 2, 2, 4, 4, 4, 4, 4, 6, 6, 6, 6, 7, 8, 8, 9, 9, 10, 12, 12, 12, 13, 14, 15, 16, 17, 18, 19, 19, 20, 21, 22, 24, 25],
      [-1, 1, 1, 1, 2, 2, 4, 4, 4, 5, 5, 5, 8, 9, 9, 10, 10, 11, 13, 14, 16, 17, 17, 18, 20, 21, 23, 25, 26, 28, 29, 31, 33, 35, 37, 38, 40, 43, 45, 47, 49],
      [-1, 1, 1, 2, 2, 4, 4, 6, 6, 8, 8, 8, 10, 12, 16, 12, 17, 16, 18, 21, 20, 23, 23, 25, 27, 29, 34, 34, 35, 38, 40, 43, 45, 48, 51, 53, 56, 59, 62, 65, 68],
      [-1, 1, 1, 2, 4, 4, 4, 5, 6, 8, 8, 11, 11, 16, 16, 18, 16, 19, 21, 25, 25, 25, 34, 30, 32, 35, 37, 40, 42, 45, 48, 51, 54, 57, 60, 63, 66, 70, 74, 77, 81]
    ].freeze

    class TooLong < ArgumentError; end

    module_function

    # A matriz do QR de [text] (linhas de booleanos, true = módulo escuro).
    def encode(text, ecl: :m)
      Encoder.new(text.to_s.b.bytes, ecl.to_sym).modules
    end

    # SVG do QR: um <path> com os módulos escuros (fill = currentColor) e a zona de silêncio de [margin] módulos.
    def svg(text, ecl: :m, margin: 4, label: nil)
      m = encode(text, ecl:)
      n = m.size + margin * 2
      d = +""
      m.each_with_index do |row, y|
        x = 0
        while x < row.size
          if row[x]
            run = 1
            run += 1 while x + run < row.size && row[x + run]
            d << "M#{x + margin} #{y + margin}h#{run}v1h-#{run}z"
            x += run
          else
            x += 1
          end
        end
      end
      aria = label ? %( role="img" aria-label="#{ERB::Util.h(label)}") : %( aria-hidden="true")
      %(<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 #{n} #{n}" class="ss-qr-svg" shape-rendering="crispEdges"#{aria}>) +
        %(<path fill="currentColor" d="#{d}"/></svg>)
    end

    class Encoder
      attr_reader :modules

      def initialize(bytes, ecl)
        raise ArgumentError, "ecl: #{ecl} (use :l, :m, :q ou :h)" unless ECC.key?(ecl)

        @ecl = ecl
        @version = (1..40).find { |v| bytes.size * 8 + 4 + (v < 10 ? 8 : 16) <= data_codewords(v) * 8 }
        raise TooLong, "texto longo demais para um QR (#{bytes.size} bytes)" unless @version

        @size = @version * 4 + 17
        @modules = Array.new(@size) { Array.new(@size, false) }
        @function = Array.new(@size) { Array.new(@size, false) }
        draw_function_patterns
        draw_codewords(add_ecc(data_bits(bytes)))
        best = (0..7).min_by do |mask|
          apply_mask(mask)
          draw_format(mask)
          p = penalty
          apply_mask(mask)
          p
        end
        apply_mask(best)
        draw_format(best)
      end

      private

      def raw_modules(v)
        r = (16 * v + 128) * v + 64
        if v >= 2
          na = v / 7 + 2
          r -= (25 * na - 10) * na - 55
          r -= 36 if v >= 7
        end
        r
      end

      def data_codewords(v) = raw_modules(v) / 8 - ECC_CODEWORDS_PER_BLOCK[ECC_INDEX[@ecl]][v] * NUM_BLOCKS[ECC_INDEX[@ecl]][v]

      def data_bits(bytes)
        bits = []
        push = ->(val, n) { (n - 1).downto(0) { |i| bits << ((val >> i) & 1) } }
        push.(4, 4)
        push.(bytes.size, @version < 10 ? 8 : 16)
        bytes.each { |b| push.(b, 8) }
        cap = data_codewords(@version) * 8
        push.(0, [4, cap - bits.size].min)
        push.(0, (8 - bits.size % 8) % 8)
        pad = [0xEC, 0x11]
        i = 0
        while bits.size < cap
          push.(pad[i % 2], 8)
          i += 1
        end
        bits.each_slice(8).map { |s| s.inject(0) { |a, b| (a << 1) | b } }
      end

      def gf_mul(x, y)
        z = 0
        7.downto(0) do |i|
          z = (z << 1) ^ ((z >> 7) * 0x11D)
          z ^= ((y >> i) & 1) * x
        end
        z & 0xFF
      end

      def rs_divisor(degree)
        r = Array.new(degree - 1, 0) + [1]
        root = 1
        degree.times do
          r.size.times do |j|
            r[j] = gf_mul(r[j], root)
            r[j] ^= r[j + 1] if j + 1 < r.size
          end
          root = gf_mul(root, 0x02)
        end
        r
      end

      def rs_remainder(data, div)
        r = Array.new(div.size, 0)
        data.each do |b|
          f = b ^ r.shift
          r << 0
          div.each_with_index { |c, i| r[i] ^= gf_mul(c, f) }
        end
        r
      end

      def add_ecc(data)
        e = ECC_INDEX[@ecl]
        nb = NUM_BLOCKS[e][@version]
        ecc_len = ECC_CODEWORDS_PER_BLOCK[e][@version]
        raw = raw_modules(@version) / 8
        short = nb - raw % nb
        short_len = raw / nb
        div = rs_divisor(ecc_len)
        k = 0
        blocks = (0...nb).map do |i|
          len = short_len - ecc_len + (i < short ? 0 : 1)
          dat = data[k, len]
          k += len
          ecc = rs_remainder(dat, div)
          dat += [0] if i < short
          dat + ecc
        end
        out = []
        blocks[0].size.times do |i|
          blocks.each_with_index { |b, j| out << b[i] if i != short_len - ecc_len || j >= short }
        end
        out
      end

      def set_fn(x, y, dark)
        @modules[y][x] = dark
        @function[y][x] = true
      end

      def align_positions
        return [] if @version == 1

        na = @version / 7 + 2
        step = (@version * 8 + na * 3 + 5) / (na * 4 - 4) * 2
        r = [6]
        pos = @size - 7
        (na - 1).times do
          r.insert(1, pos)
          pos -= step
        end
        r
      end

      def draw_function_patterns
        @size.times do |i|
          set_fn(6, i, i.even?)
          set_fn(i, 6, i.even?)
        end
        [[3, 3], [@size - 4, 3], [3, @size - 4]].each do |x, y|
          (-4..4).each do |dy|
            (-4..4).each do |dx|
              xx, yy = x + dx, y + dy
              next unless xx.between?(0, @size - 1) && yy.between?(0, @size - 1)

              dist = [dx.abs, dy.abs].max
              set_fn(xx, yy, dist != 2 && dist != 4)
            end
          end
        end
        pos = align_positions
        n = pos.size
        n.times do |i|
          n.times do |j|
            next if (i.zero? && j.zero?) || (i.zero? && j == n - 1) || (i == n - 1 && j.zero?)

            (-2..2).each { |dy| (-2..2).each { |dx| set_fn(pos[i] + dx, pos[j] + dy, [dx.abs, dy.abs].max != 1) } }
          end
        end
        draw_format(0)
        draw_version
      end

      def bit(v, i) = ((v >> i) & 1) != 0

      def draw_format(mask)
        data = (ECC[@ecl] << 3) | mask
        rem = data
        10.times { rem = (rem << 1) ^ ((rem >> 9) * 0x537) }
        bits = ((data << 10) | rem) ^ 0x5412
        (0..5).each { |i| set_fn(8, i, bit(bits, i)) }
        set_fn(8, 7, bit(bits, 6))
        set_fn(8, 8, bit(bits, 7))
        set_fn(7, 8, bit(bits, 8))
        (9..14).each { |i| set_fn(14 - i, 8, bit(bits, i)) }
        (0..7).each { |i| set_fn(@size - 1 - i, 8, bit(bits, i)) }
        (8..14).each { |i| set_fn(8, @size - 15 + i, bit(bits, i)) }
        set_fn(8, @size - 8, true)
      end

      def draw_version
        return if @version < 7

        rem = @version
        12.times { rem = (rem << 1) ^ ((rem >> 11) * 0x1F25) }
        bits = (@version << 12) | rem
        18.times do |i|
          b = bit(bits, i)
          a = @size - 11 + i % 3
          c = i / 3
          set_fn(a, c, b)
          set_fn(c, a, b)
        end
      end

      def draw_codewords(data)
        i = 0
        right = @size - 1
        while right >= 1
          right = 5 if right == 6
          @size.times do |vert|
            2.times do |j|
              x = right - j
              up = ((right + 1) & 2).zero?
              y = up ? @size - 1 - vert : vert
              next if @function[y][x] || i >= data.size * 8

              @modules[y][x] = bit(data[i >> 3], 7 - (i & 7))
              i += 1
            end
          end
          right -= 2
        end
      end

      def apply_mask(mask)
        @size.times do |y|
          @size.times do |x|
            inv = case mask
                  when 0 then (x + y).even?
                  when 1 then y.even?
                  when 2 then (x % 3).zero?
                  when 3 then ((x + y) % 3).zero?
                  when 4 then ((x / 3 + y / 2) % 2).zero?
                  when 5 then (x * y % 2 + x * y % 3).zero?
                  when 6 then ((x * y % 2 + x * y % 3) % 2).zero?
                  else (((x + y) % 2 + x * y % 3) % 2).zero?
                  end
            @modules[y][x] ^= true if inv && !@function[y][x]
          end
        end
      end

      def add_history(run, hist)
        run += @size if hist[0].zero?
        hist.pop
        hist.unshift(run)
      end

      def count_patterns(h)
        n = h[1]
        core = n.positive? && h[2] == n && h[3] == n * 3 && h[4] == n && h[5] == n
        (core && h[0] >= n * 4 && h[6] >= n ? 1 : 0) + (core && h[6] >= n * 4 && h[0] >= n ? 1 : 0)
      end

      def terminate(color, run, hist)
        if color
          add_history(run, hist)
          run = 0
        end
        add_history(run + @size, hist)
        count_patterns(hist)
      end

      def line_penalty(get)
        r = 0
        @size.times do |a|
          color = false
          run = 0
          hist = Array.new(7, 0)
          @size.times do |b|
            if get.(a, b) == color
              run += 1
              if run == 5 then r += 3
              elsif run > 5 then r += 1
              end
            else
              add_history(run, hist)
              r += count_patterns(hist) * 40 unless color
              color = get.(a, b)
              run = 1
            end
          end
          r += terminate(color, run, hist) * 40
        end
        r
      end

      def penalty
        r = line_penalty(->(y, x) { @modules[y][x] }) + line_penalty(->(x, y) { @modules[y][x] })
        (@size - 1).times do |y|
          (@size - 1).times do |x|
            c = @modules[y][x]
            r += 3 if c == @modules[y][x + 1] && c == @modules[y + 1][x] && c == @modules[y + 1][x + 1]
          end
        end
        dark = @modules.sum { |row| row.count(true) }
        total = @size * @size
        k = ((dark * 20 - total * 10).abs + total - 1) / total - 1
        r + k * 10
      end
    end
  end
end
