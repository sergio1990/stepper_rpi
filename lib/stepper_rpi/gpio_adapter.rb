module StepperRpi
  class GPIOAdapter
    def setup_pin(pin)
      raise NotImplementedError
    end

    def set_pin_value(pin, value)
      raise NotImplementedError
    end
  end
end
