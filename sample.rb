require 'bundler/setup'
require 'firmata'
require 'pry'

board = Firmata::Board.new('/dev/tty.usbmodemfa131')

board.pry