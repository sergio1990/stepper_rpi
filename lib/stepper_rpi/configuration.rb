require_relative './errors'

module StepperRpi
  class Configuration
    attr_reader :gpio_adapter

    def gpio_adapter=(value)
      if !value.is_kind_of?(StepperRpi::GPIOAdapter)
        raise StepperRpi::ConfigurationError, "You need to pass a correct GPIO adapter instance!"
      end
      @gpio_adapter = value
    end
  end
end
