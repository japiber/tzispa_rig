# frozen_string_literal: true

require 'forwardable'
require 'tzispa/utils/string'
require 'tzispa/rig'

module Tzispa
  module Rig

    class NotFound < NameError; end

    class ReadError < IOError; end

    class File

      attr_reader :file, :content, :modified

      def initialize(file)
        @file = file
        @loaded = false
      end

      def loaded?
        @loaded
      end

      def modified?
        @modified != File.mtime(@file)
      end

      def exist?
        ::File.exist?(@file)
      end

      def load!
        begin
          raise NotFound.new("Template file '#{@file}' not found") unless exist?
          ::File.open(@file, 'r:UTF-8') { |f|
            @content = String.new
            @modified = f.mtime
            while line = f.gets
              @content << line
            end
          }
          @loaded = true
        rescue Errno::ENOENT
          raise ReadError.new "Template file '#{@file}' could not be read"
        end
        self
      end

      def create(content=nil)
        ::File.open(@file, "w") { |f|
          f.puts content
        }
      end

    end


    class Template < File
      extend Forwardable

      BASIC_TYPES    = [:layout, :block, :static].freeze
      DEFAULT_FORMAT = 'htm'.freeze
      RIG_EXTENSION  = 'rig'.freeze

      attr_reader :name, :type, :domain, :format, :params, :parser, :engine, :subdomain
      def_delegators :@parser, :attribute_tags

      def initialize(name:, type:, domain: nil, parent: nil, format: nil, params: nil, engine: nil)
        subdom_name = name.downcase.split('.')
        @subdomain = subdom_name.first if subdom_name.length > 1
        @name = subdom_name.last
        @params = Parameters.new(params)
        send('type=', type)
        if parent
          @engine = engine || parent.engine
          @domain = domain || parent.domain
          @format = format || parent.format
        else
          @engine = engine
          @domain = domain
          @format = format || DEFAULT_FORMAT
        end
        super "#{@domain.path}/rig/#{@type.to_s.downcase}/#{@subdomain+'/' if @subdomain}#{@name}.#{RIG_EXTENSION}.#{@format}"
      end

      def parse!
        @parser = ParserNext.new self
        @parser.parse!
        self
      end

      def render(context)
        parse! unless @parser
        binder = TemplateBinder.for self, context
        binder.bind! if binder && binder.respond_to?(:bind!)
        @parser.render binder, context
      end

      def create
        super
        create_binder
      end

      def is_block?
        @type == :block
      end

      def is_layout?
        @type == :layout
      end

      def is_static?
        @type == :static
      end

      def params=(value)
        @params = Parameters.new(value)
      end

      def params
        @params.data
      end

      def binder_require
        "rig/#{@type}/#{@subdomain+'/' if @subdomain}#{@name.downcase}"
      end

      def binder_namespace
        "#{TzString.camelize @domain.name}::Rig::#{@type.to_s.capitalize}#{'::' + TzString.camelize(@subdomain) if @subdomain}"
      end

      def binder_class_name
        TzString.camelize @name
      end

      def binder_class
        @domain.require binder_require
        TzString.constantize "#{binder_namespace}::#{binder_class_name}"
      end

      private

      def type=(value)
        raise ArgumentError.new("#{value} is not a Rig block") unless BASIC_TYPES.include?(value)
        @type = value
      end

      def create_binder
        ::File.open("#{domain.path}/#{binder_require}.rb", "w") { |f|
          f.puts "module #{binder_namespace}\n"
          f.puts "  class #{binder_class_name} < Tzispa::Rig::TemplateBinder\n\n"
          f.puts "     def bind!"
          f.puts "     end"
          f.puts "  end"
          f.puts "end\n"
        } if @type == :block
      end

    end


    class Engine

      attr_reader :app

      def initialize(app)
        @app = app
        @pool= Hash.new
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

      def rig_template(name, type, format, params, parent)
        if @mutex.owned?
          tpl = @pool["#{type}__#{name}"] || Template.new( name: name, type: type, format: format, domain: @app.domain, params: params, parent: parent, engine: self )
          tpl.loaded? && !tpl.modified? ? tpl : tpl.load!.parse!
        else
          @mutex.synchronize {
            tpl = @pool["#{type}__#{name}"] || Template.new( name: name, type: type, format: format, domain: @app.domain, params: params, parent: parent, engine: self )
            tpl.loaded? && !tpl.modified? ? tpl : tpl.load!.parse!
          }
        end
      end

    end

  end
end
