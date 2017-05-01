# frozen_string_literal: true

require 'tzispa/rig/syntax'

module Tzispa
  module Rig

    class ParserNext
      EMPTY_STRING = ''

      include Tzispa::Rig::Syntax

      attr_reader :flags, :template, :tokens, :domain, :format,
                  :childrens, :content_type, :inner_text

      def initialize(opts = {})
        @parsed = false
        @template = opts[:template] if opts.key?(:template)
        @inner_text = (opts[:text] || template&.content)&.dup
        parent = opts[:parent]
        @domain = opts[:domain] || parent.domain
        @bindable = opts.key?(:bindable) ? opts[:bindable] : parent.bindable?
        @content_type = opts[:content_type] || parent.content_type
      end

      def empty?
        @tokens.empty?
      end

      def bindable?
        @bindable
      end

      def parsed?
        @parsed
      end

      def parse!
        unless parsed?
          @attribute_tags = nil
          @childrens = []
          @tokens = []
          parse_flags
          if bindable?
            parse_statements
            parse_expressions
            parse_url_builder
            parse_templates
          end
          @parsed = true
        end
        self
      end

      def content_escape_method
        @content_escape_method ||= :"escape_#{content_type}"
      end

      def render(binder)
        @inner_text.dup.tap do |text|
          @tokens.each { |value| text.gsub! value.anchor, value.render(binder) }
        end.freeze
      end

      def attribute_tags
        @at_tags ||= begin
                      att = tokens.select { |tk| tk.respond_to? :id }
                      att = att.map { |p| p.id.to_sym }
                      att.concat(
                        tokens.map { |p| p.attribute_tags if p.type == :ife }
                      ).compact.flatten.uniq.freeze
                    end
      end

      def loop_token(id)
        lpp = tokens.select { |p| p.type == :loop && p.id == id }
        lpp.concat(
          tokens.select { |p| p.type == :ife }.map do |p|
            p.loop_token(id)
          end.flatten.compact
        )
      end

      private

      def parse_flags
        while (match = @inner_text.match RIG_EMPTY[:flags])
          @flags = Regexp.last_match(1)
          @inner_text.gsub! match[0], ''
        end
      end

      def parse_url_builder
        RIG_URL_BUILDER.each_key do |kre|
          while (match = @inner_text.match RIG_URL_BUILDER[kre])
            tk = Token.instance(self, kre, match)
            @tokens << tk
            @inner_text.gsub! match[0], tk.anchor
          end
        end
      end

      def parse_expressions
        RIG_EXPRESSIONS.each do |kre, re|
          while (match = @inner_text.match re)
            tk = Token.instance(self, kre, match)
            @tokens << tk
            @inner_text.gsub! match[0], tk.anchor
          end
        end
      end

      def parse_statements
        while (match = @inner_text.match RIG_STATEMENTS)
          type = String.new << (match[2] || match[6])
          tk = Token.instance(self, type.to_sym, match)
          @tokens << tk.parse!
          @inner_text.gsub! match[0], tk.anchor
        end
      end

      def parse_templates
        while (match = @inner_text.match RIG_TEMPLATES)
          type = String.new << (match[2] || match[6] || match[13])
          tk = Token.instance(self, type.to_sym, match)
          @tokens << tk.parse!
          @inner_text.gsub! match[0], tk.anchor
        end
      end
    end

  end
end
