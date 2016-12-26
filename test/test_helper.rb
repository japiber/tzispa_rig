$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'tzispa_rig'
require 'minitest/autorun'
require 'tzispa/helpers/security'


module TemplateTestHelper
  extend Minitest::Spec::DSL
  include Tzispa::Helpers::Security

  TPL_META = 'meta testing {%meta1%}\n\n {%meta1%}:{%meta2%}\n'
  TPL_VAR  = 'var testing <var:uno/>\n\n {%meta1%} <var:dos/>  <var:uno/>:{%meta2%}\n'
  TPL_LOOP = '<loop:literator> loop testing <var:uno/> <var:dos/>\n <var:uno/> </loop:literator> <var:tres/>'
  TPL_IFE  = '<ife:condition> ife testing <var:uno/> <var:dos/>\n </ife:condition> <ife:condition> <var:uno/> {%dos%} {%tres%} <else:condition/> <var:dos/> </ife:condition> '
  TPL_URL1  = '<url:article[id=111,title=this_is_an_url_title]/>'
  TPL_URL2  = '<purl:article_list[id={%idp%},title=this_is_an_url_title]/>'
  TPL_URL3  = '<purl@adminapp:article_edit[id=1220,format=json]/>'
  TPL_API1  = '<api:article:add/>'
  TPL_API2  = '<api@adminapp:article:edit:{%idarticle%}/>'
  TPL_API3  = '<sapi:order:detail_sum:2016_10,2016_12/>'
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

  let(:config_fake) {
    Struct.new(:canonical_url)
  }

  let(:app_fake) {
    Struct.new(:config)
  }

  let(:context_fake) {
    Struct.new(:app, :applications, :salt) {

      def layout_path(layout, params={})
        String.new.tap { |path|
          path << "/#{layout}"
          path << "/#{params[:title]}" if params[:title]
          user_params = params.reject { |k,v| k == :title || k == :format}
          path << "/#{user_params.values.join('__')}" if user_params.size > 0
          path << ".#{params[:format]}" if params[:format]
        }
      end

      def app_layout_path(app_name, layout, params={})
        String.new.tap { |path|
          path << "/#{app_name}"
          path << "/#{layout}"
          path << "/#{params[:title]}" if params[:title]
          user_params = params.reject { |k,v| k == :title || k == :format}
          path << "/#{user_params.values.join('__')}" if user_params.size > 0
          path << ".#{params[:format]}" if params[:format]
        }
      end

      def layout_canonical_url(layout, params={})
        String.new.tap { |path|
          path << "#{app.config.canonical_url}"
          path << "/#{layout}"
          path << "/#{params[:title]}" if params[:title]
          user_params = params.reject { |k,v| k == :title || k == :format}
          path << "/#{user_params.values.join('__')}" if user_params.size > 0
          path << ".#{params[:format]}" if params[:format]
        }
      end

      def app_layout_canonical_url(app_name, layout, params={})
        String.new.tap { |path|
          path << "#{applications[app_name].config.canonical_url}"
          path << "/#{app_name}"
          path << "/#{layout}"
          path << "/#{params[:title]}" if params[:title]
          user_params = params.reject { |k,v| k == :title || k == :format}
          path << "/#{user_params.values.join('__')}" if user_params.size > 0
          path << ".#{params[:format]}" if params[:format]
        }
      end

      def api(handler, verb, predicate, sufix, app_name = nil)
        String.new.tap { |path|
          path << (app_name ?
                  "#{applications[app_name].config.canonical_url}" :
                  "#{app.config.canonical_url}")
          path << "/#{app_name}" if app_name
          path << "/#{handler}/#{verb}"
          path << "/#{predicate}" if predicate
          path << ".#{sufix}" if sufix
        }
      end

      def sapi(handler, verb, predicate, sufix, app_name = nil)
        sign = sign_array [handler, verb, predicate]
        String.new.tap { |path|
          path << (app_name ? "#{applications[app_name].config.canonical_url}" : "#{app.config.canonical_url}")
          path << "/#{app_name}" if app_name
          path << "/#{sign}__#{handler}/#{verb}"
          path << "/#{predicate}" if predicate
          path << ".#{sufix}" if sufix
        }
      end

      def sign_array(astr)
        sign, i = String.new, 0
        astr.each { |s|
          i = i + 1
          sign << "#{"_"*i}#{s}"
        }
        sign << "**#{salt}"
        Digest::SHA1.hexdigest sign
      end

    }
  }

  let(:context) {
    cfg_main = config_fake.new 'http://mytestdomainurl.com'
    cfg_admin = config_fake.new 'http://admin.mytestdomainurl.com'
    app_main = app_fake.new cfg_main
    app_admin = app_fake.new cfg_admin
    applications = {
      main: app_main,
      adminapp: app_admin
    }
    context_fake.new app_main, applications, 'qwertyuiop0987654321'
  }

end
