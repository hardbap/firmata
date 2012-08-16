require 'bundler/setup'
require 'firmata'

board = Firmata::Board.new('/dev/tty.usbmodemfa131')

board.on('ready', ->() do

  10.times do
    board.digital_write 13, Firmata::Board::HIGH
    board.delay 1

    board.digital_write 13, Firmata::Board::LOW
    board.delay 1
  end

end)

board.connect

 Thread.new do
  loop do
    board.read
    sleep 1
  end
end