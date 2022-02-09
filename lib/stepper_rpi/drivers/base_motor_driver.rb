module StepperRpi
  module Drivers
    class BaseMotorDriver
      def initialize(mode:, pins:, gpio_adapter:)
        @mode = mode
        @pins = pins
        @gpio_adapter = gpio_adapter
      end

      def connect
        raise NotImplementedError
      end

      def disconnect
        raise NotImplementedError
      end

      def step(dir:)
        raise NotImplementedError
      end

      private

      attr_reader :mode, :pins, :gpio_adapter
    end
  end
end
