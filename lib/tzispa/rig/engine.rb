# frozen_string_literal: true

require 'tzispa/rig'
require 'lru_redux'


module Tzispa
  module Rig

    class Engine

      attr_reader :app

      def initialize(app, cache_enabled, cache_size)
        @app = app
        @cache = LruRedux::ThreadSafeCache.new(cache_size) if cache_enabled
      end

      def layout(name:, format:nil, params:nil)
        rig_template name, :layout, format, params, nil
      end

      def block(name:, format:nil, params:nil, parent:nil)
        rig_template name, :block, format, params, parent
      end

      def static(name:, format:nil, params:nil, parent:nil)
        rig_template name, :static, format, params, parent
      end

      def rig_template(name, type, tpl_format, params, parent)
        if @cache
          cache_template(name, type, tpl_format, params, parent)
        else
          Template.new(name: name, type: type, format: tpl_format, domain: @app.domain, params: params, parent: parent, engine: self).load!.parse!
        end
      end

      private

      def cache_template(name, type, tpl_format, params, parent)
        key = "#{type}__#{name}".to_sym
        (get_template(key, name, type, tpl_format, parent) || set_template(key, name, type, tpl_format, parent)).dup.tap { |ctpl|
           ctpl.params = params if params
         }
      end

      def get_template(key, name, type, tpl_format, parent)
        if @cache.key?(key) && (@cache[key].modified? || !@cache[key].valid?)
          set_template(key, name, type, tpl_format, parent)
        else
          @cache[key]
        end
      end


      def set_template(key, name, type, tpl_format, parent)
        @cache[key] = Template.new(name: name, type: type, format: tpl_format, domain: @app.domain, parent: parent, engine: self).load!.parse!
      end

    end

  end
end
