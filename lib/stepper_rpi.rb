# frozen_string_literal: true

require_relative "stepper_rpi/version"
require_relative "stepper_rpi/errors"
require_relative "stepper_rpi/gpio_adapter"
require_relative "stepper_rpi/drivers/base_motor_driver"
require_relative "stepper_rpi/drivers/uln2003"
require_relative "stepper_rpi/drivers/drv8825"
require_relative "stepper_rpi/motor"

module StepperRpi
  def self.motor(driver:)
    StepperRpi::Motor.new(
      driver: driver
    )
  end
end
