require 'stringio'
require 'serialport'
require 'event_spitter'

module Firmata
  class Board
    include EventSpitter

    # Internal: Data structure representing a pin on Arduino.
    Pin = Struct.new(:supported_modes, :mode, :value, :analog_channel)

    # Public: Fixnum byte for pin mode input.
    INPUT = 0x00
    # Public: Fixnum byte for pin mode output.
    OUTPUT = 0x01
    # Public: Fixnum byte for pin mode analog.
    ANALOG = 0x02
    # Public: Fixnum byte for pin mode pulse width modulation.
    PWM = 0x03
    # Public: Fixnum byte for pin mode servo.
    SERVO = 0x04

    LOW  = 0
    HIGH = 1

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
    # Internal: Fixnum byte sysex command for firmware query and response
    FIRMWARE_QUERY = 0x79

    # Public: Returns the SerialPort port the Arduino is attached to.
    attr_reader :serial_port
    # Public: Returns the Array of pins on Arduino.
    attr_reader :pins
    # Public: Returns the Array of analog pins on Arduino.
    attr_reader :analog_pins
    # Public: Returns the String firmware name of Arduion.
    attr_reader :firmware_name

    # Public: Initialize a Board
    #
    # port - a String port or an Object that responds to read and write.
    def initialize(port)
      @serial_port = port.is_a?(String) ? SerialPort.new(port, 9600, 8, 1, SerialPort::NONE) : port
      @serial_port.read_timeout = 2
      @major_version = 0
      @minor_version = 0
      @pins = []
      @analog_pins = []
      @connected = false
    end

    # Pubilc: Check if a connection to Arduino has been made.
    #
    # Returns Boolean connected state.
    def connected?
      @connected
    end

    # Public: Make connection to Arduino.
    #
    # Returns Firmata::Board board.
    def connect
      unless @connected
        once('report_version', ->() do
          once('firmware_query', ->() do
            once('capability_query', ->() do
              once('analog_mapping_query', ->() do

                2.times { |i| toggle_pin_reporting(i) }

                @connected = true
                emit('ready')
              end)
              query_analog_mapping
           end)
            query_capabilities
          end)
        end)

         until connected?
          read_and_process
          delay(0.5)
        end
      end

      self
    end

    # Internal: Write data to the underlying serial port.
    #
    # commands - Zero or more byte commands to be written.
    #
    # Examples
    #
    #   write(START_SYSEX, CAPABILITY_QUERY, END_SYSEX)
    #
    # Returns nothing.
    def write(*commands)
      serial_port.write_nonblock(commands.map(&:chr).join)
    end

    # Internal: Read data from the underlying serial port.
    #
    # Returns String data read for serial port.
    def read
      serial_port.read_nonblock(4096)
    rescue EOFError
    end

    # Internal: Process a series of bytes.
    #
    # data: The String data to process.
    #
    # Returns nothing.
    def process(data)
      bytes = StringIO.new(String(data)).bytes
      bytes.each do |byte|
        case byte
        when REPORT_VERSION
          @major_version = bytes.next
          @minor_version = bytes.next

          emit('report_version')

        when ANALOG_MESSAGE_RANGE
          least_significant_byte = bytes.next
          most_significant_byte = bytes.next

          value = least_significant_byte | (most_significant_byte << 7)
          pin = byte & 0x0F

          if analog_pin = analog_pins[pin]
            pins[analog_pin].value = value

            emit('analog-read', pin, value)
            emit("analog-read-#{pin}", value)
          end

        when DIGITAL_MESSAGE_RANGE
          port           = byte & 0x0F
          first_bitmask  = bytes.next
          second_bitmask = bytes.next
          port_value     = first_bitmask | (second_bitmask << 7)

          8.times do |i|
            pin_number = 8 * port + i
            if pin = pins[pin_number] and pin.mode == INPUT
              value = (port_value >> (i & 0x07)) & 0x01
              pin.value = value
              emit('digital-read', pin_number, value)
              emit("digital-read-#{pin_number}", value)
            end
          end

        when START_SYSEX
          current_buffer = [byte]
          begin
            current_buffer.push(bytes.next)
          end until current_buffer.last == END_SYSEX

          command = current_buffer[1]

          case command
          when CAPABILITY_RESPONSE
            supported_modes = 0
            n = 0

            current_buffer.slice(2, current_buffer.length - 3).each do |byte|
              if byte == 127
                modes = []
                # the pin modes
                [ INPUT, OUTPUT, ANALOG, PWM, SERVO ].each do |mode|
                   modes.push(mode) unless (supported_modes & (1 << mode)).zero?
                end

                @pins.push(Pin.new(modes, OUTPUT, 0))

                supported_modes = 0
                n = 0
                next
              end

              supported_modes |= (1 << byte) if n.zero?

              n ^= 1
            end

            emit('capability_query')

          when ANALOG_MAPPING_RESPONSE
            pin_index = 0

            current_buffer.slice(2, current_buffer.length - 3).each do |byte|

              @pins[pin_index].analog_channel = byte

              @analog_pins.push(pin_index) unless byte == 127

              pin_index += 1
            end

            emit('analog_mapping_query')

          when PIN_STATE_RESPONSE
            pin       = pins[current_buffer[2]]
            pin.mode  = current_buffer[3]
            pin.value = current_buffer[4]

            pin.value |= (current_buffer[5] << 7) if current_buffer.size > 6

            pin.value |= (current_buffer[6] << 14) if current_buffer.size > 7

          when FIRMWARE_QUERY
            @firmware_name = current_buffer.slice(4, current_buffer.length - 5).reject { |b| b.zero? }.map(&:chr).join
            emit('firmware_query')

          else
            puts 'bad byte'
          end
        end
      end
    rescue StopIteration
      # do nadda
    end

    # Public: Read the serial port and process the results
    #
    # Returns nothing.
    def read_and_process
      process(read)
    end

    # Public: Send a SYSTEM_RESET to the Arduino
    #
    # Returns nothing.
    def reset
      write(SYSTEM_RESET)
    end

    # Public: Set the mode for a pin.
    #
    # pin  - The Integer pin to set.
    # mode - The Fixnum mode (INPUT, OUTPUT, ANALOG, PWM or SERVO)
    #
    # Examples
    #
    #   set_pin_mode(13, OUTPUT)
    #
    # Returns nothing.
    def set_pin_mode(pin, mode)
      pins[pin].mode = mode
      write(PIN_MODE, pin, mode)
    end

    # Public: Write a value to a digital pin.
    #
    # pin   - The Integer pin to write to.
    # value - The value to write (HIGH or LOW).
    #
    # Returns nothing.
    def digital_write(pin, value)
      port = (pin / 8).floor
      port_value = 0

      @pins[pin].value = value

      8.times do |i|
        port_value |= (1 << i) unless @pins[8 * port + i].value.zero?
      end

      write(DIGITAL_MESSAGE | port, port_value & 0x7F, (port_value >> 7) & 0x7F)
    end

    # Public: Write an analog messege.
    #
    # pin   - The Integer pin to write to.
    # value - The Integer value to write to the pin between 0-255.
    #
    # Returns nothing.
    def analog_write(pin, value)
      @pins[pin].value = value
      write(ANALOG_MESSAGE | pin, value & 0x7F, (value >> 7) & 0x7F)
    end

    # Public: Write to a servo.
    #
    # pin     - The Integer pin to write to.
    # degrees - The Integer degrees to move the servo.
    #
    # Returns nothing.
    alias_method :servo_write, :analog_write

    # Public: Ask the Arduino to sleep for a number of seconds.
    #
    # seconds - The Integer seconds to sleep for.
    #
    # Returns nothing.
    def delay(seconds)
      sleep(seconds)
    end

    # Public: The major and minor firmware version on the board. Will report as
    # "0.0" if report_version command has not been run.
    #
    # Returns String the firmware version as "minor.major".
    def version
      [@major_version, @minor_version].join('.')
    end

    # Public: Ask the Arduino to report its version.
    #
    # Returns nothing.
    def report_version
      write(REPORT_VERSION)
    end

    # Public: Ask the Ardution for its firmware name.
    #
    # Returns nothing.
    def query_firmware
      write(FIRMWARE_QUERY)
    end

    # Public: Ask the Arduino for the current configuration of any pin.
    #
    # pin - The Integer pin to query on the board.
    #
    # Returns nothing.
    def query_pin_state(pin)
      write(START_SYSEX, PIN_STATE_QUERY, pin.to_i, END_SYSEX)
    end

    # Public: Ask the Arduino about its capabilities and current state.
    #
    # Returns nothing.
    def query_capabilities
      write(START_SYSEX, CAPABILITY_QUERY, END_SYSEX)
    end

    # Public: Ask the Arduino which pins (used with pin mode message) correspond to the analog channels.
    #
    # Returns nothing.
    def query_analog_mapping
      write(START_SYSEX, ANALOG_MAPPING_QUERY, END_SYSEX)
    end

    # Public: Toggle pin reporting on or off.
    #
    # pin   - The Integer pin to toggle.
    # mode  - The Integer mode the pin will report. The valid values are
    #         REPORT_DIGITAL or REPORT_ANALOG (default: REPORT_DIGITAL).
    # state - The Integer state to toggle the pin. The valid value are
    #         HIGH or LOW (default: HIGH)
    #
    # Returns nothing.
    def toggle_pin_reporting(pin, state = HIGH, mode = REPORT_DIGITAL)
      write(mode | pin, state)
    end

  end
end
