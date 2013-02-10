require 'bundler/setup'
require 'firmata'
require 'socket'

sp = TCPSocket.open 'localhost', 4567
#sp = '/dev/tty.usbserial-A700636n'
board = Firmata::Board.new(sp)

board.connect

pin_number = 3
rate = 0.5

10.times do
  board.digital_write pin_number, Firmata::Board::HIGH
  puts '+'
  board.delay rate

  board.digital_write pin_number, Firmata::Board::LOW
  puts '-'
  board.delay rate
end