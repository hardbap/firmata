require 'serialport'

module Firmata
  class Board
    Pin = Struct.new(:supportedModes, :mode, :value, :analog_channel)

    # pin modes
    INPUT  = 0x00
    OUTPUT = 0x01
    ANALOG = 0x02
    PWM    = 0x03
    SERVO  = 0x04

    LOW  = 0
    HIGH = 1

    DIGITAL_MESSAGE         = 0x90
    ANALOG_MESSAGE          = 0xE0
    ANALOG_MESSAGE_RANGE    = 0xE0..0xEF
    SET_PIN_MODE            = 0xF4
    REPORT_ANALOG           = 0xC0
    REPORT_DIGITAL          = 0xD0
    REPORT_VERSION          = 0xF9
    CAPABILITY_QUERY        = 0x6B
    CAPABILITY_RESPONSE     = 0x6C
    START_SYSEX             = 0xF0
    END_SYSEX               = 0xF7
    PIN_STATE_QUERY         = 0x6D
    PIN_STATE_RESPONSE      = 0x6E
    SYSTEM_RESET            = 0xFF
    ANALOG_MAPPING_QUERY    = 0x69
    ANALOG_MAPPING_RESPONSE = 0x6A
    FIRMWARE_QUERY          = 0x79
    PIN_MODE                = 0xF4

    attr_reader :serial_port, :pins, :analog_pins

    def initialize(port)
      @serial_port = port.is_a?(String) ? SerialPort.new(port, 57600, 8, 1, SerialPort::NONE) : serial_port
      @serial_port.read_timeout = 2
      @major_version = 0
      @minor_version = 0
      @pins = []
      @analog_pins = []
      @started = false
      start_up
    end

    def start_up
      unless @started
        delay 3

        query_capabilities
        query_analog_mapping
        turn_pins_on

        reset

        delay 1

        reset

        @started = true
      end

      self
    end

    def process
      bytes = serial_port.bytes

      bytes.each do |byte|
        case byte
        when REPORT_VERSION
          @major_version = bytes.next
          @minor_version = bytes.next

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

          when ANALOG_MAPPING_RESPONSE
            pin_index = 0

            current_buffer.slice(2, current_buffer.length - 3).each do |byte|

              @pins[pin_index].analog_channel = byte

              @analog_pins.push(pin_index) unless byte == 127

              pin_index += 1
            end

          when PIN_STATE_RESPONSE
            pin       = pins[current_buffer[2]]
            pin.mode  = current_buffer[3]
            pin.value = current_buffer[4]

            pin.value |= (current_buffer[5] << 7) if current_buffer.size > 6

            pin.value |= (current_buffer[6] << 14) if current_buffer.size > 7

          when FIRMWARE_QUERY
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

    def write(*commands)
      @serial_port.write(commands.map(&:chr).join)
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
    alias_method :qc, :query_capabilities

    def query_analog_mapping
      write(START_SYSEX, ANALOG_MAPPING_QUERY, END_SYSEX)
    end
    alias_method :qam, :query_analog_mapping

    def turn_pins_on
      16.times do |i|
        write(REPORT_DIGITAL | i, 1)
        write(REPORT_ANALOG | i, 1)
      end
    end

    def turn_pins_off
      16.times do |i|
        write(REPORT_DIGITAL | i, 0)
        write(REPORT_ANALOG | i, 0)
      end
    end
end