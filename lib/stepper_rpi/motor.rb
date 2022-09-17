require_relative './errors'

module StepperRpi
  class Motor
    def initialize(driver:)
      @driver = driver
    end

    def connect
      return if is_connected

      driver.connect
    end

    def disconnect
      driver.disconnect
    end

    def do_steps(number_of_steps)
      if number_of_steps.nil? || !number_of_steps.kind_of?(::Integer)
        raise StepperRpi::MotorError, "The number of steps must be an integer value!"
      end
      if !is_connected
        raise StepperRpi::MotorError, "The motor isn't connected! Call `#connect` before calling this method!"
      end

      stop
      driver.do_steps(number_of_steps)
    end

    def stop
      if !is_connected
        raise StepperRpi::MotorError, "The motor isn't connected! Call `#connect` before calling this method!"
      end

      driver.stop
    end

    def is_running
      driver.is_running
    end

    def position
      driver.position
    end

    def is_connected
      driver.is_connected
    end

    def speed
      driver.speed
    end

    def speed=(new_speed)
      driver.speed = new_speed
    end

    private

    attr_reader :driver
  end
end
