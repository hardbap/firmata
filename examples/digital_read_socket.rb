require 'firmata'
require 'socket'

sp = TCPSocket.open 'localhost', 4567
board = Firmata::Board.new(sp)

board.connect

puts "Firmware name #{board.firmware_name}"
puts "Firmata version #{board.version}"

pin_number = 2
rate = 0.5

listener = ->(pin, value) { puts("#{pin}:#{value}") }
board.on('digital-read', listener)
board.set_pin_mode(pin_number, Firmata::Board::INPUT)
board.toggle_pin_reporting(pin_number)

while true do
  puts "waiting..."
  board.read_and_process
  sleep 0.5
end
