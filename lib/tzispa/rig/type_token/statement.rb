# frozen_string_literal: true

require 'forwardable'

module Tzispa
  module Rig
    module TypeToken

      class Loop < Rig::Token
        extend Forwardable

        attr_reader :id, :body_parser
        def_delegators :@body_parser, :attribute_tags, :loop_parser

        def initialize(parser, type, id, body)
          super(parser, type)
          @id = id.to_sym
          @body = body
        end

        def parse!
          @body_parser = Rig::ParserNext.new(template, text: @body, parent: parser, bindable: true ).parse!
          self
        end

        def render(binder)
          String.new.tap { |text|
            looper = binder.data.send(@id) if binder.data.respond_to?(@id)
            looper&.data&.each { |loop_item|
              text << body_parser.render(loop_item) if loop_item
            } if looper
          }
        end

      end


      class Ife < Rig::Token

        attr_reader :test, :then_parser, :else_parser

        def initialize(parser, type, test, then_body, else_body)
          super(parser, type)
          @test = test.to_sym
          @then_body = then_body
          @else_body = else_body
        end

        def parse!
          @then_parser = Rig::ParserNext.new(template, text: @then_body, parent: parser ).parse!
          @else_parser = @else_body ? Rig::ParserNext.new(template,  text: @else_body, parent: parser ).parse! : nil
          self
        end

        def attribute_tags
          @attribute_tags ||= [test].concat(then_parser.attribute_tags).concat(else_parser&.attribute_tags || Array.new).compact.uniq.freeze
        end

        def loop_parser(id)
          @then_parser.loop_parser(id).concat(else_parser&.loop_parser(id) || Array.new).compact.freeze
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