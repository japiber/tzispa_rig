# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'tzispa_utils'

module Tzispa
  module Rig

    class UnknownTag < NameError
      def initialize(name, tag)
        super "#{name} there isn't any loop tagged '#{tag}'"
      end
    end

    class DuplicatedLoop < StandardError
      def initialize(name, loop_id)
        super "#{name} there are many loops tagged '#{loop_id}' only 1 allowed at the same level"
      end
    end

    class Binder
      extend Forwardable

      attr_reader :context, :data_struct, :parser
      def_delegators :@parser, :attribute_tags
      def_delegators :@context, :app, :request, :response,
                     :session, :router_params, :cache
      def_delegators :app, :repository, :config, :logger

      alias tags attribute_tags

      def initialize(parser, context)
        @parser = parser
        @context = context
        @data_struct = if attribute_tags.count.positive?
                         Struct.new(*attribute_tags)
                       else
                         Struct.new(nil)
                       end
      end

      # Gets a LoopBinder context for the given loop_id in a rig template
      #
      #       .... <var:myvar/> ...
      #
      #    <loop:mylist>
      #       ... <var:myvar/> ....
      #    </loop:mylist>
      #
      #    loop_binder(:mylist)
      #
      # ==== Parameters
      # loop_id<Symbol>: The id of the template loop to bind
      #
      def loop_binder(loop_id)
        prl = loop?(loop_id)
        LoopBinder.new(prl, context) if prl
      end

      def attr_cache(*attrs)
        attrs.each { |attrib| cache[attrib] = send(attrib) if respond_to?(attrib) }
      end

      private

      def loop?(loop_id)
        ltk = parser.loop_token loop_id
        duplicated? ltk
        ltk.first if ltk.count.positive?
      end

      def duplicated?(token)
        raise DuplicatedLoop.new(self.class.name, token.id) if token.count > 1
      end
    end

    class AttachBinder < Binder
      using Tzispa::Utils::TzHash

      def data
        @data ||= data_struct.new
      end

      def attach(**params)
        data.tap do |d|
          params.each do |k, v|
            next unless tags.include? k
            d[k] = evaluate k, v
          end
        end
      end

      def attach_json(data)
        attach(JSON.parse(data).deep_symbolize!)
      end

      def evaluate(k, value)
        case value
        when Enumerable
          loop_binder(k)&.bind! { value.reject(&:nil?).map { |item| loop_item item } } || value
        when Proc
          loop_binder(k)&.bind!(&value) || value.call
        else
          value
        end
      end
    end

    class LoopBinder < AttachBinder
      def bind!(&generator)
        @source_object = eval 'self', generator.binding
        @data = instance_eval(&generator).to_enum(:each)
        self
      end

      def method_missing(method, *args, &generator)
        if respond_to_missing? method
          @source_object.send(method, *args, &generator)
        else
          super
        end
      end

      def respond_to_missing?(method)
        @source_object.respond_to?(method, true)
      end

      def loop_item(params = nil)
        (LoopItem.new self).tap do |item|
          params&.each do |k, v|
            next unless tags.include? k
            item.data[k] = evaluate k, v
          end
        end
      end
    end

    class LoopItem
      attr_reader :context, :data

      def initialize(binder)
        @context = binder.context
        @data = binder.data_struct.new
      end
    end

  end
end
