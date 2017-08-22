# frozen_string_literal: true

module Tzispa
  module Rig
    module Tokens

      class Blk < Rig::Token
        attr_reader :id, :params

        def initialize(parser, match)
          super(parser, :blk)
          @id = match[3]
          @params = match[4]
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
          value.gsub(RE_ANCHOR) do |match|
            anchor = parser.tokens.select { |p| p.anchor == match }
            anchor.first.render(binder)
          end
        end

        def obtain_block(id)
          case id
          when '__empty__'
            Rig::Factory.empty
          when template&.id
            # to avoid infinite recursion
            if template&.type == :block
              template
            else
              Rig::Factory.block(name: id, domain: domain, content_type: content_type)
            end
          else
            Rig::Factory.block(name: id, domain: domain, content_type: content_type)
          end
        end
      end

      class Iblk < Rig::Token
        attr_reader :id, :id_then, :params_then, :id_else, :params_else

        def initialize(parser, match)
          super(parser, :iblk)
          @id = match[7]
          @id_then = match[8]
          @params_then = match[9]
          @id_else = match[10]
          @params_else = match[11]
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
            Rig::Factory.empty
          when template&.id
            # to avoid infinite recursion
            if template&.type == :block
              template
            else
              Rig::Factory.block(name: id, domain: domain, content_type: content_type)
            end
          else
            Rig::Factory.block(name: id, domain: domain, content_type: content_type)
          end
        end

        def bind_value(value, binder)
          value.gsub(RE_ANCHOR) do |match|
            anchor = parser.tokens.select { |p| p.anchor == match }
            anchor.first.render(binder)
          end
        end
      end

      class Static < Rig::Token
        attr_reader :id, :params

        def initialize(parser, match)
          super(parser, :static)
          @id = match[14]
          @params = match[15]
        end

        def parse!
          @parsed_static = Tzispa::Rig::Factory.static name: @id,
                                                       domain: domain,
                                                       content_type: content_type
          parser.childrens << @parsed_static
          self
        end

        def render(binder)
          blk = @parsed_static.dup
          blk.params = bind_value(@params.dup, binder) if @params
          blk.render binder.context
        end

        private

        def bind_value(value, binder)
          value.gsub(RE_ANCHOR) do |match|
            anchor = parser.tokens.select { |p| p.anchor == match }
            anchor.first.render(binder)
          end
        end
      end

    end
  end
end
