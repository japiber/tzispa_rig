# frozen_string_literal: true

require 'forwardable'

module Tzispa
  module Rig
    module Token

      class Builder
        extend Forwardable

        STRING_EMPTY = ''
        RE_ANCHOR = /(@@\h+@@)/

        attr_reader :type, :parser
        def_delegators :@parser, :domain, :content_type, :template

        def initialize(parser, type)
          @parser = parser
          @type = type
        end

        def self.instance(parser, type, match)
          case type
          when :meta
            Meta.new parser, type, match[1]
          when :var
            Var.new parser, type, match[1], match[2]
          when :url
            Url.new parser, match[1].to_sym, match[3], match[5], match[2]&.slice(1..-1)
          when :api
            Api.new parser, match[1].to_sym, match[3], match[4], match[5], match[6], match[2]&.slice(1..-1)
          when :loop
            Loop.new parser, type, match[3], match[4]
          when :ife
            Ife.new parser, type, match[7], match[8], match[10]
          when :blk
            Block.new parser, type, match[3], match[4]
          when :iblk
            IBlock.new parser, type, match[7], match[8], match[9], match[10], match[11]
          when :static
            Static.new parser, type, match[14], match[15]
          end
        end

        def anchor
          @anchor ||= "@@#{"%x" % object_id}@@".freeze
        end

      end

      require 'tzispa/rig/token/api_url'
      require 'tzispa/rig/token/expression'
      require 'tzispa/rig/token/statement'
      require 'tzispa/rig/token/template'
      

    end
  end
end