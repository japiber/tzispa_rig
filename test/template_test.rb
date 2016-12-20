require 'fileutils'
require 'test_helper'

class TemplateTest < Minitest::Test
  extend Minitest::Spec::DSL

  FILENAME = "test/res/testfile"
  STR_T    = "This is a plain text file\n"
  STR_L    = "This is a layout template file\n"
  STR_B    = "This is a block template file\n"
  STR_S    = "This is a static template file\n"

  let(:file) { Tzispa::Rig::File.new(FILENAME) }
  let(:nofile) { Tzispa::Rig::File.new "test/res/notexistingfile" }

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
  let(:index_layout) { Tzispa::Rig::Template.new name: 'index', type: :layout, domain: domain }
  let(:index_block) { Tzispa::Rig::Template.new name: 'index', type: :block, domain: domain }
  let(:index_static) { Tzispa::Rig::Template.new name: 'index', type: :static, domain: domain }

  def setup
    mkfile = ::File.new file.filename, "wt"
    mkfile << STR_T
    mkfile.close
    file.load!
    mklayout = ::File.new index_layout.filename, "wt"
    mklayout << STR_L
    mklayout.close
    index_layout.load!
    mkblock = ::File.new index_block.filename, "wt"
    mkblock << STR_B
    mkblock.close
    index_block.load!
    mkstatic = ::File.new index_static.filename, "wt"
    mkstatic << STR_S
    mkstatic.close
    index_static.load!
  end

  def test_file
    assert file.exist?
    assert_equal file.content, STR_T
    refute nofile.exist?
    assert_raises(Tzispa::Rig::NotFound) { nofile.load! }
    refute file.modified?
    # to force modified file timestamp
    sleep 0.3
    mkfile = ::File.new file.filename, "at"
    mkfile << STR_T
    mkfile.close
    assert file.modified?
  end

  def test_rig_layout
    assert index_layout.exist?
    assert_equal index_layout.content, STR_L
    assert_equal index_layout.type, :layout
    assert index_layout.layout?
    refute index_layout.modified?
    # to force modified file timestamp
    sleep 0.3
    mkfile = ::File.new index_layout.filename, "at"
    mkfile << STR_L
    mkfile.close
    assert index_layout.modified?
    assert_equal index_layout.load!.content, "#{STR_L}#{STR_L}"
  end

  def test_rig_block
    assert index_block.exist?
    assert_equal index_block.content, STR_B
    assert_equal index_block.type, :block
    assert index_block.block?
  end

  def test_rig_static
    assert index_static.exist?
    assert_equal index_static.content, STR_S
    assert_equal index_static.type, :static
    assert index_static.static?
  end

  def teardown
    FileUtils.rm file.filename
    FileUtils.rm index_layout.filename
    FileUtils.rm index_block.filename
    FileUtils.rm index_static.filename
  end



end
