# frozen_string_literal: true
require 'singleton'
require 'lru_redux'
require 'tzispa/rig/template'

module Tzispa
  module Rig

    class Engine
      include Singleton

      @@cache_size = 128
      @@singleton__mutex__ = Mutex.new

      def initialize
        @cache = LruRedux::ThreadSafeCache.new(@@cache_size)
      end

      class << self

        def layout(name:, domain:, content_type:, params:nil)
          rig_template name, domain, :layout, content_type, params
        end

        def block(name:, domain:, content_type:, params:nil)
          rig_template name, domain, :block, content_type, params
        end

        def static(name:, domain:, content_type:, params:nil)
          rig_template name, domain, :static, content_type, params
        end

        def rig_template(name, domain, block_type, content_type, params)
          instance.send(:cache_template, name, domain, block_type, content_type, params)
        end

        def cache_sizee=(sz)
          @@cache_size = sz
        end

      end

      private

      def cache_template(name, domain, block_type, content_type, params)
        key = "#{domain}__#{block_type}__#{name}__#{content_type}".to_sym
        (get_template(key, name, domain, block_type, content_type) || set_template(key, name, domain, block_type, content_type)).dup.tap { |ctpl|
           ctpl.params = params if params
         }
      end

      def get_template(key, name, domain, block_type, content_type)
        if @cache.key?(key) && (@cache[key].modified? || !@cache[key].valid?)
          set_template(key, name, domain, block_type, content_type)
        else
          @cache[key]
        end
      end

      def set_template(key, name, domain, block_type, content_type)
        # can have recursion from Template
        unless @@singleton__mutex__.locked?
          @@singleton__mutex__.synchronize {
            @cache[key] = Template.new(name: name, type: block_type, domain: domain, content_type: content_type).load!.parse!
          }
        else
          @cache[key] = Template.new(name: name, type: block_type, domain: domain, content_type: content_type).load!.parse!
        end
      end

    end

  end
end
