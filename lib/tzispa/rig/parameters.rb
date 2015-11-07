module Tzispa
  module Rig
    class Parameters


      attr_reader :inner
      attr_reader :outer
      attr_reader :data


      def initialize(params=nil, iouter=',', iinner='=')
        @data = Hash.new
        @outer = iouter
        @inner = iinner
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
