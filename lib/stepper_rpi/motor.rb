require_relative './modes'
require_relative './errors'
require_relative './gpio_adapter'

module StepperRpi
  class Motor
    attr_accessor :speed
    attr_reader :is_running, :position, :is_connected

    def initialize(driver:)
      @driver = driver
      @is_running = false
      @is_connected = false
      @position = 0
      @speed = 1
      @is_running_terminated = false
    end

    def connect
      return if is_connected

      driver.connect
      @is_connected = true
    end

    def disconnect
      driver.disconnect
      @is_connected = false
    end

    def do_steps(number_of_steps)
      if number_of_steps.nil? || !number_of_steps.kind_of?(::Integer)
        raise StepperRpi::MotorError, "The number of steps must be an integer value!"
      end
      if !is_connected
        raise StepperRpi::MotorError, "The motor isn't connected! Call `#connect` before calling this method!"
      end

      stop
      run_stepper(number_of_steps)
    end

    def stop
      if !is_connected
        raise StepperRpi::MotorError, "The motor isn't connected! Call `#connect` before calling this method!"
      end

      return if !runner_thread
      return if !runner_thread.alive?

      @is_running_terminated = true
      sleep(0.001) while runner_thread.alive?
      @is_running_terminated = false
      @is_running = false
    end

    private

    attr_reader :driver, :runner_thread, :is_running_terminated

    def run_stepper(number_of_steps)
      is_backward = number_of_steps < 0
      number_of_steps = number_of_steps.abs
      step_diff = is_backward ? -1 : 1
      @is_running = true

      @runner_thread = Thread.new {
        number_of_steps.times do |step_index|
          @position += step_diff

          driver.step

          if @is_running_terminated
            # Give some time for the motor to complete rotation
            sleep(0.001)
            @is_running = false
            Thread.exit
          end

          # If it is the last step - give some time for the motor to rotate
          # If not - then put the delay according to the configured speed
          if step_index == number_of_steps - 1
            sleep(0.001)
          else
            sleep(1 / speed.to_f)
          end
        end  

        @is_running = false
      }
    end
  end
end
