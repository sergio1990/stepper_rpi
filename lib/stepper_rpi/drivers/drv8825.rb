require_relative './base_motor_driver.rb'
require_relative '../gpio_adapter.rb'

module StepperRpi
  module Drivers
    class DRV8825 < BaseMotorDriver
      class Error < ::StepperRpi::Drivers::Error; end

      module MicrosteppingMode
        STEP_FULL = 0
        STEP_HALF = 1
        STEP_1_4  = 2
        STEP_1_8  = 3
        STEP_1_16 = 4
        STEP_1_32 = 5

        ALL = [
          STEP_FULL,
          STEP_HALF,
          STEP_1_4,
          STEP_1_8,
          STEP_1_16,
          STEP_1_32
        ].freeze
      end

      module StepMode
        HARDWARE_PWM = 0
        SOFTWARE_PWM = 1

        ALL = [
          HARDWARE_PWM,
          SOFTWARE_PWM
        ].freeze
      end

      class Mode
        attr_reader :microstepping_mode, :step_mode

        def initialize(microstepping_mode:, step_mode:)
          @microstepping_mode = microstepping_mode
          @step_mode = step_mode

          ensure_correct_prop_values!
        end

        private

        def ensure_correct_prop_values!
          if !microstepping_mode.kind_of?(::Integer) || !MicrosteppingMode::ALL.include?(microstepping_mode)
            raise StepperRpi::Drivers::DRV8825::Error, "The microstepping_mode must be a value from the StepperRpi::Drivers::DRV8825::MicrosteppingMode enumeration!"
          end

          if !step_mode.kind_of?(::Integer) || !StepMode::ALL.include?(step_mode)
            raise StepperRpi::Drivers::DRV8825::Error, "The step_mode must be a value from the StepperRpi::Drivers::DRV8825::StepMode enumeration!"
          end
        end
      end

      class Pins
        attr_reader :mode, :dir, :pwm_channel

        def initialize(mode:, dir:, pwm_channel:)
          @mode = mode
          @dir = dir
          @pwm_channel = pwm_channel

          ensure_correct_prop_values!
        end

        private

        def ensure_correct_prop_values!
          if !mode.kind_of?(::Array) || mode.count != 3
            raise StepperRpi::Drivers::DRV8825::Error, "The mode must be an array of 3 elements!"
          end

          unless dir.kind_of?(::Integer)
            raise StepperRpi::Drivers::DRV8825::Error, "The dir must be an integer!"
          end

          unless pwm_channel.kind_of?(::Integer)
            raise StepperRpi::Drivers::DRV8825::Error, "The pwm_channel must be an integer!"
          end
        end
      end

      def initialize(mode:, pins:, gpio_adapter:)
        super

        ensure_correct_prop_values!
      end

      def connect
        pins.mode.each { gpio_adapter.setup_pin(_1) }
        gpio_adapter.setup_pin(pins.dir)
        if mode.step_mode == StepMode::HARDWARE_PWM
          @pwm = gpio_adapter.setup_pwm(pins.pwm_channel)
        else
          gpio_adapter.setup_pin(pins.pwm_channel)
        end
        @is_connected = true
      end

      def disconnect
        pins.mode.each { gpio_adapter.cleanup_pin(_1) }
        gpio_adapter.cleanup_pin(pins.dir)
        if mode.step_mode == StepMode::HARDWARE_PWM
          pwm.cleanup
        else
          gpio_adapter.cleanup_pin(pins.pwm_channel)
        end
        @is_connected = false
      end

      def stop
        return unless runner_thread
        return unless runner_thread.alive?

        @is_running_terminated = true
        sleep(0.001) while runner_thread.alive?
        @is_running_terminated = false
        @is_running = false
      end

      def do_steps(number_of_steps)
        is_backward = number_of_steps < 0
        number_of_steps = number_of_steps.abs
        step_diff = is_backward ? -1 : 1

        gpio_adapter.set_pin_value(pins.dir, step_diff)

        mode_pin_values = MODES_SETUP[mode.microstepping_mode]
        pins.mode.zip(mode_pin_values).each do |pin_with_value|
          pin = pin_with_value[0]
          value = pin_with_value[1]

          gpio_adapter.set_pin_value(pin, value)
        end

        @is_running = true

        if mode.step_mode == StepMode::HARDWARE_PWM
          do_steps_hardware_pwm(number_of_steps, step_diff)
        else
          do_steps_software_pwm(number_of_steps, step_diff)
        end
      end

      private

      attr_reader :pwm
      attr_reader :runner_thread, :is_running_terminated

      # [M0, M1, M2]
      MODES_SETUP = {
        MicrosteppingMode::STEP_FULL => [0, 0, 0],
        MicrosteppingMode::STEP_HALF => [1, 0, 0],
        MicrosteppingMode::STEP_1_4  => [0, 1, 0],
        MicrosteppingMode::STEP_1_8  => [1, 1, 0],
        MicrosteppingMode::STEP_1_16 => [0, 0, 1],
        MicrosteppingMode::STEP_1_32 => [1, 0, 1]
      }

      def ensure_correct_prop_values!
        if !mode.kind_of?(Mode)
          raise StepperRpi::Drivers::DRV8825::Error, "The mode must be an instance of StepperRpi::Drivers::DRV8825::Mode!"
        end

        unless pins.kind_of?(Pins)
          raise StepperRpi::Drivers::DRV8825::Error, "The pins must be an instance of StepperRpi::Drivers::DRV8825::Pins!"
        end

        unless gpio_adapter.kind_of?(::StepperRpi::GPIOAdapter)
          raise StepperRpi::Drivers::DRV8825::Error, "The gpio_adapter must be an instance of StepperRpi::GPIOAdapter!"
        end
      end

      def do_steps_hardware_pwm(number_of_steps, dir)
        pwm.speed = speed
        time_to_cover = (1 / speed.to_f) * number_of_steps.to_f
        @runner_thread = Thread.new {
          pwm.enable = true
          sleep(time_to_cover)
          @position += number_of_steps
          pwm.enable = false
          @is_running = false
        }
      end

      def do_steps_software_pwm(number_of_steps, dir)
        speed_delay = 1 / speed.to_f
        pulse_delay = speed_delay / 2.0

        @runner_thread = Thread.new {
          number_of_steps.times do |step_index|
            @position += dir

            gpio_adapter.set_pin_value(pins.pwm_channel, 1)
            sleep(pulse_delay)
            gpio_adapter.set_pin_value(pins.pwm_channel, 0)
            sleep(pulse_delay)


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
            end
          end  

          @is_running = false
        }
      end
    end
  end
end
