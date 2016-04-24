module Tzispa
  module Rig
    module Syntax

      RIG_EMPTY = {
        :flags => /<flags:(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])\/>/
      }.freeze

      RIG_EXPRESSIONS = {
        :meta => /\{%([^%]+?)%\}/,
        :var  => /<var(\[%[A-Z]?[0-9]*[a-z]\])?:(\w+)\/>/,
        :purl => /<purl:(\w+(?:\.\w+)?)(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])?\/>/,
        :url  => /<url:(\w+(?:\.\w+)?)(\[(\w+=[^,\]]+(,\w+=[^,\]]+)*?)\])?\/>/,
        :api  => /<api:([^:\.]+(?:\.[^:]+)?):([^:\/]+)(?::([^:\/]+))?(?::([^\/]+))?\/>/
      }.freeze

      RIG_STATEMENTS = /(<(loop):(\w+)>(.*?)<\/loop:\3>)|(<(ife):(\w+)>(.*?)(<else:\7\/>(.*?))?<\/ife:\7>)/m

      RIG_TEMPLATES = {
        :blk    => /<(blk):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :iblk   => /<(iblk):(\w+):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?:(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/,
        :static => /<(static):(\w+(?:\.\w+)?)(?:\[(\w+=[^,\]]+(?:,\w+=[^,\]]+)*)\])?\/>/
      }.freeze

    end
  end
end