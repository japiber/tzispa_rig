# frozen_string_literal: true

require 'tzispa/rig/token/builder'
require 'tzispa/rig/engine'

module Tzispa
  module Rig
    module Token

      class Block < Builder

        attr_reader :id, :params

        def initialize(parser, type, id, params)
          super(parser, type)
          @id = id
          @params = params
        end

        def parse!
          # to avoid infinite recursion
          @parsed_block = obtain_block @id
          parser.childrens << @parsed_block
          self
        end

        def render(binder)
          blk = @parsed_block.dup
          blk.params = bind_value(@params.dup, binder) if @params
          blk.render binder.context
        end

        private

        def bind_value(value, binder)
          value.gsub(RE_ANCHOR) { |match|
            parser.tokens.select { |p| p.anchor == match}.first.render(binder)
          }
        end

        def obtain_block(id)
          case id
          when '__empty__'
            Rig::Engine.empty
          when template.id
            # to avoid infinite recursion
            template.type == :block ?
              template :
              Rig::Engine.block(name: id, domain: domain, content_type: content_type)
          else
            Rig::Engine.block(name: id, domain: domain, content_type: content_type)
          end
        end


      end


      class IBlock < Builder

        attr_reader :id, :id_then, :params_then, :id_else, :params_else

        def initialize(parser, type, test, id_then, params_then, id_else, params_else)
          super(parser, type)
          @id = test
          @id_then = id_then
          @params_then = params_then
          @id_else = id_else
          @params_else = params_else
        end

        def parse!
          @block_then = obtain_block @id_then
          @block_else = obtain_block @id_else
          parser.childrens << @block_then << @block_else
          self
        end

        def render(binder)
          if binder.data.respond_to?(@id) && binder.data.send(@id)
            blk = @block_then.dup
            blk.params = bind_value(@params_then.dup, binder) if @params_then
          else
            blk = @block_else.dup
            blk.params = bind_value(@params_else.dup, binder) if @params_else
          end
          blk.render binder.context
        end

        private

        def obtain_block(id)
          case id
          when '__empty__'
            Rig::Engine.empty
          when template.id
            # to avoid infinite recursion
            template.type == :block ?
              template :
              Rig::Engine.block(name: id, domain: domain, content_type: content_type)
          else
            Rig::Engine.block(name: id, domain: domain, content_type: content_type)
          end
        end

        def bind_value(value, binder)
          value.gsub(RE_ANCHOR) { |match|
            parser.tokens.select { |p| p.anchor == match}.first.render(binder)
          }
        end

      end


      class Static < Builder

        attr_reader :id, :params

        def initialize(parser, type, id, params)
          super(parser, type)
          @id = id
          @params = params
        end

        def parse!
          @parsed_static = Tzispa::Rig::Engine.static name: @id, domain: domain, content_type: content_type
          parser.childrens << @parsed_static
          self
        end

        def render(binder)
          blk = @parsed_static.dup
          if @params
            b_params = @params.dup.gsub(RE_ANCHOR) { |match|
              parser.tokens.select { |p| p.anchor == match}.first.render(binder)
            }
            blk.params = b_params
          end
          blk.render binder.context
        end

      end


    end
  end
end