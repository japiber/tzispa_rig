# frozen_string_literal: true

module Tzispa
  module Rig

    autoload :Parameters,         'tzispa/rig/parameters'
    autoload :Token,              'tzispa/rig/token'
    autoload :Parsernext,         'tzispa/rig/parser_next'
    autoload :Template,           'tzispa/rig/template'
    autoload :Binder,             'tzispa/rig/binder'
    autoload :AttachBinder,       'tzispa/rig/binder'
    autoload :LoopBinder,         'tzispa/rig/binder'
    autoload :LoopItem,           'tzispa/rig/binder'
    autoload :Factory,            'tzispa/rig/factory'
    autoload :Handler,            'tzispa/rig/handler'
    autoload :AnnotatedHandler,   'tzispa/rig/annotated_handler'

  end
end
