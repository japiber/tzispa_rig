# frozen_string_literal: true

module Tzispa
  module Rig
    module TypeToken

      class Url < Rig::Token

        attr_reader :layout, :params, :app_name

        def initialize(parser, type, layout, params, app_name = nil)
          super(parser, type)
          @layout = layout
          @params = params
          @app_name = app_name&.to_sym
        end

        def render(binder)
          b_layout = bind_value(@layout.dup, binder).to_sym
          h_params = Rig::Parameters.new(bind_value(@params&.dup, binder)).to_h
          case type
          when :purl
            render_purl(binder, app_name, b_layout, h_params)
          when :url
            render_url(binder, app_name, b_layout, h_params)
          end
        end

        def render_purl(binder, app_name, b_layout, h_params)
          app_name ?
            binder.context.app_layout_path(app_name, b_layout, h_params) :
            binder.context.layout_path(b_layout, h_params)
        end

        def render_url(binder, app_name, b_layout, h_params)
          app_name ?
            binder.context.app_layout_canonical_url(app_name, b_layout, h_params) :
            binder.context.layout_canonical_url(b_layout, h_params)
        end

        def bind_value(value, binder)
          value&.gsub(RE_ANCHOR) { |match|
            parser.tokens.select { |p| p.anchor == match}.first.render(binder)
          }
        end

      end


      class Api < Rig::Token

        attr_reader :handler, :verb, :predicate, :app_name

        def initialize(parser, type, handler, verb, predicate, sufix, app_name = nil)
          super(parser, type)
          @handler = handler
          @verb = verb
          @predicate = predicate
          @sufix = sufix
          @app_name = app_name&.to_sym
        end

        def render(binder)
          b_handler = bind_value @handler.dup, binder
          b_verb = bind_value @verb.dup, binder
          b_predicate = bind_value( @predicate.dup, binder ) if @predicate
          b_sufix = bind_value( @sufix.dup, binder ) if @sufix
          binder.context.send(type.to_sym, b_handler, b_verb, b_predicate, b_sufix, app_name)
        end

        private

        def bind_value(value, binder)
          value.gsub(RE_ANCHOR) { |match|
            parser.tokens.select { |p| p.anchor == match}.first.render(binder)
          }
        end

      end

    end
  end
end
