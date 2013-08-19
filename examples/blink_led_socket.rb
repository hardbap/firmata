require 'bundler/setup'
require 'firmata'
require 'socket'

sp = TCPSocket.new 'localhost', 8023
board = Firmata::Board.new(sp)

board.connect

puts "Firmware name #{board.firmware_name}"
puts "Firmata version #{board.version}"

pin_number = 13
rate = 0.5

10.times do
  board.digital_write pin_number, Firmata::PinLevels::HIGH
  puts '+'
  board.delay rate

  board.digital_write pin_number, Firmata::PinLevels::LOW
  puts '-'
  board.delay rate
end
