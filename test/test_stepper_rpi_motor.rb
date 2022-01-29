# frozen_string_literal: true

require "test_helper"

class TestStepperRpiMotor < Minitest::Test
  def test_do_steps_successfully
    gpio_adapter = DummyGpioAdapter.new
    motor = StepperRpi::Motor.new(
      mode: StepperRpi::Mode::HALF_STEP,
      pins: [1, 2, 3, 4],
      gpio_adapter: gpio_adapter
    )
    gpio_adapter.expects(:setup_pin).times(4)
    gpio_adapter.expects(:set_pin_value).times(4)

    motor.connect
    motor.do_steps(1)

    sleep(0.01) while motor.is_running

    assert motor.is_connected
    refute motor.is_running
    assert_equal 1, motor.position
  end
end
