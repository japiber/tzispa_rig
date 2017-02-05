# frozen_string_literal: true

require 'tzispa/rig/syntax'
require 'tzispa/rig/token/builder'

module Tzispa
  module Rig

    class ParserNext

      EMPTY_STRING = ''

      include Tzispa::Rig::Syntax

      attr_reader :flags, :template, :tokens, :domain, :format, :childrens, :bindable, :content_type

      def initialize(template, text, domain: nil, content_type: nil, bindable: nil, parent: nil)
        @parsed = false
        @template = template
        @inner_text = text.dup
        @domain = domain || parent.domain
        @bindable = bindable.nil? ? parent.bindable : bindable
        @content_type = content_type || parent.content_type
      end

      def empty?
        @tokens.empty?
      end

      def parse!
        unless parsed?
          @attribute_tags  = nil
          @childrens = Array.new
          @tokens = Array.new
          if bindable
            parse_flags
            parse_statements
            parse_expressions
            parse_templates
            parse_url_builder
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
        @inner_text.gsub!(RIG_EMPTY[:flags]) { |match|
          @flags = Regexp.last_match(1)
          EMPTY_STRING
        }
      end

      def parse_url_builder
        RIG_URL_BUILDER.each_key { |kre|
          @inner_text.gsub!(RIG_URL_BUILDER[kre]) { |match|
            pe = Tzispa::Rig::Token::Builder.instance(self, kre, Regexp.last_match )
            @tokens << pe
            pe.anchor
          }
        }
      end

      def parse_expressions
        RIG_EXPRESSIONS.each { |kre, re|
          @inner_text.gsub!(re) { |match|
            pe = Tzispa::Rig::Token::Builder.instance(self, kre, Regexp.last_match )
            @tokens << pe
            pe.anchor
          }
        }
      end

      def parse_statements
        @inner_text.gsub!(RIG_STATEMENTS) { |match|
          type = (Regexp.last_match[2] || String.new) << (Regexp.last_match[6] || String.new)
          pe = Tzispa::Rig::Token::Builder.instance(self, type.to_sym, Regexp.last_match )
          @tokens << pe.parse!
          pe.anchor
        }
      end

      def parse_templates
        reTemplates = Regexp.new RIG_TEMPLATES.values.map{ |re| "(#{re})"}.join('|')
        @inner_text.gsub!(reTemplates) { |match|
          type = (Regexp.last_match[2] || String.new) << (Regexp.last_match[6] || String.new) << (Regexp.last_match[13] || String.new)
          pe = Tzispa::Rig::Token::Builder.instance(self, type.to_sym, Regexp.last_match )
          @tokens << pe.parse!
          pe.anchor
        }
      end

    end

  end
end
