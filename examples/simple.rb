# https://github.com/ClockVapor/rpi_gpio
require 'rpi_gpio'

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "stepper_rpi"

RPi::GPIO.set_numbering :board

class RpiGPIOAdapter < StepperRpi::GPIOAdapter
  def setup_pin(pin)
    RPi::GPIO.setup pin, as: :output 
  end

  def set_pin_value(pin, value)
    if value == 1
      RPi::GPIO.set_high pin
    else
      RPi::GPIO.set_low pin 
    end
  end
end

StepperRpi.configure do |config|
  config.gpio_adapter = RpiGPIOAdapter.new
end

motor = StepperRpi.motor(
  mode: StepperRpi::Mode::FUUL,
  pins: [8, 10, 12, 16]
)

motor.connect

puts "Start stepping..."
motor.do_steps(500)

sleep(10)
puts "After 10 seconds current position is: #{motor.position}"

puts "Start stepping backwards..."
motor.do_steps(-500)

sleep(10)
puts "After 10 seconds current position is: #{motor.position}"
