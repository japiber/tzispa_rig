# frozen_string_literal: true

require 'tzispa/rig/syntax'

module Tzispa
  module Rig

    class ParserNext

      EMPTY_STRING = ''

      include Tzispa::Rig::Syntax

      attr_reader :flags, :template, :tokens, :domain, :format, :childrens,
                  :bindable, :content_type, :inner_text, :content_escape_method

      def initialize(template = nil, text: nil, domain: nil, content_type: nil, bindable: nil, parent: nil)
        @parsed = false
        @template = template
        @inner_text = (text || template&.content)&.dup
        @domain = domain || parent.domain
        @bindable = bindable.nil? ? parent.bindable : bindable
        @content_type = content_type || parent.content_type
        @content_escape_method = :"escape_#{content_type}"
      end

      def empty?
        @tokens.empty?
      end

      def parse!
        unless parsed?
          @attribute_tags  = nil
          @childrens = Array.new
          @tokens = Array.new
          parse_flags
          if bindable
            parse_statements
            parse_expressions
            parse_url_builder
            parse_templates
          end
          @parsed = true
        end
        self
      end

      def parsed?
        @parsed
      end

      def render(binder)
        @inner_text.dup.tap { |text|
          @tokens.each { |value|
            text.gsub! value.anchor, value.render(binder)
          }
        }.freeze
      end

      def attribute_tags
        @attribute_tags ||= tokens.map { |p|
           p.id.to_sym if p.respond_to? :id
         }.concat(
            tokens.map{ |p|
              p.attribute_tags if p.type == :ife
            }
          ).compact.flatten.uniq.freeze
      end

      def loop_parser(id)
        tokens.select{ |p|
          p.type==:loop && p.id==id
        }.concat(
          tokens.select{ |p|
            p.type==:ife }.map {
               |p| p.loop_parser(id)
             }.flatten.compact
        )
      end

      private

      def parse_flags
        while match = @inner_text.match(RIG_EMPTY[:flags]) do
          @flags = Regexp.last_match(1)
          @inner_text.gsub! match[0], ''
        end
      end

      def parse_url_builder
        RIG_URL_BUILDER.each_key { |kre|
          while match = @inner_text.match(RIG_URL_BUILDER[kre]) do
            tk = Token.instance(self, kre, match )
            @tokens << tk
            @inner_text.gsub! match[0], tk.anchor
          end
        }
      end

      def parse_expressions
        RIG_EXPRESSIONS.each { |kre, re|
          while match = @inner_text.match(re) do
            tk = Token.instance(self, kre, match )
            @tokens << tk
            @inner_text.gsub! match[0], tk.anchor
          end
        }
      end

      def parse_statements
        while match = @inner_text.match(RIG_STATEMENTS) do
          type = (match[2] || String.new) << (match[6] || String.new)
          tk = Token.instance(self, type.to_sym, match )
          @tokens << tk.parse!
          @inner_text.gsub! match[0], tk.anchor
        end
      end

      def parse_templates
        while match = @inner_text.match(RIG_TEMPLATES) do
          type = (match[2] || String.new) << (match[6] || String.new) << (match[13] || String.new)
          tk = Token.instance(self, type.to_sym, match )
          @tokens << tk.parse!
          @inner_text.gsub! match[0], tk.anchor
        end
      end

    end

  end
end
