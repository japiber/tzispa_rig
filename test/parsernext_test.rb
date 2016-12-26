require 'fileutils'
require 'test_helper'
require 'tzispa/helpers/security'

class ParsernextTest < Minitest::Test
  include TemplateTestHelper
  include Tzispa::Helpers::Security

  def setup
    all_templates.each { |tpl|
      ::File.open(tpl.filename, "wt") { |mkfile|
        mkfile << STR_T
      }
    }
  end

  def test_empty_parser
    parser = Tzispa::Rig::ParserNext.new(STR_P, domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 0
    assert_equal parser.attribute_tags.count, 0
    assert parser.empty?
  end

  def test_meta_parser
    parser = Tzispa::Rig::ParserNext.new TPL_META, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.the_parsed.count, 3
    assert_equal parser.attribute_tags.count, 2
    assert_equal parser.attribute_tags, [:meta1, :meta2]
    assert_equal parser.attribute_tags, [:meta1, :meta2]
    assert_instance_of Tzispa::Rig::ParsedMeta, parser.the_parsed[0]
    assert_instance_of Tzispa::Rig::ParsedMeta, parser.the_parsed[1]
    assert_instance_of Tzispa::Rig::ParsedMeta, parser.the_parsed[2]
    assert_equal parser.the_parsed[0].id, :meta1
    assert_equal parser.the_parsed[1].id, :meta1
    assert_equal parser.the_parsed[2].id, :meta2
  end

  def test_meta_render
    parser = Tzispa::Rig::ParserNext.new TPL_META, domain: domain, content_type: :txt, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [123, 'john doe']
    assert_equal parser.render(binder), 'meta testing 123\n\n 123:john doe\n'
    binder = binder_fake.new parser, context, [nil, 'john doe']
    assert_equal parser.render(binder), 'meta testing \n\n :john doe\n'
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'meta testing \n\n :\n'
  end

  def test_var_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_VAR, domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 5
    assert_equal parser.attribute_tags.count, 4
    assert_equal parser.attribute_tags, [:meta1, :meta2, :uno, :dos]
    # metas are parsed before vars
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[2]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[3]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[4]
    assert_equal parser.the_parsed[2].id, :uno
    assert_equal parser.the_parsed[3].id, :dos
    assert_equal parser.the_parsed[4].id, :uno
  end

  def test_var_render
    parser = Tzispa::Rig::ParserNext.new(TPL_VAR, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, [2016, 'john doe', 'happy', 'year']
    assert_equal parser.render(binder), 'var testing happy\n\n 2016 year  happy:john doe\n'
    binder = binder_fake.new parser, context, [2015, 'john doe', 'happy']
    assert_equal parser.render(binder), 'var testing happy\n\n 2015   happy:john doe\n'
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'var testing \n\n    :\n'
  end

  def test_loop_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_LOOP, domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 2
    assert_equal parser.attribute_tags.count, 2
    assert_equal parser.attribute_tags, [:literator, :tres]
    assert_instance_of Tzispa::Rig::ParsedLoop, parser.the_parsed[0]
    assert_equal parser.the_parsed[0].id, :literator
    assert_equal parser.the_parsed[0].body_parser.the_parsed.count, 3
    assert_equal parser.the_parsed[0].body_parser.attribute_tags.count, 2
    assert_equal parser.the_parsed[0].body_parser.attribute_tags, [:uno, :dos]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[0].body_parser.the_parsed[0]
    assert_instance_of Tzispa::Rig::ParsedVar, parser.the_parsed[0].body_parser.the_parsed[1]
    assert_equal parser.the_parsed[0].body_parser.the_parsed[0].id, :uno
    assert_equal parser.the_parsed[0].body_parser.the_parsed[1].id, :dos
  end

  def test_loop_render
    parser = Tzispa::Rig::ParserNext.new(TPL_LOOP, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, [Struct.new(:data).new([
      binder_fake.new(parser.the_parsed[0].body_parser, {}, [1, 2]),
      binder_fake.new(parser.the_parsed[0].body_parser, {}, [3, 4]),
      binder_fake.new(parser.the_parsed[0].body_parser, {}, [5, 6])
      ]), 'watching']
    assert_equal parser.render(binder), ' loop testing 1 2\n 1  loop testing 3 4\n 3  loop testing 5 6\n 5  watching'
    binder = binder_fake.new parser, context, [Struct.new(:data).new([]), 'watching']
    assert_equal parser.render(binder), ' watching'
    binder = binder_fake.new parser, context, [Struct.new(:data).new, 'watching']
    assert_raises(NoMethodError) { parser.render(binder) }
    binder = binder_fake.new parser, context, [[], 'watching']
    assert_raises(NoMethodError) { parser.render(binder) }
  end

  def test_ife_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_IFE, domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 2
    assert_equal parser.the_parsed[0].attribute_tags.count, 3
    assert_equal parser.the_parsed[0].attribute_tags, [:condition, :uno, :dos]
    assert_equal parser.the_parsed[1].attribute_tags.count, 4
    assert_equal parser.the_parsed[1].attribute_tags, [:condition, :dos, :tres, :uno]
    assert_equal parser.attribute_tags.count, 4
    assert_equal parser.attribute_tags, [:condition, :uno, :dos, :tres]
    assert_instance_of Tzispa::Rig::ParsedIfe, parser.the_parsed[0]
    assert_equal parser.the_parsed[0].test, :condition
    assert_equal parser.the_parsed[1].test, :condition
    assert_equal parser.the_parsed[0].then_parser.the_parsed.count, 2
    assert_nil parser.the_parsed[0].else_parser
    assert_equal parser.the_parsed[1].then_parser.the_parsed.count, 3
    assert_equal parser.the_parsed[1].else_parser.the_parsed.count, 1
  end

  def test_ife_render
    parser = Tzispa::Rig::ParserNext.new(TPL_IFE, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, [1==1, 'john doe', 'happy', 'year']
    assert_equal parser.render(binder), ' ife testing john doe happy\n   john doe happy year  '
    binder = binder_fake.new parser, context, [1==0, 'john doe', 'happy', 'year']
    assert_equal parser.render(binder), '  happy  '
  end


  def test_url_parser
    parser = Tzispa::Rig::ParserNext.new("#{TPL_URL1} #{TPL_URL2} #{TPL_URL3}", domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 4
    assert_instance_of Tzispa::Rig::ParsedUrl, parser.the_parsed[1]
    assert_instance_of Tzispa::Rig::ParsedUrl, parser.the_parsed[2]
    assert_equal parser.the_parsed[0].id, :idp
    assert_equal parser.the_parsed[1].layout, 'article'
    assert_equal parser.the_parsed[2].layout, 'article_list'
    assert_equal parser.the_parsed[3].layout, 'article_edit'
    assert_equal parser.the_parsed[1].params, 'id=111,title=this_is_an_url_title'
    assert_equal parser.the_parsed[2].params, "id=#{parser.the_parsed[0].anchor},title=this_is_an_url_title"
    assert_equal parser.the_parsed[3].params, 'id=1220,format=json'
    assert_nil parser.the_parsed[1].app_name
    assert_nil parser.the_parsed[2].app_name
    assert_equal parser.the_parsed[3].app_name, :adminapp
  end

  def test_url_render
    parser = Tzispa::Rig::ParserNext.new(TPL_URL1, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'http://mytestdomainurl.com/article/this_is_an_url_title/111'

    parser = Tzispa::Rig::ParserNext.new(TPL_URL2, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, [2091]
    assert_equal parser.render(binder), '/article_list/this_is_an_url_title/2091'

    parser = Tzispa::Rig::ParserNext.new(TPL_URL3, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), '/adminapp/article_edit/1220.json'
  end


  def test_api_parser
    parser = Tzispa::Rig::ParserNext.new("#{TPL_API1} #{TPL_API2} #{TPL_API3}", domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 4
    assert_instance_of Tzispa::Rig::ParsedApi, parser.the_parsed[1]
    assert_instance_of Tzispa::Rig::ParsedApi, parser.the_parsed[2]
    assert_instance_of Tzispa::Rig::ParsedApi, parser.the_parsed[3]
    assert_equal parser.the_parsed[1].handler, 'article'
    assert_equal parser.the_parsed[1].verb, 'add'
    assert_nil parser.the_parsed[1].predicate
    assert_nil parser.the_parsed[1].app_name
    assert_equal parser.the_parsed[2].handler, 'article'
    assert_equal parser.the_parsed[2].verb, 'edit'
    assert_equal parser.the_parsed[2].predicate, "#{parser.the_parsed[0].anchor}"
    assert_equal parser.the_parsed[2].app_name, :adminapp
    assert_equal parser.the_parsed[3].handler, 'order'
    assert_equal parser.the_parsed[3].verb, 'detail_sum'
    assert_equal parser.the_parsed[3].predicate, '2016_10,2016_12'
    assert_nil parser.the_parsed[3].app_name
  end

  def test_api_render
    parser = Tzispa::Rig::ParserNext.new(TPL_API1, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'http://mytestdomainurl.com/article/add'

    parser = Tzispa::Rig::ParserNext.new(TPL_API2, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, [11999]
    assert_equal parser.render(binder), 'http://admin.mytestdomainurl.com/adminapp/article/edit/11999'

    sign = context.sign_array ['order', 'detail_sum', '2016_10,2016_12']
    parser = Tzispa::Rig::ParserNext.new(TPL_API3, domain: domain, content_type: :htm, bindable: true).parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), "http://mytestdomainurl.com/#{sign}__order/detail_sum/2016_10,2016_12"

  end


  def test_blk_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_BLK, domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 5
    assert_instance_of Tzispa::Rig::ParsedBlock, parser.the_parsed[1]
    assert_instance_of Tzispa::Rig::ParsedBlock, parser.the_parsed[2]
    assert_instance_of Tzispa::Rig::ParsedIBlock, parser.the_parsed[3]
    assert_instance_of Tzispa::Rig::ParsedIBlock, parser.the_parsed[4]
    assert_equal parser.the_parsed[1].id, 'detail'
    assert_equal parser.the_parsed[2].id, 'product.detail'
    assert_equal parser.the_parsed[2].params, "tab=#{parser.the_parsed[0].anchor}"
    assert_equal parser.the_parsed[3].id, "test"
    assert_equal parser.the_parsed[3].id_then, "block_one"
    assert_equal parser.the_parsed[3].id_else, 'product.block_two'
    assert_equal parser.the_parsed[3].params_then, "select=50"
    assert_nil parser.the_parsed[3].params_else
    assert_equal parser.the_parsed[4].id, "test"
    assert_equal parser.the_parsed[4].id_then, "product.block_one"
    assert_equal parser.the_parsed[4].id_else, 'block_two'
    assert_equal parser.the_parsed[4].params_else, "select=10"
    assert_nil parser.the_parsed[4].params_then
  end

  def test_static_parser
    parser = Tzispa::Rig::ParserNext.new(TPL_STA, domain: domain, content_type: :htm, bindable: true).parse!
    assert_equal parser.the_parsed.count, 4
    assert_instance_of Tzispa::Rig::ParsedStatic, parser.the_parsed[1]
    assert_instance_of Tzispa::Rig::ParsedStatic, parser.the_parsed[2]
    assert_instance_of Tzispa::Rig::ParsedStatic, parser.the_parsed[3]
    assert_equal parser.the_parsed[1].id, 'whatsnew'
    assert_equal parser.the_parsed[2].id, 'product.whatsnew'
    assert_equal parser.the_parsed[2].params, "section=retail"
    assert_equal parser.the_parsed[3].id, 'product.whatsnew'
    assert_equal parser.the_parsed[3].params, "section=#{parser.the_parsed[0].anchor}"
  end


  def teardown
    all_templates.each { |tpl|
      FileUtils.rm tpl.filename
    }
  end


end
