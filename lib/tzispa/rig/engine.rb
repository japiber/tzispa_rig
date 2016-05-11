# frozen_string_literal: true

require 'tzispa/rig'
require 'lru_redux'


module Tzispa
  module Rig

    class Engine

      attr_reader :app

      def initialize(app, cache_enabled, cache_size)
        @app = app
        @cache = LruRedux::Cache.new(cache_size) if cache_enabled
        @mutex = Mutex.new
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
          if @mutex.owned?
            cache_template(name, type, tpl_format, parent, params)
          else
            @mutex.synchronize {
              cache_template(name, type, tpl_format, parent, params)
            }
          end
        else
          Template.new(name: name, type: type, format: format, domain: @app.domain, params: params, parent: parent, engine: self).load!.parse!
        end
      end

      private

      def cache_template(name, type, tpl_format, parent, params)
        ktpl = "#{type}__#{name}".to_sym
        tpl = @cache.getset(ktpl) {
          Template.new(name: name, type: type, format: tpl_format, domain: @app.domain, parent: parent, engine: self).load!.parse!
        }
        if tpl.modified?
          @cache[ktpl] = tpl.load!.parse!
        else
          tpl
        end
        tpl.dup.tap { |ctpl|
           ctpl.params = params if params
         }
      end

    end

  end
end
