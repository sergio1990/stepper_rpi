require 'bundler/setup'

require 'stepper_rpi'
require 'raspi-gpio'

class RpiGPIOAdapter < StepperRpi::GPIOAdapter
  def initialize
    @pins = {}
  end

  def setup_pin(pin)
    gpio_pin = GPIO.new(pin, GPIO::OUT)
    # Give some time for the system to create needed files
    # and set proper permissions
    sleep(0.5)
    gpio_pin.mode = GPIO::OUT
    @pins[pin] = gpio_pin
  end

  def cleanup_pin(pin)
    @pins[pin].cleanup
  end

  def set_pin_value(pin, value)
    gpio_pin = @pins[pin]
    gpio_value = value == 1 ? GPIO::HIGH : GPIO::LOW
    gpio_pin.value = gpio_value
  end
end


mode = StepperRpi::Drivers::DRV8825::Mode.new(
  microstepping_mode: StepperRpi::Drivers::DRV8825::MicrosteppingMode::STEP_1_16,
  step_mode: StepperRpi::Drivers::DRV8825::StepMode::SOFTWARE_PWM
)
pins = StepperRpi::Drivers::DRV8825::Pins.new(
  mode: [14, 15, 18],
  dir: 24,
  pwm_channel: 23
)

driver = StepperRpi::Drivers::DRV8825.new(
  mode: mode,
  pins: pins,
  gpio_adapter: RpiGPIOAdapter.new
)

motor = StepperRpi.motor(driver: driver)

motor.speed = 5000

motor.connect

puts "Start stepping..."
motor.do_steps(8000)

sleep(20)
puts "After 20 seconds current position is: #{motor.position}"

puts "Start stepping backwards..."
motor.do_steps(-1500)

sleep(20)
puts "After 20 seconds current position is: #{motor.position}"
