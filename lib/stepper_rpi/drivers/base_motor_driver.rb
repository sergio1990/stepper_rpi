require_relative '../errors.rb'

module StepperRpi
  module Drivers
    class Error < ::StepperRpi::Error; end

    class BaseMotorDriver
      attr_accessor :speed
      attr_reader :is_running, :position, :is_connected

      def initialize(mode:, pins:, gpio_adapter:)
        @mode = mode
        @pins = pins
        @gpio_adapter = gpio_adapter
        @is_running = false
        @position = 0
        @speed = 1
        @is_connected = false
      end

      def connect
        raise NotImplementedError
      end

      def disconnect
        raise NotImplementedError
      end

      def do_steps(number_of_steps)
        raise NotImplementedError
      end

      def stop
        raise NotImplementedError
      end

      private

      attr_reader :mode, :pins, :gpio_adapter
    end
  end
end
