require 'bundler/setup'
require 'firmata'
require 'pry'

board = Firmata::Board.new('/dev/tty.usbmodemfa131')

board.on('ready', ->() { puts board.connected?; board.pry })

until board.connected?
  sleep 1
end