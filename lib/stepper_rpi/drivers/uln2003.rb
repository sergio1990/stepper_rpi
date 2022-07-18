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
      end

      def disconnect
        pins.each { gpio_adapter.cleanup_pin(_1) }
      end

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

      private

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
    end
  end
end
