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
      @current_beat = -1
      @is_running_terminated = false
      @beats_in_sequence = BEAT_SEQUENCES[mode].count

      pins.each { gpio_adapter.setup_pin(_1) }
    end

    def do_steps(number_of_steps)
      stop
      run_stepper(number_of_steps)
    end

    def stop
      return if !runner_thread
      return if !runner_thread.alive?

      @is_running_terminated = true
      sleep(0.001) while runner_thread.alive?
      @is_running_terminated = false
    end

    private

    BEAT_SEQUENCES = {
      StepperRpi::Mode::FULL_STEP => [
        [1, 0, 1, 0],
        [0, 1, 1, 0],
        [0, 1, 0, 1],
        [1, 0, 0, 1]
      ],
      StepperRpi::Mode::HALF_STEP => [
        [1, 0, 0, 0],
        [1, 0, 1, 0],
        [0, 0, 1, 0],
        [0, 1, 1, 0],
        [0, 1, 0, 0],
        [0, 1, 0, 1],
        [0, 0, 0, 1],
        [1, 0, 0, 1]
      ]
    }

    attr_reader :mode, :pins, :gpio_adapter, :current_beat, :runner_thread, :beats_in_sequence, :is_running_terminated

    def run_stepper(number_of_steps)
      is_backward = number_of_steps < 0
      number_of_steps = abs(number_of_steps)
      step_diff = is_backward ? -1 : 1

      @runner_thread = Thread.new {
        number_of_steps.each do
          @position += step_diff
          @current_beat += step_diff
          if @current_beat < 0
            @current_beat = beats_in_sequence - 1
          elsif @current_beat > beats_in_sequence - 1
            @current_beat = 0
          end
          sequence = BEAT_SEQUENCES[mode][@current_beat]
          pins.zip(sequence).each do |pin_with_value|
            pin = pin_with_value[0]
            value = pin_with_value[1]

            gpio_adapter.set_pin_value(pin, value)
          end

          sleep(0.001)

          if @is_running_terminated
            Thread.exit
          end
        end  
      }
    end
  end
end
