require 'bundler/setup'
require 'firmata'
require 'pry'

board = Firmata::Board.new('/dev/tty.usbmodemfa131')

board.on('ready', ->() { board.pry })

loop do
  board.read
  sleep 1
end until board.connected?