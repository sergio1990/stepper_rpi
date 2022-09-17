# frozen_string_literal: true

require "test_helper"

class TestStepperRpiMotor < Minitest::Test
  def test_connection_flow
    gpio_adapter = DummyGpioAdapter.new
    driver = DummyDriver.new(mode: 0, pins: [1, 2, 3, 4], gpio_adapter: gpio_adapter)
    motor = StepperRpi::Motor.new(driver: driver)

    driver.expects(:connect).once
    motor.connect

    driver.expects(:disconnect).once
    motor.disconnect
  end

  def test_stepping_flow
    gpio_adapter = DummyGpioAdapter.new
    driver = DummyDriver.new(mode: 0, pins: [1, 2, 3, 4], gpio_adapter: gpio_adapter)
    motor = StepperRpi::Motor.new(driver: driver)

    motor.connect
    
    driver.expects(:stop).once
    driver.expects(:do_steps).once
    motor.do_steps(5)
  end
end
