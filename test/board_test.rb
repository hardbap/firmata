require 'minitest/autorun'
require 'minitest/pride'

require_relative '../lib/firmata'
require_relative 'fake_serial_port'

class BoardTest < MiniTest::Unit::TestCase

  def mock_serial_port(*args, &block)
    mock_port = MiniTest::Mock.new
    mock_port.expect(:read_timeout=, 2, [2])
    mock_port.expect(:is_a?, false, [nil])

    if block_given?
      yield mock_port
    else
      expected = args.map(&:chr).join
      mock_port.expect(:write_nonblock, 1, [expected])
    end

    mock_port
  end

  def test_writing_report_version
    mock_sp = mock_serial_port(Firmata::Board::REPORT_VERSION)

    board = Firmata::Board.new(mock_sp)
    board.report_version

    mock_sp.verify
  end

  def test_processing_report_version
    board = Firmata::Board.new(FakeSerialPort.new)
    board.report_version
    board.read_and_process

    assert_equal '2.3', board.version
  end

  def test_writing_capability_query
    mock_sp = mock_serial_port(Firmata::Board::START_SYSEX, Firmata::Board::CAPABILITY_QUERY, Firmata::Board::END_SYSEX)

    board = Firmata::Board.new(mock_sp)
    board.query_capabilities

    mock_sp.verify
  end

  def test_processing_capabilities_query
    board = Firmata::Board.new(FakeSerialPort.new)
    board.query_capabilities
    board.read_and_process

    assert_equal 20, board.pins.size
  end

  def test_writing_analog_mapping_query
    mock_sp = mock_serial_port(Firmata::Board::START_SYSEX, Firmata::Board::ANALOG_MAPPING_QUERY, Firmata::Board::END_SYSEX)

    board = Firmata::Board.new(mock_sp)
    board.query_analog_mapping

    mock_sp.verify
  end

  def test_processing_analog_mapping_query
    board = Firmata::Board.new(FakeSerialPort.new)
    board.query_capabilities
    board.read_and_process

    board.query_analog_mapping
    board.read_and_process

    assert_equal 6, board.analog_pins.size
  end

  def test_processing_digital_message
    board = Firmata::Board.new(FakeSerialPort.new)

    board.query_capabilities
    board.read_and_process

    board.query_analog_mapping
    board.read_and_process

    pin = board.pins[8]
    pin.mode = Firmata::Board::INPUT

    board.process("\x91\x01\x00")

    assert_equal Firmata::Board::HIGH, pin.value
  end

  def test_set_pin_mode
    mock_sp = mock_serial_port(Firmata::Board::PIN_MODE, 13, Firmata::Board::OUTPUT)

    board = Firmata::Board.new(mock_sp)
    board.pins[13] = Firmata::Board::Pin.new([0, 1, 4], 0, 0, nil)

    board.set_pin_mode(13, Firmata::Board::OUTPUT)

    assert_equal Firmata::Board::OUTPUT, board.pins[13].mode
    mock_sp.verify
  end

  def test_write_pin_state_query
    mock_sp = mock_serial_port(Firmata::Board::START_SYSEX, Firmata::Board::PIN_STATE_QUERY, 13, Firmata::Board::END_SYSEX)

    board = Firmata::Board.new(mock_sp)
    board.query_pin_state(13)

    mock_sp.verify
  end

  def test_processing_pin_state_query
    board = Firmata::Board.new(FakeSerialPort.new)
    board.query_capabilities
    board.read_and_process

    board.pins[13].mode = Firmata::Board::INPUT

    board.query_pin_state(13)
    board.read_and_process

    assert_equal Firmata::Board::OUTPUT, board.pins[13].mode
  end


  def test_toggling_pin_reporting
    mock_sp = mock_serial_port do |mock|
      mock.expect(:write_nonblock, 2, [[Firmata::Board::REPORT_DIGITAL | 13, 1].map(&:chr).join])
    end

    board = Firmata::Board.new(mock_sp)

    board.toggle_pin_reporting(13)
    mock_sp.verify

    mock_sp.expect(:write_nonblock, 2, [[Firmata::Board::REPORT_DIGITAL | 13, 0].map(&:chr).join])
    board.toggle_pin_reporting(13, 0)
    mock_sp.verify

  end

  def test_processing_analog_message
    fake_port = FakeSerialPort.new
    board = Firmata::Board.new(fake_port)

    board.query_capabilities
    board.read_and_process

    board.query_analog_mapping
    board.read_and_process

    fake_port.buffer = "\xE0\e\u0005\xE1N\u0004\xE2A\u0004\xE3C\u0004\xE4o\u0004\xE5f\u0004\xE0w\u0004\xE1]\u0004\xE2N\u0004\xE3I\u0004\xE4x\u0004\xE5m\u0004\xE0m\u0004\xE1`\u0004\xE2T\u0004\xE3L\u0004\xE4s\u0004\xE5l\u0004\xE0i\u0004\xE1`\u0004\xE2V\u0004\xE3N\u0004\xE4m\u0004\xE5j\u0004\xE0f\u0004\xE1^\u0004\xE2U\u0004\xE3O\u0004\xE4h\u0004\xE5g\u0004\xE0d\u0004\xE1\\\u0004\xE2T\u0004\xE3O\u0004\xE4d\u0004\xE5d\u0004\xE0b\u0004\xE1Z\u0004\xE2S\u0004\xE3N\u0004\xE4`\u0004\xE5a\u0004\xE0_\u0004\xE1X\u0004\xE2Q\u0004\xE3L\u0004\xE4\\\u0004\xE5^\u0004\xE0\\\u0004\xE1T\u0004\xE2N\u0004\xE3J\u0004\xE4X\u0004\xE5Z\u0004\xE0X\u0004\xE1Q\u0004\xE2K\u0004\xE3G\u0004\xE4T\u0004\xE5W\u0004\xE0V\u0004\xE1O\u0004\xE2H\u0004\xE3D\u0004\xE4Q\u0004\xE5T\u0004\xE0S\u0004\xE1L\u0004\xE2F\u0004\xE3B\u0004\xE4N\u0004\xE5Q\u0004\xE0P\u0004\xE1J\u0004\xE2C\u0004\xE3@\u0004\xE4K\u0004\xE5N\u0004\xE0N\u0004\xE1G\u0004\xE2A\u0004\xE3>\u0004\xE4I\u0004\xE5L\u0004\xE0L\u0004\xE1D\u0004\xE2?\u0004\xE3<\u0004\xE4F\u0004\xE5I\u0004\xE0I\u0004\xE1B\u0004\xE2=\u0004\xE39\u0004\xE4C\u0004\xE5F\u0004\xE0F\u0004\xE1?\u0004\xE2:\u0004\xE37\u0004\xE4@\u0004\xE5C\u0004\xE0C\u0004\xE1<\u0004\xE28\u0004\xE34\u0004\xE4>\u0004\xE5A\u0004\xE0A\u0004\xE1:\u0004\xE26\u0004\xE32\u0004\xE4<\u0004\xE5?\u0004\xE0?\u0004\xE19\u0004\xE24\u0004\xE31\u0004\xE4:\u0004\xE5=\u0004\xE0>\u0004\xE17\u0004\xE22\u0004\xE3/\u0004\xE49\u0004\xE5;\u0004\xE0<\u0004\xE15\u0004\xE20\u0004\xE3-\u0004\xE46\u0004\xE59\u0004\xE09\u0004\xE12\u0004\xE2.\u0004\xE3+\u0004\xE44\u0004\xE57\u0004\xE07\u0004\xE10\u0004\xE2,\u0004\xE3)\u0004\xE42\u0004\xE55\u0004\xE05\u0004\xE1.\u0004\xE2*\u0004\xE3'\u0004\xE40\u0004\xE52\u0004\xE03\u0004\xE1-\u0004\xE2(\u0004\xE3&\u0004\xE4/\u0004\xE51\u0004\xE02\u0004\xE1+\u0004\xE2&\u0004\xE3$\u0004\xE4-\u0004\xE50\u0004\xE00\u0004\xE1*\u0004\xE2%\u0004\xE3#\u0004\xE4,\u0004\xE5.\u0004\xE0/\u0004\xE1(\u0004\xE2$\u0004\xE3!\u0004\xE4*\u0004\xE5,\u0004\xE0-\u0004\xE1&\u0004\xE2\"\u0004\xE3\u001F\u0004\xE4(\u0004\xE5*\u0004\xE0+\u0004\xE1$\u0004\xE2 \u0004\xE3\u001D\u0004\xE4&\u0004\xE5(\u0004\xE0)\u0004\xE1\"\u0004\xE2\u001F\u0004\xE3\u001C\u0004\xE4%\u0004\xE5'\u0004\xE0(\u0004\xE1!\u0004\xE2\u001D\u0004\xE3\e\u0004\xE4$\u0004\xE5&\u0004\xE0&\u0004\xE1 \u0004\xE2\u001C\u0004\xE3\u001A\u0004\xE4#\u0004\xE5%\u0004\xE0&\u0004\xE1\u001F\u0004\xE2\e\u0004\xE3\u0019\u0004\xE4\"\u0004\xE5$\u0004\xE0$\u0004\xE1\u001E\u0004\xE2\u0019\u0004\xE3\u0018\u0004\xE4 \u0004\xE5\"\u0004\xE0\"\u0004\xE1\u001C\u0004\xE2\u0018\u0004\xE3\u0016\u0004\xE4\u001F\u0004\xE5 \u0004\xE0!\u0004\xE1\u001A\u0004\xE2\u0017\u0004\xE3\u0014\u0004\xE4\u001D\u0004\xE5\u001E\u0004\xE0\u001F\u0004\xE1\u0019\u0004\xE2\u0015\u0004\xE3\u0013\u0004\xE4\u001C\u0004\xE5\u001D\u0004\xE0\u001E\u0004\xE1\u0018\u0004\xE2\u0013\u0004\xE3\u0012\u0004\xE4\e\u0004\xE5\u001C\u0004\xE0\u001D\u0004\xE1\u0017\u0004\xE2\u0014\u0004\xE3\u0012\u0004\xE4\e\u0004\xE5\u001C\u0004\xE0\u001D\u0004\xE1\u0016\u0004\xE2\u0013\u0004\xE3\u0011\u0004\xE4\u001A\u0004\xE5\e\u0004\xE0\u001C\u0004\xE1\u0015\u0004\xE2\u0011\u0004\xE3\u0010\u0004\xE4\u0018\u0004\xE5\u0019\u0004\xE0\u001A\u0004\xE1\u0014\u0004\xE2\u0010\u0004\xE3\u000E\u0004\xE4\u0017\u0004\xE5\u0018\u0004\xE0\u0018\u0004\xE1\u0012\u0004\xE2\u000E\u0004\xE3\r\u0004\xE4\u0015\u0004\xE5\u0016\u0004\xE0\u0017\u0004\xE1\u0011\u0004\xE2\u000E\u0004\xE3\f\u0004\xE4\u0015\u0004\xE5\u0016\u0004\xE0\u0016\u0004\xE1\u0010\u0004\xE2\f\u0004\xE3\v\u0004\xE4\u0014\u0004\xE5\u0015\u0004\xE0\u0016\u0004\xE1\u000F\u0004\xE2\v\u0004\xE3\n\u0004\xE4\u0013\u0004\xE5\u0014\u0004\xE0\u0015\u0004\xE1\u000F\u0004\xE2\v\u0004\xE3\t\u0004\xE4\u0012\u0004\xE5\u0013\u0004\xE0\u0014\u0004\xE1\u000E\u0004\xE2\n\u0004\xE3\t\u0004\xE4\u0012\u0004\xE5\u0012\u0004\xE0\u0013\u0004\xE1\f\u0004\xE2\t\u0004\xE3\a\u0004\xE4\u0010\u0004\xE5\u0011\u0004\xE0\u0011\u0004\xE1\v\u0004\xE2\b\u0004\xE3\u0006\u0004\xE4\u000F\u0004\xE5\u000F\u0004\xE0\u0010\u0004\xE1\n\u0004\xE2\u0006\u0004\xE3\u0005\u0004\xE4\u000E\u0004\xE5\u000F\u0004\xE0\u000F\u0004\xE1\t\u0004\xE2\u0006\u0004\xE3\u0004\u0004\xE4\r\u0004\xE5\u000E\u0004\xE0\u000F\u0004\xE1\t\u0004\xE2\u0006\u0004\xE3\u0004\u0004\xE4\r\u0004\xE5\u000E\u0004\xE0\u000E\u0004\xE1\b\u0004\xE2\u0004\u0004\xE3\u0003\u0004\xE4\f\u0004\xE5\r\u0004\xE0\u000E\u0004\xE1\a\u0004\xE2\u0004\u0004\xE3\u0003\u0004"
    board.read_and_process

    board.analog_pins.each do |pin|
      refute_nil board.pins[pin].analog_channel, "Analog channel not set for pin #{pin}"
    end
  end

  def test_reset
    mock_sp = mock_serial_port(Firmata::Board::SYSTEM_RESET)

    board = Firmata::Board.new(mock_sp)
    board.reset

    mock_sp.verify
  end

  def test_write_firmware_query
    mock_sp = mock_serial_port(Firmata::Board::FIRMWARE_QUERY)

    board = Firmata::Board.new(mock_sp)
    board.query_firmware

    mock_sp.verify
  end

  def test_process_firmware_query
    fake_port = FakeSerialPort.new
    fake_port.buffer = "\xF0y\u0002\u0003S\u0000t\u0000a\u0000n\u0000d\u0000a\u0000r\u0000d\u0000F\u0000i\u0000r\u0000m\u0000a\u0000t\u0000a\u0000\xF7"
    board = Firmata::Board.new(fake_port)

    board.read_and_process

    assert_equal 'StandardFirmata', board.firmware_name, 'Firmware Name is incorrect'
  end

  def test_digital_write
    mock_sp = mock_serial_port(145, 127, 1)
    board = Firmata::Board.new(mock_sp)

    8.times do |x|
      board.pins[x + 8] = Firmata::Board::Pin.new([], 0, 250 + x, nil)
    end

    board.digital_write(13, 1)

    assert_equal 1, board.pins[13].value, "Pin value not set"
    mock_sp.verify
  end

  def test_analog_write
    mock_sp = mock_serial_port(233, 127, 1)
    board = Firmata::Board.new(mock_sp)

    8.times do |x|
      board.pins[x + 8] = Firmata::Board::Pin.new([], 0, 250 + x, nil)
    end

    board.analog_write(9, 255)

    assert_equal 255, board.pins[9].value
    mock_sp.verify
  end

  def test_servo_write
    board = Firmata::Board.new(FakeSerialPort.new)
    assert board.respond_to? :servo_write
  end
end