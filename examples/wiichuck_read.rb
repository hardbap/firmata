require 'bundler/setup'
require 'firmata'
require 'socket'

sp = TCPSocket.open 'localhost', 4567
#sp = '/dev/tty.usbserial-A700636n'
board = Firmata::Board.new(sp)

board.connect

puts "Firmware name #{board.firmware_name}"
puts "Firmata version #{board.version}"

rate = 0.5
address = 0x52

listener = ->(value) { puts value }
board.on("i2c_reply", listener)

board.i2c_config(0, 0)
[ 0x40, 0x00 ].each do |byte|
  board.i2c_write_request(address, byte)
end

while true do
	puts "waiting..."
	board.i2c_write_request(address, 0x00)
	board.i2c_read_request(address, 6)
	board.read_and_process
	sleep 0.5
end















        every(interval) do
          connection.i2c_request(address, 0x00)
          connection.read_and_process
        end