require 'firmata'
require 'socket'

#sp = TCPSocket.open 'localhost', 4567
sp = "/dev/ttyACM0"
board = Firmata::Board.new(sp)
 
board.connect
 
puts "Firmware name #{board.firmware_name}"
puts "Firmata version #{board.version}"
 
rate = 0.5
address = 0x52
 
listener = ->(value) { 
  puts value 
  #value[:data].each do |n|
  # puts "data: #{n}"  
  #nd
}
board.on("i2c_reply", listener)
 
board.i2c_config(0)
board.i2c_write_request(address, 0x40, 0x00)
 
while true do
  board.i2c_write_request(address, 0x00, 0x00)
  board.i2c_read_request(address, 6)
  board.read_and_process
  sleep 0.2
end
