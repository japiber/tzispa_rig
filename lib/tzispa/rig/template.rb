# frozen_string_literal: true

require 'forwardable'
require 'fileutils'
require 'tzispa/utils/string'
require 'tzispa/utils/indenter'

module Tzispa
  module Rig

    class NotFound < NameError; end

    class ReadError < IOError; end

    class TemplateBase

      attr_reader :content

      def initialize
        @content = nil
        @loaded = true
      end

      def loaded?
        @loaded
      end

      def modified?
        false
      end

      def exist?
        true
      end

      def load!
        self
      end

      def parse!
        self
      end

      def render(context, binder=nil)
        ""
      end

    end

    class File < TemplateBase

      attr_reader :filename, :encoding

      def initialize(name, encoding: 'UTF-8')
        super()
        @filename = name
        @loaded = false
        @encoding = encoding
      end

      def modified?
        @modified && (@modified != ::File.mtime(filename))
      end

      def exist?
        ::File.exist?(filename)
      end

      def load!
        raise NotFound.new("Template file '#{filename}' not found") unless exist?
        ::File.open(filename, "r:#{encoding}") { |f|
          @content = String.new
          @modified = f.mtime
          f.each { |line|
            @content << line
          }
          @loaded = true
        }
        self
      rescue Errno::ENOENT
        raise ReadError.new "Template file '#{@file}' could not be read"
      end

      def create(content=nil)
        ::File.open(filename, "w:#{encoding}") { |f|
          f.puts content
        }
      end

    end


    class Template < File
      extend Forwardable

      using Tzispa::Utils

      BASIC_TYPES    = [:layout, :block, :static].freeze
      RIG_EXTENSION  = 'rig'

      attr_reader :id, :name, :type, :domain, :parser, :subdomain, :childrens, :content_type
      def_delegators :@parser, :attribute_tags

      def initialize(name:, type:, domain:, content_type:, params: nil)
        @id = name
        name.downcase.split('.').tap { |sdn|
          @subdomain = sdn.length > 1 ? sdn.first : nil
          @name = sdn.last
        }
        @domain = domain
        @content_type = content_type
        @params = Parameters.new(params)
        send('type=', type)
        super "#{path}/#{@name}.#{RIG_EXTENSION}.#{content_type}"
      end

      def parse!
        @parser = ParserNext.new self, content, domain: domain, content_type: content_type, bindable: bindable?
        parser.parse!
        self
      end

      def modified?
        super || (parser && parser.childrens.index { |tpl|
          tpl.modified?
        })
      end

      def valid?
        !content.empty? && !parser.empty?
      end

      def render(context, binder=nil)
        parse! unless parser
        binder ||= TemplateBinder.for self, context
        binder.bind! if binder&.respond_to?(:bind!)
        parser.render binder
      end

      def path
        String.new.tap { |pth|
          pth << "#{domain.path}/rig/#{type.to_s.downcase}"
          pth << "/#{subdomain}" if subdomain
        }
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
        "#{@domain.name.to_s.camelize}::Rig::#{@type.to_s.capitalize}#{'::' + @subdomain.camelize if @subdomain}"
      end

      def binder_class_name
        @name.camelize
      end

      def binder_class
        @domain.require binder_require
        "#{binder_namespace}::#{binder_class_name}".constantize
      end

      private

      def type=(value)
        raise ArgumentError.new("#{value} is not a Rig block") unless BASIC_TYPES.include?(value)
        @type = value
      end

      def create_binder
        ::File.open("#{domain.path}/#{binder_require}.rb", "w") { |f|
          f.puts write_binder_code
        } if @type == :block
      end

      def write_binder_code
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
