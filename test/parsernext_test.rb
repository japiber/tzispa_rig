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
    parser = Tzispa::Rig::ParserNext.new text: STR_P, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 0
    assert_equal parser.attribute_tags.count, 0
    assert parser.empty?
  end

  def test_meta_parser
    parser = Tzispa::Rig::ParserNext.new text: TPL_META, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 2
    assert_equal parser.attribute_tags.count, 2
    assert_equal parser.attribute_tags, [:meta1, :meta2]
    assert_equal parser.attribute_tags, [:meta1, :meta2]
    assert_instance_of Tzispa::Rig::TypeToken::Meta, parser.tokens[0]
    assert_instance_of Tzispa::Rig::TypeToken::Meta, parser.tokens[1]
    assert_equal parser.tokens[0].id, :meta1
    assert_equal parser.tokens[1].id, :meta2
  end

  def test_meta_render
    parser = Tzispa::Rig::ParserNext.new text: TPL_META, domain: domain, content_type: :txt, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [123, 'john doe']
    assert_equal parser.render(binder), 'meta testing 123\n\n 123:john doe\n'
    binder = binder_fake.new parser, context, [nil, 'john doe']
    assert_equal parser.render(binder), 'meta testing \n\n :john doe\n'
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'meta testing \n\n :\n'
  end

  def test_var_parser
    parser = Tzispa::Rig::ParserNext.new text: TPL_VAR, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 4
    assert_equal parser.attribute_tags.count, 4
    assert_equal parser.attribute_tags, [:meta1, :meta2, :uno, :dos]
    # metas are parsed before vars
    assert_instance_of Tzispa::Rig::TypeToken::Var, parser.tokens[2]
    assert_instance_of Tzispa::Rig::TypeToken::Var, parser.tokens[3]
    assert_equal parser.tokens[2].id, :uno
    assert_equal parser.tokens[3].id, :dos
  end

  def test_var_render
    parser = Tzispa::Rig::ParserNext.new text: TPL_VAR, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [2016, 'john doe', 'happy', 'year']
    assert_equal parser.render(binder), 'var testing happy\n\n 2016 year  happy:john doe\n'
    binder = binder_fake.new parser, context, [2015, 'john doe', 'happy']
    assert_equal parser.render(binder), 'var testing happy\n\n 2015   happy:john doe\n'
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'var testing \n\n    :\n'
  end

  def test_loop_parser
    parser = Tzispa::Rig::ParserNext.new text: TPL_LOOP, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 2
    assert_equal parser.attribute_tags.count, 2
    assert_equal parser.attribute_tags, [:literator, :tres]
    assert_instance_of Tzispa::Rig::TypeToken::Loop, parser.tokens[0]
    assert_equal parser.tokens[0].id, :literator
    assert_equal parser.tokens[0].body_parser.tokens.count, 2
    assert_equal parser.tokens[0].body_parser.attribute_tags.count, 2
    assert_equal parser.tokens[0].body_parser.attribute_tags, [:uno, :dos]
    assert_instance_of Tzispa::Rig::TypeToken::Var, parser.tokens[0].body_parser.tokens[0]
    assert_instance_of Tzispa::Rig::TypeToken::Var, parser.tokens[0].body_parser.tokens[1]
    assert_equal parser.tokens[0].body_parser.tokens[0].id, :uno
    assert_equal parser.tokens[0].body_parser.tokens[1].id, :dos
  end

  def test_loop_render
    parser = Tzispa::Rig::ParserNext.new text: TPL_LOOP, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [Struct.new(:data).new([
      binder_fake.new(parser.tokens[0].body_parser, {}, [1, 2]),
      binder_fake.new(parser.tokens[0].body_parser, {}, [3, 4]),
      binder_fake.new(parser.tokens[0].body_parser, {}, [5, 6])
      ]), 'watching']
    assert_equal parser.render(binder), ' loop testing 1 2\n 1  loop testing 3 4\n 3  loop testing 5 6\n 5  watching'
    binder = binder_fake.new parser, context, [Struct.new(:data).new([]), 'watching']
    assert_equal parser.render(binder), ' watching'
    binder = binder_fake.new parser, context, [Struct.new(:data).new, 'watching']
    #assert_raises(NoMethodError) { parser.render(binder) }
    binder = binder_fake.new parser, context, [[], 'watching']
    assert_raises(NoMethodError) { parser.render(binder) }
  end

  def test_ife_parser
    parser = Tzispa::Rig::ParserNext.new text: TPL_IFE, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 2
    assert_equal parser.tokens[0].attribute_tags.count, 3
    assert_equal parser.tokens[0].attribute_tags, [:condition, :uno, :dos]
    assert_equal parser.tokens[1].attribute_tags.count, 4
    assert_equal parser.tokens[1].attribute_tags, [:condition, :dos, :tres, :uno]
    assert_equal parser.attribute_tags.count, 4
    assert_equal parser.attribute_tags, [:condition, :uno, :dos, :tres]
    assert_instance_of Tzispa::Rig::TypeToken::Ife, parser.tokens[0]
    assert_equal parser.tokens[0].test, :condition
    assert_equal parser.tokens[1].test, :condition
    assert_equal parser.tokens[0].then_parser.tokens.count, 2
    assert_nil parser.tokens[0].else_parser
    assert_equal parser.tokens[1].then_parser.tokens.count, 3
    assert_equal parser.tokens[1].else_parser.tokens.count, 1
  end

  def test_ife_render
    parser = Tzispa::Rig::ParserNext.new text: TPL_IFE, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [1==1, 'john doe', 'happy', 'year']
    assert_equal parser.render(binder), ' ife testing john doe happy\n   john doe happy year  '
    binder = binder_fake.new parser, context, [1==0, 'john doe', 'happy', 'year']
    assert_equal parser.render(binder), '  happy  '
  end


  def test_url_parser
    parser = Tzispa::Rig::ParserNext.new text: "#{TPL_URL1} #{TPL_URL2} #{TPL_URL3}", domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 4
    assert_instance_of Tzispa::Rig::TypeToken::Url, parser.tokens[1]
    assert_instance_of Tzispa::Rig::TypeToken::Url, parser.tokens[2]
    assert_equal parser.tokens[0].id, :idp
    assert_equal parser.tokens[1].layout, 'article'
    assert_equal parser.tokens[2].layout, 'product@list'
    assert_equal parser.tokens[3].layout, 'article_edit'
    assert_equal parser.tokens[1].params, 'id=111,title=this_is_an_url_title'
    assert_equal parser.tokens[2].params, "id=#{parser.tokens[0].anchor},title=this_is_an_url_title"
    assert_equal parser.tokens[3].params, 'id=1220,format=json'
    assert_nil parser.tokens[1].app_name
    assert_nil parser.tokens[2].app_name
    assert_equal parser.tokens[3].app_name, :adminapp
  end

  def test_url_render
    parser = Tzispa::Rig::ParserNext.new text: TPL_URL1, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'http://mytestdomainurl.com/article/this_is_an_url_title/111'

    parser = Tzispa::Rig::ParserNext.new text: TPL_URL2, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [2091]
    assert_equal parser.render(binder), '/product@list/this_is_an_url_title/2091'

    parser = Tzispa::Rig::ParserNext.new text: TPL_URL3, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), '/adminapp/article_edit/1220.json'
  end

  def test_api_parser
    parser = Tzispa::Rig::ParserNext.new text: "#{TPL_API1} #{TPL_API2} #{TPL_API3}", domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 4
    assert_instance_of Tzispa::Rig::TypeToken::Api, parser.tokens[1]
    assert_instance_of Tzispa::Rig::TypeToken::Api, parser.tokens[2]
    assert_instance_of Tzispa::Rig::TypeToken::Api, parser.tokens[3]
    assert_equal parser.tokens[1].handler, 'article'
    assert_equal parser.tokens[1].verb, 'add'
    assert_nil parser.tokens[1].predicate
    assert_nil parser.tokens[1].app_name
    assert_equal parser.tokens[2].handler, 'article'
    assert_equal parser.tokens[2].verb, 'edit'
    assert_equal parser.tokens[2].predicate, "#{parser.tokens[0].anchor}"
    assert_equal parser.tokens[2].app_name, :adminapp
    assert_equal parser.tokens[3].handler, 'order'
    assert_equal parser.tokens[3].verb, 'detail_sum'
    assert_equal parser.tokens[3].predicate, '2016_10,2016_12'
    assert_nil parser.tokens[3].app_name
  end

  def test_api_render
    parser = Tzispa::Rig::ParserNext.new text: TPL_API1, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), 'http://mytestdomainurl.com/article/add'

    parser = Tzispa::Rig::ParserNext.new text: TPL_API2, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, [11999]
    assert_equal parser.render(binder), 'http://admin.mytestdomainurl.com/adminapp/article/edit/11999'

    sign = context.sign_array ['order', 'detail_sum', '2016_10,2016_12']
    parser = Tzispa::Rig::ParserNext.new text: TPL_API3, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    binder = binder_fake.new parser, context, []
    assert_equal parser.render(binder), "http://mytestdomainurl.com/#{sign}__order/detail_sum/2016_10,2016_12"
  end


  def test_blk_parser
    parser = Tzispa::Rig::ParserNext.new text: TPL_BLK, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 5
    assert_instance_of Tzispa::Rig::TypeToken::Blk, parser.tokens[1]
    assert_instance_of Tzispa::Rig::TypeToken::Blk, parser.tokens[2]
    assert_instance_of Tzispa::Rig::TypeToken::Iblk, parser.tokens[3]
    assert_instance_of Tzispa::Rig::TypeToken::Iblk, parser.tokens[4]
    assert_equal parser.tokens[1].id, 'detail'
    assert_equal parser.tokens[2].id, 'product@detail'
    assert_equal parser.tokens[2].params, "tab=#{parser.tokens[0].anchor}"
    assert_equal parser.tokens[3].id, "test"
    assert_equal parser.tokens[3].id_then, "block_one"
    assert_equal parser.tokens[3].id_else, 'product@block_two'
    assert_equal parser.tokens[3].params_then, "select=50"
    assert_nil parser.tokens[3].params_else
    assert_equal parser.tokens[4].id, "test"
    assert_equal parser.tokens[4].id_then, "product@block_one"
    assert_equal parser.tokens[4].id_else, 'block_two'
    assert_equal parser.tokens[4].params_else, "select=10"
    assert_nil parser.tokens[4].params_then
  end

  def test_static_parser
    parser = Tzispa::Rig::ParserNext.new text: TPL_STA, domain: domain, content_type: :htm, bindable: true
    parser.parse!
    assert_equal parser.tokens.count, 4
    assert_instance_of Tzispa::Rig::TypeToken::Static, parser.tokens[1]
    assert_instance_of Tzispa::Rig::TypeToken::Static, parser.tokens[2]
    assert_instance_of Tzispa::Rig::TypeToken::Static, parser.tokens[3]
    assert_equal parser.tokens[1].id, 'whatsnew'
    assert_equal parser.tokens[2].id, 'product@whatsnew'
    assert_equal parser.tokens[2].params, "section=retail"
    assert_equal parser.tokens[3].id, 'product@whatsnew'
    assert_equal parser.tokens[3].params, "section=#{parser.tokens[0].anchor}"
  end


  def teardown
    all_templates.each { |tpl|
      FileUtils.rm tpl.filename
    }
  end


end
