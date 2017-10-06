# frozen_string_literal: true

require 'tzispa/rig/handler'
require 'tzispa_annotations'

module Tzispa
  module Rig
    class AnnotatedHandler < Tzispa::Rig::Handler
      extend Tzispa::Annotations
      include Tzispa::Annotations::Builtin
    end
  end
end
