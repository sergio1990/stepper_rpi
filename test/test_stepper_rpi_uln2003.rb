# frozen_string_literal: true

require "test_helper"

class TestStepperRpiULN2003 < Minitest::Test
  def test_do_steps_successfully
    gpio_adapter = DummyGpioAdapter.new
    driver = StepperRpi::Drivers::ULN2003.new(mode: 0, pins: [1, 2, 3, 4], gpio_adapter: gpio_adapter)

    driver.connect
    driver.do_steps(1)

    sleep(0.01) while driver.is_running

    assert driver.is_connected
    refute driver.is_running
    assert_equal 1, driver.position

    driver.disconnect

    refute driver.is_connected
  end
end
