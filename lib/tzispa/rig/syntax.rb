# frozen_string_literal: true

module Tzispa
  module Rig
    module Syntax

      RIG_EMPTY = {
        flags: /<flags:(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])\/>/
      }.freeze

      RIG_EXPRESSIONS = {
        meta: /\{%([^%]+?)%\}/,
        var:  /<var(\[%[A-Z]?[0-9]*[a-z]\])?:(\w+)\/>/
      }.freeze

      RIG_URL_BUILDER = {
        url: /<(url|purl)(#\w+)?:([^\[\@\/]+(?:\@[^\[\/]+)?)(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])?\/>/,
        api: /<(api|sapi)(#\w+)?:([^:\@]+(?:\@[^:]+)?):([^:\/]+)(?::([^:\/]+))?(?::([^\/]+))?\/>/
      }.freeze

      RIG_STATEMENTS = /(<(loop):(\w+)>(.*?)<\/loop:\3>)|(<(ife):(\w+)>(.*?)(<else:\7\/>(.*?))?<\/ife:\7>)/m

      RIG_TEMPLATES = /(<(blk):(\w+(?:@\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>)|(<(iblk):(\w+):(\w+(?:@\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?:(\w+(?:@\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>)|(<(static):(\w+(?:@\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>)/

    end
  end
end
