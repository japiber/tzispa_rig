# frozen_string_literal: true

require 'forwardable'
require 'tzispa/rig/parameters'
require 'tzispa/rig/parser_next'
require 'tzispa/rig/template_binder'
require 'tzispa/rig/helpers/template_maker'

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
          @content = +''
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

      include Tzispa::Rig::Helpers::TemplateMaker

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

      def render(context, bind = nil)
        parse! unless parser
        parser.render binder(context, bind)
      end

      def binder(context, bind)
        bind || TemplateBinder.for(self, context)&.bound
      end

      def path
        @path ||= "#{domain.path}/view/#{subdomain || '_'}/#{type.to_s.downcase}"
      end

      def params=(value)
        @params = Parameters.new(value)
      end

      def params
        @params.data
      end

      def modified?
        super || parser&.childrens&.index(&:modified?)
      end

      def valid?
        !content.empty? && !parser.empty?
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
    end

  end
end
