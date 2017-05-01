# frozen_string_literal: true

require 'forwardable'
require 'tzispa/utils/string'

module Tzispa
  module Rig

    class Token
      extend Forwardable

      using Tzispa::Utils::TzString

      RE_ANCHOR = /(\u0010\$\h+\$\u0010)/

      attr_reader :type, :parser
      def_delegators :@parser, :domain, :content_type, :template

      def initialize(parser, type)
        @parser = parser
        @type = type
      end

      class << self
        def instance(parser, type, match)
          "Tzispa::Rig::Tokens::#{type.to_s.capitalize}".constantize.new parser, match
        end
      end

      def anchor
        @anchor ||= "\u0010$#{format '%x', object_id}$\u0010"
      end
    end

    require 'tzispa/rig/tokens/api_url'
    require 'tzispa/rig/tokens/expression'
    require 'tzispa/rig/tokens/statement'
    require 'tzispa/rig/tokens/block'

  end
end
