require 'test_helper'

class ParametersTest < Minitest::Test
  extend Minitest::Spec::DSL

  RAW_PARAMS = "k1=value1;k2=value2"
  RAW_ADDPARAMS = "k4=value4"

  let(:params) { Tzispa::Rig::Parameters.new RAW_PARAMS, ';' }
  let(:badparams) { Tzispa::Rig::Parameters.new RAW_PARAMS }

  def test_params
    assert params.has? 'k1'
    assert params['k1'] == 'value1'
    assert_equal params['k2'], 'value2'
    assert_nil params['k4']
  end

  def test_params_set
    params.merge RAW_ADDPARAMS
    assert_equal params['k4'], 'value4'
    assert_equal params.to_s, "#{RAW_PARAMS};#{RAW_ADDPARAMS}"
    params['k5'] = 'value5'
    assert params.has? 'k5'
    assert_equal params['k5'], 'value5'
    assert_equal params.to_s, "#{RAW_PARAMS};#{RAW_ADDPARAMS};k5=value5"
  end

  def test_bad_params
    refute_equal badparams['k1'], 'value1'
    refute badparams.has? 'k2'
  end


end
