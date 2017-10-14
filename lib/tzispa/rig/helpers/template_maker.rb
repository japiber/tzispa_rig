# frozen_string_literal: true

require 'fileutils'
require 'tzispa_utils'

module Tzispa
  module Rig
    module Helpers
      module TemplateMaker
        using Tzispa::Utils::TzString

        BASIC_TYPES    = %i[layout block static].freeze

        RIG_EXTENSION  = 'rig'

        def create(content = '')
          FileUtils.mkdir_p(path) unless Dir.exist? path
          super(content)
          create_binder
        end

        def binder_require
          @binder_require ||= "view/#{subdomain || '_'}/#{type}/#{name.downcase}"
        end

        def binder_namespace
          @binder_namespace ||= "#{domain.name.to_s.camelize}::#{subdomain&.camelize}View"
        end

        def binder_class_name
          @binder_class_name ||= "#{name.camelize}#{type.to_s.capitalize}"
        end

        def binder_class
          @binder_class ||= begin
            domain.require binder_require
            "#{binder_namespace}::#{binder_class_name}".constantize
          end
        end

        def create_binder
          return unless %i[block layout].include?(type)
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
end
