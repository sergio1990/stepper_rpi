# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "stepper_rpi"

require "minitest/autorun"
require 'mocha/minitest'

class DummyGpioAdapter < StepperRpi::GPIOAdapter
end
