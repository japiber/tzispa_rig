# frozen_string_literal: true

require 'forwardable'
require 'fileutils'
require 'tzispa/utils/string'
require 'tzispa/utils/indenter'
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
        @modified != ::File.mtime(@file)
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

      attr_reader :name, :type, :domain, :format, :params, :parser, :engine, :subdomain, :childrens
      def_delegators :@parser, :attribute_tags

      def initialize(name:, type:, domain: nil, parent: nil, format: nil, params: nil, engine: nil)
        subdom_name = name.downcase.split('.')
        @subdomain = subdom_name.first if subdom_name.length > 1
        @name = subdom_name.last
        @params = Parameters.new(params)
        @childrens = Array.new
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
        super "#{path}/#{@name}.#{RIG_EXTENSION}.#{@format}"
      end

      def parse!
        @parser = ParserNext.new self
        @parser.parse!
        self
      end

      def modified?
        super || (childrens.count > 0 && childrens.index { |tpl|
          tpl.modified?
        })
      end

      def valid?
        !content.empty? && !parser.empty?
      end

      def render(context)
        parse! unless @parser
        binder = TemplateBinder.for self, context
        binder.bind! if binder && binder.respond_to?(:bind!)
        @parser.render binder, context
      end

      def path
        "#{@domain.path}/rig/#{@type.to_s.downcase}#{'/'+@subdomain if @subdomain}"
      end

      def create(content='')
        FileUtils.mkdir_p(path) unless Dir.exist? path
        super(content)
        create_binder
      end

      def block?
        @type == :block
      end

      def layout?
        @type == :layout
      end

      def static?
        @type == :static
      end

      def bindable?
        block? || layout?
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
          f.puts new_binder_code
        } if @type == :block
      end

      def new_binder_code
        Tzispa::Utils::Indenter.new(2).tap { |binder_code|
          binder_code << "require 'tzispa/rig/binder'\n\n"
          level = 0
          binder_namespace.split('::').each { |ns|
            binder_code.indent if level > 0
            binder_code << "module #{ns}\n"
            level += 1
          }
          binder_code.indent << "\nclass #{binder_class_name} < Tzispa::Rig::TemplateBinder\n\n"
          binder_code.indent << "def bind!\n"
          binder_code << "end\n\n"
          binder_code.unindent << "end\n"
          binder_namespace.split('::').each { |ns|
            binder_code.unindent << "end\n"
          }
        }.to_s
      end

    end


  end
end
