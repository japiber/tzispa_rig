# frozen_string_literal: true

require 'forwardable'
require 'tzispa/utils/string'

module Tzispa
  module Rig

    class Token
      extend Forwardable

      using Tzispa::Utils

      RE_ANCHOR = /(\$\$\h+\$\$)/

      attr_reader :type, :parser
      def_delegators :@parser, :domain, :content_type, :template

      def initialize(parser, type)
        @parser = parser
        @type = type
      end

      class << self
        def instance(parser, type, match)
          "Tzispa::Rig::TypeToken::#{type.to_s.capitalize}".constantize.new parser, match
        end
      end

      def anchor
        @anchor ||= "$$#{format '%x', object_id}$$"
      end
    end

    require 'tzispa/rig/type_token/api_url'
    require 'tzispa/rig/type_token/expression'
    require 'tzispa/rig/type_token/statement'
    require 'tzispa/rig/type_token/block'

  end
end
