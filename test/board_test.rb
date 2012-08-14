require 'minitest/autorun'
require 'minitest/pride'

require_relative '../lib/firmata'
require_relative 'fake_serial_port'

class BoardTest < MiniTest::Unit::TestCase

  def mock_serial_port(*args)
    mock_port = MiniTest::Mock.new
    mock_port.expect(:read_timeout=, 2, [2])
    mock_port.expect(:is_a?, false, [nil])

    expected = args.map(&:chr).join
    mock_port.expect(:write, 1, [expected])

    mock_port
  end

  def test_writing_report_version
    mock_sp = mock_serial_port(Firmata::Board::REPORT_VERSION)

    board = Firmata::Board.new(mock_sp)
    board.report_version

    mock_sp.verify
  end

  def test_reading_report_version
    board = Firmata::Board.new(FakeSerialPort.new)
    board.report_version
    board.read

    assert_equal '2.3', board.version
  end

  def test_writing_capability_query
    mock_sp = mock_serial_port(Firmata::Board::START_SYSEX, Firmata::Board::CAPABILITY_QUERY, Firmata::Board::END_SYSEX)

    board = Firmata::Board.new(mock_sp)
    board.query_capabilities

    mock_sp.verify
  end


  def test_reading_query_capabilities
    board = Firmata::Board.new(FakeSerialPort.new)
    board.query_capabilities
    board.read

    assert_equal 20, board.pins.length
  end

  def test_pin_mode
    flunk
  end

  def test_query_pin_state
    # query_pin_state 13
    # "\xF0n\r\u0001\u0000\xF7"
    flunk
  end

  def test_query_analog_mapping
    # "\xF0j\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u007F\u0000\u0001\u0002\u0003\u0004\u0005\xF7"
    flunk
  end

  def test_turn_pins_on
    # "\xE0\e\u0005\xE1N\u0004\xE2A\u0004\xE3C\u0004\xE4o\u0004\xE5f\u0004\xE0w\u0004\xE1]\u0004\xE2N\u0004\xE3I\u0004\xE4x\u0004\xE5m\u0004\xE0m\u0004\xE1`\u0004\xE2T\u0004\xE3L\u0004\xE4s\u0004\xE5l\u0004\xE0i\u0004\xE1`\u0004\xE2V\u0004\xE3N\u0004\xE4m\u0004\xE5j\u0004\xE0f\u0004\xE1^\u0004\xE2U\u0004\xE3O\u0004\xE4h\u0004\xE5g\u0004\xE0d\u0004\xE1\\\u0004\xE2T\u0004\xE3O\u0004\xE4d\u0004\xE5d\u0004\xE0b\u0004\xE1Z\u0004\xE2S\u0004\xE3N\u0004\xE4`\u0004\xE5a\u0004\xE0_\u0004\xE1X\u0004\xE2Q\u0004\xE3L\u0004\xE4\\\u0004\xE5^\u0004\xE0\\\u0004\xE1T\u0004\xE2N\u0004\xE3J\u0004\xE4X\u0004\xE5Z\u0004\xE0X\u0004\xE1Q\u0004\xE2K\u0004\xE3G\u0004\xE4T\u0004\xE5W\u0004\xE0V\u0004\xE1O\u0004\xE2H\u0004\xE3D\u0004\xE4Q\u0004\xE5T\u0004\xE0S\u0004\xE1L\u0004\xE2F\u0004\xE3B\u0004\xE4N\u0004\xE5Q\u0004\xE0P\u0004\xE1J\u0004\xE2C\u0004\xE3@\u0004\xE4K\u0004\xE5N\u0004\xE0N\u0004\xE1G\u0004\xE2A\u0004\xE3>\u0004\xE4I\u0004\xE5L\u0004\xE0L\u0004\xE1D\u0004\xE2?\u0004\xE3<\u0004\xE4F\u0004\xE5I\u0004\xE0I\u0004\xE1B\u0004\xE2=\u0004\xE39\u0004\xE4C\u0004\xE5F\u0004\xE0F\u0004\xE1?\u0004\xE2:\u0004\xE37\u0004\xE4@\u0004\xE5C\u0004\xE0C\u0004\xE1<\u0004\xE28\u0004\xE34\u0004\xE4>\u0004\xE5A\u0004\xE0A\u0004\xE1:\u0004\xE26\u0004\xE32\u0004\xE4<\u0004\xE5?\u0004\xE0?\u0004\xE19\u0004\xE24\u0004\xE31\u0004\xE4:\u0004\xE5=\u0004\xE0>\u0004\xE17\u0004\xE22\u0004\xE3/\u0004\xE49\u0004\xE5;\u0004\xE0<\u0004\xE15\u0004\xE20\u0004\xE3-\u0004\xE46\u0004\xE59\u0004\xE09\u0004\xE12\u0004\xE2.\u0004\xE3+\u0004\xE44\u0004\xE57\u0004\xE07\u0004\xE10\u0004\xE2,\u0004\xE3)\u0004\xE42\u0004\xE55\u0004\xE05\u0004\xE1.\u0004\xE2*\u0004\xE3'\u0004\xE40\u0004\xE52\u0004\xE03\u0004\xE1-\u0004\xE2(\u0004\xE3&\u0004\xE4/\u0004\xE51\u0004\xE02\u0004\xE1+\u0004\xE2&\u0004\xE3$\u0004\xE4-\u0004\xE50\u0004\xE00\u0004\xE1*\u0004\xE2%\u0004\xE3#\u0004\xE4,\u0004\xE5.\u0004\xE0/\u0004\xE1(\u0004\xE2$\u0004\xE3!\u0004\xE4*\u0004\xE5,\u0004\xE0-\u0004\xE1&\u0004\xE2\"\u0004\xE3\u001F\u0004\xE4(\u0004\xE5*\u0004\xE0+\u0004\xE1$\u0004\xE2 \u0004\xE3\u001D\u0004\xE4&\u0004\xE5(\u0004\xE0)\u0004\xE1\"\u0004\xE2\u001F\u0004\xE3\u001C\u0004\xE4%\u0004\xE5'\u0004\xE0(\u0004\xE1!\u0004\xE2\u001D\u0004\xE3\e\u0004\xE4$\u0004\xE5&\u0004\xE0&\u0004\xE1 \u0004\xE2\u001C\u0004\xE3\u001A\u0004\xE4#\u0004\xE5%\u0004\xE0&\u0004\xE1\u001F\u0004\xE2\e\u0004\xE3\u0019\u0004\xE4\"\u0004\xE5$\u0004\xE0$\u0004\xE1\u001E\u0004\xE2\u0019\u0004\xE3\u0018\u0004\xE4 \u0004\xE5\"\u0004\xE0\"\u0004\xE1\u001C\u0004\xE2\u0018\u0004\xE3\u0016\u0004\xE4\u001F\u0004\xE5 \u0004\xE0!\u0004\xE1\u001A\u0004\xE2\u0017\u0004\xE3\u0014\u0004\xE4\u001D\u0004\xE5\u001E\u0004\xE0\u001F\u0004\xE1\u0019\u0004\xE2\u0015\u0004\xE3\u0013\u0004\xE4\u001C\u0004\xE5\u001D\u0004\xE0\u001E\u0004\xE1\u0018\u0004\xE2\u0013\u0004\xE3\u0012\u0004\xE4\e\u0004\xE5\u001C\u0004\xE0\u001D\u0004\xE1\u0017\u0004\xE2\u0014\u0004\xE3\u0012\u0004\xE4\e\u0004\xE5\u001C\u0004\xE0\u001D\u0004\xE1\u0016\u0004\xE2\u0013\u0004\xE3\u0011\u0004\xE4\u001A\u0004\xE5\e\u0004\xE0\u001C\u0004\xE1\u0015\u0004\xE2\u0011\u0004\xE3\u0010\u0004\xE4\u0018\u0004\xE5\u0019\u0004\xE0\u001A\u0004\xE1\u0014\u0004\xE2\u0010\u0004\xE3\u000E\u0004\xE4\u0017\u0004\xE5\u0018\u0004\xE0\u0018\u0004\xE1\u0012\u0004\xE2\u000E\u0004\xE3\r\u0004\xE4\u0015\u0004\xE5\u0016\u0004\xE0\u0017\u0004\xE1\u0011\u0004\xE2\u000E\u0004\xE3\f\u0004\xE4\u0015\u0004\xE5\u0016\u0004\xE0\u0016\u0004\xE1\u0010\u0004\xE2\f\u0004\xE3\v\u0004\xE4\u0014\u0004\xE5\u0015\u0004\xE0\u0016\u0004\xE1\u000F\u0004\xE2\v\u0004\xE3\n\u0004\xE4\u0013\u0004\xE5\u0014\u0004\xE0\u0015\u0004\xE1\u000F\u0004\xE2\v\u0004\xE3\t\u0004\xE4\u0012\u0004\xE5\u0013\u0004\xE0\u0014\u0004\xE1\u000E\u0004\xE2\n\u0004\xE3\t\u0004\xE4\u0012\u0004\xE5\u0012\u0004\xE0\u0013\u0004\xE1\f\u0004\xE2\t\u0004\xE3\a\u0004\xE4\u0010\u0004\xE5\u0011\u0004\xE0\u0011\u0004\xE1\v\u0004\xE2\b\u0004\xE3\u0006\u0004\xE4\u000F\u0004\xE5\u000F\u0004\xE0\u0010\u0004\xE1\n\u0004\xE2\u0006\u0004\xE3\u0005\u0004\xE4\u000E\u0004\xE5\u000F\u0004\xE0\u000F\u0004\xE1\t\u0004\xE2\u0006\u0004\xE3\u0004\u0004\xE4\r\u0004\xE5\u000E\u0004\xE0\u000F\u0004\xE1\t\u0004\xE2\u0006\u0004\xE3\u0004\u0004\xE4\r\u0004\xE5\u000E\u0004\xE0\u000E\u0004\xE1\b\u0004\xE2\u0004\u0004\xE3\u0003\u0004\xE4\f\u0004\xE5\r\u0004\xE0\u000E\u0004\xE1\a\u0004\xE2\u0004\u0004\xE3\u0003\u0004"
    flunk
  end

  def test_turn_pins_off
    flunk
  end

  def test_reset
    flunk
  end

  def test_firmware_query
    #"\xF9\u0002\u0003\xF0y\u0002\u0003S\u0000t\u0000a\u0000n\u0000d\u0000a\u0000r\u0000d\u0000F\u0000i\u0000r\u0000m\u0000a\u0000t\u0000a\u0000\xF7"
    flunk
  end

  def test_digital_write
    flunk
  end

  def test_delay
    flunk
  end
end