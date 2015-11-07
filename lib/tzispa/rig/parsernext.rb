require 'forwardable'
require 'tzispa/domain'
require 'tzispa/utils/string'


module Tzispa
  module Rig

    class ParsedEntity
      extend Forwardable

      STRING_EMPTY = ''.freeze
      RE_ANCHOR = /(@@\h+@@)/

      attr_reader :type, :parser
      def_delegators :@parser, :template

      def initialize(parser, type)
        @parser = parser
        @type = type
      end

      def self.instance(parser, type, match)
        case type
        when :metavar
          ParsedMetavar.new parser, type, match[1]
        when :var
          ParsedVar.new parser, type, match[1], match[2]
        when :purl
          ParsedUrl.new parser, type, match[1], match[3]
        when :api
          ParsedApi.new parser, type, match[1], match[2], match[3]
        when :loop
          ParsedLoop.new parser, type, match[1], match[2]
        when :ife
          ParsedIfe.new parser, type, match[1], match[2], match[4]
        when :blk
          ParsedBlock.new parser, type, match[3], match[4]
        when :iblk
          ParsedIBlock.new parser, type, match[7], match[8], match[9], match[10], match[11]
        when :static
          ParsedStatic.new parser, type, match[14], match[15]
        end
      end

      def anchor
        @anchor ||= "@@#{"%x" % object_id}@@".freeze
      end

    end

    class ParsedMetavar < ParsedEntity

      attr_reader :id

      def initialize(parser, type, id)
        super(parser, type)
        @id = id.to_sym
      end

      def render(binder)
        if binder.data.respond_to? @id
          binder.data.send(@id).to_s
        else
          unknown
        end
      end

      private

      def unknown
        @unknown ||= "#{@id}:unknown!!".freeze
      end

    end


    class ParsedVar < ParsedEntity

      attr_reader :id

      def initialize(parser, type, format, id)
        super(parser, type)
        @format = format
        @id = id.to_sym
      end

      def render(binder)
        binder.data.respond_to?(@id) ? binder.data.send(@id).to_s : unknown
      end

      private

      def unknown
        @unknown ||= "#{@id}:unknown!!".freeze
      end

    end


    class ParsedUrl < ParsedEntity

      def initialize(parser, type, path_id, params)
        super(parser, type)
        @path_id = path_id.to_sym
        @params = params
      end

      def render(binder)
        b_params = @params.dup.gsub(RE_ANCHOR) { |match|
          parser.the_parsed.select { |p| p.anchor == match}.first.render(binder)
        } if @params
        binder.context.path @path_id, Parameters.new(b_params).data
      end

    end


    class ParsedApi < ParsedEntity

      attr_reader :handler, :verb, :predicate

      def initialize(parser, type, handler, verb, predicate)
        super(parser, type)
        @handler = handler
        @verb = verb
        @predicate = predicate
      end

      def render(binder)
        b_handler = bind_value @handler.dup, binder
        b_verb = bind_value @verb.dup, binder
        b_predicate = bind_value( @predicate.dup, binder ) if @predicate
        binder.context.api b_handler, b_verb, b_predicate
      end

      private

      def bind_value(value, binder)
        value.gsub(RE_ANCHOR) { |match|
          parser.the_parsed.select { |p| p.anchor == match}.first.render(binder)
        }
      end

    end


    class ParsedLoop < ParsedEntity
      extend Forwardable

      attr_reader :id
      def_delegators :@loop_parser, :attribute_tags, :loop_parser

      def initialize(parser, type, id, body)
        super(parser, type)
        @id = id.to_sym
        @body = body
      end

      def parse!
        @loop_parser = ParserNext.new(template, @body).parse!
        self
      end

      def render(binder)
        looper = binder.data.respond_to?(@id) ? binder.data.send(@id) : nil
        looper ? looper.data.map { |item|
          @loop_parser.render(item)
        }.to_a.join :
        "missing looper for #{@id}".freeze
      end

    end


    class ParsedIfe < ParsedEntity

      attr_reader :test

      def initialize(parser, type, test, then_body, else_body)
        super(parser, type)
        @test = test.to_sym
        @then_body = then_body
        @else_body = else_body
      end

      def parse!
        @then_parser = ParserNext.new( template, @then_body ).parse!
        @else_parser = ParserNext.new( template, @else_body ).parse! if @else_body
        self
      end

      def attribute_tags
        @attribute_tags ||= [@test].concat(@then_parser.attribute_tags).concat(@else_parser? @else_parser.attribute_tags : []).compact.uniq.freeze
      end

      def render(binder)
        test_eval = binder.data.respond_to?(@test) && binder.data.send(@test)
        ifeparser = test_eval ? @then_parser : @else_parser
        ifeparser ? ifeparser.render(binder) : STRING_EMPTY
      end

    end

    class ParsedBlock < ParsedEntity

      def initialize(parser, type, id, params)
        super(parser, type)
        @id = id
        @params = params
      end

      def parse!
        @parsed_block = template.engine.block name: @id, parent: template
        self
      end

      def render(binder)
        blk = @parsed_block.dup
        if @params
          b_params = @params.dup.gsub(RE_ANCHOR) { |match|
            parser.the_parsed.select { |p| p.anchor == match}.first.render(binder)
          }
          blk.params = b_params
        end
        blk.render binder.context
      end

    end

    class ParsedIBlock < ParsedEntity

      def initialize(parser, type, test, id_then, params_then, id_else, params_else)
        super(parser, type)
        @test = test
        @id_then = id_then
        @params_then = params_then
        @id_else = id_else
        @params_else = params_else
      end

      def parse!
        @block_then = template.engine.block name: @id_then, parent: template
        @block_else = template.engine.block name: @id_else, parent: template
        self
      end

      def render(binder)
        if binder.respond_to?(@test) && binder.send(@test)
          blk = @block_then.dup
          if @params_then
            b_params = @params_then.dup.gsub(RE_ANCHOR) { |match|
              parser.the_parsed.select { |p| p.anchor == match}.first.render(binder)
            }
            blk.params = b_params
          end
        else
          blk = @block_else.dup
          if @params_else
            b_params = @params_else.dup.gsub(RE_ANCHOR) { |match|
              parser.the_parsed.select { |p| p.anchor == match}.first.render(binder)
            }
            blk.params = b_params
          end
        end
        blk.render binder.context
      end

    end


    class ParsedStatic < ParsedEntity

      def initialize(parser, type, id, params)
        super(parser, type)
        @id = id
        @params = params
      end

      def parse!
        @parsed_static = template.engine.static name: @id, parent: template
        self
      end

      def render(binder)
        blk = @parsed_static.dup
        if @params
          b_params = @params.dup.gsub(RE_ANCHOR) { |match|
            parser.the_parsed.select { |p| p.anchor == match}.first.render(binder)
          }
          blk.params = b_params
        end
        blk.render binder.context
      end

    end



    class ParserNext

      EMPTY_STRING = ''.freeze

      attr_reader :flags, :template, :the_parsed

      RIG_EMPTY = {
        :flags   => /<flags:(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])\/>/
      }.freeze

      RIG_EXPRESSIONS = {
        :metavar => /\{%([^%]+?)%\}/,
        :var     => /<var(\[%[A-Z]?[0-9]*[a-z]\])?:(\w+)\/>/,
        :purl    => /<purl:(\w+(?:\.\w+)?)(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])?\/>/,
        :api     => /<api:(\w+(?:\.\w+)?):([^:\/]+)(?::([^\/]+))?\/>/
      }.freeze

      RIG_STATEMENTS = {
        :loop    => /<loop:(\w+)>(.*?)<\/loop:\1>/m,
        :ife     => /<ife:(\w+)>(.*?)(<else:\1\/>(.*?))?<\/ife:\1>/m
      }.freeze

      RIG_TEMPLATES = {
        :blk     => /<(blk):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :iblk    => /<(iblk):(\w+):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?:(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :static  => /<(static):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/
      }.freeze

      def initialize(template, text=nil)
        @template = template
        @inner_text = text ? text : template.content
        @the_parsed = Array.new
      end

      def parse!
        @tags = nil
        parse_flags
        if @template.is_block?
          parse_statements
          parse_expressions
        end
        parse_templates
        self
      end

      def render(binder, context=nil)
        text = @inner_text.dup
        @the_parsed.each { |value|
          text.gsub! value.anchor, value.render(binder)
        }
        text
      end

      def attribute_tags
        @attribute_tags ||= @the_parsed.map { |p|
           p.id.to_sym if p.respond_to? :id
         }.concat(@the_parsed.map{ |p|
            p.attribute_tags if p.type==:ife
        }).compact.flatten.uniq.freeze
      end

      def loop_parser(id)
        @the_parsed.select { |p| p.type==:loop && p.id==id}.first
      end

      private

      def parse_flags
        @inner_text.gsub!(RIG_EMPTY[:flags]) { |match|
          @flags = Regexp.last_match(1)
          EMPTY_STRING
        }
      end

      def parse_expressions
        RIG_EXPRESSIONS.each_key { |kre|
          @inner_text.gsub!(RIG_EXPRESSIONS[kre]) { |match|
            pe = ParsedEntity.instance(self, kre, Regexp.last_match )
            @the_parsed << pe
            pe.anchor
          }
        }
      end

      def parse_statements
        RIG_STATEMENTS.each_key { |kre|
          @inner_text.gsub!(RIG_STATEMENTS[kre]) { |match|
            pe = ParsedEntity.instance(self, kre, Regexp.last_match )
            @the_parsed << pe.parse!
            pe.anchor
          }
        }
      end

      def parse_templates
        reTemplates = Regexp.new RIG_TEMPLATES.values.map{ |re| "(#{re})"}.join('|')
        @inner_text.gsub!(reTemplates) { |match|
          type = (Regexp.last_match[2] || '') << (Regexp.last_match[6] || '') << (Regexp.last_match[13] || '')
          pe = ParsedEntity.instance(self, type.to_sym, Regexp.last_match )
          @the_parsed << pe.parse!
          pe.anchor
        }
      end

    end

  end
end
