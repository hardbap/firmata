require 'stringio'
require 'event_emitter'

module Firmata
  class Board
    include EventEmitter

    # Internal: Data structure representing a pin on Arduino.
    Pin = Struct.new(:supported_modes, :mode, :value, :analog_channel)

    # Public: Returns the SerialPort port the Arduino is attached to.
    attr_reader :serial_port
    # Public: Returns the Array of pins on Arduino.
    attr_reader :pins
    # Public: Returns the Array of analog pins on Arduino.
    attr_reader :analog_pins
    # Public: Returns the String firmware name of Arduino.
    attr_reader :firmware_name
    # Public: Returns array of any Events returned from ????
    attr_reader :async_events

    # Public: Initialize a Board
    #
    # port - a String port or an Object that responds to read and write.
    def initialize(port)
      if port.is_a?(String)
        require 'serialport'
        @serial_port = SerialPort.new(port, 57600, 8, 1, SerialPort::NONE)
        @serial_port.read_timeout = 2
      else
        @serial_port = port
      end

      @serial_port_status = Port::OPEN
      @major_version = 0
      @minor_version = 0
      @firmware_name = nil
      @pins = []
      @analog_pins = []
      @connected = false
      @async_events = []

      trap_signals 'SIGHUP', 'SIGINT', 'SIGKILL', 'SIGTERM'
    rescue LoadError
      puts "Please 'gem install hybridgroup-serialport' for serial port support."
    end

    # Public: Check if a connection to Arduino has been made.
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

        handle_events!

        catch(:initialized) do
          loop do
            query_report_version #unless @major_version.zero?
            sleep 0.1
            read_and_process
          end
        end
      end

      self
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
      write(START_SYSEX, FIRMWARE_QUERY, END_SYSEX)
    end

    # Public: Ask the Arduino for the current configuration of any pin.
    #
    # pin - The Integer pin to query on the board.
    #
    # Returns nothing.
    def query_pin_state(pin)
      write(START_SYSEX, PIN_STATE_QUERY, pin.to_i, END_SYSEX)
    end

    #
    def query_report_version
      write REPORT_VERSION
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
    # Public: Make an i2c request.
    #
    # I2C read/write request
    #
    # 0  START_SYSEX (0xF0) (MIDI System Exclusive)
    # 1  I2C_REQUEST (0x76)
    # 2  slave address (LSB)
    # 3  slave address (MSB) + read/write and address mode bits
    #      {7: always 0} + {6: reserved} + {5: address mode, 1 means 10-bit mode} +
    #      {4-3: read/write, 00 => write, 01 => read once, 10 => read continuously, 11 => stop reading} +
    #      {2-0: slave address MSB in 10-bit mode, not used in 7-bit mode}
    # 4  data 0 (LSB)
    # 5  data 0 (MSB)
    # 6  data 1 (LSB)
    # 7  data 1 (MSB)
    # n  END_SYSEX (0xF7)
    # Returns nothing.
    def i2c_read_request(slave_address, num_bytes)
      address = [slave_address].pack("v")
      write(START_SYSEX, I2C_REQUEST, address[0], (I2C_MODE_READ << 3), num_bytes & 0x7F, ((num_bytes >> 7) & 0x7F), END_SYSEX)
    end

    def i2c_write_request(slave_address, *data)
      address = [slave_address].pack("v")
      ret = [START_SYSEX, I2C_REQUEST, address[0], (I2C_MODE_WRITE << 3)] 
      data.each do |n|
        ret.push([n].pack("v")[0])
        ret.push([n].pack("v")[1])
      end
      ret.push(END_SYSEX)
      write(*ret)
    end
    # Public: Set i2c config.
    #   I2C config
    # 0  START_SYSEX (0xF0) (MIDI System Exclusive)
    # 1  I2C_CONFIG (0x78)
    # 2  Delay in microseconds (LSB)
    # 3  Delay in microseconds (MSB)
    # ... user defined for special cases, etc
    # n  END_SYSEX (0xF7)
    # Returns nothing.
    def i2c_config(*data)
      ret = [START_SYSEX, I2C_CONFIG]
      data.each do |n|
        ret.push([n].pack("v")[0])
        ret.push([n].pack("v")[1])
      end
      ret.push(END_SYSEX)
      write(*ret)
    end

    protected
    # Dispatches an event
    def event(name, *data)
      async_events << Event.new(name, *data)
      emit(name, *data)
    end

    private
    def close
      return if @serial_port_status == Port::CLOSE
      @serial_port.close
      @serial_port_status = Port::CLOSE
      loop do
        break if @serial_port.closed?
        sleep 0.01
      end
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
      return serial_port.read_nonblock(1024)
    rescue EOFError
    rescue Errno::EAGAIN
    end

    # Internal: Process a series of bytes.
    #
    # data: The String data to process.
    #
    # Returns nothing.
    def process(data)
      bytes = StringIO.new(String(data))
      while byte = bytes.getbyte
        case byte
        when REPORT_VERSION
          @major_version = bytes.getbyte
          @minor_version = bytes.getbyte
          event :report_version
        when ANALOG_MESSAGE_RANGE
          least_significant_byte = bytes.getbyte
          most_significant_byte = bytes.getbyte

          value = least_significant_byte | (most_significant_byte << 7)
          pin = byte & 0x0F

          if analog_pin = analog_pins[pin]
            pins[analog_pin].value = value

            event :analog_read, pin, value
            event("analog_read_#{pin}", value)
          end

        when DIGITAL_MESSAGE_RANGE
          port           = byte & 0x0F
          first_bitmask  = bytes.getbyte
          second_bitmask = bytes.getbyte
          port_value     = first_bitmask | (second_bitmask << 7)

          8.times do |i|
            pin_number = 8 * port + i
            if pin = pins[pin_number] and pin.mode == INPUT
              value = (port_value >> (i & 0x07)) & 0x01
              pin.value = value
              event :digital_read, pin_number, value
              event "digital_read_#{pin_number}", value
            end
          end

        when START_SYSEX
          current_buffer = [byte]
          begin
            current_buffer.push(bytes.getbyte)
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

            event :capability_query

          when ANALOG_MAPPING_RESPONSE
            pin_index = 0

            current_buffer.slice(2, current_buffer.length - 3).each do |byte|

              @pins[pin_index].analog_channel = byte

              @analog_pins.push(pin_index) unless byte == 127

              pin_index += 1
            end
  
            event :analog_mapping_query

          when PIN_STATE_RESPONSE
            pin       = pins[current_buffer[2]]
            pin.mode  = current_buffer[3]
            pin.value = current_buffer[4]

            pin.value |= (current_buffer[5] << 7) if current_buffer.size > 6

            pin.value |= (current_buffer[6] << 14) if current_buffer.size > 7

            event(:pin_state, current_buffer[2], pin.value)
            event("pin_#{current_buffer[2]}_state", pin.value)
          when I2C_REPLY
            # I2C reply
            # 0  START_SYSEX (0xF0) (MIDI System Exclusive)
            # 1  I2C_REPLY (0x77)
            # 2  slave address (LSB)
            # 3  slave address (MSB)
            # 4  register (LSB)
            # 5  register (MSB)
            # 6  data 0 LSB
            # 7  data 0 MSB
            # n  END_SYSEX (0xF7)
            i2c_reply = {
              :slave_address => current_buffer[2,2].pack("CC").unpack("v").first,
              :register => current_buffer[4,2].pack("CC").unpack("v").first,
              :data => [current_buffer[6,2].pack("CC").unpack("v").first]
            }
            i = 8
            while current_buffer[i] != "0xF7".hex do
              break if !(!current_buffer[i,2].nil? && current_buffer[i,2].count == 2)
              i2c_reply[:data].push(current_buffer[i,2].pack("CC").unpack("v").first)
              i += 2
            end
            event :i2c_reply, i2c_reply

          when FIRMWARE_QUERY
            @firmware_name = current_buffer.slice(4, current_buffer.length - 5).reject { |b| b.zero? }.map(&:chr).join
            event :firmware_query
          else
            puts 'bad byte'
          end
        end
      end
    rescue StopIteration
      # do nadda
    rescue NoMethodError
      # got some bad data or something? hack to just skip to next attempt to process...
    end

    def trap_signals(*signals)
      signals.each do |signal|
        trap signal do
          close
          exit
        end
      end
    end

    def handle_events!
      once :report_version do
        query_firmware unless @firmware_name
      end

      once :firmware_query do
        query_capabilities
      end

      once :capability_query do
        query_analog_mapping
      end

      once :analog_mapping_query do
        2.times { |i| toggle_pin_reporting(i) }

        @connected = true
        event :ready
        throw :initialized
      end
    end
  end
end
