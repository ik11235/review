#
# Copyright (c) 2002-2008 Minero Aoki
#               2009-2016 Minero Aoki, Kenshi Muto
#
# This program is free software.
# You can distribute or modify this program under the terms of
# the GNU LGPL, Lesser General Public License version 2.1.
# For details of the GNU LGPL, see the file "COPYING".
#
require 'review/book/compilable'
module ReVIEW
  module Book
    class Chapter
      include Compilable

      attr_reader :number, :book

      def initialize(book, number, name, path, io = nil)
        @book = book
        @number = number
        @name = name
        @path = path
        @io = io
        @title = nil
        if @io
          begin
            @content = @io.read
          rescue
            @content = nil
          end
        else
          @content = nil
        end
        if !@content && @path && File.exist?(@path)
          @content = File.read(@path).sub(/\A\xEF\xBB\xBF/u, '')
          @number = nil if ['nonum', 'nodisp', 'notoc'].include?(check_header)
        end
        @list_index = nil
        @table_index = nil
        @footnote_index = nil
        @image_index = nil
        @icon_index = nil
        @numberless_image_index = nil
        @indepimage_index = nil
        @headline_index = nil
        @column_index = nil
        @volume = nil
      end

      def check_header
        f = LineInput.new(Preprocessor::Strip.new(StringIO.new(@content)))
        while f.next?
          case f.peek
          when /\A=+[\[\s\{]/
            m = /\A(=+)(?:\[(.+?)\])?(?:\{(.+?)\})?(.*)/.match(f.gets)
            return m[2] # tag
          when %r</\A//[a-z]+/>
            line = f.gets
            if line.rstrip[-1,1] == "{"
              f.until_match(%r<\A//\}>)
            end
          end
          f.gets
        end
        nil
      end

      def inspect
        "\#<#{self.class} #{@number} #{@path}>"
      end

      def format_number(heading = true)
        return "" unless @number

        if on_PREDEF?
          return "#{@number}"
        end

        if on_APPENDIX?
          return "#{@number}" if @number < 1 || @number > 27

          i18n_appendix = I18n.get("appendix")
          fmt = i18n_appendix.scan(/%p\w/).first || "%s"

          # Backward compatibility
          if @book.config["appendix_format"]
            type = @book.config["appendix_format"].downcase.strip
            case type
            when "roman"
              fmt = "%pR"
            when "alphabet", "alpha"
              fmt = "%pA"
            else
              fmt = "%s"
            end
            I18n.update({"appendix" => i18n_appendix.gsub(/%\w\w?/, fmt)})
          end

          I18n.update({"appendix_without_heading" => fmt})

          if heading
            return I18n.t("appendix", @number)
          else
            return I18n.t("appendix_without_heading", @number)
          end
        end

        if heading
          "#{I18n.t("chapter", @number)}"
        else
          "#{@number}"
        end
      end

      def on_CHAPS?
        on_FILE?(@book.read_CHAPS)
      end

      def on_PREDEF?
        on_FILE?(@book.read_PREDEF)
      end

      def on_APPENDIX?
        on_FILE?(@book.read_APPENDIX)
      end

      def on_POSTDEF?
        on_FILE?(@book.read_POSTDEF)
      end

      private
      def on_FILE?(contents)
        contents.lines.map(&:strip).include?("#{id()}#{@book.ext()}")
      end
    end
  end
end
