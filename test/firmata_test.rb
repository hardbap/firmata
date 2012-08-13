require 'minitest/autorun'
require 'minitest/pride'
require 'pry'

require_relative '../lib/firmata'

class FirmataTest < MiniTest::Unit::TestCase

  def test_report_version
    port = "/dev/tty.usbmodemfa131"
    board = Firmata::Board.new(port)

    board.pry
  end
end