# frozen_string_literal: true

require 'forwardable'

module Tzispa
  module Rig
    module Tokens

      class Loop < Rig::Token
        extend Forwardable

        attr_reader :id, :body_parser
        def_delegators :@body_parser, :attribute_tags, :loop_token

        def initialize(parser, match)
          super(parser, :loop)
          @id = match[3].to_sym
          @body = match[4]
        end

        def parse!
          @body_parser = Rig::ParserNext.new template: template,
                                             text: @body,
                                             parent: parser,
                                             bindable: true
          @body_parser.parse!
          self
        end

        def render(binder)
          String.new.tap do |text|
            looper = binder.data.send(@id) if binder.data.respond_to?(@id)
            looper&.data&.each do |loop_item|
              text << body_parser.render(loop_item) if loop_item
            end
          end
        end
      end

      class Ife < Rig::Token
        attr_reader :test, :then_parser, :else_parser

        def initialize(parser, match)
          super(parser, :ife)
          @test = match[7].to_sym
          @then_body = match[8]
          @else_body = match[10]
        end

        def parse!
          @then_parser = Rig::ParserNext.new(template: template,
                                             text: @then_body,
                                             parent: parser).parse!
          @else_parser = if @else_body
                           Rig::ParserNext.new(template: template,
                                               text: @else_body,
                                               parent: parser).parse!
                         end
          self
        end

        def attribute_tags
          @attribute_tags ||= begin
                               att = [test].concat(then_parser.attribute_tags)
                               att.concat(else_parser&.attribute_tags || [])
                               att.compact.uniq.freeze
                             end
        end

        def loop_token(id)
          lpp = then_parser.loop_token(id)
          lpp.concat(else_parser&.loop_token(id) || [])
          lpp.compact.freeze
        end

        def render(binder)
          test_eval = binder.data && binder.data.respond_to?(test) && binder.data.send(test)
          ifeparser = test_eval ? then_parser : else_parser
          ifeparser ? ifeparser.render(binder) : ''
        end
      end

    end
  end
end
