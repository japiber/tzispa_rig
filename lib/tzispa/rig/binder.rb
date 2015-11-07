require 'forwardable'
require 'tzispa/rig'

module Tzispa
  module Rig

    class Binder
      extend Forwardable

      attr_reader :context, :dataStruct
      def_delegators :context, :app, :request, :response
      def_delegators :@parser, :attribute_tags

      def initialize(parser, context)
        @parser = parser
        @context = context
        @dataStruct = attribute_tags.count > 0 ? Struct.new(*attribute_tags) : Struct.new(nil)
      end

      def data(params=nil)
        (@data ||= @dataStruct.new).tap { |d|
          params.each{ |k,v|
            d[k] = v
          } if params
        }
      end

      def loop_binder(loop_id)
        loop_parser = @parser.loop_parser loop_id
        raise ArgumentError.new("There isn't any loop tagged #{loop_id}") unless loop_parser
        LoopBinder.new loop_parser, @context
      end

      def self.template_binder(template, context)
        if template.is_block?
          binder_class = template.binder_class
          binder_class.new( template.parser, context ) if binder_class
        else
          self.new(template.parser, context)
        end
      end

    end


    class LoopBinder
      extend Forwardable

      attr_reader :context, :dataStruct, :data
      def_delegators :@parser, :attribute_tags

      def initialize(parser, context)
        @parser = parser
        @context = context
        @dataStruct = attribute_tags.count > 0 ? Struct.new(*attribute_tags) : Struct.new(nil)
      end

      def bind!(&generator)
        @self_before_instance_eval = eval "self", generator.binding
        @data = instance_eval(&generator).to_enum(:each)
        self
      end

      def method_missing(method, *args, &generator)
        @self_before_instance_eval.send method, *args, &generator
      end

      def loop_item(params=nil)
        (LoopItem.new self).tap { |item|
          params.each{ |k,v|
            item.data[k] = v
          } if params
        }
      end

      def loop_binder(loop_id)
        loop_parser = @parser.loop_parser(loop_id)
        raise ArgumentError.new("There isn't any loop tagged '#{loop_id}'") unless loop_parser
        LoopBinder.new loop_parser, @context
      end

    end


    class LoopItem

      attr_reader :context, :data

      def initialize(binder)
        @context = binder.context
        @data = binder.dataStruct.new if binder.dataStruct
      end

    end


  end
end
