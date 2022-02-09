# frozen_string_literal: true

require "test_helper"

class TestStepperRpiMotor < Minitest::Test
  def test_do_steps_successfully
    gpio_adapter = DummyGpioAdapter.new
    driver = DummyDriver.new(mode: 0, pins: [1, 2, 3, 4], gpio_adapter: gpio_adapter)
    motor = StepperRpi::Motor.new(
      driver: driver
    )
    driver.expects(:connect).once

    motor.connect
    motor.do_steps(1)

    sleep(0.01) while motor.is_running

    assert motor.is_connected
    refute motor.is_running
    assert_equal 1, motor.position
  end
end
