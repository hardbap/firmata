require 'bundler/setup'
require 'firmata'

board = Firmata::Board.new('/dev/tty.usbmodemfa131')

board.connect

10.times do
  board.digital_write 13, Firmata::Board::HIGH
  puts '+'
  board.delay 0.5

  board.digital_write 13, Firmata::Board::LOW
  puts '-'
  board.delay 0.5
end