# frozen_string_literal: true

require 'forwardable'
require 'tzispa/rig'

module Tzispa
  module Rig


    class UnknownTag < NameError; end
    class DuplicatedLoop < StandardError; end


    class Binder
      extend Forwardable

      attr_reader :context, :dataStruct, :tags, :parser
      def_delegators :@parser, :attribute_tags
      def_delegators :@context, :app, :request, :response, :repository, :config


      def initialize(parser, context)
        @parser = parser
        @context = context
        @dataStruct = attribute_tags.count > 0 ? Struct.new(*attribute_tags) : Struct.new(nil)
      end

      alias :tags :attribute_tags

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
      # other words, in the top example the two 'myvar' symbols are different symbols
      # and you can not access the first myvar value inside the loop
      #
      # ==== Parameters
      # loop_id<Symbol>: The id of the template loop to bind
      #
      def loop_binder(loop_id)
        loop_parser = @parser.loop_parser loop_id
        raise UnknownTag.new("#{self.class.name} there isn't any loop tagged '#{loop_id}'") unless loop_parser && loop_parser.count > 0
        raise DuplicatedLoop.new("#{self.class.name} there are #{loop_parser.count} loops tagged '#{loop_id}' at the same level: only one allowed") unless loop_parser.count == 1
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
            raise UnknownTag.new "#{k} is not a tag in #{self.class.name}" unless tags.include? k
            d[k] = v
          }
        }
      end

      def self.for(template, context)
        if template.bindable?
          binder_class = template.binder_class
          binder_class.new(template, context).tap { |binder|
            raise ArgumentError.new "#{binder_class.name} isn't a TemplateBinder" unless binder&.is_a? Tzispa::Rig::TemplateBinder
          } if binder_class
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

      def loop_item(params=nil)
        (LoopItem.new self).tap { |item|
          params.each{ |k,v|
            raise UnknownTag.new "#{k} is not a tag in #{self.class.name}" unless tags.include? k
            item.data[k] = v
          } if params
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
