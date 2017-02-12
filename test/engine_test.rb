require 'fileutils'
require 'test_helper'

class EngineTest < Minitest::Test
  include TemplateTestHelper

  def setup
    mklayout = ::File.new index_layout.filename, "wt"
    mklayout << STR_L
    mklayout.close
    index_layout.load!
    mkplayout = ::File.new productlist_layout.filename, "wt"
    mkplayout << STR_L
    mkplayout.close
    productlist_layout.load!
  end

  def test_index
    index = Tzispa::Rig::Engine.layout(name: 'index', domain: domain, content_type: :txt)
    assert_equal index.content, STR_L
    assert_equal index.type, :layout
    assert index.layout?
    refute index.modified?
    # to force modified file timestamp
    sleep 0.3
    mkfile = ::File.new index_layout.filename, "at"
    mkfile << STR_L
    mkfile.close
    assert index.modified?
    assert_equal index.load!.content, "#{STR_L}#{STR_L}"
  end

  def test_subdomainlayout
    playout = Tzispa::Rig::Engine.layout(name: 'product@list', domain: domain, content_type: :htm)
    assert_equal playout.type, :layout
    assert playout.layout?
    refute playout.modified?
    assert_equal playout.content, STR_L
  end

end
