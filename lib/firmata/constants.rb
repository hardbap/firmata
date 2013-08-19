module Firmata

  module Port
    OPEN  = 1
    CLOSE = 0
  end

  module PinModes
    INPUT  = 0x00
    OUTPUT = 0x01
    ANALOG = 0x02
    PWM    = 0x03
    SERVO  = 0x04
  end

  module PinLevels
    LOW  = 0
    HIGH = 1
  end

  module MidiMessages
    # Internal: Fixnum byte command for protocol version
    REPORT_VERSION = 0xF9
    # Internal: Fixnum byte command for system reset
    SYSTEM_RESET = 0xFF
    # Internal: Fixnum byte command for digital I/O message
    DIGITAL_MESSAGE = 0x90
    # Pubilc: Fixnum byte for range for digital pins for digital 2 byte data format
    DIGITAL_MESSAGE_RANGE = 0x90..0x9F
    # Internal: Fixnum byte command for an analog I/O message
    ANALOG_MESSAGE = 0xE0
    # Internal: Fixnum byte range for analog pins for analog 14-bit data format
    ANALOG_MESSAGE_RANGE = 0xE0..0xEF
    # Internal: Fixnum byte command to report analog pin
    REPORT_ANALOG = 0xC0
    # Internal: Fixnum byte command to report digital port
    REPORT_DIGITAL = 0xD0
    # Internal: Fixnum byte command to set pin mode (I/O)
    PIN_MODE  = 0xF4

    # Internal: Fixnum byte command for start of Sysex message
    START_SYSEX = 0xF0
    # Internal: Fixnum byte command for end of Sysex message
    END_SYSEX = 0xF7
    # Internal: Fixnum byte sysex command for capabilities query
    CAPABILITY_QUERY = 0x6B
    # Internal: Fixnum byte sysex command for capabilities response
    CAPABILITY_RESPONSE = 0x6C
    # Internal: Fixnum byte sysex command for pin state query
    PIN_STATE_QUERY = 0x6D
    # Internal: Fixnum byte sysex command for pin state response
    PIN_STATE_RESPONSE = 0x6E
    # Internal: Fixnum byte sysex command for analog mapping query
    ANALOG_MAPPING_QUERY    = 0x69
    # Internal: Fixnum byte sysex command for analog mapping response
    ANALOG_MAPPING_RESPONSE = 0x6A
    # Internal: Fixnum byte sysex command for i2c request
    I2C_REQUEST = 0x76
    # Internal: Fixnum byte sysex command for i2c reply
    I2C_REPLY = 0x77
    # Internal: Fixnum byte sysex command for i2c config
    I2C_CONFIG = 0x78
    # Internal: Fixnum byte sysex command for firmware query and response
    FIRMWARE_QUERY = 0x79
    # Internal: Fixnum byte i2c mode write
    I2C_MODE_WRITE = 0x00
    # Internal: Fixnum byte i2c mode read
    I2C_MODE_READ = 0x01
    # Internal: Fixnum byte i2c mode continous read
    I2C_MODE_CONTINUOUS_READ = 0x02
    # Internal: Fixnum byte i2c mode stop reading
    I2C_MODE_STOP_READING = 0x03
  end

  class Board
    include PinModes
    include PinLevels
    include MidiMessages
  end
end
