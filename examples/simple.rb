# https://github.com/theovidal/raspi-gpio-rb
require 'raspi-gpio'

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "stepper_rpi"

class RpiGPIOAdapter < StepperRpi::GPIOAdapter
  def initialize
    @pins = {}  
  end

  def setup_pin(pin)
    gpio_pin = GPIO.new(pin, OUT)
    gpio_pin.set_mode(OUT)
    @pins[pin] = gpio_pin
  end

  def set_pin_value(pin, value)
    gpio_pin = @pins[pin]
    gpio_value = value == 1 ? HIGH : LOW
    gpio_pin.set_value(gpio_value)
  end
end

StepperRpi.configure do |config|
  config.gpio_adapter = RpiGPIOAdapter.new
end

motor = StepperRpi.motor(
  mode: StepperRpi::Mode::HALF_STEP,
  pins: [14, 15, 18, 23]
)
motor.speed = 70

motor.connect

puts "Start stepping..."
motor.do_steps(2000)

sleep(20)
puts "After 20 seconds current position is: #{motor.position}"

puts "Start stepping backwards..."
motor.do_steps(-1500)

sleep(20)
puts "After 20 seconds current position is: #{motor.position}"
