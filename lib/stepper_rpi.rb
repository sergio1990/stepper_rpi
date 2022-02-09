# frozen_string_literal: true

require_relative "stepper_rpi/version"
require_relative "stepper_rpi/errors"
require_relative "stepper_rpi/gpio_adapter"
require_relative "stepper_rpi/configuration"
require_relative "stepper_rpi/drivers/base_motor_driver"
require_relative "stepper_rpi/drivers/uln2003"
require_relative "stepper_rpi/motor"

module StepperRpi
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end
  
  def self.configure
    yield(configuration)
  end

  def self.motor(driver:)
    StepperRpi::Motor.new(
      driver: driver
    )
  end
end
