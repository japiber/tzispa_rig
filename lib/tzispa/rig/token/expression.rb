# frozen_string_literal: true

require 'tzispa/rig/token/builder'

module Tzispa
  module Rig
    module Token

      class Meta < Builder

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


      class Var < Builder

        attr_reader :id

        def initialize(parser, type, format, id)
          super(parser, type)
          @format = format
          @id = id.to_sym
        end

        def render(binder)
          if binder.data.respond_to?(@id)
            value = binder.data.send(@id).to_s
            escaper = :"escape_#{parser.content_type}"
            respond_to?(escaper) ? send(escaper, value) : value
          else
            unknown
          end
        end

        private

        def unknown
          @unknown ||= "#{@id}".freeze
        end

      end

    end
  end
end