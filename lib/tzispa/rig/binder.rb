# frozen_string_literal: true

require 'forwardable'
require 'tzispa/rig'

module Tzispa
  module Rig


    class Binder
      extend Forwardable

      attr_reader :context, :dataStruct, :parser
      def_delegators :@parser, :attribute_tags
      def_delegators :@context, :app, :request, :response


      def initialize(parser, context)
        @parser = parser
        @context = context
        @dataStruct = attribute_tags.count > 0 ? Struct.new(*attribute_tags) : Struct.new(nil)
      end

      def loop_binder(loop_id)
        loop_parser = @parser.loop_parser loop_id
        raise ArgumentError.new("#{self.class}:: there isn't any loop tagged '#{loop_id}'") unless loop_parser && loop_parser.count > 0
        raise ArgumentError.new("#{self.class}:: there are #{loop_parser.count} loops tagged '#{loop_id}' at the same level: only one allowed") unless loop_parser.count == 1
        LoopBinder.new loop_parser[0], @context
      end

    end


    class TemplateBinder < Binder
      extend Forwardable

      attr_reader :template
      def_delegators :@template, :params


      def initialize(template, context)
        super(template.parser, context)
        @template = template
      end

      def data(**params)
        (@data ||= @dataStruct.new).tap { |d|
          params.each{ |k,v|
            d[k] = v
          }
        }
      end

      def self.for(template, context)
        if template.is_block?
          binder_class = template.binder_class
          binder_class.new( template, context ) if binder_class
        else
          self.new(template, context)
        end
      end

    end


    class LoopBinder < Binder

      attr_reader :data

      def bind!(&generator)
        @source_object = eval "self", generator.binding
        @data = instance_eval(&generator).to_enum(:each)
        self
      end

      def method_missing(method, *args, &generator)
        @source_object.send method, *args, &generator
      end

      def loop_item(**params)
        (LoopItem.new self).tap { |item|
          params.each{ |k,v|
            item.data[k] = v
          }
        }
      end

    end


    class LoopItem

      attr_reader :context, :data

      def initialize(binder)
        @context = binder.context
        @data = binder.dataStruct.new
      end

    end


  end
end
