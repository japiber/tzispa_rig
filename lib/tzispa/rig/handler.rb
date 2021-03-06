# frozen_string_literal: true

require 'forwardable'
require 'tzispa_helpers'
require_relative 'handler_error'

module Tzispa
  module Rig

    class ApiException < StandardError; end
    class UnknownHandlerVerb < ApiException
      def initialize(s, name)
        super("Unknown verb: '#{s}' called in api handler '#{name}'")
      end
    end
    class InvalidSign < ApiException; end

    class Handler
      extend Forwardable

      include Tzispa::Rig::HandlerError
      include Tzispa::Helpers::Provider
      include Tzispa::Helpers::SignRequirer
      include Tzispa::Helpers::Hooks::Before
      include Tzispa::Helpers::Hooks::After

      using Tzispa::Utils::TzString

      attr_reader :context, :type, :data, :error, :rescue_hook, :status
      def_delegators :@context, :request, :response, :app, :repository,
                     :config, :logger, :error_log, :info_log

      def initialize(context)
        @context = context
        @error = nil
        @status = nil
        @rescue_hook = nil
      end

      def result(type:, data: nil)
        @type = type
        @data = data
      end

      def result_json(data)
        result type: :json, data: data
      end

      def result_download(data)
        result type: :download, data: data
      end

      def result_redirect(data = nil)
        result type: :redirect, data: data
      end

      def error_status(error_code, http_status = nil)
        @error = error_code
        @status = http_status
        result_json error_message: error_message
      end

      def run!(verb, predicate = nil)
        raise UnknownHandlerVerb.new(verb, self.class.name) unless provides? verb
        raise InvalidSign if sign_required? && !sign_valid?
        do_before
        send verb, *(predicate&.split(','))
        do_after
      end

      def redirect_url(url)
        if url && !url.strip.empty?
          url.start_with?('#') ? "#{request.referer}#{url}" : url
        else
          request.referer
        end
      end

      protected

      def static_path_sign?
        context.path_sign? context.router_params[:sign],
                           context.router_params[:handler],
                           context.router_params[:verb],
                           context.router_params[:predicate]
      end
    end

  end
end
