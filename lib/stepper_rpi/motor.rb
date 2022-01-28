require_relative './modes'
require_relative './errors'
require_relative './gpio_adapter'

module StepperRpi
  class Motor
    attr_accessor :speed
    attr_reader :is_running, :position

    def initialize(mode:, pins:, gpio_adapter:)
      if !StepperRpi::MODES.include?(mode)
        raise StepperRpi::MotorError, "Invalid mode passed: '#{mode}'!"
      end
      if !pins.is_kind_of?(::Array) || pins.count != 4
        raise StepperRpi::MotorError, "Passed pins isn't an array or the number of elements isn't 4!"
      end
      if gpio_adapter == nil || !gpio_adapter.is_kind_of?(StepperRpi::GPIOAdapter)
        raise StepperRpi::MotorError, "Invalid GPIO adapter passed! The income adapter is whether nil isn't inherited from the `StepperRpi::GPIOAdapter` class!"
      end

      @mode = mode
      @pins = pins
      @gpio_adapter = gpio_adapter
      @is_running = false
      @position = 0
      @speed = 1
    end

    def do_steps(number_of_steps)
      
    end

    def stop
      
    end

    private

    attr_reader :mode, :pins, :gpio_adapter
  end
end
