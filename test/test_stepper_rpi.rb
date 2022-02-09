# frozen_string_literal: true

require "test_helper"

class TestStepperRpi < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::StepperRpi::VERSION
  end

  def test_creating_motor_instance_successfully
    driver = DummyDriver.new(mode: 0, pins: [1, 2, 3, 4], gpio_adapter: DummyGpioAdapter.new)
    motor = StepperRpi.motor(driver: driver)
    refute_nil motor
    assert_kind_of StepperRpi::Motor, motor
  end
end
