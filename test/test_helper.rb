$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tzispa_rig'
require 'minitest/autorun'


module TemplateTestHelper
  extend Minitest::Spec::DSL

  TPL_META = 'meta testing {%meta1%}\n\n {%meta1%}:{%meta2%}\n'
  TPL_VAR  = 'var testing <var:uno/>\n\n {%meta1%} <var:dos/>  <var:uno/>:{%meta2%}\n'
  TPL_LOOP = '<loop:literator> loop testing <var:uno/> <var:dos/>\n </loop:literator> <var:dos/>'
  TPL_IFE  = '<ife:condition> ife testing <var:uno/> <var:dos/>\n </ife:condition> <ife:condition> <var:uno/> {%dos%} <else:condition/> <var:dos/> </ife:condition> '
  TPL_URL  = '<url:article[id=111,title=this_is_an_url_title]/> <purl:article_list[id={%idp%},title=this_is_an_url_title]/> <purl@adminapp:article_edit[id=122,format=json]/>'
  TPL_API  = '<api:article:add/> <api@adminapp:article:edit:{%idarticle%}/> <sapi:order:detail_sum:2016_10,2016_12/>'
  TPL_BLK  = '<blk:detail/> <blk:product.detail[tab={%selected_tab%}]/> <iblk:test:block_one[select=50]:product.block_two/> <iblk:test:product.block_one:block_two[select=10]/>'
  TPL_STA  = '<static:whatsnew/> <static:product.whatsnew[section=retail]/> <static:product.whatsnew[section={%selected%}]/>'


  FILENAME = "test/res/testfile"
  STR_T    = "This is a plain text file\n"
  STR_P    = "This is a rig template file\n"
  STR_L    = "This is a layout template file\n"
  STR_B    = "This is a block template file\n"
  STR_S    = "This is a static template file\n"

  let(:domain_fake) {
    Struct.new(:name) {
      def path
        "test/res/apps/#{name}"
      end

      def require(file)
        Kernel.require "./#{path}/#{file}"
      end
    }
  }
  let(:domain) { domain_fake.new :test_domain  }
  let(:file) { Tzispa::Rig::File.new(FILENAME) }
  let(:nofile) { Tzispa::Rig::File.new "test/res/notexistingfile" }
  let(:index_layout) { Tzispa::Rig::Template.new name: 'index', type: :layout, domain: domain, content_type: 'txt' }
  let(:index_block) { Tzispa::Rig::Template.new name: 'index', type: :block, domain: domain, content_type: 'txt' }
  let(:index_static) { Tzispa::Rig::Template.new name: 'index', type: :static, domain: domain, content_type: 'txt' }
  let(:detail_block) { Tzispa::Rig::Template.new name: 'detail', type: :block, domain: domain, content_type: :htm }
  let(:product_detail_block) { Tzispa::Rig::Template.new name: 'product.detail', type: :block, domain: domain, content_type: :htm }
  let(:block_one) { Tzispa::Rig::Template.new name: 'block_one', type: :block, domain: domain, content_type: :htm }
  let(:product_block_two) { Tzispa::Rig::Template.new name: 'product.block_two', type: :block, domain: domain, content_type: :htm }
  let(:product_block_one) { Tzispa::Rig::Template.new name: 'product.block_one', type: :block, domain: domain, content_type: :htm }
  let(:block_two) { Tzispa::Rig::Template.new name: 'block_two', type: :block, domain: domain, content_type: :htm }
  let(:whatsnew_static) { Tzispa::Rig::Template.new name: 'whatsnew', type: :static, domain: domain, content_type: :htm }
  let(:product_whatsnew_static) { Tzispa::Rig::Template.new name: 'product.whatsnew', type: :static, domain: domain, content_type: :htm }
  let(:all_templates) { [detail_block, product_detail_block, block_one, product_block_two, product_block_one, block_two, whatsnew_static, product_whatsnew_static] }

  let(:binder_fake) {
    Struct.new(:parser, :context, :values) {
      def data_struct
        parser.attribute_tags.count > 0 ? Struct.new(*parser.attribute_tags) : Struct.new(nil)
      end

      def data
        data_struct.new(*values)
      end
    }
  }

end
