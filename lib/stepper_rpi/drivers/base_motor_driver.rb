module StepperRpi
  module Drivers
    class BaseMotorDriver
      def initialize(gpio_adapter:)
        @gpio_adapter = gpio_adapter
      end

      def connect
        raise NotImplementedError
      end

      def disconnect
        raise NotImplementedError
      end

      def step
        raise NotImplementedError
      end

      private

      attr_reader :gpio_adapter
    end
  end
end
