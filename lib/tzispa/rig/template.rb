# frozen_string_literal: true

require 'forwardable'
require 'fileutils'
require 'tzispa/utils/string'
require 'tzispa/utils/indenter'
require 'tzispa/rig/parameters'
require 'tzispa/rig/parsernext'
require 'tzispa/rig/binder'

module Tzispa
  module Rig

    class NotFound < NameError
      def initialize(filename)
        super "Template file '#{filename}' not found"
      end
    end

    class ReadError < IOError
      def initialize(file)
        super "Template file '#{file}' could not be read"
      end
    end

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

      def render(_context, _binder = nil)
        ''
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
        raise Tzispa::Rig::NotFound.new(filename) unless exist?
        ::File.open(filename, "r:#{encoding}") do |f|
          @content = String.new
          @modified = f.mtime
          f.each { |line| @content << line }
          @loaded = true
        end
        self
      rescue Errno::ENOENT
        raise Tzispa::Rig::ReadError.new(@file)
      end

      def create(content = nil)
        ::File.open(filename, "w:#{encoding}") { |f| f.puts content }
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
        build_name name
        @domain = domain
        @content_type = content_type
        @params = Parameters.new(params)
        send('type=', type)
        super "#{path}/#{@name}.#{RIG_EXTENSION}.#{content_type}"
      end

      def parse!
        @parser = ParserNext.new template: self,
                                 domain: domain,
                                 content_type: content_type,
                                 bindable: bindable?
        parser.parse!
        self
      end

      def modified?
        super || (parser && parser.childrens.index(&:modified?))
      end

      def valid?
        !content.empty? && !parser.empty?
      end

      def render(context, binder = nil)
        parse! unless parser
        binder ||= TemplateBinder.for self, context
        binder.bind! if binder&.respond_to?(:bind!)
        parser.render binder
      end

      def path
        @path ||= "#{domain.path}/view/#{subdomain || '_'}/#{type.to_s.downcase}"
      end

      def create(content = '')
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
        @binder_require ||= "view/#{subdomain || '_'}/#{type}/#{name.downcase}"
      end

      def binder_namespace
        @binder_namespace ||= "#{domain.name.to_s.camelize}::#{subdomain&.camelize}View"
      end

      def binder_class_name
        @binder_class_name ||= @name.camelize
      end

      def binder_class
        @binder_class ||= begin
          domain.require binder_require
          "#{binder_namespace}::#{binder_class_name}#{type.to_s.capitalize}".constantize
        end
      end

      private

      def build_name(name)
        name.to_s.downcase.split('@').tap do |sdn|
          @subdomain = sdn.first if sdn.length > 1
          @name = sdn.last
        end
      end

      def type=(value)
        raise ArgumentError("#{value} is not a Rig block") unless BASIC_TYPES.include?(value)
        @type = value
      end

      def create_binder
        return unless [:block, :layout].include?(type)
        ::File.open("#{domain.path}/#{binder_require}.rb", 'w') do |f|
          f.puts write_binder_code
        end
      end

      def write_binder_code
        Tzispa::Utils::Indenter.new(2).tap do |binder_code|
          binder_code << "require 'tzispa/rig/binder'\n\n"
          level = 0
          binder_namespace.split('::').each do |ns|
            binder_code.indent if level.positive?
            binder_code << "module #{ns}\n"
            level += 1
          end
          binder_code.indent << "\nclass #{binder_class_name} < Tzispa::Rig::TemplateBinder\n\n"
          binder_code.indent << "def bind!\n"
          binder_code << "end\n\n"
          binder_code.unindent << "end\n"
          binder_namespace.split('::').each { binder_code.unindent << "end\n" }
        end.to_s
      end
    end

  end
end
