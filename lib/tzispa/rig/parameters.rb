# frozen_string_literal: true

module Tzispa
  module Rig

    class Parameters

      attr_reader :inner, :outer

      def initialize(params=nil, outer=',', inner='=')
        @data = Hash.new
        @outer = outer
        @inner = inner
        setData(params) if params
      end

      def set(key,value)
        @data[key.to_sym] = value
      end

      def get(key)
        @data[key.to_sym]
      end

      def [](key)
        @data[key.to_sym]
      end

      def has?(key)
        @data.key?(key.to_sym)
      end

      def to_s
        @data.map { |k,v| "#{k}#{inner}#{v}" }.join(outer)
      end

      def to_h
        @data
      end

      alias_method :data, :to_h

      def merge(params)
        setData(params)
      end

      private

      def setData(params)
        params.split(outer).each do |param|
          key,value = param.split(inner)
          @data[key.to_sym] = value
        end
      end


    end
  end
end
