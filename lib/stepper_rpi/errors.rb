module StepperRpi
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class MotorError < Error; end
end
