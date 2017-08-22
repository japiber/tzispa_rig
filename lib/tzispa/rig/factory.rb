# frozen_string_literal: true

require 'singleton'
require 'digest'
require 'moneta'
require 'tzispa/rig/template'

module Tzispa
  module Rig

    class Factory
      include Singleton

      def initialize
        @cache = Moneta.new(:LRUHash, threadsafe: true)
        # @cache = LruRedux::TTL::ThreadSafeCache.new(Engine.cache_size, Engine.cache_ttl)
      end

      class << self
        def empty
          TemplateBase.new
        end

        def layout(name:, domain:, content_type:, params: nil)
          rig_template name, domain, :layout, content_type, params
        end

        def block(name:, domain:, content_type:, params: nil)
          rig_template name, domain, :block, content_type, params
        end

        def static(name:, domain:, content_type:, params: nil)
          rig_template name, domain, :static, content_type, params
        end

        def rig_template(name, domain, block_type, content_type, params)
          instance.send(:cache_template, name, domain, block_type, content_type, params)
        end
      end

      private

      def cache_template(name, domain, block_type, content_type, params)
        key = "#{domain.name}/#{block_type}/#{name}/#{content_type}".to_sym
        get_template(key, name, domain, block_type, content_type).dup.tap do |ctpl|
          ctpl.params = params if params
        end
      end

      def get_template(key, name, domain, block_type, content_type)
        if !@cache.key?(key) || @cache.key?(key) && (@cache[key].modified? || !@cache[key].valid?)
          set_template(key, name, domain, block_type, content_type)
        else
          @cache[key]
        end
      end

      def set_template(key, name, domain, block_type, content_type)
        @cache[key] = Template.new(name: name,
                                   type: block_type,
                                   domain: domain,
                                   content_type: content_type).load!.parse!
      end
    end

  end
end
