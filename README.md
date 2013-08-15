# Firmata

A Ruby implementation of the [Firmata protocol](http://firmata.org/wiki/V2.3ProtocolDetails).

This library is inspired by the awesome [firmata](http://jgautier.github.com/firmata/) by [jgautier](https://github.com/jgautier).

## Installation

Add this line to your application's Gemfile:

    gem 'firmata'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install firmata

## Prerequisites

1. Download the [Arduio IDE](http://www.arduino.cc/en/Main/Software) for your OS
2. Plug in your Arduino via USB
3. Open the Arduino IDE, select: File > Examples > Firmata > StandardFirmata
4. Click the Upload button
5. Make note of the serial port: Tools > Serial Port

There have been reports of [issues](https://github.com/jgautier/firmata/issues/8) with Firmata 2.3.
Try downgrading to [Firmata 2.2](http://at.or.at/hans/pd/Firmata-2.2.zip) if you're having a problem.

## Usage

Here is a simple example using IRB that will turn pin 13 on and off.
(Replace xxxxx with the USB port from step 5 in Prerequisites)

    1.9.3p194 :001 > require 'firmata'
    1.9.3p194 :002 > board = Firmata::Board.new('/dev/tty.usbmodemxxxxx')
    1.9.3p194 :003 > board.connect
    1.9.3p194 :004 > board.connected?
     => true
    1.9.3p194 :005 > board.version
     => "2.3"
    1.9.3p194 :006 > board.firmware_name
     => "StandardFirmata"
    1.9.3p194 :007 > board.digital_write(13, Firmata::Board::HIGH)
    1.9.3p194 :008 > board.digital_write(13, Firmata::Board::LOW)

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
