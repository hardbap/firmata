require 'bundler/setup'
require 'firmata'
require 'socket'

sp = TCPSocket.open 'localhost', 8023
board = Firmata::Board.new(sp)
 
board.connect
 
puts "Firmware name #{board.firmware_name}"
puts "Firmata version #{board.version}"
 
rate = 0.5
address = 0x52
 
board.on :i2c_reply do |value|
  puts value
end
 
board.i2c_config(0)
board.i2c_write_request(address, 0x40, 0x00)
 
n = 0
while true do
  board.i2c_write_request(address, 0x00, 0x00)
  board.i2c_read_request(address, 6)
  board.read_and_process
  sleep 0.2
end
