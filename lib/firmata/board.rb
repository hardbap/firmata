require 'serialport'
require 'event_spitter'

module Firmata
  class Board
    include EventSpitter

    Pin = Struct.new(:supportedModes, :mode, :value, :analog_channel)

    # pin modes
    INPUT  = 0x00
    OUTPUT = 0x01
    ANALOG = 0x02
    PWM    = 0x03
    SERVO  = 0x04

    LOW  = 0
    HIGH = 1

    # Public: Fixnum byte command for protocol version
    REPORT_VERSION = 0xF9
    # Public: Fixnum byte command for system reset
    SYSTEM_RESET = 0xFF
    # Public: Fixnum byte command for digital I/O message
    DIGITAL_MESSAGE = 0x90
    # Pubilc: Fixnum byte for range for digital pins for digital 2 byte data format
    DIGITAL_MESSAGE_RANGE = 0x90..0x9F
    # Public: Fixnum byte command for an analog I/O message
    ANALOG_MESSAGE = 0xE0
    # Public: Fixnum byte range for analog pins for analog 14-bit data format
    ANALOG_MESSAGE_RANGE = 0xE0..0xEF
    # Public: Fixnum byte command to report analog pin
    REPORT_ANALOG = 0xC0
    # Public: Fixnum byte command to report digital port
    REPORT_DIGITAL = 0xD0
    # Public: Fixnum byte command to set pin mode (I/O)
    PIN_MODE  = 0xF4

    # Public: Fixnum byte command for start of Sysex message
    START_SYSEX = 0xF0
    # Public: Fixnum byte command for end of Sysex message
    END_SYSEX = 0xF7
    # Public: Fixnum byte sysex command for capabilities query
    CAPABILITY_QUERY = 0x6B
    # Public: Fixnum byte sysex command for capabilities response
    CAPABILITY_RESPONSE = 0x6C
    # Public: Fixnum byte sysex command for pin state query
    PIN_STATE_QUERY = 0x6D
    # Public: Fixnum byte sysex command for pin state response
    PIN_STATE_RESPONSE = 0x6E
    # Public: Fixnum byte sysex command for analog mapping query
    ANALOG_MAPPING_QUERY    = 0x69
    # Public: Fixnum byte sysex command for analog mapping response
    ANALOG_MAPPING_RESPONSE = 0x6A
    # Public: Fixnum byte sysex command for firmware query and response
    FIRMWARE_QUERY = 0x79


    attr_reader :serial_port, :pins, :analog_pins, :firmware_name

    def initialize(port)
      @serial_port = port.is_a?(String) ? SerialPort.new(port, 57600, 8, 1, SerialPort::NONE) : port
      @serial_port.read_timeout = 2
      @major_version = 0
      @minor_version = 0
      @pins = []
      @analog_pins = []
      @connected = false
    end

    def connected?
      @connected
    end

    def connect
      unless @connected
        self.once('report_version', ->() do
          self.once('firmware_query', ->() do
            self.once('capability_query', ->() do
              self.once('analog_mapping_query', ->() do
                @connected = true
                emit('ready')
              end)
              query_analog_mapping
           end)
            query_capabilities
          end)
        end)
      end
    end

    # Public: Write data to the underlying serial port.
    #
    # commands - Zero or more byte commands to be written.
    #
    # Examples
    #
    #   write(START_SYSEX, CAPABILITY_QUERY, END_SYSEX)
    #
    # Returns nothing.
    def write(*commands)
      serial_port.write(commands.map(&:chr).join)
    end

    # Public: Read data from the underlying serial port.
    #
    # Returns Enumerator of bytes read.
    def read
      serial_port.bytes
    end

    # Public: Process the bytes read from serial port.
    #
    # bytes: An Enumerator of bytes (default: read())
    #
    # Returns nothing.
    def process(bytes = read)
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
          end

        when START_SYSEX
          current_buffer = [byte]
          begin
            current_buffer.push(bytes.next)
          end until current_buffer.last == END_SYSEX

          command = current_buffer[1]

          case command
          when CAPABILITY_RESPONSE
            supportedModes = 0
            n = 0

            current_buffer.slice(2, current_buffer.length - 3).each do |byte|
              if byte == 127
                modesArray = []
                # the pin modes
                [ INPUT, OUTPUT, ANALOG, PWM, SERVO ].each do |mode|
                   modesArray.push(mode) unless (supportedModes & (1 << mode)).zero?
                end

                @pins.push(Pin.new(modesArray, OUTPUT, 0))

                supportedModes = 0
                n = 0
                next
              end

              supportedModes |= (1 << byte) if n.zero?

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
            # TODO decide what to do with unknown message
          end
        end
      end
    rescue StopIteration
      # do nadda
    end

    def reset
      write(SYSTEM_RESET)
    end

    def pin_mode(pin, mode)
      pins[pin].mode = mode
      write(PIN_MODE, pin, mode)
    end

    def digital_write(pin, value)

      port = (pin / 8).floor
      port_value = 0

      @pins[pin].value = value

      8.times do |i|
        port_value |= (1 << i) unless @pins[8 * port + i].value.zero?
      end

      write(DIGITAL_MESSAGE | port, port_value & 0x7F, (port_value >> 7) & 0x7F)
    end

    def delay(seconds)
      sleep(seconds)
    end

    def version
      [@major_version, @minor_version].join('.')
    end

    def report_version
      write(REPORT_VERSION)
    end

    def query_pin_state(pin)
      write(START_SYSEX, PIN_STATE_QUERY, pin.to_i, END_SYSEX)
    end

    def query_capabilities
      write(START_SYSEX, CAPABILITY_QUERY, END_SYSEX)
    end

    def query_analog_mapping
      write(START_SYSEX, ANALOG_MAPPING_QUERY, END_SYSEX)
    end

    def toggle_pins(state)
      16.times do |i|
        write(REPORT_DIGITAL | i, state)
        write(REPORT_ANALOG | i, state)
      end
    end

    def turn_pins_on
      toggle_pins(1)
    end

    def turn_pins_off
      toggle_pins(0)
    end
  end
end