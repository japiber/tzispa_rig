# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'tzispa/utils/hash'
require 'tzispa/helpers/hooks/before'
require 'tzispa/helpers/hooks/after'
require 'tzispa/rig/binder'

module Tzispa
  module Rig

    class IsnotTemplateBinder < ArgumentError
      def initialize(name)
        super "Class #{name} isn't a TemplateBinder"
      end
    end

    class TemplateBinder < Binder
      extend Forwardable

      using Tzispa::Utils::TzHash

      include Tzispa::Helpers::Hooks::Before
      include Tzispa::Helpers::Hooks::After

      attr_reader :template
      def_delegators :@template, :params

      def initialize(template, context)
        super(template.parser, context)
        @template = template
      end

      def bound
        do_before
        bind! if respond_to?(:bind!)
        do_after
      end

      def data
        @data ||= @data_struct.new
      end

      def attach(json = nil, **params)
        attach_json(json) if json
        data.tap do |d|
          params.each do |k, v|
            next unless tags.include? k
            d[k] = case v
                   when Enumerable
                     bind_loopitems(k, v)
                   when Proc
                     loop_binder(k)&.bind!(&v) || v.call
                   else
                     v
                   end
          end
        end
      end

      def attach_json(data)
        src = JSON.parse(data).symbolize!
        attach(src.reject { |_, v| v.is_a?(Array) || v.is_a?(::Hash) })
        attach(src.select { |_, v| v.is_a?(Array) }.map do |k, v|
          [k, bind_loopitems(k, v)]
        end.to_h)
      end

      def bind_loopitems(k, v)
        loop_binder(k)&.bind! { v.map { |item| loop_item item.symbolize! } }
      end

      def self.for(template, context)
        if template.bindable?
          binder_class = template.binder_class
          binder_class&.new(template, context)&.tap do |binder|
            raise IsnotTemplateBinder(binder_class.name) unless binder.is_a? TemplateBinder
          end
        else
          new(template, context)
        end
      end
    end

  end
end
