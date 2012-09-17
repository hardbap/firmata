require 'bundler/setup'
require 'firmata'

board = Firmata::Board.new('/dev/tty.usbmodemfd13131')

board.connect

pin_number = 3

10.times do
  board.digital_write pin_number, Firmata::Board::HIGH
  puts '+'
  board.delay 0.5

  board.digital_write pin_number, Firmata::Board::LOW
  puts '-'
  board.delay 0.5
end