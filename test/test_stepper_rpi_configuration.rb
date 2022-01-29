# frozen_string_literal: true

require "test_helper"

class TestStepperRpiConfiguration < Minitest::Test
  def test_setting_wrong_gpio_adapter
    configuration = StepperRpi::Configuration.new

    error = assert_raises(StepperRpi::ConfigurationError) {
      configuration.gpio_adapter = Object.new
    }

    assert_nil configuration.gpio_adapter
    assert_equal "You need to pass a correct GPIO adapter instance!", error.message
  end

  def test_setting_correct_gpio_adapter
    configuration = StepperRpi::Configuration.new
    adapter = DummyGpioAdapter.new
    configuration.gpio_adapter = adapter

    refute_nil configuration.gpio_adapter
    assert_same configuration.gpio_adapter, adapter
  end
end
