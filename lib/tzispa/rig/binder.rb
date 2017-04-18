# frozen_string_literal: true

require 'forwardable'
require 'json'
require 'tzispa/utils/hash'

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

    class IsnotTemplateBinder < ArgumentError
      def initialize(name)
        super "Class #{name} isn't a TemplateBinder"
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
      # The LoopBinder returned by this funcion is independent of the
      # parent binder where it is defined, so the template symbols of the parent
      # binder are not accesible in the loop_binder context. In
      # other words, in the top example the two 'myvar' symbols are different
      # and you can not access the first myvar value inside the loop
      #
      # ==== Parameters
      # loop_id<Symbol>: The id of the template loop to bind
      #
      def loop_binder(loop_id)
        loop_parser = @parser.loop_parser loop_id
        unknown? loop_parser
        duplicated? loop_parser
        LoopBinder.new loop_parser[0], @context
      end

      def attr_cache(*attrs)
        attrs.each { |attrib| cache[attrib] = send(attrib) if respond_to?(attrib) }
      end

      private

      def unknown?(loop_parser)
        raise UnknownTag.new(self.class.name, loop_parser.id) unless loop_parser.count.positive?
      end

      def duplicated?(loop_parser)
        raise DuplicatedLoop.new(self.class.name, loop_parser.id) unless loop_parser.count == 1
      end
    end

    class TemplateBinder < Binder
      extend Forwardable

      using Tzispa::Utils::TzHash

      attr_reader :template
      def_delegators :@template, :params

      def initialize(template, context)
        super(template.parser, context)
        @template = template
      end

      def data
        @data ||= @data_struct.new
      end

      def attach(json = nil, **params)
        attach_json(json) if json
        data.tap do |d|
          params.each do |k, v|
            raise UnknownTag.new(self.class.name, k) unless tags.include? k
            d[k] = v.is_a?(Enumerable) ? attach_loop(k, v) : v
          end
        end
      end

      def attach_json(data)
        src = JSON.parse(data).symbolize!
        attach(src.reject { |_, v| v.is_a?(Array) || v.is_a?(::Hash) })
        attach(src.select { |_, v| v.is_a?(Array) }.map do |k, v|
          [k, attach_loop(k, v)]
        end.to_h)
      end

      def attach_loop(k, v)
        loop_binder(k).bind! { v.map { |item| loop_item item.symbolize! } }
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

    class LoopBinder < Binder
      attr_reader :data

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
            raise UnknownTag(self.class.name, k) unless tags.include? k
            item.data[k] = v
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
