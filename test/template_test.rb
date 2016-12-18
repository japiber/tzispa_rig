require 'fileutils'
require 'test_helper'

class TemplateTest < Minitest::Test

  FILENAME = "test/res/testfile"
  STR_T = "This is a plain text file\n"

  def setup
    mkfile = ::File.new FILENAME, "wt"
    mkfile << STR_T
    mkfile.close
    @file = Tzispa::Rig::File.new FILENAME
    @file.load!
    @nofile = Tzispa::Rig::File.new "test/res/notexistingfile"
    #@tpl = Tzispa::Rig::Template.new("test/res/template.rig")
  end

  def test_file
    assert @file.exist?
    assert_equal @file.content, STR_T
    refute @nofile.exist?
    assert_raises(Tzispa::Rig::NotFound) { @nofile.load! }
  end

  def test_modified_file
    refute @file.modified?
    # to force modified file timestamp
    sleep 0.3
    mkfile = ::File.new FILENAME, "at"
    mkfile << STR_T
    mkfile.close
    assert @file.modified?
  end

  def teardown
    FileUtils.rm FILENAME
  end



end
