require_relative './base_motor_driver.rb'

module StepperRpi
  module Drivers
    class ULN2003 < BaseMotorDriver
      module Mode
        FULL_STEP = 0
        HALF_STEP = 1

        ALL = [FULL_STEP, HALF_STEP].freeze
      end

      def initialize(mode:, pins:, gpio_adapter:)
        super

        @current_beat = -1
        @beat_sequence = BEAT_SEQUENCES[mode]
        @beats_in_sequence = @beat_sequence.count
      end

      def connect
        pins.each { gpio_adapter.setup_pin(_1) }
        @is_connected = true
      end

      def disconnect
        pins.each { gpio_adapter.cleanup_pin(_1) }
        @is_connected = false
      end

      def stop
        return if !runner_thread
        return if !runner_thread.alive?

        @is_running_terminated = true
        sleep(0.001) while runner_thread.alive?
        @is_running_terminated = false
        @is_running = false
      end

      def do_steps(number_of_steps)
        is_backward = number_of_steps < 0
        number_of_steps = number_of_steps.abs
        step_diff = is_backward ? -1 : 1
        @is_running = true
        speed_delay = 1 / speed.to_f

        @runner_thread = Thread.new {
          number_of_steps.times do |step_index|
            @position += step_diff

            step(dir: step_diff)

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
              sleep(speed_delay)
            end
          end  

          @is_running = false
        }
      end

      private

      attr_reader :runner_thread, :is_running_terminated

      # [ORANGE, YELLOW, PINK, BLUE]
      BEAT_SEQUENCES = {
        Mode::FULL_STEP => [
          [1, 0, 1, 0],
          [0, 1, 1, 0],
          [0, 1, 0, 1],
          [1, 0, 0, 1]
        ],
        Mode::HALF_STEP => [
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

      def step(dir:)
        @current_beat += dir
        if @current_beat < 0
          @current_beat = @beats_in_sequence - 1
        elsif @current_beat > @beats_in_sequence - 1
          @current_beat = 0
        end
        sequence = @beat_sequence[@current_beat]
        pins.zip(sequence).each do |pin_with_value|
          pin = pin_with_value[0]
          value = pin_with_value[1]

          gpio_adapter.set_pin_value(pin, value)
        end
      end
    end
  end
end
