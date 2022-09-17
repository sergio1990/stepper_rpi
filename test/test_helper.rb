# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "stepper_rpi"

require "minitest/autorun"
require 'mocha/minitest'

class DummyGpioAdapter < StepperRpi::GPIOAdapter
  def setup_pin(pin)
  end

  def cleanup_pin(pin)
  end

  def set_pin_value(pin, value)
  end
end

class DummyDriver < StepperRpi::Drivers::BaseMotorDriver
  def connect
    @is_connected = true
  end

  def disconnect
    @is_connected = false
  end

  def stop
    @is_running = false
  end

  def do_steps(number_of_steps)
  end
end
