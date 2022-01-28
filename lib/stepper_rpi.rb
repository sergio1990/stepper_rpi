# frozen_string_literal: true

require_relative "stepper_rpi/version"
require_relative "stepper_rpi/errors"
require_relative "stepper_rpi/modes"
require_relative "stepper_rpi/gpio_adapter"
require_relative "stepper_rpi/configuration"
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

  def motor(mode:, pins:)
    StepperRpi::Motor.new(
      mode: mode,
      pins: pins,
      gpio_adapter: StepperRpi.configuration.gpio_adapter
    )
  end
end
