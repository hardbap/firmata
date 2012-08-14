require 'bundler/setup'
require 'firmata'
require 'irb'

b = Firmata::Board.new('/dev/tty.usbmodemfd13131') do |board|
  puts "I'm in here"

  led_pin = 13

  board.pin_mode(led_pin, Firmata::Board::OUTPUT)

  10.times do
    board.digital_write(led_pin, Firmata::Board::HIGH)

    board.delay(2)

    board.digital_write(led_pin, Firmata::Board::LOW)

    board.delay(2)
  end
end

IRB.setup nil
IRB.conf[:MAIN_CONTEXT] = IRB::Irb.new.context
require 'irb/ext/multi-irb'

IRB.conf[:PROMPT][:MY_PROMPT] = { # name of prompt mode
  :PROMPT_I => "firmata> ",       # normal prompt
  :PROMPT_S => "...",             # prompt for continuing strings
  :PROMPT_C => "...",             # prompt for continuing statement
  :RETURN => "    ==>%s\n"        # format to return value
}
IRB.conf[:PROMPT_MODE] = :MY_PROMPT
IRB.irb nil, b