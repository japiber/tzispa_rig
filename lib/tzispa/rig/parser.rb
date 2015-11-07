require 'tzispa/rig/engine'
require 'tzispa/rig/formatter'
require 'tzispa/helpers/security'

module Tzispa
  module Rig
    class Parser

      include Tzispa::Helpers::Security

      EMPTY_STRING = ''.freeze

      attr_reader :text

      RIG_SYNTAX = {
        :re_flags   => /<flags:(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])\/>/,
        :blk        => /<(blk):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :iblk       => /<(iblk):(\w+):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?:(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :static     => /<(static):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :re_var     => /<var(\[%[A-Z]?[0-9]*[a-z]\])?:(\w+)\/>/,
        :re_metavar => /\{%([^%]+?)%\}/,
        :re_loop    => /<loop:(\w+)>(.*?)<\/loop:\1>/m,
        :re_ife     => /<ife:(\w+)>(.*?)(<else:\1\/>(.*?))?<\/ife:\1>/m,
        :re_purl    => /<purl:(\w+)(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])?\/>/,
        :re_api     => /<api:(\w+(?:\.\w+)?):(\w+)(?::(\w+))?\/>/,
      }

      def initialize(engine, binder=nil, text=nil)
        @engine = engine
        @binder = binder || engine.binder
        @context = engine.context
        @text = text
      end

      def parse!
        @text ||= @engine.content
        @binder.bind! if @binder && @binder.respond_to?( :bind! )
        if @engine.type == :block
          parseStatement
          parseExpression
        end
        parseBlock
        self
      end


    private

      def parseExpression
        parseMetavar
        parseVar
        parsePurl
        parseAPI
      end

      def parseStatement
        parseLoop
        parseIfe
      end

      def parseFlags
        @text.gsub!(RIG_SYNTAX[:re_flags]) { |match|
          flags = Regexp.last_match(1)
          @engine.flags = flags
          EMPTY_STRING
        }
      end

      def parseLoop
        @text.gsub!(RIG_SYNTAX[:re_loop]) { |match|
          loopid = Regexp.last_match(1)
          loopbody = Regexp.last_match(2)
          lenrig = @binder.respond_to?("#{loopid}") ? @binder.send("#{loopid}") : []
          lenrig.respond_to?(:map) ? lenrig.map { |item| Parser.new(@engine, item, loopbody.dup).parse!.text }.join : String.new.freeze
        }
      end

      def parseIfe
        @text.gsub!(RIG_SYNTAX[:re_ife]) { |match|
          ifetest = Regexp.last_match(1)
          test = @binder.respond_to?("#{ifetest}") ? @binder.send("#{ifetest}") : false
          ifebody = Regexp.last_match(2)
          elsebody = Regexp.last_match(4)
          Parser.new(@engine, @binder, test ? "#{ifebody}" : "#{elsebody}").parse!.text
        }
      end

      def parseMetavar
        @text.gsub!(RIG_SYNTAX[:re_metavar]) { |match|
          varid = Regexp.last_match(1)
          if @context.respond_to?(varid)
            @context.send(varid)
          elsif !@context.env.nil? and !@context.env[varid].nil?
            @context.env[varid]
          elsif @binder.respond_to?(varid)
            @binder.send(varid)
          else
            Formatter.unknown(varid)
          end
        }
      end

      def parseVar
        @text.gsub!(RIG_SYNTAX[:re_var]) { |match|
          fmt = Regexp.last_match(1)
          varid = Regexp.last_match(2)
          value = @binder.respond_to?(varid) ? @binder.send(varid) : Formatter.unknown(varid)
          Formatter.rigvar(value, fmt)
        }
      end

      def parsePurl
        @text.gsub!(RIG_SYNTAX[:re_purl]) { |match|
          urlid = Regexp.last_match[1]
          urlparams = Parameters.new(Regexp.last_match[3])
          @engine.app.router_path urlid.to_sym, urlparams.data
        }
      end

      def parseAPI
        @text.gsub!(RIG_SYNTAX[:re_api]) { |match|
          handler, verb, predicate = Regexp.last_match[1], Regexp.last_match[2], Regexp.last_match[3]
          sign = Parser.sign_array [handler, verb, predicate], @engine.app.config.salt
          @engine.app.router_path :api, {handler: handler, verb: verb, predicate: predicate, sign: sign}
        }
      end

      def parseBlock
        reBlocks = Regexp.new(RIG_SYNTAX[:re_blk].to_s + '|' + RIG_SYNTAX[:re_iblk].to_s + '|' + RIG_SYNTAX[:re_static].to_s)

        @text.gsub!(reBlocks) {
          strtype = (Regexp.last_match[2] || '') << (Regexp.last_match[7] || '') << (Regexp.last_match[16] || '')
          case strtype
            when 'blk'
              rigtype = :block
              rigname = Regexp.last_match[3]
              rigparams = Regexp.last_match[5]
            when 'iblk'
              rigtype = :block
              rigtest = Regexp.last_match[8]
              if (@binder.respond_to?("#{rigtest}?") ? @binder.send("#{rigtest}?") : false)
                rigname = Regexp.last_match[9]
                rigparams = Regexp.last_match[11]
              else
                rigname = Regexp.last_match[12]
                rigparams = Regexp.last_match[14]
              end
            when 'static'
              rigtype = :static
              rigname = Regexp.last_match[17]
              rigparams = Regexp.last_match[19]
            else
              raise ArgumentError.new("Unknown Rig type: #{strtype}")
          end
          engine = Engine.new(name: rigname, type: rigtype, parent: @engine, params: rigparams)
          engine.render!
          engine.text
        }
      end

    end
  end
end
