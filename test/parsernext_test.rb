require 'test_helper'

class ParsernextTest < Minitest::Test
  extend Minitest::Spec::DSL

  TPL_META = 'meta testing {%meta1%}\n\n {%meta1%}:{%meta2%}\n'
  TPL_VAR  = 'var testing <var:uno/>\n\n {%meta1%} <var:dos/>  <var:uno/>:{%meta2%}\n'
  TPL_LOOP = '<loop:literator> loop testing <var:uno/> <var:dos/>\n </loop:literator> <var:dos/>'
  TPL_IFE  = '<ife:condition> ife testing <var:uno/> <var:dos/>\n </ife:condition> <ife:condition> <var:uno/> {%dos%} <else:condition/> <var:dos/> </ife:condition> '

  def test_meta_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_META, domain: :test_domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 3
    assert_instance_of Tzispa::Rig::ParsedMeta, parser.the_parsed[0]
    assert_instance_of Tzispa::Rig::ParsedMeta, parser.the_parsed[1]
    assert_instance_of Tzispa::Rig::ParsedMeta, parser.the_parsed[2]
    assert_equal parser.the_parsed[0].id, :meta1
    assert_equal parser.the_parsed[1].id, :meta1
    assert_equal parser.the_parsed[2].id, :meta2
  end

  def test_var_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_VAR, domain: :test_domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 5
    # metas are parsed before vars
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[2]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[3]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[4]
    assert_equal parser.the_parsed[2].id, :uno
    assert_equal parser.the_parsed[3].id, :dos
    assert_equal parser.the_parsed[4].id, :uno
  end

  def test_loop_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_LOOP, domain: :test_domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 2
    assert_instance_of Tzispa::Rig::ParsedLoop, parser.the_parsed[0]
    assert_equal parser.the_parsed[0].id, :literator
    assert_equal parser.the_parsed[0].body_parser.the_parsed.count, 2
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[0].body_parser.the_parsed[0]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[0].body_parser.the_parsed[1]
    assert_equal parser.the_parsed[0].body_parser.the_parsed[0].id, :uno
    assert_equal parser.the_parsed[0].body_parser.the_parsed[1].id, :dos
  end

  def test_ife_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_IFE, domain: :test_domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 2
    assert_instance_of Tzispa::Rig::ParsedIfe, parser.the_parsed[0]
    assert_equal parser.the_parsed[0].test, :condition
    assert_equal parser.the_parsed[1].test, :condition
    assert_equal parser.the_parsed[0].then_parser.the_parsed.count, 2
    assert_nil parser.the_parsed[0].else_parser
    assert_equal parser.the_parsed[1].then_parser.the_parsed.count, 2
    assert_equal parser.the_parsed[1].else_parser.the_parsed.count, 1
  end



end
