# frozen_string_literal: true

require 'tzispa/utils/string'

module Tzispa
  module Rig
    module Tokens

      class Meta < Rig::Token
        attr_reader :id

        def initialize(parser, match)
          super(parser, :meta)
          @id = match[1].to_sym
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
          @unknown ||= id.to_s
        end
      end

      class Var < Rig::Token
        using Tzispa::Utils::TzString

        attr_reader :id

        def initialize(parser, match)
          super(parser, :var)
          @format = match[1]
          @id = match[2].to_sym
        end

        def render(binder)
          if binder.data.respond_to?(id)
            value = binder.data.send(id).to_s
            begin
              value.send(parser.content_escape_method)
            rescue
              value
            end
          else
            unknown
          end
        end

        private

        def unknown
          @unknown ||= @id.to_s
        end
      end

    end
  end
end
