# frozen_string_literal: true

require "test_helper"

class TestStepperRpiDRV8825 < Minitest::Test
  def test_do_steps_successfully
    gpio_adapter = DummyGpioAdapter.new
    mode = StepperRpi::Drivers::DRV8825::Mode.new(
      microstepping_mode: StepperRpi::Drivers::DRV8825::MicrosteppingMode::STEP_FULL,
      step_mode: StepperRpi::Drivers::DRV8825::StepMode::SOFTWARE_PWM
    )
    pins = StepperRpi::Drivers::DRV8825::Pins.new(
      mode: [15, 16, 17],
      dir: 8,
      pwm_channel: 10
    )
    driver = StepperRpi::Drivers::DRV8825.new(mode: mode, pins: pins, gpio_adapter: gpio_adapter)

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
