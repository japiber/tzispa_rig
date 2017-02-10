# frozen_string_literal: true

require 'tzispa/utils/string'

module Tzispa
  module Rig
    module TypeToken

      class Meta < Rig::Token

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
          @unknown ||= "#{@id}"
        end

      end


      class Var < Rig::Token
        using Tzispa::Utils

        attr_reader :id

        def initialize(parser, type, format, id)
          super(parser, type)
          @format = format
          @id = id.to_sym
        end

        def render(binder)
          if binder.data.respond_to?(@id)
            value = binder.data.send(@id).to_s
            value.send(parser.content_escape_method) rescue value
          else
            unknown
          end
        end

        private

        def unknown
          @unknown ||= "#{@id}"
        end

      end

    end
  end
end