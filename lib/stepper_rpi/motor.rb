require_relative './modes'
require_relative './errors'
require_relative './gpio_adapter'

module StepperRpi
  class Motor
    attr_accessor :speed
    attr_reader :is_running, :position, :is_connected

    def initialize(mode:, pins:, gpio_adapter:)
      if !StepperRpi::MODES.include?(mode)
        raise StepperRpi::MotorError, "Invalid mode passed: '#{mode}'!"
      end
      if !pins.kind_of?(::Array) || pins.count != 4
        raise StepperRpi::MotorError, "Passed pins isn't an array or the number of elements isn't 4!"
      end
      if gpio_adapter == nil || !gpio_adapter.kind_of?(StepperRpi::GPIOAdapter)
        raise StepperRpi::MotorError, "Invalid GPIO adapter passed! The income adapter is whether nil or isn't inherited from the `StepperRpi::GPIOAdapter` class!"
      end

      @mode = mode
      @pins = pins
      @gpio_adapter = gpio_adapter
      @is_running = false
      @is_connected = false
      @position = 0
      @speed = 1
      @current_beat = -1
      @is_running_terminated = false
      @beat_sequence = BEAT_SEQUENCES[mode]
      @beats_in_sequence = @beat_sequence.count
    end

    def connect
      return if is_connected

      pins.each { gpio_adapter.setup_pin(_1) }
      @is_connected = true
    end

    def disconnect
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

    # [ORANGE, YELLOW, PINK, BLUE]
    BEAT_SEQUENCES = {
      StepperRpi::Mode::FULL_STEP => [
        [1, 0, 1, 0],
        [0, 1, 1, 0],
        [0, 1, 0, 1],
        [1, 0, 0, 1]
      ],
      StepperRpi::Mode::HALF_STEP => [
        [1, 0, 0, 0],
        [1, 1, 0, 0],
        [0, 1, 0, 0],
        [0, 1, 1, 0],
        [0, 0, 1, 0],
        [0, 0, 1, 1],
        [0, 0, 0, 1],
        [1, 0, 0, 1]
      ]
    }

    attr_reader :mode,
      :pins,
      :gpio_adapter,
      :current_beat,
      :runner_thread,
      :beats_in_sequence,
      :beat_sequence,
      :is_running_terminated

    def run_stepper(number_of_steps)
      is_backward = number_of_steps < 0
      number_of_steps = number_of_steps.abs
      step_diff = is_backward ? -1 : 1
      @is_running = true

      @runner_thread = Thread.new {
        number_of_steps.times do |step_index|
          @position += step_diff
          @current_beat += step_diff
          if @current_beat < 0
            @current_beat = beats_in_sequence - 1
          elsif @current_beat > beats_in_sequence - 1
            @current_beat = 0
          end
          sequence = beat_sequence[@current_beat]
          pins.zip(sequence).each do |pin_with_value|
            pin = pin_with_value[0]
            value = pin_with_value[1]

            gpio_adapter.set_pin_value(pin, value)
          end

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
