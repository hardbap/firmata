require 'bundler/setup'
require 'firmata'
require 'pry'

board = Firmata::Board.new('/dev/tty.usbmodemfa131')

board.connect

Thread.new do
  loop do
    begin
      board.read_and_process
      sleep(0.5)
    rescue Exception => e
      puts e.message
      puts e.backtrace.inspect
    end
  end
end

board.pry