# frozen_string_literal: true

require 'forwardable'
require 'tzispa_helpers'
require 'tzispa_rig'

module Tzispa
  module Rig

    class IsnotTemplateBinder < ArgumentError
      def initialize(name)
        super "Class #{name} isn't a TemplateBinder"
      end
    end

    class TemplateBinder < AttachBinder
      extend Forwardable

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
        self
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
